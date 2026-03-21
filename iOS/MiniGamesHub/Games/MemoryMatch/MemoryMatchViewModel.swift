import SwiftUI

// MARK: - Types

struct MemoryCard: Identifiable {
    let id: Int
    let symbol: String
    var isFaceUp = false
    var isMatched = false
}

// MARK: - ViewModel

@MainActor
final class MemoryMatchViewModel: ObservableObject {
    @Published var cards: [MemoryCard] = []
    @Published var moves: Int = 0
    @Published var isComplete: Bool = false

    private var firstFlippedIndex: Int? = nil
    private var isEvaluating = false

    private let symbols = ["star","heart","moon","sun.max","cloud","bolt",
                           "leaf","flame","drop","snowflake","wind","tornado"]

    func start(pairs: Int = 8) {
        let selected = Array(symbols.prefix(pairs))
        let doubled = (selected + selected).shuffled()
        cards = doubled.enumerated().map { MemoryCard(id: $0.offset, symbol: $0.element) }
        moves = 0
        isComplete = false
        firstFlippedIndex = nil
    }

    func flip(card: MemoryCard) {
        guard !isEvaluating,
              let index = cards.firstIndex(where: { $0.id == card.id }),
              !cards[index].isFaceUp,
              !cards[index].isMatched else { return }

        cards[index].isFaceUp = true

        if let first = firstFlippedIndex {
            moves += 1
            isEvaluating = true
            let second = index
            Task {
                try? await Task.sleep(for: .seconds(0.8))
                evaluate(first: first, second: second)
                isEvaluating = false
            }
            firstFlippedIndex = nil
        } else {
            firstFlippedIndex = index
        }
    }

    // MARK: Private

    private func evaluate(first: Int, second: Int) {
        if cards[first].symbol == cards[second].symbol {
            cards[first].isMatched = true
            cards[second].isMatched = true
            if cards.allSatisfy(\.isMatched) { isComplete = true }
        } else {
            cards[first].isFaceUp = false
            cards[second].isFaceUp = false
        }
    }
}
