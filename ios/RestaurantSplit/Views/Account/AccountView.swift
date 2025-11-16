import SwiftUI

struct AccountView: View {
    @StateObject private var viewModel = AccountViewModel()
    @EnvironmentObject private var theme: Theme

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: Binding(
                        get: { viewModel.profile.user.name },
                        set: { viewModel.profile.user.name = $0 }
                    ))
                    TextField("Email", text: .constant(viewModel.profile.user.email))
                        .disabled(true)
                    Picker("Currency", selection: $viewModel.preferredCurrency) {
                        ForEach(["USD", "EUR", "GBP", "JPY"], id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                    Toggle("Notifications", isOn: $viewModel.notificationsEnabled)
                }

                Section("Actions") {
                    Button("Save Changes", action: save)
                        .disabled(viewModel.isLoading)
                    Button("Load Profile", action: load)
                    Button("Logout", role: .destructive) {
                        viewModel.logout()
                    }
                }
            }
            .navigationTitle("Account")
            .overlay(alignment: .bottom) {
                if let message = viewModel.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(theme.accentColor.opacity(0.8))
                        .clipShape(Capsule())
                        .padding()
                        .transition(.opacity)
                }
            }
        }
    }

    private func load() {
        Task { await viewModel.loadProfile() }
    }

    private func save() {
        Task { await viewModel.saveChanges() }
    }
}

#Preview {
    AccountView()
        .environmentObject(Theme())
}
