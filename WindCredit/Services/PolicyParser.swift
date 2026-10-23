import Foundation
import UIKit
import Vision

// OCR runs on-device with Vision. The photo never leaves the phone.
enum PolicyScanner {
    static func readText(from image: UIImage) async throws -> [String] {
        guard let cg = image.cgImage else { return [] }
        let orientation = image.cgOrientation
        // perform() is synchronous, so run it off the main thread and read results afterwards.
        // (Using a completion handler here risked resuming the continuation twice on errors.)
        return try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            try VNImageRequestHandler(cgImage: cg, orientation: orientation).perform([request])
            return (request.results ?? [])
                .sorted { a, b in
                    // Vision's y axis starts at the bottom
                    abs(a.boundingBox.midY - b.boundingBox.midY) > 0.01
                        ? a.boundingBox.midY > b.boundingBox.midY : a.boundingBox.minX < b.boundingBox.minX
                }
                .compactMap { $0.topCandidates(1).first?.string }
        }.value
    }
}

// Every insurer lays out the page differently, so look for labels and grab the amount next to them.
enum PolicyParser {
    // Order matters: the most specific wording is tried first.
    private enum Labels {
        static let total = ["TOTAL POLICY PREMIUM", "TOTAL PREMIUM", "ANNUAL PREMIUM", "POLICY PREMIUM", "TOTAL ANNUAL"]
        static let hurricane = ["HURRICANE PREMIUM", "WINDSTORM PREMIUM", "WIND PREMIUM", "HURRICANE WIND PREMIUM"]
        static let notHurricane = ["NON-HURRICANE", "NON HURRICANE", "EXCLUDING"]
        static let dwelling = ["COVERAGE A", "DWELLING"]
    }

