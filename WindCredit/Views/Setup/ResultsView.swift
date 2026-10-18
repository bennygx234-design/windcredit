import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var model: AppModel
    let isSetup: Bool
    @State private var showMath = false
    @State private var showHow = false

    // middle of the $100–200 range local inspectors charge
    static let inspectionCost = 150

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if let e = model.estimate, model.needsInspectionToKnow {
                    unknownHeadline
                    whatIfList.reveal(0.15)
                    if let g = model.grant { grantCard(g).reveal(0.3) }
                    assumptions(e)
                    Button { showHow = true } label: {
                        Label("How WindCredit works", systemImage: "gearshape.2")
                    }
                    .buttonStyle(PillButtonStyle())
                } else if let e = model.estimate {
                    headline(e)
                    if e.hasSavings {
                        premiumBars(e).reveal(0.15)
                        payback(e).reveal(0.25)
                    }
                    if !e.missing.isEmpty { missingList(e).reveal(0.35) }
                    if let g = model.grant { grantCard(g).reveal(0.45) }
                    assumptions(e).reveal(0.5)
                    Button { showHow = true } label: {
                        Label("How WindCredit works", systemImage: "gearshape.2")
                    }
                    .buttonStyle(PillButtonStyle())
                    .accessibilityIdentifier("howItWorks")
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
        .sheet(isPresented: $showHow) { HowItWorksSheet() }
        .navigationTitle(isSetup ? "" : "Your savings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func headline(_ e: DiscountEngine.Estimate) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: e.hasSavings ? "Your estimate" : "Good news")
            if e.hasSavings {
                CountUp(values: [e.missedLow, e.missedHigh], font: .wcFigure(54))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .accessibilityIdentifier("savingsRange")
                Text("a year in hurricane discounts your home likely qualifies for but isn’t getting")
                    .font(.wcBody).foregroundStyle(Theme.ink).lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("You’re already getting the discounts your answers show")
                    .font(.wcTitle).foregroundStyle(Theme.ink)
                Text("An inspection could still find more, like how the roof deck is nailed down.")
                    .font(.wcBody).foregroundStyle(Theme.muted)
            }
        }
    }

    private var unknownHeadline: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "Not sure yet")
            CountUp(values: [model.whatIf.first?.yearlyHigh ?? 0], prefix: "Up to ", font: .wcFigure(54))
                .minimumScaleFactor(0.5).lineLimit(1)
                .accessibilityIdentifier("savingsRange")
            Text("a year is possible. You weren’t sure about some features, and an inspection is how you find out.")
                .font(.wcBody).foregroundStyle(Theme.ink).lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var whatIfList: some View {
        Card {
            Text("What each one is worth to you").font(.wcHeadingSmall).foregroundStyle(Theme.ink)
            ForEach(model.whatIf) { m in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "questionmark.circle.fill").foregroundStyle(Theme.coral).font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(m.title).font(.wcHeadline).foregroundStyle(Theme.ink)
                            Spacer()
                            Text("up to \(AppModel.money(m.yearlyHigh))").font(.wcSubStrong).foregroundStyle(Theme.tealDeep)
                        }
                        Text(m.why).font(.wcSub).foregroundStyle(Theme.muted).fixedSize(horizontal: false, vertical: true)
                    }
                }
                if m.id != model.whatIf.last?.id { Divider().overlay(Theme.line) }
            }
            Text("A $\(Self.inspectionCost) inspection checks all of these at once. Go back to change an answer if you know it.")
                .font(.wcCaption).foregroundStyle(Theme.muted)
        }
    }

    private func premiumBars(_ e: DiscountEngine.Estimate) -> some View {
        let now = e.windPremium
        let after = max(now - Double(e.missedLow + e.missedHigh) / 2, 0)
        return Card {
            Text("Hurricane part of your premium").font(.wcSubStrong).foregroundStyle(Theme.ink)
            bar("Now", now, of: now, color: Theme.coral, delay: 0.3)
            bar("With discounts", after, of: now, color: Theme.teal, delay: 0.55)
            if e.windPremiumWasAssumed {
                Text("Estimated from your total premium. Add the hurricane premium from your policy for a sharper number.")
                    .font(.wcCaption).foregroundStyle(Theme.muted)
            }
        }
    }

    private func bar(_ label: String, _ value: Double, of maxValue: Double, color: Color, delay: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.wcCaption).foregroundStyle(Theme.muted)
                Spacer()
                Text(AppModel.money(Int(value))).font(.wcSubStrong).foregroundStyle(Theme.ink)
            }
            GrowingBar(fraction: value / max(maxValue, 1), color: color, delay: delay)
        }
        .accessibilityElement(children: .combine)
    }

    private func payback(_ e: DiscountEngine.Estimate) -> some View {
        let weekly = Double(e.missedLow) / 52
        let weeks = weekly > 0 ? Int((Double(Self.inspectionCost) / weekly).rounded(.up)) : 0
        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: "clock.arrow.circlepath").font(.system(size: 22)).foregroundStyle(Theme.coral)
            VStack(alignment: .leading, spacing: 3) {
                Text("Worth it in about \(max(weeks, 1)) week\(weeks == 1 ? "" : "s")").font(.wcHeadline).foregroundStyle(Theme.ink)
                Text("A typical $\(Self.inspectionCost) wind-mitigation inspection pays for itself that fast, even at the low end of your estimate.")
                    .font(.wcSub).foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.sand, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func missingList(_ e: DiscountEngine.Estimate) -> some View {
        Card {
            Text("Discounts you’re likely missing").font(.wcHeadingSmall).foregroundStyle(Theme.ink)
            ForEach(e.missing) { m in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "plus.circle.fill").foregroundStyle(Theme.coral).font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(m.title).font(.wcHeadline).foregroundStyle(Theme.ink)
                            Spacer()
                            Text("up to \(AppModel.money(m.yearlyHigh))").font(.wcSubStrong).foregroundStyle(Theme.tealDeep)
                        }
                        Text(m.why).font(.wcSub).foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if m.id != e.missing.last?.id { Divider().overlay(Theme.line) }
            }
            Text("Discounts overlap, so these don’t add up to the total.")
                .font(.wcCaption).foregroundStyle(Theme.muted)
        }
    }

    private func grantCard(_ g: GrantEligibility) -> some View {
        let (icon, title, body, color): (String, String, String, Color) = switch g {
        case .likely: ("checkmark.seal.fill", "You may qualify for a free inspection", "My Safe Florida Home, the state program, offers free inspections. Low- and moderate-income owners can also get grants up to $10,000 for upgrades.", Theme.tealDeep)
        case .maybe(let why): ("questionmark.circle.fill", "You might qualify for My Safe Florida Home", why, Theme.ink)
        case .no(let why): ("info.circle.fill", "My Safe Florida Home probably isn’t for you", why, Theme.ink)
        }
        return Card {
            Label(title, systemImage: icon).font(.wcHeadline).foregroundStyle(color)
            Text(body).font(.wcSub).foregroundStyle(Theme.muted).fixedSize(horizontal: false, vertical: true)
            if case .no = g {
                EmptyView()
            } else {
                Link(destination: URL(string: "https://mysafeflhome.com")!) {
                    Label("Check current status", systemImage: "arrow.up.right")
                }
                .buttonStyle(PillButtonStyle())
            }
        }
    }

    private func assumptions(_ e: DiscountEngine.Estimate) -> some View {
        DisclosureGroup(isExpanded: $showMath) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Hurricane part of your premium: \(AppModel.money(Int(e.windPremium)))\(e.windPremiumWasAssumed ? " (estimated from your total)" : "")")
                Text("Discount now \(pct(e.creditNow)), could be \(pct(e.creditPossible)), from Florida’s official credit table (OIR-B1-1699). Discounts don’t add up: each combination of features has one credit. For most existing Palm Beach homes they top out around 82–84%.")
                Text("The state table dates from 2006 (an update is pending), and insurers file their own, so we show a cautious range (50–75% of the table’s number). Roof-deck nailing is assumed weakest until an inspector checks. If your policy doesn’t list a hurricane premium, we estimate it at 65% of the total for pre-2002 homes and 45% for newer ones.")
                Text("This is an estimate, not a quote. Confirm with a licensed inspector or your agent.").font(.wcSubStrong)
            }
            .font(.wcSub).foregroundStyle(Theme.muted)
            .padding(.top, 8)
        } label: {
            Text("How we got this number").font(.wcSubStrong).foregroundStyle(Theme.ink)
        }
        .padding(18)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.line))
    }

    private func pct(_ v: Double) -> String { v.formatted(.percent.precision(.fractionLength(0))) }
}

