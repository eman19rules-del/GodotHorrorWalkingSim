import SwiftUI

// MARK: - Types

enum TicTacToePlayer: String {
    case x = "X"
    case o = "O"
}

enum TicTacToeCellState {
    case empty
    case filled(TicTacToePlayer)
}

enum TicTacToeResult {
    case ongoing
    case win(TicTacToePlayer)
    case draw
}

// MARK: - ViewModel

@MainActor
final class TicTacToeViewModel: ObservableObject {
    @Published var board: [TicTacToeCellState] = Array(repeating: .empty, count: 9)
    @Published var currentPlayer: TicTacToePlayer = .x
    @Published var result: TicTacToeResult = .ongoing

    private let winningLines = [
        [0,1,2],[3,4,5],[6,7,8], // rows
        [0,3,6],[1,4,7],[2,5,8], // columns
        [0,4,8],[2,4,6]          // diagonals
    ]

    func tap(index: Int) {
        guard case .empty = board[index], case .ongoing = result else { return }
        board[index] = .filled(currentPlayer)
        result = evaluate()
        if case .ongoing = result {
            currentPlayer = currentPlayer == .x ? .o : .x
        }
    }

    func reset() {
        board = Array(repeating: .empty, count: 9)
        currentPlayer = .x
        result = .ongoing
    }

    // MARK: Private

    private func evaluate() -> TicTacToeResult {
        for line in winningLines {
            let states = line.map { board[$0] }
            if case .filled(let p) = states[0],
               case .filled(let q) = states[1], p == q,
               case .filled(let r) = states[2], p == r {
                return .win(p)
            }
        }
        if board.allSatisfy({ if case .empty = $0 { return false } else { return true } }) {
            return .draw
        }
        return .ongoing
    }
}
