import SwiftUI

@MainActor
final class LeaderboardViewModel: ObservableObject {
    @Published var scores: [Score] = []
    @Published var isLoading = false
    @Published var error: String?

    func load(gameId: String? = nil) async {
        isLoading = true
        defer { isLoading = false }
        do {
            scores = try await APIService.shared.leaderboard(gameId: gameId)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}