struct HowItWorksSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let steps: [(String, String, String)] = [
        ("map", "Finds your home in public records",
         "Palm Beach County’s address service gives the exact point on your house; the county parcel map gives the parcel; the Property Appraiser record gives year built and roof type."),
        ("doc.viewfinder", "Reads your policy on your phone",
         "Apple’s Vision text recognition reads the declarations page on the device. Nothing is uploaded. A parser finds the premiums, coverage, renewal date and any wind discounts already applied."),
        ("tablecells", "Looks up Florida’s official credit table",
         "Every combination of roof shape, roof-to-wall ties, window protection, roof age and sealed deck has one credit in the state’s table (OIR-B1-1699). They don’t add up; for most existing Palm Beach homes they top out around 82–84%."),
        ("chart.bar.xaxis", "Turns the gap into dollars",
         "Missed = hurricane premium × (possible credit − current credit) ÷ (1 − current credit). Shown as a cautious range because each insurer’s table is a little different."),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("How WindCredit works").font(.wcTitle).foregroundStyle(Theme.ink)
                    ForEach(Array(steps.enumerated()), id: \.offset) { i, s in
                        HStack(alignment: .top, spacing: 16) {
                            Text("\(i + 1)").font(.wcFigure(20)).foregroundStyle(.white)
                                .frame(width: 40, height: 40).background(Theme.teal, in: Circle())
                            VStack(alignment: .leading, spacing: 5) {
                                Label(s.1, systemImage: s.0).font(.wcHeadline).foregroundStyle(Theme.ink)
                                Text(s.2).font(.wcSub).foregroundStyle(Theme.muted).lineSpacing(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    Text("Built in Swift and SwiftUI. Data: Palm Beach County GIS, Palm Beach County Property Appraiser, Florida statewide parcels, Florida Office of Insurance Regulation.")
                        .font(.wcCaption).foregroundStyle(Theme.muted)
                }
                .padding(24)
            }
            .background(Theme.background.ignoresSafeArea())
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .presentationDetents([.large])
    }
}
