import XCTest
@testable import WindCredit

final class DiscountEngineTests: XCTestCase {
    let engine = DiscountEngine()

    func testTableMatchesStateValues() {
        // Spot-checks against OIR-B1-1699 (Terrain B, non-FBC cover, deck A).
        var f = MitigationFeatures()
        XCTAssertEqual(engine.credit(for: f, newConstruction: false), 0, accuracy: 0.0001)
        f.roofShape = .hip
        XCTAssertEqual(engine.credit(for: f, newConstruction: false), 0.4684, accuracy: 0.0001)
        f = MitigationFeatures(roofToWall: .clips)
        XCTAssertEqual(engine.credit(for: f, newConstruction: false), 0.3460, accuracy: 0.0001)
        f = MitigationFeatures(openings: .hurricane)
        XCTAssertEqual(engine.credit(for: f, newConstruction: false), 0.4388, accuracy: 0.0001)
    }

    func testDiscountsDoNotAddUp() {
        let hip = engine.credit(for: .init(roofShape: .hip), newConstruction: false)
        let clips = engine.credit(for: .init(roofToWall: .clips), newConstruction: false)
        let both = engine.credit(for: .init(roofShape: .hip, roofToWall: .clips), newConstruction: false)
        XCTAssertLessThan(both, hip + clips)
        XCTAssertGreaterThan(both, max(hip, clips))
    }

    func testCapAt89Percent() {
        let best = MitigationFeatures(roofShape: .hip, roofToWall: .doubleWraps, openings: .hurricane, roofMeetsCode: .yes, sealedRoofDeck: .yes)
        XCTAssertLessThanOrEqual(engine.credit(for: best, newConstruction: false), 0.89)
        XCTAssertLessThanOrEqual(engine.credit(for: best, newConstruction: true), 0.89)
    }

    func testNewConstructionStartsHigh() {
        XCTAssertGreaterThanOrEqual(engine.credit(for: MitigationFeatures(), newConstruction: true), 0.68)
    }

    func testEstimateForTypicalOlderBocaHome() throws {
        // 1993 home, $6,300 premium, nothing credited, owner reports hip roof + clips.
        let policy = PolicyInfo(totalPremium: 6_300)
        let home = MitigationFeatures(roofShape: .hip, roofToWall: .clips)
        let e = try XCTUnwrap(engine.estimate(record: .sample, home: home, policy: policy))
        XCTAssertTrue(e.windPremiumWasAssumed)
        XCTAssertEqual(e.windPremium, 6_300 * 0.65, accuracy: 0.01)
        XCTAssertGreaterThan(e.missedLow, 0)
        XCTAssertLessThan(e.missedLow, e.missedHigh)
        XCTAssertEqual(e.missedLow % 50, 0)
        XCTAssertEqual(Set(e.missing.map(\.id)), ["hip", "roofToWall"])
    }

    func testNoSavingsWhenPolicyAlreadyCreditsEverything() throws {
        let f = MitigationFeatures(roofShape: .hip, roofToWall: .clips, openings: .hurricane)
        var policy = PolicyInfo(totalPremium: 5_000, hurricanePremium: 2_000)
        policy.creditedFeatures = f
        let e = try XCTUnwrap(engine.estimate(record: .sample, home: f, policy: policy))
        XCTAssertFalse(e.hasSavings)
        XCTAssertTrue(e.missing.isEmpty)
    }

    func testListedWindPremiumIsUsed() throws {
        let e = try XCTUnwrap(engine.estimate(record: .sample, home: .init(roofShape: .hip),
                                              policy: PolicyInfo(totalPremium: 6_000, hurricanePremium: 3_000)))
        XCTAssertFalse(e.windPremiumWasAssumed)
        // 3000 × 0.4684 = 1405 → low 700, high 1050 (rounded to $50)
        XCTAssertEqual(e.missedLow, 700)
        XCTAssertEqual(e.missedHigh, 1_050)
    }

    func testGrantEligibility() {
        var p = PolicyInfo(totalPremium: 5_000)
        p.dwellingCoverage = 400_000
        XCTAssertEqual(DiscountEngine.safeFloridaHome(record: .sample, policy: p), .likely)
        var newer = PropertyRecord.sample
        newer.yearBuilt = 2010
        if case .no = DiscountEngine.safeFloridaHome(record: newer, policy: p) {} else { XCTFail() }
        var condo = PropertyRecord.sample
        condo.isCondo = true
        if case .no = DiscountEngine.safeFloridaHome(record: condo, policy: p) {} else { XCTFail() }
    }
}

