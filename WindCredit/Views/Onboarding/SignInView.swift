import SwiftUI

// Comes after the results on purpose: show the value before asking for an account.
struct SignInView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer()
            Eyebrow(text: "Your plan is ready")
            Text("Make it yours")
                .font(.wcTitle).foregroundStyle(Theme.ink)

            if model.savingsText != "$0" {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.savingsText).font(.wcFigure(40)).foregroundStyle(Theme.teal)
                        .minimumScaleFactor(0.6).lineLimit(1)
                    Text("a year in discounts, plus your 4-step plan and renewal reminder")
                        .font(.wcSub).foregroundStyle(Theme.muted)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.mist, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .reveal(0.1)
            }

            VStack(alignment: .leading, spacing: 12) {
                perk("person.text.rectangle", "Your name and email go on the report for your agent")
                perk("iphone", "Your plan stays on this phone either way")
                perk("tag", "Free. No ads, no subscriptions")
            }
            .reveal(0.2)

            Spacer()

            GoogleSignInPill { Task { await auth.signInWithGoogle() } }
                .reveal(0.3)

            Button("Skip, keep it on this phone") { auth.continueWithoutAccount() }
                .font(.wcBodyMedium)
                .foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .accessibilityIdentifier("noAccount")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
        .background(Theme.background.ignoresSafeArea())
        .alert("Sign-in", isPresented: Binding(get: { auth.errorMessage != nil }, set: { if !$0 { auth.errorMessage = nil } })) {
            Button("OK", role: .cancel) {
                if auth.continueLocallyAfterAlert {
                    auth.continueLocallyAfterAlert = false
                    auth.continueWithoutAccount()
                }
            }
        } message: { Text(auth.errorMessage ?? "") }
    }

    private func perk(_ icon: String, _ text: String) -> some View {
        Label {
            Text(text).font(.wcSub).foregroundStyle(Theme.ink)
        } icon: {
            Image(systemName: icon).foregroundStyle(Theme.teal).frame(width: 24)
        }
    }
}
