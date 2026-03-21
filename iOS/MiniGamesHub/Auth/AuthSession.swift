import SwiftUI

/// Holds the authenticated user state. Injected as an @EnvironmentObject.
@MainActor
final class AuthSession: ObservableObject {
    @Published var currentUser: User?
    @Published var token: String?

    var isAuthenticated: Bool { token != nil }

    func signIn(token: String, user: User) {
        self.token = token
        self.currentUser = user
    }

    func signOut() {
        token = nil
        currentUser = nil
    }
}
