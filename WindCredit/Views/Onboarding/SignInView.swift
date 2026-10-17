import AuthenticationServices
import GoogleSignInSwift
import SwiftUI

struct SignInView: View {
    @EnvironmentObject var auth: AuthService
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "wind")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 92, height: 92)
                .background(Theme.teal, in: RoundedRectangle(cornerRadius: 24))
            Text("WindCredit").font(Theme.serif(38)).foregroundStyle(Theme.ink)
            Text("Save your home and plan so you can pick up where you left off.")
                .font(.body).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
            Spacer()

            VStack(spacing: 12) {
                SignInWithAppleButton(.continue) { auth.prepareApple($0) } onCompletion: { result in
                    Task { await auth.finishApple(result) }
                }
                .signInWithAppleButtonStyle(scheme == .dark ? .white : .black)
                .frame(height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Google's own button, as its branding rules require.
                GoogleSignInButton(scheme: scheme == .dark ? .dark : .light, style: .wide, state: .normal) {
                    Task { await auth.signInWithGoogle() }
                }
                .frame(height: 54)
                .accessibilityIdentifier("googleSignIn")

                if !AppConfig.isSupabaseConfigured {
                    Button("Continue in demo mode") { auth.continueInDemoMode() }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.muted)
                        .padding(.top, 4)
                        .accessibilityIdentifier("demoMode")
                }
            }
            .disabled(auth.isWorking)
            .overlay { if auth.isWorking { ProgressView() } }

            Label("Your policy photo never leaves your phone.", systemImage: "lock.fill")
                .font(.footnote).foregroundStyle(Theme.muted)
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 24)
        .background(Theme.background.ignoresSafeArea())
        .alert("Sign-in", isPresented: Binding(get: { auth.errorMessage != nil }, set: { if !$0 { auth.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(auth.errorMessage ?? "") }
    }
}
