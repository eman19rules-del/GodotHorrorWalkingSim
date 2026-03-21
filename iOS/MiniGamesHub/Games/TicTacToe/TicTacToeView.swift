import SwiftUI

struct TicTacToeView: View {
    @StateObject private var viewModel = TicTacToeViewModel()

    var body: some View {
        VStack(spacing: 24) {
            statusText
            boardGrid
            Button("New Game", action: viewModel.reset)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Tic-Tac-Toe")
    }

    // MARK: Subviews

    private var statusText: some View {
        Group {
            switch viewModel.result {
            case .ongoing:
                Text("Player \(viewModel.currentPlayer.rawValue)'s turn")
            case .win(let player):
                Text("Player \(player.rawValue) wins!")
                    .foregroundStyle(.tint)
            case .draw:
                Text("It's a draw!")
            }
        }
        .font(.title2.bold())
    }

    private var boardGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
            ForEach(0..<9) { index in
                cell(at: index)
            }
        }
    }

    private func cell(at index: Int) -> some View {
        Button {
            viewModel.tap(index: index)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .aspectRatio(1, contentMode: .fit)
                if case .filled(let player) = viewModel.board[index] {
                    Text(player.rawValue)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(player == .x ? Color.blue : Color.red)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
