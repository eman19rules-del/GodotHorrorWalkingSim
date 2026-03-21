import SwiftUI

/// Root view. Shows the auth flow if the user is not signed in,
/// otherwise shows the game hub.
struct ContentView: View {
    @EnvironmentObject private var authSession: AuthSession

    var body: some View {
        if authSession.isAuthenticated {
            HubView()
        } else {
            AuthView()
        }
    }
}
