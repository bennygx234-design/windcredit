import Foundation
import GoogleSignIn
import UIKit

// Google sign-in with no backend. It only needs a (free) iOS OAuth client ID in
// Config.xcconfig. The plan itself always lives on the phone, so an account is optional.
@MainActor
final class AuthService: ObservableObject {
    enum Status: Equatable {
        case checking, signedOut, local
        case signedIn(name: String, email: String)
    }

    @Published private(set) var status: Status = .checking
    @Published var errorMessage: String?
    @Published var continueLocallyAfterAlert = false

    static var googleClientID: String {
        (Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String ?? "").trimmingCharacters(in: .whitespaces)
    }
    static var isGoogleConfigured: Bool { !googleClientID.isEmpty }

    private let localKey = "localMode"

    init() {
        if UserDefaults.standard.bool(forKey: localKey) {
            status = .local
        } else if Self.isGoogleConfigured {
            GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, _ in
                Task { @MainActor in self?.status = user.map(Self.status(for:)) ?? .signedOut }
            }
        } else {
            status = .signedOut
        }
    }

    var isSignedIn: Bool {
        switch status { case .signedIn, .local: true; default: false }
    }

    var firstName: String? {
        if case .signedIn(let name, _) = status { name } else { nil }
    }

    var email: String? {
        if case .signedIn(_, let email) = status, !email.isEmpty { email } else { nil }
    }

    func signInWithGoogle() async {
        guard Self.isGoogleConfigured else {
            errorMessage = "Google sign-in isn’t turned on in this test build. Your plan will be saved on this phone."
            continueLocallyAfterAlert = true
            return
        }
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first
        else { return }

        do {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: Self.googleClientID)
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: root)
            UserDefaults.standard.set(false, forKey: localKey)
            status = Self.status(for: result.user)
        } catch let error as GIDSignInError where error.code == .canceled {
            return
        } catch {
            errorMessage = "Google sign-in didn’t work. Check your connection and try again."
        }
    }

    func continueWithoutAccount() {
        UserDefaults.standard.set(true, forKey: localKey)
        status = .local
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        UserDefaults.standard.set(false, forKey: localKey)
        status = .signedOut
    }

    /// Also revokes WindCredit's Google access, not just the local session.
    func deleteAccount() async {
        if case .signedIn = status { try? await GIDSignIn.sharedInstance.disconnect() }
        signOut()
    }

    private static func status(for user: GIDGoogleUser) -> Status {
        .signedIn(name: user.profile?.givenName ?? user.profile?.name ?? "You", email: user.profile?.email ?? "")
    }
}
