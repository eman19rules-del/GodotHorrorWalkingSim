import SwiftUI

// MARK: - MiniGame Protocol

/// Every mini-game must conform to this protocol and register itself in `GameRegistry`.
protocol MiniGame: Identifiable, Hashable {
    var id: String { get }
    var displayName: String { get }
    var iconName: String { get }   // SF Symbol name
    var description: String { get }
    associatedtype GameView: View
    @ViewBuilder func makeView() -> GameView
}

// MARK: - Type-erased wrapper

/// Type-erased wrapper so heterogeneous games can be stored in an array.
struct AnyMiniGame: Identifiable, Hashable {
    let id: String
    let displayName: String
    let iconName: String
    let description: String
    private let _makeView: () -> AnyView

    init<G: MiniGame>(_ game: G) {
        id = game.id
        displayName = game.displayName
        iconName = game.iconName
        description = game.description
        _makeView = { AnyView(game.makeView()) }
    }

    func makeAnyView() -> AnyView { _makeView() }

    static func == (lhs: AnyMiniGame, rhs: AnyMiniGame) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
