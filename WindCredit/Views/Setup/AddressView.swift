import MapKit
import SwiftUI

/// Type an address; Apple Maps suggests matches; county records do the rest.
struct AddressView: View {
    @EnvironmentObject var model: AppModel
    @StateObject private var search = AddressSearch()
    @State private var isLooking = false
    @State private var error: String?
    @FocusState private var focused: Bool
    let next: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(step: "Step 1 of 3", title: "What’s your address?",
                             subtitle: "We look up your home in Palm Beach County’s public records.")

                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(Theme.muted)
                    TextField("Street address in Palm Beach County", text: $search.query)
                        .font(.wcBody)
                        .textContentType(.fullStreetAddress)
                        .autocorrectionDisabled()
                        .focused($focused)
                        .submitLabel(.search)
                        .onSubmit { Task { await lookUp(search.query) } }
                        .accessibilityIdentifier("addressField")
                    if !search.query.isEmpty {
                        Button { search.query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.muted) }
                            .accessibilityLabel("Clear")
                    }
                }
                .padding(16)
                .background(Theme.card, in: Capsule())
                .overlay(Capsule().stroke(focused ? Theme.teal : Theme.line, lineWidth: focused ? 2 : 1))

                if isLooking {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Checking county records…").font(.wcSub).foregroundStyle(Theme.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }

                if let error {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.wcSub).foregroundStyle(Theme.coral)
                }

                VStack(spacing: 0) {
                    ForEach(search.results, id: \.self) { item in
                        Button { Task { await lookUp(item.title + ", " + item.subtitle) } } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill").font(.system(size: 24)).foregroundStyle(Theme.teal)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title).font(.wcBodyMedium).foregroundStyle(Theme.ink)
                                    Text(item.subtitle).font(.wcCaption).foregroundStyle(Theme.muted)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
                .disabled(isLooking)

                if search.results.isEmpty && !isLooking {
                    sampleCard
                }
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { focused = model.saved.record == nil }
    }

    /// For judges and testers without a Palm Beach address.
    private var sampleCard: some View {
        Button {
            model.setRecord(.sample)
            next()
        } label: {
            HStack(spacing: 14) {
                HouseIllustration(shape: .gable).frame(width: 64, height: 52)
                VStack(alignment: .leading, spacing: 3) {
                    Text("No Palm Beach home?").font(.wcHeadline).foregroundStyle(Theme.ink)
                    Text("Try a sample 1993 Boca house").font(.wcSub).foregroundStyle(Theme.muted)
                }
                Spacer()
                Image(systemName: "arrow.right").foregroundStyle(Theme.teal)
            }
            .padding(16)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.line, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
        }
        .buttonStyle(.plain)
        .padding(.top, 12)
        .accessibilityIdentifier("sampleHome")
    }

    private func lookUp(_ address: String) async {
        let cleaned = address.replacingOccurrences(of: ", United States", with: "")
        guard !cleaned.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        focused = false
        error = nil
        isLooking = true
        defer { isLooking = false }
        do {
            let record = try await PropertyLookupService().lookup(address: cleaned)
            model.setRecord(record)
            next()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

/// Wraps Apple's address autocomplete, limited to the Palm Beach County area.
@MainActor
final class AddressSearch: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var query = "" { didSet { completer.queryFragment = query } }
    @Published var results: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
        completer.region = MKCoordinateRegion(center: .init(latitude: 26.65, longitude: -80.25),
                                              span: .init(latitudeDelta: 0.8, longitudeDelta: 0.8))
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let found = completer.results.filter { $0.subtitle.contains("FL") || $0.subtitle.contains("Florida") }
        Task { @MainActor in self.results = Array(found.prefix(6)) }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in self.results = [] }
    }
}
