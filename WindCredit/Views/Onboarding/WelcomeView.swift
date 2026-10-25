import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var model: AppModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HeaderBand {
                    HStack(spacing: 10) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Theme.teal)
                            .frame(width: 40, height: 40)
                            .background(.white, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .accessibilityHidden(true)
                        Text("WindCredit").font(.wcHeading)
                    }
                    Text("Find the hurricane discounts your home is missing")
                        .font(.wcTitle)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6)
                    HStack(spacing: 8) {
                        HeaderChip(text: "Free")
                        HeaderChip(text: "Palm Beach County")
                        HeaderChip(text: "Florida law")
                    }
                    .padding(.bottom, 30)
                }

                premiumCard
                    .padding(.horizontal, 18)
                    .padding(.top, -40)

                Text("Discounts Florida requires")
                    .font(.wcHeading).foregroundStyle(Theme.ink)
                    .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 12)

                LazyVGrid(columns: columns, spacing: 10) {
                    tile("Hip roof", "47%", icon: "house.fill", color: Theme.orange).reveal(0.1)
                    tile("Shutters", "44%", icon: "square.grid.2x2.fill", color: Theme.purple).reveal(0.2)
                    tile("Roof clips", "35%", icon: "link", color: Theme.tealTile).reveal(0.3)
                }
                .padding(.horizontal, 18)

                Text("Florida OIR-B1-1699. Average from OIR, July 2026.")
                    .font(.wcCaption).foregroundStyle(Theme.muted)
                    .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 20)
            }
        }
        .background {
            // brand color behind the status bar, so the header band runs to the top edge
            VStack(spacing: 0) {
                Theme.teal.frame(height: 150)
                Theme.background
            }
            .ignoresSafeArea()
        }
        .safeAreaInset(edge: .bottom) {
            BottomBar {
                Button("Check my house") { finish() }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("introNext")
            }
        }
    }

    private var premiumCard: some View {
        HStack(spacing: 14) {
            IconBadge(systemImage: "chart.line.uptrend.xyaxis", color: Theme.coral, size: 46)
            VStack(alignment: .leading, spacing: 0) {
                Text("Average home insurance here").font(.wcCaption).foregroundStyle(Theme.muted)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    CountUp(values: [6_323], font: .wcFigure(28), color: Theme.ink, delay: 0.25)
                    Text("a year").font(.wcSubStrong).foregroundStyle(Theme.muted)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.10), radius: 12, y: 4)
    }

    private func tile(_ name: String, _ value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: icon).font(.system(size: 22, weight: .semibold)).accessibilityHidden(true)
            Spacer(minLength: 12)
            Text(value).font(.wcFigure(26))
            Text(name).font(.wcSubStrong).opacity(0.95)
        }
        .foregroundStyle(.white)
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        .background(color, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func finish() { model.saved.hasSeenIntro = true }
}
