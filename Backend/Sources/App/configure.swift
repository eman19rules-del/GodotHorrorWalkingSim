import Vapor
import Fluent
import FluentPostgresDriver
import JWT

public func configure(_ app: Application) async throws {
    // MARK: - Database
    app.databases.use(
        .postgres(url: Environment.get("DATABASE_URL") ?? "postgres://localhost/minigames"),
        as: .psql
    )

    // MARK: - Migrations
    app.migrations.add(CreateUser())
    app.migrations.add(CreateScore())
    try await app.autoMigrate()

    // MARK: - JWT
    let jwtSecret = Environment.get("JWT_SECRET") ?? "change-me-in-production"
    await app.jwt.keys.add(hmac: .init(from: jwtSecret), digestAlgorithm: .sha256)

    // MARK: - Routes
    try routes(app)
}
