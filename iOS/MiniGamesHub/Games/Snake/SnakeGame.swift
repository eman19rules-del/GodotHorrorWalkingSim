import SwiftUI

struct SnakeGame: MiniGame {
    let id = "snake"
    let displayName = "Snake"
    let iconName = "arrow.up.right.and.arrow.down.left.rectangle"
    let description = "Eat food, grow longer, don't crash"

    func makeView() -> SnakeView {
        SnakeView()
    }
}
