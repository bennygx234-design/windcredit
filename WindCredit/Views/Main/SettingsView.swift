import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var auth: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false
    @State private var confirmRestart = false
    @State private var deleteError: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if case .local = auth.status {
                        LabeledContent("Account", value: "None, saved on this phone")
                        Button("Sign in to back up your plan") { Task { await auth.signOut(); dismiss() } }
                    } else {
                        LabeledContent("Signed in as", value: auth.displayName)
                        Button("Sign out") { Task { await auth.signOut(); dismiss() } }
                    }
                } header: { Text("Account") }

                Section("Your home") {
                    Button("Edit home and policy") {
                        model.saved.setupDone = false
                        dismiss()
                    }
                    Button("Start over with a new address") { confirmRestart = true }
                        .confirmationDialog("Start over?", isPresented: $confirmRestart, titleVisibility: .visible) {
                            Button("Start over", role: .destructive) { model.startOver(); dismiss() }
                        } message: { Text("Your home, answers and plan will be cleared.") }
                }

                Section {
                    Link("Palm Beach County Property Appraiser", destination: URL(string: "https://pbcpao.gov")!)
                    Link("Florida OIR discount table (OIR-B1-1699)", destination: URL(string: "https://floir.gov/property-casualty/premium-discounts-for-hurricane-loss-mitigation")!)
                    Link("Inspection form (OIR-B1-1802)", destination: URL(string: "https://floir.gov/docs-sf/default-source/property-and-casualty/oir-b1-1802.pdf")!)
                    Link("My Safe Florida Home", destination: URL(string: "https://mysafeflhome.com")!)
                } header: { Text("Where the numbers come from") } footer: {
                    Text("WindCredit gives estimates, not insurance quotes or advice. Confirm with a licensed wind-mitigation inspector or your agent. Your policy photo is read on your phone and never uploaded.")
                }

                Section {
                    Button("Delete account and data", role: .destructive) { confirmDelete = true }
                        .accessibilityIdentifier("deleteAccount")
                        .confirmationDialog("Delete your account?", isPresented: $confirmDelete, titleVisibility: .visible) {
                            Button("Delete account", role: .destructive) { Task { await deleteAccount() } }
                        } message: { Text("This can’t be undone.") }
                } footer: {
                    Text("Removes your account and everything WindCredit saved, on this phone and on our server.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .alert("Couldn’t delete", isPresented: Binding(get: { deleteError != nil }, set: { if !$0 { deleteError = nil } })) {
                Button("OK", role: .cancel) {}
            } message: { Text(deleteError ?? "") }
        }
    }

    private func deleteAccount() async {
        do {
            try await auth.deleteAccount()
            model.eraseEverything()
            dismiss()
        } catch {
            deleteError = "Check your connection and try again."
        }
    }
}
