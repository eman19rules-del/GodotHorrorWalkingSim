import SwiftUI

struct TicTacToeGame: MiniGame {
    let id = "tic-tac-toe"
    let displayName = "Tic-Tac-Toe"
    let iconName = "grid"
    let description = "Classic 3×3 game vs AI or a friend"

    func makeView() -> TicTacToeView {
        TicTacToeView()
    }
}
