import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var model: AppModel
    @State private var page = 0
    private let count = 3

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("WindCredit").font(.wcHeadingSmall).foregroundStyle(Theme.ink)
                Spacer()
                Button("Skip") { finish() }
                    .font(.wcBodyMedium)
                    .foregroundStyle(Theme.muted)
                    .accessibilityIdentifier("skipIntro")
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            TabView(selection: $page) {
                page(premiumCard).tag(0)
                page(lawCard).tag(1)
                page(howCard).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(0..<count, id: \.self) { i in
                    Capsule().fill(i == page ? Theme.teal : Theme.line)
                        .frame(width: i == page ? 22 : 8, height: 8)
                }
            }
            .animation(.spring(duration: 0.3), value: page)
            .padding(.bottom, 18)

            Button(page == count - 1 ? "Check my home" : "Next") {
                if page == count - 1 { finish() } else { withAnimation { page += 1 } }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .accessibilityIdentifier("introNext")
        }
        .background(Theme.background.ignoresSafeArea())
    }

    /// Centers a card vertically, but scrolls instead of cutting text off at large text sizes.
    private func page<Card: View>(_ card: Card) -> some View {
        GeometryReader { geo in
            ScrollView {
                card
                    .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            // fade text that scrolls under the page dots
            .mask(LinearGradient(stops: [.init(color: .black, location: 0.97), .init(color: .clear, location: 1)],
                                 startPoint: .top, endPoint: .bottom))
        }
    }

    private var premiumCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer()
            Eyebrow(text: "Palm Beach County · 2026")
            CountUp(values: [6_323], font: .wcFigure(84), delay: 0.25)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text("is the average yearly home insurance bill here, wind coverage included.")
                .font(.wcHeading)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("About half of a typical Florida premium pays for hurricane coverage, and that’s the part you can shrink.")
                .font(.wcBody).foregroundStyle(Theme.muted).lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Text("Sources: Florida OIR Property Insurance Stability Report, July 2026; Brookings, 2026")
                .font(.wcCaption).foregroundStyle(Theme.muted)
                .padding(.bottom, 16)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 28)
    }

    private var lawCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 8)
            HouseIllustration(shape: .hip).frame(height: 160).frame(maxWidth: .infinity).reveal(0.1)
            Text("Florida law says storm-strong homes pay less")
                .font(.wcTitle).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 10) {
                feature("Hip roof", "47%").reveal(0.25)
                feature("Hurricane shutters or impact windows", "44%").reveal(0.35)
                feature("Metal roof-to-wall clips", "35%").reveal(0.45)
            }
            Text("Discount each one earns on its own, off the hurricane part of your premium (Florida’s credit table, OIR‑B1‑1699). Many homes qualify and never get them.")
                .font(.wcCaption).foregroundStyle(Theme.muted).lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    private func feature(_ name: String, _ value: String) -> some View {
        HStack {
            Text(name).font(.wcSub).foregroundStyle(Theme.ink).fixedSize(horizontal: false, vertical: true)
            Spacer()
            Text(value).font(.wcSubStrong).foregroundStyle(Theme.tealDeep)
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.line))
    }

    private var howCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            Spacer()
            Text("Find yours in about two minutes")
                .font(.wcTitle).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            step(1, "Type your address", "We pull your home from county records.").reveal(0.1)
            step(2, "Answer four picture questions", "Roof, straps, windows. “Not sure” is fine.").reveal(0.25)
            step(3, "Scan your policy", "Read on your phone. Never uploaded.").reveal(0.4)
            Text("Then see what you’re missing, in dollars, and exactly what to do next.")
                .font(.wcBody).foregroundStyle(Theme.muted).lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Label("Free. No ads, no subscriptions, no account needed.", systemImage: "checkmark.seal")
                .font(.wcSubStrong).foregroundStyle(Theme.tealDeep)
                .fixedSize(horizontal: false, vertical: true)
                .reveal(0.55)
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    private func step(_ n: Int, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(n)")
                .font(.wcFigure(22))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(n == 3 ? Theme.coral : Theme.teal, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.wcHeadline).foregroundStyle(Theme.ink).fixedSize(horizontal: false, vertical: true)
                Text(detail).font(.wcSub).foregroundStyle(Theme.muted).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func finish() { model.saved.hasSeenIntro = true }
}
