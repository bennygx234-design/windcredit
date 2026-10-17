import GoogleSignIn
import SwiftUI

@main
struct WindCreditApp: App {
    @StateObject private var model = AppModel()
    @StateObject private var auth = AuthService()

    init() { Appearance.apply() }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .environmentObject(auth)
                .tint(Theme.teal)
                .font(.wcBody)
                .onOpenURL { GIDSignIn.sharedInstance.handle($0) }
        }
    }
}

/// One straight path, value first:
/// welcome → address → your home → your policy → results → save your plan → plan.
struct RootView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var auth: AuthService

    var body: some View {
        Group {
            if !model.saved.hasSeenIntro {
                WelcomeView()
            } else if !model.saved.setupDone {
                SetupFlow()
            } else if auth.status == .checking {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.background)
            } else if !auth.isSignedIn {
                SignInView()
            } else {
                DashboardView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: model.saved.hasSeenIntro)
        .animation(.easeInOut(duration: 0.25), value: auth.status)
        .animation(.easeInOut(duration: 0.25), value: model.saved.setupDone)
        .task(id: model.saved.completed) { await model.sync(using: auth.client) }
    }
}
