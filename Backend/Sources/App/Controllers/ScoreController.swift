import Vapor

struct ScoreController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post("scores", use: submit)
        routes.get("users", "me", use: me)
    }

    func submit(req: Request) async throws -> Score {
        struct SubmitBody: Content, Validatable {
            let gameId: String
            let value: Int
            static func validations(_ validations: inout Validations) {
                validations.add("gameId", as: String.self, is: !.empty)
                validations.add("value", as: Int.self, is: .range(0...))
            }
        }
        try SubmitBody.validate(content: req)
        let body = try req.content.decode(SubmitBody.self)
        let user = try req.auth.require(User.self)
        let score = try Score(userID: user.requireID(), gameId: body.gameId, value: body.value)
        try await score.save(on: req.db)
        return score
    }

    func me(req: Request) async throws -> User.Public {
        try req.auth.require(User.self).toPublic()
    }
}
