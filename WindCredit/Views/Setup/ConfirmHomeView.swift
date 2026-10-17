import MapKit
import SwiftUI

/// Shows what county records say, then asks four picture questions (from the state inspection form).
struct ConfirmHomeView: View {
    @EnvironmentObject var model: AppModel
    let next: () -> Void

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ScreenHeader(step: "Step 2 of 3", title: "Your home",
                             subtitle: "Here’s what public records say. Check the four questions below; “Not sure” is fine.")
                if let r = model.saved.record {
                    recordCard(r)
                    if r.isCondo { condoNote }
                }

                question("What shape is your roof?", hint: hintText) {
                    ForEach(RoofShape.allCases) { s in
                        ChoiceCard(title: s.title, detail: s.detail, art: .roof(s), selected: model.saved.home.roofShape == s) {
                            model.saved.home.roofShape = s
                        }
                    }
                }

                question("How is the roof tied to the walls?", hint: "It’s on your wind-mitigation report if you’ve had one. Otherwise pick Not sure.") {
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
                    question("Was the roof put on or replaced after 2002?", hint: "Newer roofs meet the stronger Florida Building Code.") {
                        ForEach(YesNoUnsure.allCases) { v in
                            ChoiceCard(title: v.title, detail: v == .yes ? "Permit after March 2002" : v == .no ? "Original or older roof" : "We’ll assume no",
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
        guard let r = model.saved.record, !r.roofStructureText.isEmpty else { return "Look at your house from the street or the satellite view above." }
        return "County records say “\(r.roofStructureText.capitalized)”. Check the satellite view above."
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
            InfoRow(label: "Year built", value: r.yearBuilt.map(String.init) ?? "Not listed")
            InfoRow(label: "Roof cover", value: r.roofCover == .unknown ? "Not listed" : r.roofCover.title)
            InfoRow(label: "Living area", value: r.livingArea.map { "\($0.formatted()) sq ft" } ?? "Not listed")
            InfoRow(label: "Homestead", value: r.homestead ? "Yes" : "No")
            Text(r.isSample ? "Sample home for testing" : "Source: Palm Beach County Property Appraiser")
                .font(.wcCaption).foregroundStyle(Theme.muted)
        }
    }

    private var condoNote: some View {
        Label("This looks like a condo. Wind discounts usually go on the building’s association policy, so your savings may be smaller.",
              systemImage: "building.2")
            .font(.wcSub).foregroundStyle(Theme.ink)
            .padding(14)
            .background(Theme.mist, in: RoundedRectangle(cornerRadius: 14))
    }

    private func question<Content: View>(_ title: String, hint: String?, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.wcHeading).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let hint { Text(hint).font(.wcSub).foregroundStyle(Theme.muted).fixedSize(horizontal: false, vertical: true) }
            LazyVGrid(columns: columns, spacing: 12) { content() }
        }
    }
}
