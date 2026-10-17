import AuthenticationServices
import CryptoKit
import Foundation
import GoogleSignIn
import Supabase

/// Keys come from Config.xcconfig → Info.plist. Empty keys mean demo mode.
enum AppConfig {
    static func value(_ key: String) -> String {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "").trimmingCharacters(in: .whitespaces)
    }
    static var supabaseURL: URL? {
        let s = value("SUPABASE_URL")
        return s.hasPrefix("https://") && !s.contains("YOUR-PROJECT") ? URL(string: s) : nil
    }
    static var supabaseKey: String { value("SUPABASE_ANON_KEY") }
    static var googleClientID: String { value("GIDClientID") }
    static var isSupabaseConfigured: Bool { supabaseURL != nil && !supabaseKey.isEmpty }
    static var isGoogleConfigured: Bool { isSupabaseConfigured && !googleClientID.isEmpty }
}

/// Sign in with Apple or Google through Supabase (the backend that stores accounts).
@MainActor
final class AuthService: ObservableObject {
    enum Status: Equatable {
        case checking, signedOut, signedIn(name: String), local
    }

    @Published private(set) var status: Status = .checking
    @Published var errorMessage: String?
    @Published var isWorking = false

    let client: SupabaseClient?
    private var appleNonce: String?

    init() {
        if let url = AppConfig.supabaseURL, AppConfig.isSupabaseConfigured {
            client = SupabaseClient(supabaseURL: url, supabaseKey: AppConfig.supabaseKey)
        } else {
            client = nil
        }
        if UserDefaults.standard.bool(forKey: "localMode") { status = .local; return }
        Task { await restore() }
    }

    var isSignedIn: Bool {
        switch status { case .signedIn, .local: true; default: false }
    }
    var displayName: String {
        switch status { case .signedIn(let n): n; case .local: "Not signed in"; default: "" }
    }

    private func restore() async {
        guard let client, let session = try? await client.auth.session else { status = .signedOut; return }
        status = .signedIn(name: Self.name(for: session.user))
    }

    // MARK: Apple

    /// Called by SignInWithAppleButton before it shows Apple's sheet.
    func prepareApple(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonce()
        appleNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    func finishApple(_ result: Result<ASAuthorization, Error>) async {
        guard let client else { notAvailable("Apple"); return }
        do {
            guard let cred = try result.get().credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = cred.identityToken, let token = String(data: tokenData, encoding: .utf8)
            else { throw URLError(.badServerResponse) }
            isWorking = true
            defer { isWorking = false }
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: token, nonce: appleNonce))
            // Apple only sends the name the first time, so save it.
            if let given = cred.fullName?.givenName {
                _ = try? await client.auth.update(user: UserAttributes(data: ["full_name": .string(given)]))
            }
            status = .signedIn(name: cred.fullName?.givenName ?? Self.name(for: session.user))
        } catch let e as ASAuthorizationError where e.code == .canceled {
            return
        } catch {
            errorMessage = "Apple sign-in didn’t work. Try again."
        }
    }

    // MARK: Google

    func signInWithGoogle() async {
        guard let client, AppConfig.isGoogleConfigured else { notAvailable("Google"); return }
        guard let root = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first?.rootViewController
        else { return }
        do {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: AppConfig.googleClientID)
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: root)
            guard let idToken = result.user.idToken?.tokenString else { throw URLError(.badServerResponse) }
            isWorking = true
            defer { isWorking = false }
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(provider: .google, idToken: idToken, accessToken: result.user.accessToken.tokenString))
            status = .signedIn(name: result.user.profile?.givenName ?? Self.name(for: session.user))
        } catch let e as GIDSignInError where e.code == .canceled {
            return
        } catch {
            errorMessage = "Google sign-in didn’t work. Try again."
        }
    }

    // MARK: No account, sign out, delete

    /// Accounts are optional (App Store 5.1.1): the plan can live only on this phone.
    func continueWithoutAccount() {
        UserDefaults.standard.set(true, forKey: "localMode")
        status = .local
    }

    /// Test builds without sign-in keys: say so plainly, then keep the plan on the phone.
    @Published var continueLocallyAfterAlert = false
    private func notAvailable(_ provider: String) {
        errorMessage = "\(provider) sign-in isn’t turned on in this test build. Your plan will be saved on this phone."
        continueLocallyAfterAlert = true
    }

    func signOut() async {
        UserDefaults.standard.set(false, forKey: "localMode")
        GIDSignIn.sharedInstance.signOut()
        try? await client?.auth.signOut()
        status = .signedOut
    }

    /// App Store rule 5.1.1(v): accounts must be deletable inside the app.
    /// The `delete-account` Edge Function removes the user with the server-only key.
    func deleteAccount() async throws {
        if let client, case .signedIn = status {
            try await client.functions.invoke("delete-account")
        }
        await signOut()
    }

    // MARK: Helpers

    private static func name(for user: User) -> String {
        if case .string(let n)? = user.userMetadata["full_name"] { return n.components(separatedBy: " ").first ?? n }
        if case .string(let n)? = user.userMetadata["name"] { return n.components(separatedBy: " ").first ?? n }
        return user.email ?? "Signed in"
    }

    private static func randomNonce(length: Int = 32) -> String {
        let chars = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String((0..<length).map { _ in chars.randomElement()! })
    }

    private static func sha256(_ s: String) -> String {
        SHA256.hash(data: Data(s.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
