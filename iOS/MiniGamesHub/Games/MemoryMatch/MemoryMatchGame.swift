import SwiftUI

struct MemoryMatchGame: MiniGame {
    let id = "memory-match"
    let displayName = "Memory Match"
    let iconName = "rectangle.grid.3x2"
    let description = "Flip cards and find matching pairs"

    func makeView() -> MemoryMatchView {
        MemoryMatchView()
    }
}
