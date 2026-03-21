import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var error: String?

    func signIn(session: AuthSession) async {
        guard validate() else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await APIService.shared.login(username: username, password: password)
            session.signIn(token: response.token, user: response.user)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func register(session: AuthSession) async {
        guard validate() else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await APIService.shared.register(username: username, password: password)
            session.signIn(token: response.token, user: response.user)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func validate() -> Bool {
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.isEmpty else {
            error = "Username and password are required."
            return false
        }
        error = nil
        return true
    }
}
