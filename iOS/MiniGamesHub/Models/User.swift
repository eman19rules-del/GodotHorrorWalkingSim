import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let username: String
}
