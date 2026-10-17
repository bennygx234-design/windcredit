import SwiftUI

/// Home screen after setup: savings, the 4-step plan with a progress ring, reminder, and report.
struct DashboardView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var auth: AuthService
    @State private var showSettings = false
    @State private var reminderNote: String?
    @State private var pickRenewal = false
    @State private var renewalPick = Calendar.current.date(byAdding: .month, value: 3, to: .now)!
    @State private var reportURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    greeting
                    savingsCard
                    planCard
                    reminderCard
                    reportButton
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
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(model.saved.record?.displayAddress ?? "Your home").font(.footnote).foregroundStyle(Theme.muted)
            Text("Your plan").font(Theme.serif(32)).foregroundStyle(Theme.ink)
        }
    }

    private var savingsCard: some View {
        NavigationLink { ResultsView(isSetup: false) } label: {
            Card {
                Text("Likely missing").font(.subheadline).foregroundStyle(Theme.muted)
                Text(model.savingsText).font(Theme.serif(38, .semibold)).foregroundStyle(Theme.teal)
                    .minimumScaleFactor(0.6).lineLimit(1)
                HStack {
                    Text("a year · see why").font(.footnote).foregroundStyle(Theme.muted)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(Theme.muted)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("savingsCard")
    }

    private var planCard: some View {
        Card {
            HStack(spacing: 14) {
                ProgressRing(progress: model.progress).frame(width: 54, height: 54)
                    .overlay(Text("\(model.saved.completed.count)/\(PlanStep.allCases.count)").font(.caption.weight(.semibold)).foregroundStyle(Theme.ink))
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.progress == 1 ? "All done" : "Steps to get your discount").font(.headline).foregroundStyle(Theme.ink)
                    Text(model.progress == 1 ? "Watch for a lower premium at renewal." : "Tap a step when it's done.")
                        .font(.footnote).foregroundStyle(Theme.muted)
                }
            }
            Divider()
            ForEach(PlanStep.allCases) { step in
                let done = model.saved.completed.contains(step)
                let isNext = !done && PlanStep.allCases.first { !model.saved.completed.contains($0) } == step
                Button { withAnimation { model.toggle(step) } } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: done ? "checkmark.circle.fill" : isNext ? "arrow.right.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(done ? Theme.teal : isNext ? Theme.coral : Theme.muted)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title).foregroundStyle(done ? Theme.muted : Theme.ink).strikethrough(done)
                            Text(step.detail).font(.caption).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("step-\(step.rawValue)")
                if step == .bookInspection && !done { inspectionLinks }
            }
        }
    }

    private var inspectionLinks: some View {
        HStack(spacing: 10) {
            Link(destination: URL(string: "https://mysafeflhome.com")!) {
                Label("Free via MSFH", systemImage: "seal").font(.caption.weight(.semibold)).lineLimit(1)
            }
            .buttonStyle(.bordered).tint(Theme.teal)
            Link(destination: URL(string: "https://maps.apple.com/?q=wind+mitigation+inspection&near=Boca+Raton")!) {
                Label("Inspectors", systemImage: "map").font(.caption.weight(.semibold)).lineLimit(1)
            }
            .buttonStyle(.bordered).tint(Theme.teal)
        }
        .padding(.leading, 36)
    }

    private var reminderCard: some View {
        Card {
            HStack {
                Image(systemName: "bell.badge").font(.title3).foregroundStyle(Theme.coral)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.saved.reminderSet ? "Renewal reminder is on" : "Remind me before renewal").font(.headline).foregroundStyle(Theme.ink)
                    Text(renewalText).font(.footnote).foregroundStyle(Theme.muted)
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
            if let reminderNote { Text(reminderNote).font(.caption).foregroundStyle(Theme.muted) }
        }
    }

    private var renewalText: String {
        guard let d = model.saved.policy.renewalDate else { return "We'll nudge you 30 and 7 days before." }
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
        Button { reportURL = ReportRenderer.makePDF(model: model) } label: {
            Label("Share report with my agent", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(PrimaryButtonStyle())
        .accessibilityIdentifier("shareReport")
    }
}

extension URL: @retroactive Identifiable { public var id: String { absoluteString } }

/// The standard iOS share sheet, for the PDF report.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
