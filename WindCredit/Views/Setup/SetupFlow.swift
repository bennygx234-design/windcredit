import SwiftUI

enum SetupStep: Hashable { case home, policy, results }

struct SetupFlow: View {
    @EnvironmentObject var model: AppModel
    @State private var path: [SetupStep] = []

    var body: some View {
        NavigationStack(path: $path) {
            AddressView { path.append(.home) }
                .navigationDestination(for: SetupStep.self) { step in
                    switch step {
                    case .home: ConfirmHomeView { path.append(.policy) }
                    case .policy: PolicyView { path.append(.results) }
                    case .results: ResultsView(isSetup: true)
                    }
                }
        }
        .onAppear {
            if model.saved.record != nil && path.isEmpty {
                path = model.saved.policyDone ? [.home, .policy, .results] : [.home]
            }
        }
    }
}
