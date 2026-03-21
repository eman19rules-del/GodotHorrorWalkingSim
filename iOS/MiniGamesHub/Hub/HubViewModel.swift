import SwiftUI

@MainActor
final class HubViewModel: ObservableObject {
    @Published var navigationPath = NavigationPath()
    let games: [AnyMiniGame] = GameRegistry.games
}
