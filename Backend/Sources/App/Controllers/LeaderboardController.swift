import Vapor

struct LeaderboardController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let lb = routes.grouped("leaderboard")
        lb.get(use: global)
        lb.get(":gameId", use: perGame)
    }

    func global(req: Request) async throws -> [LeaderboardEntry] {
        try await topScores(gameId: nil, req: req)
    }

    func perGame(req: Request) async throws -> [LeaderboardEntry] {
        guard let gameId = req.parameters.get("gameId") else {
            throw Abort(.badRequest)
        }
        return try await topScores(gameId: gameId, req: req)
    }

    // MARK: Private

    private func topScores(gameId: String?, req: Request) async throws -> [LeaderboardEntry] {
        var query = Score.query(on: req.db)
            .with(\.$user)
            .sort(\.$value, .descending)
            .limit(100)
        if let gameId { query = query.filter(\.$gameId == gameId) }
        let scores = try await query.all()
        return scores.map {
            LeaderboardEntry(
                id: $0.id ?? UUID(),
                userId: $0.$user.id,
                username: $0.user.username,
                gameId: $0.gameId,
                value: $0.value,
                createdAt: $0.createdAt ?? Date()
            )
        }
    }
}

// MARK: - DTO

struct LeaderboardEntry: Content {
    let id: UUID
    let userId: UUID
    let username: String
    let gameId: String
    let value: Int
    let createdAt: Date
}
