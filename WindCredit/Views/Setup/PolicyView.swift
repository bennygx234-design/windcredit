import PhotosUI
import SwiftUI
import VisionKit

/// Scan the declarations page (or type the premium). Then the user checks what was read.
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
    @State private var missingPremium = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(step: "Step 3 of 3", title: "Your policy",
                             subtitle: "Scan the declarations page: the summary page of your home insurance. It’s read on your phone and never uploaded.")

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
                    Text("Turn on any your page lists. If there’s no wind-mitigation section, leave these off.")
                        .font(.wcSub).foregroundStyle(Theme.muted)
                    Toggle("Hip roof", isOn: binding(\.roofShape, on: .hip, off: .notSure))
                    Toggle("Roof clips or straps", isOn: Binding(
                        get: { DiscountEngine.strength(draft.creditedFeatures.roofToWall) > 0 },
                        set: { draft.creditedFeatures.roofToWall = $0 ? (model.saved.home.roofToWall == .notSure || model.saved.home.roofToWall == .toeNails ? .clips : model.saved.home.roofToWall) : .notSure }))
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
            BottomBar {
                Button("See my savings") { finish() }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("seeSavings")
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
        .alert("Add your premium", isPresented: $missingPremium) {
            Button("OK", role: .cancel) {}
        } message: { Text("Type the total yearly premium from your policy so we can estimate dollars.") }
    }

    // MARK: Logic

    private func load() {
        draft = model.saved.policy
        premiumText = draft.totalPremium.map { String(Int($0)) } ?? ""
        windText = draft.hurricanePremium.map { String(Int($0)) } ?? ""
        dwellingText = draft.dwellingCoverage.map { String(Int($0)) } ?? ""
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
        if let v = parsed.totalPremium { premiumText = String(Int(v)) }
        if let v = parsed.hurricanePremium { windText = String(Int(v)) }
        if let v = parsed.dwellingCoverage { dwellingText = String(Int(v)) }
        if let d = parsed.renewalDate { renewal = d; hasRenewal = true }
        scanned = true
        let found = [parsed.totalPremium, parsed.hurricanePremium, parsed.dwellingCoverage].compactMap { $0 }.count
        message = parsed.noMitigationSectionFound
            ? "Read \(found) amount\(found == 1 ? "" : "s"). No wind-mitigation discounts found on the page."
            : "Read \(found) amount\(found == 1 ? "" : "s") and the discounts below. Fix anything that’s off."
    }

    private func useSample() {
        let p = AppModel.samplePolicy
        premiumText = String(Int(p.totalPremium ?? 0))
        windText = String(Int(p.hurricanePremium ?? 0))
        dwellingText = String(Int(p.dwellingCoverage ?? 0))
        if let d = p.renewalDate { renewal = d; hasRenewal = true }
        draft.creditedFeatures = MitigationFeatures()
        scanned = true
        message = "Loaded a sample policy: no wind discounts on it yet."
    }

    private func finish() {
        guard let premium = Self.number(premiumText), premium > 0 else { missingPremium = true; return }
        draft.totalPremium = premium
        draft.hurricanePremium = Self.number(windText)
        draft.dwellingCoverage = Self.number(dwellingText)
        draft.renewalDate = hasRenewal ? renewal : nil
        model.finishPolicy(draft)
        next()
    }

    static func number(_ s: String) -> Double? {
        Double(s.filter { $0.isNumber || $0 == "." })
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
                TextField("0", text: text).font(.wcBodyMedium).keyboardType(.numberPad).accessibilityIdentifier(id)
            }
            .padding(14)
            .background(Theme.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.line))
        }
    }
}

/// Apple's document camera: finds the page edges and straightens the photo.
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