    static func parse(lines: [String]) -> PolicyInfo {
        var info = PolicyInfo()
        let upper = lines.map { $0.uppercased() }

        info.totalPremium = amount(after: Labels.total, in: upper)
        info.hurricanePremium = amount(after: Labels.hurricane, in: upper, excluding: Labels.notHurricane)
        info.dwellingCoverage = amount(after: Labels.dwelling, in: upper)
        info.renewalDate = renewalDate(in: upper)

        let all = upper.joined(separator: "\n")
        var f = MitigationFeatures()
        // only trust HIP when it's on a line that mentions the roof
        if line(in: upper, containsAll: ["ROOF"], any: ["HIP"]) != nil, !all.contains("NON-HIP") { f.roofShape = .hip }
        else if line(in: upper, containsAll: ["ROOF"], any: ["GABLE", "OTHER"]) != nil { f.roofShape = .gable }

        if all.contains("DOUBLE WRAP") { f.roofToWall = .doubleWraps }
        else if all.contains("SINGLE WRAP") { f.roofToWall = .singleWraps }
        else if all.range(of: #"\bCLIPS?\b"#, options: .regularExpression) != nil { f.roofToWall = .clips }
        else if all.contains("TOE NAIL") { f.roofToWall = .toeNails }

        if let l = line(in: upper, containsAll: [], any: ["OPENING PROTECTION", "OPENING PROT", "SHUTTER"]) {
            if l.contains("NONE") || l.range(of: #"\bNO\b"#, options: .regularExpression) != nil { f.openings = .none }
            else if l.contains("HURRICANE") || l.contains("CLASS A") || l.contains("IMPACT") { f.openings = .hurricane }
            else if l.contains("BASIC") || l.contains("CLASS B") || l.contains("INTERMEDIATE") { f.openings = .basic }
        }
        if let l = line(in: upper, containsAll: [], any: ["SECONDARY WATER", "SWR", "SEALED ROOF DECK"]) {
            if l.contains("YES") { f.sealedRoofDeck = .yes }
            else if l.range(of: #"\bNO\b"#, options: .regularExpression) != nil { f.sealedRoofDeck = .no }
        }
        if line(in: upper, containsAll: ["ROOF"], any: ["FBC", "BUILDING CODE", "MEETS"]) != nil { f.roofMeetsCode = .yes }

        info.creditedFeatures = f
        let mentionsMitigation = ["MITIGATION", "WIND LOSS", "WINDSTORM LOSS", "WLM", "HURRICANE DISCOUNT", "WIND CREDIT"].contains { all.contains($0) }
        info.noMitigationSectionFound = !mentionsMitigation && f == MitigationFeatures()
        return info
    }

    // MARK: Helpers

    // some pages put the amount on the line below the label
    static func amount(after labels: [String], in lines: [String], excluding: [String] = []) -> Double? {
        for label in labels {
            for (i, l) in lines.enumerated() where l.contains(label) && !excluding.contains(where: { l.contains($0) }) {
                let rest = String(l[l.range(of: label)!.upperBound...])
                if let v = firstDollar(in: rest) { return v }
                if i + 1 < lines.count, let v = firstDollar(in: lines[i + 1]) { return v }
            }
        }
        return nil
    }

    static func firstDollar(in text: String) -> Double? {
        let pattern = #"\$?\s?(\d{1,3}(?:,\d{3})+|\d{3,7})(?:\.(\d{2}))?"#
        guard let re = try? NSRegularExpression(pattern: pattern),
              let m = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let r = Range(m.range(at: 1), in: text)
        else { return nil }
        var s = text[r].replacingOccurrences(of: ",", with: "")
        if let c = Range(m.range(at: 2), in: text) { s += "." + text[c] }
        guard let v = Double(s), v >= 100 else { return nil }
        // a bare 2026 is a year, not a premium
        if (1990...2040).contains(v) && !text.contains("$") && !text.contains(",") { return nil }
        return v
    }

    static func line(in lines: [String], containsAll: [String], any: [String]) -> String? {
        lines.first { l in containsAll.allSatisfy { l.contains($0) } && any.contains { l.contains($0) } }
    }

    // renewal = later date on the policy period / expiration line
    static func renewalDate(in lines: [String]) -> Date? {
        let keyed = lines.enumerated().filter { _, l in
            ["POLICY PERIOD", "EXPIRATION", "EXPIRES"].contains { l.contains($0) }
                || l.range(of: #"\bPOLICY TERM\b|\bTERM:"#, options: .regularExpression) != nil
        }
        for (i, l) in keyed {
            let text = l + " " + (i + 1 < lines.count ? lines[i + 1] : "")
            if let d = dates(in: text).max() { return d }
        }
        return nil
    }

    static func dates(in text: String) -> [Date] {
        let re = try! NSRegularExpression(pattern: #"(\d{1,2})/(\d{1,2})/(\d{2,4})"#)
        let ns = text as NSString
        return re.matches(in: text, range: NSRange(location: 0, length: ns.length)).compactMap { m in
            guard var y = Int(ns.substring(with: m.range(at: 3))),
                  let month = Int(ns.substring(with: m.range(at: 1))), (1...12).contains(month),
                  let day = Int(ns.substring(with: m.range(at: 2))), (1...31).contains(day)
            else { return nil }
            if y < 100 { y += 2000 }
            guard (2000...2100).contains(y) else { return nil }
            // Calendar would quietly roll Feb 31 into March, so check the round trip.
            let cal = Calendar(identifier: .gregorian)
            guard let date = cal.date(from: DateComponents(year: y, month: month, day: day)),
                  cal.component(.day, from: date) == day else { return nil }
            return date
        }
    }
}

extension UIImage {
    var cgOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: .up
        case .down: .down
        case .left: .left
        case .right: .right
        case .upMirrored: .upMirrored
        case .downMirrored: .downMirrored
        case .leftMirrored: .leftMirrored
        case .rightMirrored: .rightMirrored
        @unknown default: .up
        }
    }
}
