import AuthenticationServices
import GoogleSignInSwift
import SwiftUI

/// "Save your plan": shown after the results, so people see the value before any account.
struct SignInView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var model: AppModel
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer()
            Eyebrow(text: "Your plan is ready")
            Text("Save it so you don’t lose it")
                .font(.wcTitle).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

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
            }
            Spacer()

            VStack(spacing: 12) {
                SignInWithAppleButton(.continue) { auth.prepareApple($0) } onCompletion: { result in
                    Task { await auth.finishApple(result) }
                }
                .signInWithAppleButtonStyle(scheme == .dark ? .white : .black)
                .frame(height: 54)
                .clipShape(Capsule())

                // Google's own button, as its branding rules require.
                GoogleSignInButton(scheme: scheme == .dark ? .dark : .light, style: .wide, state: .normal) {
                    Task { await auth.signInWithGoogle() }
                }
                .frame(height: 54)
                .accessibilityIdentifier("googleSignIn")

                Button("Keep it on this phone instead") { auth.continueWithoutAccount() }
                    .font(.wcBodyMedium)
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 6)
                    .accessibilityIdentifier("noAccount")
            }
            .disabled(auth.isWorking)
            .overlay { if auth.isWorking { ProgressView() } }

            Label("Your policy photo never leaves your phone.", systemImage: "lock.fill")
                .font(.wcCaption).foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 24)
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
}
