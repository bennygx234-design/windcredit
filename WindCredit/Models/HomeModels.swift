import Foundation

// MARK: - Wind-mitigation features (mirror the 7 questions on OIR-B1-1802)

enum RoofShape: String, Codable, CaseIterable, Identifiable {
    case hip, gable, flat, notSure
    var id: String { rawValue }
    var title: String {
        switch self {
        case .hip: "Hip"
        case .gable: "Gable"
        case .flat: "Flat"
        case .notSure: "Not sure"
        }
    }
    var detail: String {
        switch self {
        case .hip: "Slopes down on all four sides"
        case .gable: "Triangle ends on two sides"
        case .flat: "Flat or nearly flat"
        case .notSure: "We’ll assume no credit"
        }
    }
}

enum RoofToWall: String, Codable, CaseIterable, Identifiable {
    case toeNails, clips, singleWraps, doubleWraps, notSure
    var id: String { rawValue }
    var title: String {
        switch self {
        case .toeNails: "Nails only"
        case .clips: "Metal clips"
        case .singleWraps: "Single straps"
        case .doubleWraps: "Double straps"
        case .notSure: "Not sure"
        }
    }
    var detail: String {
        switch self {
        case .toeNails: "Roof beams nailed at an angle"
        case .clips: "Small metal brackets on each beam"
        case .singleWraps: "One strap wraps over each beam"
        case .doubleWraps: "Straps on both sides of each beam"
        case .notSure: "An inspector checks this in the attic"
        }
    }
    // "Not sure" gets no credit, same as toe nails.
    var tableKey: String { self == .notSure ? RoofToWall.toeNails.rawValue : rawValue }
}

enum OpeningProtection: String, Codable, CaseIterable, Identifiable {
    case hurricane, basic, none, notSure
    var id: String { rawValue }
    var title: String {
        switch self {
        case .hurricane: "Impact windows or rated shutters"
        case .basic: "Some protection"
        case .none: "None or plywood"
        case .notSure: "Not sure"
        }
    }
    var detail: String {
        switch self {
        case .hurricane: "On every window and glass door"
        case .basic: "Rated, but not for large debris"
        case .none: "Citizens gives plywood no credit"
        case .notSure: "We’ll assume no credit"
        }
    }
    var tableKey: String {
        switch self {
        case .hurricane: "hurricane"
        case .basic: "basic"
        case .none, .notSure: "none"
        }
    }
}

enum RoofCover: String, Codable, CaseIterable {
    case tile, shingle, metal, flat, other, unknown
    var title: String {
        switch self {
        case .tile: "Tile"
        case .shingle: "Shingle"
        case .metal: "Metal"
        case .flat: "Flat roof"
        case .other: "Other"
        case .unknown: "Unknown"
        }
    }

    static func fromAppraiser(_ text: String) -> RoofCover {
        let t = text.uppercased()
        if t.contains("TILE") { return .tile }
        if t.contains("SHG") || t.contains("SHINGLE") || t.contains("COMP") { return .shingle }
        if t.contains("METAL") || t.contains("ALUM") || t.contains("STEEL") { return .metal }
        if t.contains("BUILT") || t.contains("MEMBRANE") || t.contains("ROLL") || t.contains("TAR") { return .flat }
        if t.isEmpty { return .unknown }
        return .other
    }
}

enum YesNoUnsure: String, Codable, CaseIterable, Identifiable {
    case yes, no, notSure
    var id: String { rawValue }
    var title: String {
        switch self {
        case .yes: "Yes"
        case .no: "No"
        case .notSure: "Not sure"
        }
    }
}

struct MitigationFeatures: Codable, Equatable {
    var roofShape: RoofShape = .notSure
    var roofToWall: RoofToWall = .notSure
    var openings: OpeningProtection = .notSure
    // Roof put on after March 1, 2002 counts as meeting the Florida Building Code.
    var roofMeetsCode: YesNoUnsure = .notSure
    // SWR = secondary water resistance (sealed roof deck).
    var sealedRoofDeck: YesNoUnsure = .notSure
}

