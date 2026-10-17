import Foundation
import Supabase

/// Everything the user has entered, saved on the phone (and to their account when signed in).
@MainActor
final class AppModel: ObservableObject {
    struct Saved: Codable {
        var hasSeenIntro = false
        var record: PropertyRecord?
        var home = MitigationFeatures()
        var policy = PolicyInfo()
        var policyDone = false
        var setupDone = false
        var completed: Set<PlanStep> = []
        var reminderSet = false
        var neighborhood: Neighborhood?
    }

    @Published var saved: Saved { didSet { persist() } }

    let engine = DiscountEngine()
    private let key = "windcredit.saved.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key), let s = try? JSONDecoder().decode(Saved.self, from: data) {
            saved = s
        } else {
            saved = Saved()
        }
        // Lets UI tests and demos start from a known home.
        if ProcessInfo.processInfo.arguments.contains("-resetState") { saved = Saved() }
        if ProcessInfo.processInfo.arguments.contains("-sampleHome") { loadSample() }
    }

    var estimate: DiscountEngine.Estimate? {
        guard let r = saved.record else { return nil }
        return engine.estimate(record: r, home: saved.home, policy: saved.policy)
    }

    var grant: GrantEligibility? {
        saved.record.map { DiscountEngine.safeFloridaHome(record: $0, policy: saved.policy) }
    }

    /// Possible savings for "Not sure" answers, if an inspection finds the feature.
    var whatIf: [DiscountEngine.MissingCredit] {
        guard let r = saved.record else { return [] }
        return engine.whatIf(record: r, home: saved.home, policy: saved.policy)
    }

    /// True when we can't show savings only because the owner wasn't sure about the features.
    var needsInspectionToKnow: Bool { estimate?.hasSavings == false && !whatIf.isEmpty }

    var savingsText: String {
        if let e = estimate, e.hasSavings { return "\(Self.money(e.missedLow))–\(Self.money(e.missedHigh))" }
        if let best = whatIf.first { return "Up to \(Self.money(best.yearlyHigh))" }
        return "$0"
    }

    var progress: Double { Double(saved.completed.count) / Double(PlanStep.allCases.count) }

    // MARK: Actions

    func setRecord(_ r: PropertyRecord) {
        if saved.record?.parcelID != r.parcelID { saved.neighborhood = nil }
        saved.record = r
        // Preselect what public records suggest. The user confirms on the next screen.
        if saved.home.roofShape == .notSure { saved.home.roofShape = r.roofShapeHint }
    }

    /// Loads the neighborhood count once per home (sample home uses stored numbers).
    func loadNeighborhood() async {
        guard let r = saved.record, saved.neighborhood == nil else { return }
        if r.isSample { saved.neighborhood = .sample; return }
        saved.neighborhood = try? await NeighborhoodService().load(latitude: r.latitude, longitude: r.longitude)
    }

    /// Typical yearly dollars missed for this home (middle of the range), used for the neighborhood estimate.
    var perHomeMissed: Int {
        if let e = estimate, e.hasSavings { return (e.missedLow + e.missedHigh) / 2 }
        if let best = whatIf.first { return (best.yearlyLow + best.yearlyHigh) / 2 }
        return 0
    }

    static let samplePolicy = PolicyInfo(totalPremium: 5_716, hurricanePremium: 3_912, dwellingCoverage: 385_000,
                                         renewalDate: Calendar.current.date(byAdding: .day, value: 148, to: .now),
                                         noMitigationSectionFound: false)

    func confirmHome() { saved.completed.insert(.confirmHome) }

    func finishPolicy(_ p: PolicyInfo) {
        saved.policy = p
        saved.policyDone = true
        saved.completed.insert(.scanPolicy)
    }

    func toggle(_ step: PlanStep) {
        if saved.completed.contains(step) { saved.completed.remove(step) } else { saved.completed.insert(step) }
    }

    func startOver() {
        let intro = saved.hasSeenIntro
        saved = Saved()
        saved.hasSeenIntro = intro
        ReminderService.cancel()
    }

    func eraseEverything() {
        saved = Saved()
        ReminderService.cancel()
    }

    func loadSample() {
        var s = Saved()
        s.hasSeenIntro = true
        s.record = .sample
        s.home = MitigationFeatures(roofShape: .hip, roofToWall: .clips, openings: .hurricane, roofMeetsCode: .no, sealedRoofDeck: .notSure)
        s.policy = PolicyInfo(totalPremium: 6_300, hurricanePremium: nil, dwellingCoverage: 420_000,
                              renewalDate: Calendar.current.date(byAdding: .day, value: 75, to: .now), noMitigationSectionFound: true)
        s.policyDone = true
        s.setupDone = true
        s.completed = [.confirmHome, .scanPolicy]
        s.neighborhood = .sample
        saved = s
    }

    // MARK: Saving

    private func persist() {
        if let data = try? JSONEncoder().encode(saved) { UserDefaults.standard.set(data, forKey: key) }
    }

    /// Saves the home to the signed-in user's row (table `homes`, see supabase/migrations). Failures are ignored: the phone copy is the source of truth.
    func sync(using client: SupabaseClient?) async {
        guard let client, let user = try? await client.auth.session.user, let record = saved.record else { return }
        struct Row: Encodable {
            let user_id: UUID; let parcel_id: String; let address: String
            let features: MitigationFeatures; let completed_steps: [String]; let updated_at: Date
        }
        let row = Row(user_id: user.id, parcel_id: record.parcelID, address: record.address, features: saved.home,
                      completed_steps: saved.completed.map(\.rawValue), updated_at: .now)
        _ = try? await client.from("homes").upsert(row, onConflict: "user_id").execute()
    }

    nonisolated static func money(_ n: Int) -> String {
        n.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}
