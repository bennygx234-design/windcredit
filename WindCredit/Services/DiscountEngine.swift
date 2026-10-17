import Foundation

/// Estimates the wind-mitigation discount a home is missing.
///
/// Florida discounts don't add up. Each combination of features has ONE credit
/// in the state's table (OIR-B1-1699), and the total is capped at 89% of the
/// wind part of the premium. So we look up the whole combination, never sum.
struct DiscountEngine {
    struct Table: Decodable {
        let cap: Double
        let existing: [String: Double]
        let concreteDeck: [String: Double]
        let newConstruction: [String: Double]
        let source: String
    }

    struct MissingCredit: Identifiable, Equatable {
        let id: String
        let title: String
        let why: String
        let yearlyLow: Int
        let yearlyHigh: Int
    }

    struct Estimate: Equatable {
        let creditNow: Double
        let creditPossible: Double
        let windPremium: Double
        let windPremiumWasAssumed: Bool
        let missedLow: Int
        let missedHigh: Int
        let missing: [MissingCredit]
        var hasSavings: Bool { missedHigh > 0 }
    }

    let table: Table

    /// Insurers' own tables differ from the state table and are newer, so we show a cautious range.
    static let lowFactor = 0.5
    static let highFactor = 0.75
    /// Share of the premium that pays for hurricane coverage when the policy doesn't say (Brookings WP114, 2026).
    static let windShareOlder = 0.65
    static let windShareNewer = 0.45

    init(table: Table) { self.table = table }

