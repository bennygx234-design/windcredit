import SwiftUI

/// Three short cards, each built around one real number or picture. Skip is always visible.
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
                premiumCard.tag(0)
                lawCard.tag(1)
                howCard.tag(2)
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

    // Card 1: the number that makes the problem real.
    private var premiumCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer()
            Eyebrow(text: "Palm Beach County · 2026")
            Text("$6,323")
                .font(.wcFigure(84))
                .foregroundStyle(Theme.teal)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text("is what the average home insurance policy here costs each year.")
                .font(.wcHeading)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("More than half of it pays for hurricane coverage, and that’s the part you can shrink.")
                .font(.wcBody).foregroundStyle(Theme.muted).lineSpacing(3)
            Spacer()
            Text("Source: Florida Office of Insurance Regulation, July 2026")
                .font(.wcCaption).foregroundStyle(Theme.muted)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 28)
    }

    // Card 2: the law, with the state's own numbers.
    private var lawCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer(minLength: 8)
            HouseIllustration(shape: .hip).frame(height: 160).frame(maxWidth: .infinity)
            Text("Florida law says storm-strong homes pay less")
                .font(.wcTitle).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 10) {
                feature("Hip roof", "47%")
                feature("Hurricane shutters or impact windows", "44%")
                feature("Metal roof-to-wall clips", "35%")
            }
            Text("Discount each one earns on its own, off the hurricane part of your premium (Florida’s credit table, OIR-B1-1699). Many homes qualify and never get them.")
                .font(.wcCaption).foregroundStyle(Theme.muted).lineSpacing(2)
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    private func feature(_ name: String, _ value: String) -> some View {
        HStack {
            Text(name).font(.wcSub).foregroundStyle(Theme.ink)
            Spacer()
            Text(value).font(.wcSubStrong).foregroundStyle(Theme.tealDeep)
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.line))
    }

    // Card 3: how it works, in three steps.
    private var howCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            Spacer()
            Text("Find yours in about two minutes")
                .font(.wcTitle).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            step(1, "Type your address", "We pull your home from county records.")
            step(2, "Answer four picture questions", "Roof, straps, windows. “Not sure” is fine.")
            step(3, "Scan your policy", "Read on your phone. Never uploaded.")
            Text("Then see what you’re missing, in dollars, and exactly what to do next.")
                .font(.wcBody).foregroundStyle(Theme.muted).lineSpacing(3)
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
                Text(title).font(.wcHeadline).foregroundStyle(Theme.ink)
                Text(detail).font(.wcSub).foregroundStyle(Theme.muted)
            }
        }
    }

    private func finish() { model.saved.hasSeenIntro = true }
}