final class PolicyParserTests: XCTestCase {
    func testParsesTypicalDeclarationsPage() {
        let lines = [
            "HOMEOWNERS DECLARATIONS",
            "POLICY PERIOD: 03/15/2026 TO 03/15/2027",
            "COVERAGE A - DWELLING $385,000",
            "HURRICANE PREMIUM $3,912.00",
            "NON-HURRICANE PREMIUM $1,804.00",
            "TOTAL POLICY PREMIUM $5,716.00",
            "WIND LOSS MITIGATION",
            "ROOF SHAPE: HIP",
            "ROOF TO WALL: TOE NAILS",
            "OPENING PROTECTION: NONE",
            "SECONDARY WATER RESISTANCE: NO",
        ]
        let p = PolicyParser.parse(lines: lines)
        XCTAssertEqual(p.totalPremium, 5_716)
        XCTAssertEqual(p.hurricanePremium, 3_912)
        XCTAssertEqual(p.dwellingCoverage, 385_000)
        XCTAssertEqual(p.creditedFeatures.roofShape, .hip)
        XCTAssertEqual(p.creditedFeatures.roofToWall, .toeNails)
        XCTAssertEqual(p.creditedFeatures.openings, .none)
        XCTAssertEqual(p.creditedFeatures.sealedRoofDeck, .no)
        XCTAssertFalse(p.noMitigationSectionFound)
        let renewal = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: p.renewalDate!)
        XCTAssertEqual(renewal.year, 2027)
        XCTAssertEqual(renewal.month, 3)
    }

    func testAmountOnNextLine() {
        let p = PolicyParser.parse(lines: ["Total Annual Premium", "$4,250"])
        XCTAssertEqual(p.totalPremium, 4_250)
        XCTAssertTrue(p.noMitigationSectionFound)
    }

    func testIgnoresYearsAsAmounts() {
        XCTAssertNil(PolicyParser.firstDollar(in: " 2026"))
        XCTAssertEqual(PolicyParser.firstDollar(in: " $2,026"), 2_026)
    }
}

final class PropertyLookupTests: XCTestCase {
    func testParsesAppraiserPage() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "papa_sfr", withExtension: "html"))
        let d = try PropertyLookupService.parseAppraiserPage(String(contentsOf: url, encoding: .utf8))
        XCTAssertEqual(d.yearBuilt, 1993)
        XCTAssertEqual(d.roofCover, "CONCRETE TILE")
        XCTAssertEqual(d.roofStructure, "GABLE/HIP")
        XCTAssertEqual(d.livingArea, 1776)
        XCTAssertEqual(d.homestead, true)
        XCTAssertEqual(RoofCover.fromAppraiser(d.roofCover), .tile)
    }

    func testPicksParcelMatchingHouseNumber() {
        let a = PropertyLookupService.Parcel(parid: "1", use: "SINGLE FAMILY", isCondo: false, homestead: false, market: nil, municipality: "", site: "1400 SW 18TH ST")
        let b = PropertyLookupService.Parcel(parid: "2", use: "SINGLE FAMILY", isCondo: false, homestead: true, market: nil, municipality: "", site: "1398 SW 18TH ST")
        XCTAssertEqual(PropertyLookupService.pick([a, b], houseNumber: "1398")?.parid, "2")
        XCTAssertNil(PropertyLookupService.pick([a, b], houseNumber: nil))
        XCTAssertEqual(PropertyLookupService.houseNumber(in: "1398 SW 18th St, Boca Raton"), "1398")
    }

    func testDisplayAddress() {
        var r = PropertyRecord.sample
        r.address = "1398 SW 18TH ST, BOCA RATON, 33486"
        XCTAssertEqual(r.displayAddress, "1398 SW 18th St, Boca Raton, 33486")
    }

    func testRoofShapeHint() {
        var r = PropertyRecord.sample
        XCTAssertEqual(r.roofShapeHint, .notSure) // "GABLE/HIP" is ambiguous
        r.roofStructureText = "HIP"
        XCTAssertEqual(r.roofShapeHint, .hip)
    }
}