    init() {
        let url = Bundle.main.url(forResource: "oir_b1_1699", withExtension: "json")
            ?? Bundle(for: BundleToken.self).url(forResource: "oir_b1_1699", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        self.init(table: try! JSONDecoder().decode(Table.self, from: data))
    }

    // MARK: Credit lookup

    /// The credit (0–0.89) for a set of features.
    func credit(for f: MitigationFeatures, newConstruction: Bool, terrain: String = "B") -> Double {
        let shape = f.roofShape == .hip ? "hip" : "other"
        let swr = f.sealedRoofDeck == .yes ? "swr" : "noswr"
        let raw: Double
        if newConstruction {
            let open = f.openings == .hurricane || f.openings == .basic ? "protected" : "none"
            raw = table.newConstruction["\(shape)|\(open)|\(swr)"] ?? 0
        } else {
            let cover = f.roofMeetsCode == .yes ? "FBC" : "nonFBC"
            // Deck nailing can only be seen in the attic, so assume the weakest (A) until an inspection says otherwise.
            let key = "\(cover)|A|\(f.roofToWall.tableKey)|\(f.openings.tableKey)|\(terrain)|\(shape)|\(swr)"
            raw = table.existing[key] ?? 0
        }
        return min(raw, table.cap)
    }

    // MARK: Estimate

    func estimate(record: PropertyRecord, home: MitigationFeatures, policy: PolicyInfo) -> Estimate? {
        guard let total = policy.totalPremium, total > 0 else { return nil }
        let isNew = record.isNewConstruction

        // What the home could get: the better of what the policy already credits and what the owner says it has.
        let possible = Self.best(home, policy.creditedFeatures)
        let cNow = credit(for: policy.creditedFeatures, newConstruction: isNew)
        let cPossible = max(cNow, credit(for: possible, newConstruction: isNew))

        let assumed = policy.hurricanePremium == nil
        let wind = policy.hurricanePremium ?? total * (isNew ? Self.windShareNewer : Self.windShareOlder)

        let (low, high) = range(wind: wind, from: cNow, to: cPossible)

        // Worth of each missing feature on its own (they overlap, so these don't add up to the total).
        var missing: [MissingCredit] = []
        func check(_ id: String, _ title: String, _ why: String, _ apply: (inout MitigationFeatures) -> Void) {
            var one = policy.creditedFeatures
            apply(&one)
            let c = max(cNow, credit(for: one, newConstruction: isNew))
            let (l, h) = range(wind: wind, from: cNow, to: c)
            if h > 0 { missing.append(.init(id: id, title: title, why: why, yearlyLow: l, yearlyHigh: h)) }
        }
        if possible.roofShape == .hip && policy.creditedFeatures.roofShape != .hip {
            check("hip", "Hip roof credit", "Roofs that slope on all four sides resist wind better.") { $0.roofShape = .hip }
        }
        if !isNew, Self.strength(possible.roofToWall) > Self.strength(policy.creditedFeatures.roofToWall) {
            check("roofToWall", "\(possible.roofToWall.title) credit", "Metal ties keep the roof from lifting off in high wind.") { $0.roofToWall = possible.roofToWall }
        }
        if Self.strength(possible.openings) > Self.strength(policy.creditedFeatures.openings) {
            check("openings", "Window protection credit", "Protected windows keep wind from getting inside and pushing the roof up.") { $0.openings = possible.openings }
        }
        if !isNew, possible.roofMeetsCode == .yes && policy.creditedFeatures.roofMeetsCode != .yes {
            check("roofCover", "Building-code roof credit", "Roofs installed after 2002 meet the stronger Florida Building Code.") { $0.roofMeetsCode = .yes }
        }
        if possible.sealedRoofDeck == .yes && policy.creditedFeatures.sealedRoofDeck != .yes {
            check("swr", "Sealed roof deck credit", "A sealed deck keeps rain out if shingles or tiles blow off.") { $0.sealedRoofDeck = .yes }
        }

        return Estimate(creditNow: cNow, creditPossible: cPossible, windPremium: wind, windPremiumWasAssumed: assumed,
                        missedLow: low, missedHigh: high, missing: missing.sorted { $0.yearlyHigh > $1.yearlyHigh })
    }

    /// For "Not sure" answers: what each common feature would be worth if an inspector finds it.
    func whatIf(record: PropertyRecord, home: MitigationFeatures, policy: PolicyInfo) -> [MissingCredit] {
        guard let total = policy.totalPremium, total > 0 else { return [] }
        let isNew = record.isNewConstruction
        let credited = policy.creditedFeatures
        let cNow = credit(for: credited, newConstruction: isNew)
        let wind = policy.hurricanePremium ?? total * (isNew ? Self.windShareNewer : Self.windShareOlder)
        var out: [MissingCredit] = []
        func add(_ id: String, _ title: String, _ why: String, unknown: Bool, _ apply: (inout MitigationFeatures) -> Void) {
            guard unknown else { return }
            var f = credited
            apply(&f)
            let (l, h) = range(wind: wind, from: cNow, to: max(cNow, credit(for: f, newConstruction: isNew)))
            if h > 0 { out.append(.init(id: id, title: title, why: why, yearlyLow: l, yearlyHigh: h)) }
        }
        add("hip", "If it’s a hip roof", "Look at your roof from the street: slopes on all four sides?",
            unknown: home.roofShape == .notSure && credited.roofShape != .hip) { $0.roofShape = .hip }
        add("roofToWall", "If it has metal clips", "Often found in homes built after Hurricane Andrew (1992).",
            unknown: !isNew && home.roofToWall == .notSure && Self.strength(credited.roofToWall) == 0) { $0.roofToWall = .clips }
        add("openings", "If windows are protected", "Impact windows or rated shutters on every opening.",
            unknown: home.openings == .notSure && Self.strength(credited.openings) == 0) { $0.openings = .hurricane }
        return out.sorted { $0.yearlyHigh > $1.yearlyHigh }
    }

    /// Dollars a year saved moving from one credit to another.
    /// The wind premium on the policy is already discounted by `from`, so undo that first.
    func range(wind: Double, from cNow: Double, to cNew: Double) -> (Int, Int) {
        guard cNew > cNow, cNow < 1 else { return (0, 0) }
        let missed = wind * (cNew - cNow) / (1 - cNow)
        return (Self.roundTo50(missed * Self.lowFactor), Self.roundTo50(missed * Self.highFactor))
    }

    static func roundTo50(_ x: Double) -> Int { Int((x / 50).rounded()) * 50 }

    static func best(_ a: MitigationFeatures, _ b: MitigationFeatures) -> MitigationFeatures {
        var r = a
        if b.roofShape == .hip { r.roofShape = .hip }
        if strength(b.roofToWall) > strength(a.roofToWall) { r.roofToWall = b.roofToWall }
        if strength(b.openings) > strength(a.openings) { r.openings = b.openings }
        if b.roofMeetsCode == .yes { r.roofMeetsCode = .yes }
        if b.sealedRoofDeck == .yes { r.sealedRoofDeck = .yes }
        return r
    }

    static func strength(_ r: RoofToWall) -> Int {
        switch r { case .notSure, .toeNails: 0; case .clips: 1; case .singleWraps: 2; case .doubleWraps: 3 }
    }
    static func strength(_ o: OpeningProtection) -> Int {
        switch o { case .notSure, .none: 0; case .basic: 1; case .hurricane: 2 }
    }
}

// MARK: - My Safe Florida Home eligibility (Fla. Stat. 215.5586)

enum GrantEligibility: Equatable {
    case likely, maybe(String), no(String)
}

extension DiscountEngine {
    static func safeFloridaHome(record: PropertyRecord, policy: PolicyInfo) -> GrantEligibility {
        if record.isCondo { return .no("Condos use the separate Condo Pilot program.") }
        if !record.isSingleFamilyOrTownhouse { return .no("Only single-family homes and townhouses qualify.") }
        if !record.homestead { return .no("The home needs a homestead exemption.") }
        guard let year = record.yearBuilt else { return .maybe("We couldn’t find the year built.") }
        if year >= 2008 { return .no("Homes permitted in 2008 or later don’t qualify.") }
        guard let dwelling = policy.dwellingCoverage else { return .maybe("Check that your dwelling coverage is $700,000 or less.") }
        if dwelling > 700_000 { return .maybe("Dwelling coverage over $700,000 qualifies only for low-income owners.") }
        return .likely
    }
}

private final class BundleToken {}
