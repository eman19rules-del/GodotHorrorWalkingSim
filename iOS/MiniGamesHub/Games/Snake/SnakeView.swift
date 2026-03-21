import SwiftUI

struct SnakeView: View {
    @StateObject private var viewModel = SnakeViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text("Score: \(viewModel.score)")
                .font(.title2.bold())

            GeometryReader { geo in
                let cellSize = geo.size.width / CGFloat(SnakeViewModel.gridSize)
                Canvas { context, _ in
                    // Draw food
                    let foodRect = CGRect(
                        x: CGFloat(viewModel.food.x) * cellSize,
                        y: CGFloat(viewModel.food.y) * cellSize,
                        width: cellSize, height: cellSize
                    ).insetBy(dx: 2, dy: 2)
                    context.fill(Circle().path(in: foodRect), with: .color(.red))

                    // Draw snake
                    for (i, pt) in viewModel.snake.enumerated() {
                        let rect = CGRect(
                            x: CGFloat(pt.x) * cellSize,
                            y: CGFloat(pt.y) * cellSize,
                            width: cellSize, height: cellSize
                        ).insetBy(dx: 1, dy: 1)
                        context.fill(
                            RoundedRectangle(cornerRadius: 3).path(in: rect),
                            with: .color(i == 0 ? .green : .mint)
                        )
                    }
                }
                .background(Color(.systemGroupedBackground))
                .cornerRadius(12)
            }
            .aspectRatio(1, contentMode: .fit)

            // D-pad controls
            dPad

            if viewModel.state == .idle || viewModel.state == .gameOver {
                Button(viewModel.state == .gameOver ? "Play Again" : "Start") {
                    viewModel.start()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .navigationTitle("Snake")
    }

    private var dPad: some View {
        VStack(spacing: 0) {
            arrowButton("chevron.up") { viewModel.changeDirection(.up) }
            HStack(spacing: 0) {
                arrowButton("chevron.left") { viewModel.changeDirection(.left) }
                Spacer().frame(width: 60, height: 60)
                arrowButton("chevron.right") { viewModel.changeDirection(.right) }
            }
            arrowButton("chevron.down") { viewModel.changeDirection(.down) }
        }
    }

    private func arrowButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title)
                .frame(width: 60, height: 60)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
