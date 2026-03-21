import SwiftUI

/// Main hub screen showing the grid of available mini-games.
struct HubView: View {
    @StateObject private var viewModel = HubViewModel()
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.games) { game in
                        NavigationLink(value: game) {
                            GameCard(game: game)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Mini Games")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: HubDestination.leaderboard) {
                        Label("Leaderboard", systemImage: "trophy")
                    }
                }
            }
            .navigationDestination(for: AnyMiniGame.self) { game in
                game.makeAnyView()
            }
            .navigationDestination(for: HubDestination.self) { destination in
                switch destination {
                case .leaderboard:
                    LeaderboardView()
                }
            }
        }
    }
}

enum HubDestination: Hashable {
    case leaderboard
}
