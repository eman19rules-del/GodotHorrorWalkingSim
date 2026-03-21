import SwiftUI

/// Visual card representing a single mini-game in the hub grid.
struct GameCard: View {
    let game: AnyMiniGame

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: game.iconName)
                .font(.system(size: 44))
                .foregroundStyle(.tint)
            Text(game.displayName)
                .font(.headline)
            Text(game.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
