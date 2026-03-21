import Vapor

func routes(_ app: Application) throws {
    let v1 = app.grouped("api", "v1")

    try v1.register(collection: AuthController())
    try v1.register(collection: LeaderboardController())

    let protected = v1.grouped(UserAuthenticator(), User.guardMiddleware())
    try protected.register(collection: ScoreController())
}
