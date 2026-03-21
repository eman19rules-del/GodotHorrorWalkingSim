import SwiftUI

/// Central registry of all available mini-games.
/// To add a new game, conform it to `AnyMiniGame` and append it here.
enum GameRegistry {
    static let games: [AnyMiniGame] = [
        AnyMiniGame(TicTacToeGame()),
        AnyMiniGame(SnakeGame()),
        AnyMiniGame(MemoryMatchGame()),
    ]
}
