import MapKit
import SwiftUI

struct ConfirmHomeView: View {
    @EnvironmentObject var model: AppModel
    let next: () -> Void

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ScreenHeader(step: 2, title: "Your house")
                if let r = model.saved.record {
                    recordCard(r).reveal(0.05)
                    if r.isCondo { condoNote }
                }

                question("What shape is your roof?", hint: hintText) {
                    ForEach(RoofShape.allCases) { s in
                        ChoiceCard(title: s.title, detail: s.detail, art: .roof(s), selected: model.saved.home.roofShape == s) {
                            model.saved.home.roofShape = s
                        }
                    }
                }

                question("How is the roof tied to the walls?", hint: nil) {
                    ForEach(RoofToWall.allCases) { r in
                        ChoiceCard(title: r.title, detail: r.detail, art: .connection(r), selected: model.saved.home.roofToWall == r) {
                            model.saved.home.roofToWall = r
                        }
                    }
                }

                question("How are your windows protected?", hint: nil) {
                    ForEach(OpeningProtection.allCases) { o in
                        ChoiceCard(title: o.title, detail: o.detail, art: .window(o), selected: model.saved.home.openings == o) {
                            model.saved.home.openings = o
                        }
                    }
                }

                if !(model.saved.record?.isNewConstruction ?? false) {
                    question("Was the roof replaced after March 2002?", hint: nil) {
                        ForEach(YesNoUnsure.allCases) { v in
                            ChoiceCard(title: v.title, detail: roofAgeDetail(v),
                                       art: .roofAge(v),
                                       selected: model.saved.home.roofMeetsCode == v) {
                                model.saved.home.roofMeetsCode = v
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            BottomBar {
                Button("Looks right") {
                    model.confirmHome()
                    next()
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("confirmHome")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hintText: String? {
        guard let r = model.saved.record, !r.roofStructureText.isEmpty else { return nil }
        return "County says: \(r.roofStructureText.capitalized)"
    }

    private func recordCard(_ r: PropertyRecord) -> some View {
        Card {
            Map(initialPosition: .camera(.init(centerCoordinate: .init(latitude: r.latitude, longitude: r.longitude), distance: 160))) {
                Marker("", coordinate: .init(latitude: r.latitude, longitude: r.longitude)).tint(Theme.coral)
            }
            .mapStyle(.imagery)
            .frame(height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .allowsHitTesting(false)
            .accessibilityLabel("Satellite view of your roof")

            Text(r.displayAddress).font(.wcHeadingSmall).foregroundStyle(Theme.ink)
            HStack(spacing: 8) {
                stat(r.yearBuilt.map(String.init) ?? "–", "Built")
                stat(r.roofCover == .unknown ? "–" : r.roofCover.title, "Roof")
                stat(r.livingArea.map { $0.formatted() } ?? "–", "Sq ft")
                stat(r.homestead ? "Yes" : "No", "Homestead")
            }
            Label(r.isSample ? "Sample home" : "County records", systemImage: "checkmark.circle.fill")
                .font(.wcCaptionStrong).foregroundStyle(Theme.green)
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.wcHeadline).foregroundStyle(Theme.teal)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(label).font(.wcCaption).foregroundStyle(Theme.muted).lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10).padding(.horizontal, 4)
        .background(Theme.mist, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var condoNote: some View {
        Label("Condo: savings may be smaller.",
              systemImage: "building.2")
            .font(.wcSub).foregroundStyle(Theme.ink)
            .padding(14)
            .background(Theme.mist, in: RoundedRectangle(cornerRadius: 14))
    }

    private func roofAgeDetail(_ answer: YesNoUnsure) -> String {
        switch answer {
        case .yes: "Roofing permit on or after 3/1/2002"
        case .no: "Original or older roof"
        case .notSure: "We’ll assume no"
        }
    }

    private func question<Content: View>(_ title: String, hint: String?, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.wcHeading).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let hint {
                Text(hint).font(.wcCaptionStrong).foregroundStyle(Theme.tealDeep)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Theme.mist, in: Capsule())
            }
            LazyVGrid(columns: columns, spacing: 12) { content() }
        }
    }
}
