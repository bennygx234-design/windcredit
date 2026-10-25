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
            VStack(alignment: .leading, spacing: 0) {
                if let e = model.estimate {
                    HeaderBand { model.needsInspectionToKnow ? AnyView(unknownHeadline) : AnyView(headline(e)) }
                }
                content.padding(20)
            }
        }
        .background {
            // same blue behind the nav bar as the header band
            VStack(spacing: 0) {
                Theme.teal.frame(height: 220)
                Theme.background
            }
            .ignoresSafeArea()
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            if isSetup {
                BottomBar {
                    Button("Make my plan") { model.saved.setupDone = true }
                        .buttonStyle(PrimaryButtonStyle())
                        .accessibilityIdentifier("makePlan")
                }
            }
        }
        .sheet(isPresented: $showHow) { HowItWorksSheet() }
        .navigationTitle(isSetup ? "" : "Your savings")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private var content: some View {
            VStack(alignment: .leading, spacing: 16) {
                if let e = model.estimate, model.needsInspectionToKnow {
                    whatIfList.reveal(0.15)
                    if let g = model.grant { grantCard(g).reveal(0.3) }
                    assumptions(e)
                    Button { showHow = true } label: {
                        Label("How WindCredit works", systemImage: "gearshape.2")
                    }
                    .buttonStyle(PillButtonStyle())
                } else if let e = model.estimate {
                    if e.hasSavings {
                        premiumBars(e).reveal(0.15)
                        payback(e).reveal(0.25)
                    }
                    if !e.missing.isEmpty { missingList(e).reveal(0.35) }
                    if let g = model.grant { grantCard(g).reveal(0.45) }
                    sources.reveal(0.5)
                    assumptions(e).reveal(0.5)
                    Button { showHow = true } label: {
                        Label("How WindCredit works", systemImage: "gearshape.2")
                    }
                    .buttonStyle(PillButtonStyle())
                    .accessibilityIdentifier("howItWorks")
                } else {
                    ContentUnavailableView("Add your premium", systemImage: "doc.text")
                }
            }
    }

    private func headline(_ e: DiscountEngine.Estimate) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if e.hasSavings {
                Text("You could save").font(.wcSubStrong).opacity(0.9)
                CountUp(values: [e.missedLow, e.missedHigh], font: .wcFigure(44), color: .white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .accessibilityIdentifier("savingsRange")
                Text("a year on hurricane insurance").font(.wcSub).opacity(0.9)
            } else {
                Text("You already have your discounts").font(.wcTitle)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var unknownHeadline: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("You could save").font(.wcSubStrong).opacity(0.9)
            CountUp(values: [model.whatIf.first?.yearlyHigh ?? 0], prefix: "Up to ", font: .wcFigure(44), color: .white)
                .minimumScaleFactor(0.5).lineLimit(1)
                .accessibilityIdentifier("savingsRange")
            Text("a year. An inspection tells you for sure.").font(.wcSub).opacity(0.9)
        }
    }

    private var whatIfList: some View {
        Card {
            Text("What each one is worth").font(.wcHeadingSmall).foregroundStyle(Theme.ink)
            ForEach(model.whatIf) { m in
                creditRow(m)
                if m.id != model.whatIf.last?.id { Divider().overlay(Theme.line) }
            }
        }
    }

    private func premiumBars(_ e: DiscountEngine.Estimate) -> some View {
        let now = e.windPremium
        let after = max(now - Double(e.missedLow + e.missedHigh) / 2, 0)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                compareCard("Now", now, color: Theme.coral)
                compareCard("With discounts", after, color: Theme.green)
            }
            Text(e.windPremiumWasAssumed ? "Hurricane premium a year, estimated" : "Hurricane premium a year")
                .font(.wcCaption).foregroundStyle(Theme.muted)
        }
    }

    private func compareCard(_ label: String, _ value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label).font(.wcCaptionStrong).foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(color)
            Text(AppModel.money(Int(value))).font(.wcFigure(26)).foregroundStyle(Theme.ink)
                .monospacedDigit()
                .padding(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(color, lineWidth: 2))
        .accessibilityElement(children: .combine)
    }

    private func payback(_ e: DiscountEngine.Estimate) -> some View {
        let weekly = Double(e.missedLow) / 52
        let weeks = weekly > 0 ? Int((Double(Self.inspectionCost) / weekly).rounded(.up)) : 0
        return HStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath").font(.system(size: 22, weight: .semibold)).foregroundStyle(Color(light: 0x92400E, dark: 0xFCD34D))
            Text("A $\(Self.inspectionCost) inspection pays for itself in about \(max(weeks, 1)) week\(weeks == 1 ? "" : "s")")
                .font(.wcSubStrong).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.sand, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func missingList(_ e: DiscountEngine.Estimate) -> some View {
        Card {
            Text("Discounts you’re missing").font(.wcHeadingSmall).foregroundStyle(Theme.ink)
            ForEach(e.missing) { m in
                creditRow(m)
                if m.id != e.missing.last?.id { Divider().overlay(Theme.line) }
            }
            Text("They overlap, so they don’t add up.")
                .font(.wcCaption).foregroundStyle(Theme.muted)
        }
    }

    private func creditRow(_ m: DiscountEngine.MissingCredit) -> some View {
        let (icon, color): (String, Color) = switch m.id {
        case "hip": ("house.fill", Theme.orange)
        case "roofToWall": ("link", Theme.tealTile)
        case "openings": ("square.grid.2x2.fill", Theme.purple)
        case "roofCover": ("hammer.fill", Theme.teal)
        default: ("shield.fill", Theme.tealDeep)
        }
        return HStack(spacing: 12) {
            IconBadge(systemImage: icon, color: color, size: 38)
            Text(m.title.replacingOccurrences(of: " credit", with: ""))
                .font(.wcHeadline).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Text("up to \(AppModel.money(m.yearlyHigh))").font(.wcSubStrong).foregroundStyle(Theme.green)
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(m.why)
    }

    private var sources: some View {
        HStack(spacing: 6) {
            Text("Data").font(.wcCaptionStrong).foregroundStyle(Theme.muted)
            ForEach(["Florida OIR-B1-1699", "County records", "Your policy"], id: \.self) { s in
                Text(s).font(.wcCaption).foregroundStyle(Theme.ink)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Theme.line, in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .lineLimit(1).minimumScaleFactor(0.8)
    }

    private func grantCard(_ g: GrantEligibility) -> some View {
        let (icon, title, body, color): (String, String, String, Color) = switch g {
        case .likely: ("checkmark.seal.fill", "You may get a free inspection", "From My Safe Florida Home, plus grants up to $10,000.", Theme.green)
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
