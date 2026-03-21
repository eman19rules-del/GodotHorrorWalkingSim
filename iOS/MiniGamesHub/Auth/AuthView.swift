import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @EnvironmentObject private var authSession: AuthSession

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)
                Text("Mini Games Hub")
                    .font(.largeTitle.bold())

                VStack(spacing: 12) {
                    TextField("Username", text: $viewModel.username)
                        .textFieldStyle(.roundedBorder)
                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                if let error = viewModel.error {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                VStack(spacing: 8) {
                    Button("Sign In") {
                        Task { await viewModel.signIn(session: authSession) }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)

                    Button("Create Account") {
                        Task { await viewModel.register(session: authSession) }
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isLoading)
                }

                Spacer()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}
