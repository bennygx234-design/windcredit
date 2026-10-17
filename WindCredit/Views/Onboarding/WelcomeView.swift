import SwiftUI

/// Three short cards. Skip is always visible (people who already get it shouldn't have to swipe).
struct WelcomeView: View {
    @EnvironmentObject var model: AppModel
    @State private var page = 0

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("house.and.flag", "Palm Beach pays a lot for insurance",
         "The average home policy here costs about $6,300 a year. Most of that pays for hurricane coverage."),
        ("checkmark.shield", "The law says your home can earn discounts",
         "Florida insurers must give credits for storm-strong features like a hip roof, roof straps and impact windows. Many homes qualify and never get them."),
        ("magnifyingglass.circle", "Find yours in about two minutes",
         "Type your address and scan your policy. WindCredit shows what you're likely missing, in dollars, and what to do next."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip") { finish() }
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.muted)
                    .padding()
                    .accessibilityIdentifier("skipIntro")
            }
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    VStack(spacing: 24) {
                        Spacer()
                        Image(systemName: pages[i].symbol)
                            .font(.system(size: 76, weight: .light))
                            .foregroundStyle(Theme.teal)
                            .frame(width: 150, height: 150)
                            .background(Theme.mist, in: Circle())
                        Text(pages[i].title)
                            .font(Theme.serif(30))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.center)
                        Text(pages[i].body)
                            .font(.body)
                            .foregroundStyle(Theme.muted)
                            .multilineTextAlignment(.center)
                        Spacer()
                        Spacer()
                    }
                    .padding(.horizontal, 28)
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(page == pages.count - 1 ? "Get started" : "Next") {
                if page == pages.count - 1 { finish() } else { withAnimation { page += 1 } }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .accessibilityIdentifier("introNext")
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private func finish() { model.saved.hasSeenIntro = true }
}