// MARK: - The home, from public records

struct PropertyRecord: Codable, Equatable {
    var parcelID: String
    var address: String
    var municipality: String
    var useDescription: String
    var yearBuilt: Int?
    var roofCoverText: String
    var roofStructureText: String
    var livingArea: Int?
    var marketValue: Int?
    var homestead: Bool
    var isCondo: Bool
    var latitude: Double
    var longitude: Double

    var roofCover: RoofCover { RoofCover.fromAppraiser(roofCoverText) }

    var streetName: String {
        let words = (address.components(separatedBy: ",").first ?? address).split(separator: " ").map(String.init)
        let name = words.first?.allSatisfy(\.isNumber) == true ? Array(words.dropFirst()) : words
        return Self.prettify(name.joined(separator: " "))
    }

    // .capitalized turns "SW 18TH" into "Sw 18Th", so do it by hand.
    var displayAddress: String { isSample ? address : Self.prettify(address) }

    static func prettify(_ text: String) -> String {
        let directions: Set<String> = ["N", "S", "E", "W", "NE", "NW", "SE", "SW"]
        return text.split(separator: " ").map { raw -> String in
            let word = String(raw)
            let core = word.trimmingCharacters(in: .punctuationCharacters).uppercased()
            if directions.contains(core) { return word.uppercased() }
            if let first = word.first, first.isNumber { return word.lowercased() }
            return word.capitalized
        }.joined(separator: " ")
    }

    var roofShapeHint: RoofShape {
        let t = roofStructureText.uppercased()
        if t.contains("HIP") && !t.contains("GABLE") { return .hip }
        if t.contains("GABLE") && !t.contains("HIP") { return .gable }
        if t.contains("FLAT") { return .flat }
        return .notSure
    }

    var isNewConstruction: Bool { (yearBuilt ?? 0) >= 2002 }
    var isSingleFamilyOrTownhouse: Bool {
        let u = useDescription.uppercased()
        return !isCondo && (u.contains("SINGLE") || u.contains("TOWNHOUSE") || u.contains("SFR"))
    }

    var isSample: Bool { parcelID == PropertyRecord.sample.parcelID }

    // Made-up 1993 Boca house for demos. Not a real owner's record.
    static let sample = PropertyRecord(
        parcelID: "SAMPLE-HOME", address: "Sample home, Boca Raton", municipality: "BOCA RATON",
        useDescription: "SINGLE FAMILY", yearBuilt: 1993, roofCoverText: "CONCRETE TILE",
        roofStructureText: "GABLE/HIP", livingArea: 1776, marketValue: 683_966, homestead: true,
        isCondo: false, latitude: 26.33195, longitude: -80.11389)
}

// MARK: - The policy, from the declarations page

struct PolicyInfo: Codable, Equatable {
    var totalPremium: Double?
    var hurricanePremium: Double?
    var dwellingCoverage: Double?
    var renewalDate: Date?
    // What the insurer already credits, per the declarations page.
    var creditedFeatures = MitigationFeatures()
    var noMitigationSectionFound = false
}

// MARK: - Action plan

enum PlanStep: String, Codable, CaseIterable, Identifiable {
    case confirmHome, scanPolicy, bookInspection, sendToAgent
    var id: String { rawValue }
    var title: String {
        switch self {
        case .confirmHome: "Confirm your home"
        case .scanPolicy: "Scan your policy"
        case .bookInspection: "Get a wind-mitigation inspection"
        case .sendToAgent: "Send the report to your agent"
        }
    }
    var detail: String {
        switch self {
        case .confirmHome: "Roof shape, straps and windows"
        case .scanPolicy: "So we know what you already get"
        case .bookInspection: "About $100–$200, or free through My Safe Florida Home if eligible. Good for 5 years."
        case .sendToAgent: "Credits start once your insurer has the form"
        }
    }
}
