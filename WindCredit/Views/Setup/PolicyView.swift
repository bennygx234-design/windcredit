import PhotosUI
import SwiftUI
import VisionKit

struct PolicyView: View {
    @EnvironmentObject var model: AppModel
    let next: () -> Void

    @State private var draft = PolicyInfo()
    @State private var premiumText = ""
    @State private var windText = ""
    @State private var dwellingText = ""
    @State private var hasRenewal = false
    @State private var renewal = Calendar.current.date(byAdding: .month, value: 6, to: .now)!
    @State private var showCamera = false
    @State private var photo: PhotosPickerItem?
    @State private var isReading = false
    @State private var scanned = false
    @State private var message: String?
    @State private var inputProblem: String?
    @FocusState private var typing: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(step: 3, title: "Scan your policy")
                Label("Read on your phone. Never uploaded.", systemImage: "lock.fill")
                    .font(.wcCaptionStrong).foregroundStyle(Theme.green)

                HStack(spacing: 12) {
                    if VNDocumentCameraViewController.isSupported {
                        Button { showCamera = true } label: { Label("Scan page", systemImage: "doc.viewfinder") }
                            .buttonStyle(PrimaryButtonStyle())
                    }
                    PhotosPicker(selection: $photo, matching: .images) {
                        Label(VNDocumentCameraViewController.isSupported ? "Photo" : "Choose a photo", systemImage: "photo")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("pickPhoto")
                }

                if model.saved.record?.isSample == true && !scanned {
                    Button { useSample() } label: { Label("Use the sample policy", systemImage: "doc.text") }
                        .buttonStyle(PillButtonStyle())
                        .accessibilityIdentifier("samplePolicy")
                }
                if isReading {
                    HStack(spacing: 12) { ProgressView(); Text("Reading your page…").font(.wcSub).foregroundStyle(Theme.muted) }
                }
                if let message {
                    Label(message, systemImage: scanned ? "checkmark.circle.fill" : "info.circle")
                        .font(.wcSub).foregroundStyle(scanned ? Theme.tealDeep : Theme.muted)
                }

                Card {
                    Text(scanned ? "Check what we read" : "Or type it in").font(.wcHeadingSmall).foregroundStyle(Theme.ink)
                    moneyField("Total yearly premium", text: $premiumText, id: "premiumField")
                    moneyField("Hurricane premium (if listed)", text: $windText, id: "windField")
                    moneyField("Dwelling coverage (Coverage A)", text: $dwellingText, id: "dwellingField")
                    Toggle("I know my renewal date", isOn: $hasRenewal.animation())
                    if hasRenewal {
                        DatePicker("Renews on", selection: $renewal, displayedComponents: .date)
                    }
                }

                Card {
                    Text("Discounts already on your policy").font(.wcHeadingSmall).foregroundStyle(Theme.ink)
                    Toggle("Hip roof", isOn: binding(\.roofShape, on: .hip, off: .notSure))
                    Toggle("Roof clips or straps", isOn: roofTiesCredited)
                    Toggle("Window protection", isOn: Binding(
                        get: { DiscountEngine.strength(draft.creditedFeatures.openings) > 0 },
                        set: { draft.creditedFeatures.openings = $0 ? .hurricane : .notSure }))
                    Toggle("Building-code roof", isOn: binding(\.roofMeetsCode, on: .yes, off: .notSure))
                    Toggle("Sealed roof deck (SWR)", isOn: binding(\.sealedRoofDeck, on: .yes, off: .notSure))
                }
                .tint(Theme.teal)
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            // hidden while typing so it doesn't ride up behind the keyboard's Done button
            if !typing {
                BottomBar {
                    Button("See my savings") { finish() }
                        .buttonStyle(PrimaryButtonStyle())
                        .accessibilityIdentifier("seeSavings")
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCamera) {
            DocumentCamera { image in Task { await read(image) } }.ignoresSafeArea()
        }
        .onChange(of: photo) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) { await read(image) }
                photo = nil
            }
        }
        .onAppear(perform: load)
        .alert("Check your numbers", isPresented: Binding(get: { inputProblem != nil }, set: { if !$0 { inputProblem = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(inputProblem ?? "") }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { typing = false }
            }
        }
    }

    // MARK: Logic

    private func load() {
        draft = model.saved.policy
        premiumText = draft.totalPremium.map(Self.grouped) ?? ""
        windText = draft.hurricanePremium.map(Self.grouped) ?? ""
        dwellingText = draft.dwellingCoverage.map(Self.grouped) ?? ""
        if let r = draft.renewalDate { renewal = r; hasRenewal = true }
    }

    private func read(_ image: UIImage) async {
        isReading = true
        defer { isReading = false }
        let lines = (try? await PolicyScanner.readText(from: image)) ?? []
        guard !lines.isEmpty else { message = "Couldn’t read that photo. Try again in good light, or type the numbers."; return }
        let parsed = PolicyParser.parse(lines: lines)
        draft.creditedFeatures = parsed.creditedFeatures
        draft.noMitigationSectionFound = parsed.noMitigationSectionFound
        if let v = parsed.totalPremium { premiumText = Self.grouped(v) }
        if let v = parsed.hurricanePremium { windText = Self.grouped(v) }
        if let v = parsed.dwellingCoverage { dwellingText = Self.grouped(v) }
        if let d = parsed.renewalDate { renewal = d; hasRenewal = true }
        scanned = true
        let found = [parsed.totalPremium, parsed.hurricanePremium, parsed.dwellingCoverage].compactMap { $0 }.count
        message = parsed.noMitigationSectionFound
            ? "Read \(found) amount\(found == 1 ? "" : "s"). No wind-mitigation discounts found on the page."
            : "Read \(found) amount\(found == 1 ? "" : "s") and the discounts below. Fix anything that’s off."
    }

    private func useSample() {
        let p = AppModel.samplePolicy
        premiumText = Self.grouped(p.totalPremium ?? 0)
        windText = Self.grouped(p.hurricanePremium ?? 0)
        dwellingText = Self.grouped(p.dwellingCoverage ?? 0)
        if let d = p.renewalDate { renewal = d; hasRenewal = true }
        draft.creditedFeatures = MitigationFeatures()
        scanned = true
        message = "Loaded a sample policy: no wind discounts on it yet."
    }

    private func finish() {
        if let problem = Self.problem(total: premiumText, wind: windText) {
            inputProblem = problem
            return
        }
        draft.totalPremium = Self.number(premiumText)
        draft.hurricanePremium = Self.number(windText).flatMap { $0 > 0 ? $0 : nil }
        draft.dwellingCoverage = Self.number(dwellingText).flatMap { $0 > 0 ? $0 : nil }
        draft.renewalDate = hasRenewal ? renewal : nil
        model.finishPolicy(draft)
        next()
    }

    /// 385000 → "385,000" (number(_:) strips the commas again).
    static func grouped(_ v: Double) -> String { Int(v.rounded()).formatted(.number.grouping(.automatic)) }

    static func number(_ s: String) -> Double? {
        Double(s.filter { $0.isNumber || $0 == "." })
    }

    /// Catches the typos that would make the estimate meaningless.
    static func problem(total: String, wind: String) -> String? {
        guard let t = number(total), t > 0 else {
            return "Type the total yearly premium from your policy so we can estimate dollars."
        }
        if t < 200 || t > 100_000 {
            return "A yearly premium of \(AppModel.money(Int(t))) looks off. Use the total for the whole year."
        }
        if let w = number(wind), w > t {
            return "The hurricane premium can’t be bigger than the total premium."
        }
        return nil
    }

    /// On = credit the connection the owner described, or plain clips if they didn't say.
    private var roofTiesCredited: Binding<Bool> {
        Binding(
            get: { DiscountEngine.strength(draft.creditedFeatures.roofToWall) > 0 },
            set: { isOn in
                let described = model.saved.home.roofToWall
                let strongest = DiscountEngine.strength(described) > 0 ? described : .clips
                draft.creditedFeatures.roofToWall = isOn ? strongest : .notSure
            })
    }

    private func binding<T: Equatable>(_ path: WritableKeyPath<MitigationFeatures, T>, on: T, off: T) -> Binding<Bool> {
        Binding(get: { draft.creditedFeatures[keyPath: path] == on },
                set: { draft.creditedFeatures[keyPath: path] = $0 ? on : off })
    }

    private func moneyField(_ label: String, text: Binding<String>, id: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.wcCaptionStrong).foregroundStyle(Theme.muted)
            HStack {
                Text("$").font(.wcBodyMedium).foregroundStyle(Theme.muted)
                TextField("0", text: text).font(.wcBodyMedium).keyboardType(.numberPad).focused($typing).accessibilityIdentifier(id)
            }
            .padding(14)
            .background(Theme.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.line))
        }
    }
}

struct DocumentCamera: UIViewControllerRepresentable {
    let onScan: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }
    func updateUIViewController(_ vc: VNDocumentCameraViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentCamera
        init(_ parent: DocumentCamera) { self.parent = parent }
        func documentCameraViewController(_ c: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            if scan.pageCount > 0 { parent.onScan(scan.imageOfPage(at: 0)) }
            parent.dismiss()
        }
        func documentCameraViewControllerDidCancel(_ c: VNDocumentCameraViewController) { parent.dismiss() }
        func documentCameraViewController(_ c: VNDocumentCameraViewController, didFailWithError error: Error) { parent.dismiss() }
    }
}
