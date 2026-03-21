import SwiftUI

struct MemoryMatchView: View {
    @StateObject private var viewModel = MemoryMatchViewModel()
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        VStack(spacing: 16) {
            Text("Moves: \(viewModel.moves)")
                .font(.title2.bold())

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(viewModel.cards) { card in
                    CardView(card: card)
                        .onTapGesture { viewModel.flip(card: card) }
                }
            }

            if viewModel.isComplete {
                Text("Completed in \(viewModel.moves) moves!")
                    .font(.headline)
                    .foregroundStyle(.tint)
            }

            Button("New Game") { viewModel.start() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Memory Match")
        .onAppear { viewModel.start() }
    }
}

// MARK: - CardView

private struct CardView: View {
    let card: MemoryCard

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(card.isMatched ? Color.green.opacity(0.3) : (card.isFaceUp ? Color.white : Color.indigo))
            if card.isFaceUp || card.isMatched {
                Image(systemName: card.symbol)
                    .font(.largeTitle)
                    .foregroundStyle(card.isMatched ? .green : .primary)
            } else {
                Image(systemName: "questionmark")
                    .font(.title)
                    .foregroundStyle(.white)
            }
        }
        .aspectRatio(2/3, contentMode: .fit)
        .rotation3DEffect(.degrees(card.isFaceUp ? 0 : 180), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(duration: 0.4), value: card.isFaceUp)
    }
}
