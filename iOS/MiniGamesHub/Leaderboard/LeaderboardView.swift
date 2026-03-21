import SwiftUI

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.error {
                ContentUnavailableView(error, systemImage: "wifi.slash")
            } else {
                List(viewModel.scores) { score in
                    HStack {
                        Text(score.username)
                            .font(.body)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(score.value)")
                                .font(.headline.monospacedDigit())
                            Text(score.gameId)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Leaderboard")
        .task { await viewModel.load() }
    }
}
