import SwiftUI
import Combine

// MARK: - Types

struct GridPoint: Hashable {
    var x: Int
    var y: Int
}

enum SnakeDirection { case up, down, left, right }
enum SnakeGameState { case idle, playing, gameOver }

// MARK: - ViewModel

@MainActor
final class SnakeViewModel: ObservableObject {
    static let gridSize = 20

    @Published var snake: [GridPoint] = []
    @Published var food: GridPoint = GridPoint(x: 10, y: 10)
    @Published var state: SnakeGameState = .idle
    @Published var score: Int = 0

    private var direction: SnakeDirection = .right
    private var pendingDirection: SnakeDirection = .right
    private var timer: AnyCancellable?

    func start() {
        snake = [GridPoint(x: 5, y: 10), GridPoint(x: 4, y: 10), GridPoint(x: 3, y: 10)]
        direction = .right
        pendingDirection = .right
        score = 0
        placeFood()
        state = .playing
        timer = Timer.publish(every: 0.15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    func changeDirection(_ newDirection: SnakeDirection) {
        // Prevent reversing
        let forbidden: SnakeDirection
        switch direction {
        case .up: forbidden = .down
        case .down: forbidden = .up
        case .left: forbidden = .right
        case .right: forbidden = .left
        }
        if newDirection != forbidden { pendingDirection = newDirection }
    }

    // MARK: Private

    private func tick() {
        direction = pendingDirection
        guard var head = snake.first else { return }

        switch direction {
        case .up:    head.y -= 1
        case .down:  head.y += 1
        case .left:  head.x -= 1
        case .right: head.x += 1
        }

        let g = Self.gridSize
        guard head.x >= 0, head.x < g, head.y >= 0, head.y < g else {
            endGame(); return
        }
        guard !snake.contains(head) else { endGame(); return }

        snake.insert(head, at: 0)
        if head == food {
            score += 1
            placeFood()
        } else {
            snake.removeLast()
        }
    }

    private func endGame() {
        timer?.cancel()
        state = .gameOver
    }

    private func placeFood() {
        let occupied = Set(snake)
        let g = Self.gridSize
        var candidate: GridPoint
        repeat {
            candidate = GridPoint(x: Int.random(in: 0..<g), y: Int.random(in: 0..<g))
        } while occupied.contains(candidate)
        food = candidate
    }
}
