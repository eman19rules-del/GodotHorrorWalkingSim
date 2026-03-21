import Foundation

struct Score: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let username: String
    let gameId: String
    let value: Int
    let createdAt: Date
}

struct ScoreSubmission: Codable {
    let gameId: String
    let value: Int
}
