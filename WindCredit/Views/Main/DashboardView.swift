import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var auth: AuthService
    @State private var showSettings = false
    @State private var reminderNote: String?
    @State private var pickRenewal = false
    @State private var renewalPick = Calendar.current.date(byAdding: .month, value: 3, to: .now)!
    @State private var reportURL: URL?
    @State private var housesLit = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder private var savingsFigure: some View {
        if let e = model.estimate, e.hasSavings {
            CountUp(values: [e.missedLow, e.missedHigh], font: .wcFigure(44), color: .white)
        } else if let best = model.whatIf.first {
            CountUp(values: [best.yearlyHigh], prefix: "Up to ", font: .wcFigure(44), color: .white)
        } else {
            Text("$0").font(.wcFigure(44)).foregroundStyle(.white)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    greeting
                    savingsCard.reveal(0.05)
                    planCard.reveal(0.15)
                    neighborhoodCard.reveal(0.25)
                    reminderCard.reveal(0.3)
                    reportButton.reveal(0.35)
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                        .accessibilityIdentifier("settingsButton")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $pickRenewal) { renewalSheet }
            .sheet(item: $reportURL) { url in ShareSheet(items: [url]).presentationDetents([.medium, .large]) }
            .task(id: model.saved.record?.parcelID) { await model.loadNeighborhood() }
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 6) {
            Eyebrow(text: model.saved.record?.displayAddress ?? "Your home", color: Theme.muted)
            Text(auth.firstName.map { "\($0)’s plan" } ?? "Your plan").font(.wcTitle).foregroundStyle(Theme.ink)
        }
    }

    private var savingsCard: some View {
        NavigationLink { ResultsView(isSetup: false) } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text("Likely missing each year").font(.wcSub).foregroundStyle(.white.opacity(0.85))
                savingsFigure
                    .minimumScaleFactor(0.6).lineLimit(1)
                HStack {
                    Text("See the details").font(.wcSubStrong).foregroundStyle(.white)
                    Image(systemName: "arrow.right").font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                }
                .padding(.top, 4)
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.tealDeep, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("savingsCard")
    }

    private var planCard: some View {
        Card {
            HStack(spacing: 14) {
                ProgressRing(progress: model.progress).frame(width: 56, height: 56)
                    .overlay(Text("\(model.saved.completed.count)/\(PlanStep.allCases.count)").font(.wcCaptionStrong).foregroundStyle(Theme.ink))
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.progress == 1 ? "All done" : "Steps to get your discount").font(.wcHeadingSmall).foregroundStyle(Theme.ink)
                    Text(model.progress == 1 ? "Watch for a lower premium at renewal." : "Tap a step when it’s done.")
                        .font(.wcSub).foregroundStyle(Theme.muted)
                }
            }
            Divider().overlay(Theme.line)
            ForEach(PlanStep.allCases) { step in
                let done = model.saved.completed.contains(step)
                let isNext = !done && PlanStep.allCases.first { !model.saved.completed.contains($0) } == step
                Button { withAnimation { model.toggle(step) } } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: done ? "checkmark.circle.fill" : isNext ? "arrow.right.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundStyle(done ? Theme.teal : isNext ? Theme.coral : Theme.line)
                            .contentTransition(.symbolEffect(.replace))
                            .symbolEffect(.bounce, value: done)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title).font(isNext ? .wcHeadline : .wcBodyMedium)
                                .foregroundStyle(done ? Theme.muted : Theme.ink).strikethrough(done)
                            Text(step.detail).font(.wcCaption).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.success, trigger: done)
                .accessibilityIdentifier("step-\(step.rawValue)")
                if step == .bookInspection && !done { inspectionLinks }
            }
        }
    }

    private var inspectionLinks: some View {
        HStack(spacing: 8) {
            Link(destination: URL(string: "https://mysafeflhome.com")!) {
                Label("Free via MSFH", systemImage: "seal").lineLimit(1)
            }
            Link(destination: URL(string: "https://maps.apple.com/?q=wind+mitigation+inspection&near=Boca+Raton")!) {
                Label("Inspectors", systemImage: "map").lineLimit(1)
            }
        }
        .buttonStyle(PillButtonStyle())
        .padding(.leading, 34)
    }

    // MARK: Neighborhood (civic view)

    @ViewBuilder private var neighborhoodCard: some View {
        if let n = model.saved.neighborhood, n.homes > 0, let r = model.saved.record {
            Card {
                Eyebrow(text: "Your neighborhood", color: Theme.tealDeep)
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(Int((n.olderShare * 100).rounded()))%").font(.wcFigure(40)).foregroundStyle(Theme.ink)
                    Text("of the \(n.homes) homes within a quarter mile were built before the 2002 building code")
                        .font(.wcSub).foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                neighborhoodDots(n)
                HStack(spacing: 14) {
                    legend(Theme.coral, "Built before 2002")
                    legend(Theme.teal.opacity(0.45), "2002 or later")
                }
                if model.perHomeMissed > 0 {
                    Text("If just 1 in 4 is missing a discount like yours, your neighborhood overpays about **\(AppModel.money(n.dollarsIfQuarterMissing(perHome: model.perHomeMissed)))** a year.")
                        .font(.wcSub).foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    ShareLink(item: NeighborhoodService.shareText(n, street: r.streetName, perHome: model.perHomeMissed)) {
                        Label("Share with my representative", systemImage: "building.columns")
                    }
                    .buttonStyle(PillButtonStyle())
                    .accessibilityIdentifier("shareNeighborhood")
                }
                Text("Source: Florida statewide parcel data (tax roll). Estimate.")
                    .font(.wcCaption).foregroundStyle(Theme.muted)
            }
        }
    }

    private func legend(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "house.fill").font(.system(size: 10)).foregroundStyle(color)
            Text(text).font(.wcCaption).foregroundStyle(Theme.muted)
        }
    }

    // 40 houses, so each one is roughly 2.5% of the neighborhood.
    private func neighborhoodDots(_ n: Neighborhood) -> some View {
        let dots = 40
        let older = Int((n.olderShare * Double(dots)).rounded())
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 20), spacing: 6) {
            ForEach(0..<dots, id: \.self) { i in
                Image(systemName: "house.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(i < older && housesLit ? Theme.coral : Theme.teal.opacity(0.45))
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.25).delay(0.4 + Double(i) * 0.025), value: housesLit)
            }
        }
        .onAppear { housesLit = true }
        .accessibilityElement()
        .accessibilityLabel("\(n.olderHomes) of \(n.homes) homes built before 2002")
    }

    // MARK: Reminder and report

    private var reminderCard: some View {
        Card {
            HStack(spacing: 12) {
                Image(systemName: model.saved.reminderSet ? "bell.badge.fill" : "bell.badge").font(.system(size: 22)).foregroundStyle(Theme.coral)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.saved.reminderSet ? "Renewal reminder is on" : "Remind me before renewal").font(.wcHeadline).foregroundStyle(Theme.ink)
                    Text(renewalText).font(.wcSub).foregroundStyle(Theme.muted)
                }
                Spacer()
            }
            if !model.saved.reminderSet {
                Button("Turn on reminder") {
                    if model.saved.policy.renewalDate == nil { pickRenewal = true } else { Task { await setReminder() } }
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityIdentifier("reminderButton")
            }
            if let reminderNote { Text(reminderNote).font(.wcCaption).foregroundStyle(Theme.muted) }
        }
    }

    private var renewalText: String {
        guard let d = model.saved.policy.renewalDate else { return "We’ll nudge you 30 and 7 days before." }
        let days = Calendar.current.dateComponents([.day], from: .now, to: d).day ?? 0
        return "Renews \(d.formatted(date: .abbreviated, time: .omitted)) · \(max(days, 0)) days"
    }

    private var renewalSheet: some View {
        NavigationStack {
            Form {
                DatePicker("Renewal date", selection: $renewalPick, in: Date.now..., displayedComponents: .date)
                    .datePickerStyle(.graphical)
            }
            .navigationTitle("When does it renew?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { pickRenewal = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        model.saved.policy.renewalDate = renewalPick
                        pickRenewal = false
                        Task { await setReminder() }
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func setReminder() async {
        guard let d = model.saved.policy.renewalDate else { return }
        let ok = await ReminderService.schedule(renewal: d, savingsText: model.savingsText)
        model.saved.reminderSet = ok
        reminderNote = ok ? nil : "Notifications are off for WindCredit. Turn them on in Settings to get reminders."
    }

    private var reportButton: some View {
        Button { reportURL = ReportRenderer.makePDF(model: model, name: auth.firstName, email: auth.email) } label: {
            Label("Share report with my agent", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(PrimaryButtonStyle())
        .accessibilityIdentifier("shareReport")
    }
}

extension URL: @retroactive Identifiable { public var id: String { absoluteString } }

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
