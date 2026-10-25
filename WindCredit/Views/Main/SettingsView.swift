import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var auth: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false
    @State private var confirmRestart = false

    var body: some View {
        NavigationStack {
            List {
                if AuthService.isGoogleConfigured {
                    Section("Account") {
                        if let name = auth.firstName {
                            LabeledContent("Signed in as", value: auth.email ?? name)
                            Button("Sign out") { auth.signOut(); dismiss() }
                        } else {
                            LabeledContent("Google", value: "Not connected")
                            Button("Sign in with Google") { auth.signOut(); dismiss() }
                        }
                    }
                }

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
                    Link("Florida credit table (OIR-B1-1699)", destination: URL(string: "https://floir.gov/consumers/wind-mitigation-resources")!)
                    Link("Inspection form (OIR-B1-1802, Rev. 04/26)", destination: URL(string: "https://floir.gov/docs-sf/default-source/property-and-casualty/oir-b1-1802.pdf")!)
                    Link("Average premiums (OIR, July 2026)", destination: URL(string: "https://floir.gov/docs-sf/default-source/property-and-casualty/stability-unit-reports/july-2026-isu-report.pdf")!)
                    Link("My Safe Florida Home", destination: URL(string: "https://mysafeflhome.com")!)
                } header: { Text("Where the numbers come from") } footer: {
                    Text("Estimates, not insurance quotes or advice. Confirm with a licensed wind-mitigation inspector or your agent.")
                }

                Section {
                    Button("Delete my data", role: .destructive) { confirmDelete = true }
                        .accessibilityIdentifier("deleteAccount")
                        .confirmationDialog("Delete everything?", isPresented: $confirmDelete, titleVisibility: .visible) {
                            Button("Delete", role: .destructive) {
                                Task {
                                    await auth.deleteAccount()
                                    model.eraseEverything()
                                    dismiss()
                                }
                            }
                        } message: { Text("Your home, plan and reminders are erased, and WindCredit’s access to your Google account is removed. This can’t be undone.") }
                } footer: {
                    Text("WindCredit is free: no ads, no subscriptions, no servers. Your data only lives on this phone, and your policy photo is read on the phone and never uploaded.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
