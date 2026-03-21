import Fluent

struct CreateScore: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Score.schema)
            .id()
            .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .field("game_id", .string, .required)
            .field("value", .int, .required)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Score.schema).delete()
    }
}
