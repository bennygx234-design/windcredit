import Foundation
import UIKit
import Vision

/// Reads a photo of an insurance declarations page (the summary page of a policy) on the phone.
/// Nothing is uploaded: Apple's Vision framework does the reading on-device.
enum PolicyScanner {
    static func readText(from image: UIImage) async throws -> [String] {
        guard let cg = image.cgImage else { return [] }
        return try await withCheckedThrowingContinuation { cont in
            let request = VNRecognizeTextRequest { req, err in
                if let err { cont.resume(throwing: err); return }
                let lines = (req.results as? [VNRecognizedTextObservation] ?? [])
                    .sorted { a, b in
                        // Top-to-bottom, then left-to-right (Vision's y axis starts at the bottom).
                        abs(a.boundingBox.midY - b.boundingBox.midY) > 0.01
                            ? a.boundingBox.midY > b.boundingBox.midY : a.boundingBox.minX < b.boundingBox.minX
                    }
                    .compactMap { $0.topCandidates(1).first?.string }
                cont.resume(returning: lines)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            DispatchQueue.global(qos: .userInitiated).async {
                do { try VNImageRequestHandler(cgImage: cg, orientation: image.cgOrientation).perform([request]) }
                catch { cont.resume(throwing: error) }
            }
        }
    }
}

/// Turns the declarations-page text into numbers and credits.
/// Every insurer formats its page differently, so this looks for labels and the dollar amount next to them.
enum PolicyParser {
    static func parse(lines: [String]) -> PolicyInfo {
        var info = PolicyInfo()
        let upper = lines.map { $0.uppercased() }

        info.totalPremium = amount(after: ["TOTAL POLICY PREMIUM", "TOTAL PREMIUM", "ANNUAL PREMIUM", "POLICY PREMIUM", "TOTAL ANNUAL"], in: upper)
        info.hurricanePremium = amount(after: ["HURRICANE PREMIUM", "WINDSTORM PREMIUM", "WIND PREMIUM", "HURRICANE WIND PREMIUM"], in: upper, excluding: ["NON-HURRICANE", "NON HURRICANE", "EXCLUDING"])
        info.dwellingCoverage = amount(after: ["COVERAGE A", "DWELLING"], in: upper)
        info.renewalDate = renewalDate(in: upper)

        let all = upper.joined(separator: "\n")
        var f = MitigationFeatures()
        // Roof shape: only credit "HIP" when it's on a roof line, not part of another word.
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

    /// The first dollar amount on the line with a label, or on the next line (some pages put it below).
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
        // Skip things that look like years (a lone 2026 next to a label is rarely a premium).
        if (1990...2040).contains(v) && !text.contains("$") && !text.contains(",") { return nil }
        return v
    }

    static func line(in lines: [String], containsAll: [String], any: [String]) -> String? {
        lines.first { l in containsAll.allSatisfy { l.contains($0) } && any.contains { l.contains($0) } }
    }

    /// Renewal = the end of the policy period: the later of the dates on the "policy period" or "expiration" line.
    static func renewalDate(in lines: [String]) -> Date? {
        let keyed = lines.enumerated().filter { _, l in ["POLICY PERIOD", "EXPIRATION", "EXPIRES", "TERM"].contains { l.contains($0) } }
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
            var y = Int(ns.substring(with: m.range(at: 3)))!
            if y < 100 { y += 2000 }
            let comps = DateComponents(year: y, month: Int(ns.substring(with: m.range(at: 1))), day: Int(ns.substring(with: m.range(at: 2))))
            return Calendar(identifier: .gregorian).date(from: comps)
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
