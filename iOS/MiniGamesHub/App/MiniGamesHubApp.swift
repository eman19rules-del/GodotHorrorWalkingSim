import SwiftUI

@main
struct MiniGamesHubApp: App {
    @StateObject private var authSession = AuthSession()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authSession)
        }
    }
}
