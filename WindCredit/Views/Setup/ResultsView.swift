import SwiftUI

/// The payoff: dollars a year likely missed, which discounts, and why.
struct ResultsView: View {
    @EnvironmentObject var model: AppModel
    let isSetup: Bool
    @State private var showMath = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let e = model.estimate {
                    headline(e)
                    if !e.missing.isEmpty { missingList(e) }
                    if let g = model.grant { grantCard(g) }
                    assumptions(e)
                } else {
                    ContentUnavailableView("Add your premium", systemImage: "doc.text",
                                           description: Text("We need your yearly premium to estimate dollars."))
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            if isSetup {
                BottomBar {
                    Button("Make my plan") { model.saved.setupDone = true }
                        .buttonStyle(PrimaryButtonStyle(color: Theme.coral))
                        .accessibilityIdentifier("makePlan")
                }
            }
        }
        .navigationTitle(isSetup ? "" : "Your savings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func headline(_ e: DiscountEngine.Estimate) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(e.hasSavings ? "Your home could save" : "Good news")
                .font(Theme.serif(24)).foregroundStyle(Theme.ink)
            if e.hasSavings {
                Text("\(AppModel.money(e.missedLow))–\(AppModel.money(e.missedHigh))")
                    .font(Theme.serif(46, .semibold))
                    .foregroundStyle(Theme.teal)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .accessibilityIdentifier("savingsRange")
                Text("a year on hurricane coverage").foregroundStyle(Theme.muted)
            } else {
                Text("Your policy already gets the discounts your answers show. An inspection could still find more (like roof-deck nailing).")
                    .foregroundStyle(Theme.muted)
            }
            HStack(spacing: 16) {
                stat("Discount now", e.creditNow)
                stat("Could be", e.creditPossible)
            }
            .padding(.top, 8)
        }
    }

    private func stat(_ label: String, _ v: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(Theme.muted)
            Text(v.formatted(.percent.precision(.fractionLength(0)))).font(.title3.weight(.semibold)).foregroundStyle(Theme.ink)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.mist, in: RoundedRectangle(cornerRadius: 14))
    }

    private func missingList(_ e: DiscountEngine.Estimate) -> some View {
        Card {
            Text("Discounts you're likely missing").font(.headline).foregroundStyle(Theme.ink)
            ForEach(e.missing) { m in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "plus.circle.fill").foregroundStyle(Theme.coral).font(.title3)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(m.title).fontWeight(.semibold).foregroundStyle(Theme.ink)
                            Spacer()
                            Text("up to \(AppModel.money(m.yearlyHigh))").font(.subheadline).foregroundStyle(Theme.teal)
                        }
                        Text(m.why).font(.footnote).foregroundStyle(Theme.muted)
                    }
                }
                if m.id != e.missing.last?.id { Divider() }
            }
            Text("Discounts overlap, so these don't add up to the total.")
                .font(.caption).foregroundStyle(Theme.muted)
        }
    }

    private func grantCard(_ g: GrantEligibility) -> some View {
        let (icon, title, body, color): (String, String, String, Color) = switch g {
        case .likely: ("checkmark.seal.fill", "You may qualify for a free inspection", "My Safe Florida Home offers free inspections and grants up to $10,000 for upgrades.", Theme.teal)
        case .maybe(let why): ("questionmark.circle.fill", "You might qualify for My Safe Florida Home", why, Theme.muted)
        case .no(let why): ("info.circle.fill", "My Safe Florida Home probably isn't for you", why, Theme.muted)
        }
        return Card {
            Label(title, systemImage: icon).font(.headline).foregroundStyle(color)
            Text(body).font(.subheadline).foregroundStyle(Theme.ink)
            if case .no = g {
                EmptyView()
            } else {
                Link("Check the program", destination: URL(string: "https://mysafeflhome.com")!)
                    .font(.subheadline.weight(.semibold))
            }
        }
    }

    private func assumptions(_ e: DiscountEngine.Estimate) -> some View {
        DisclosureGroup(isExpanded: $showMath) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Hurricane part of your premium: \(AppModel.money(Int(e.windPremium)))\(e.windPremiumWasAssumed ? " (estimated from your total)" : "")")
                Text("Credits come from Florida's official table (OIR-B1-1699). Discounts don't add up: each combination has one credit, capped at 89%.")
                Text("Insurers use their own, newer tables, so we show a cautious range. Roof-deck nailing is assumed weakest until an inspector checks.")
                Text("This is an estimate, not a quote. Confirm with a licensed inspector or your agent.").fontWeight(.medium)
            }
            .font(.footnote).foregroundStyle(Theme.muted)
            .padding(.top, 8)
        } label: {
            Text("How we got this number").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.ink)
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}
