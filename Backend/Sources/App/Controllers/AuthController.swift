import Vapor
import JWT

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("register", use: register)
        auth.post("login", use: login)
    }

    // MARK: - Register

    func register(req: Request) async throws -> AuthResponse {
        struct RegisterBody: Content, Validatable {
            let username: String
            let password: String
            static func validations(_ validations: inout Validations) {
                validations.add("username", as: String.self, is: .count(3...32) && .alphanumeric)
                validations.add("password", as: String.self, is: .count(8...))
            }
        }
        try RegisterBody.validate(content: req)
        let body = try req.content.decode(RegisterBody.self)

        guard try await User.query(on: req.db)
                .filter(\.$username == body.username).first() == nil else {
            throw Abort(.conflict, reason: "Username already taken.")
        }

        let user = try User(
            username: body.username,
            passwordHash: Bcrypt.hash(body.password)
        )
        try await user.save(on: req.db)
        return try await issueToken(for: user, req: req)
    }

    // MARK: - Login

    func login(req: Request) async throws -> AuthResponse {
        struct LoginBody: Content {
            let username: String
            let password: String
        }
        let body = try req.content.decode(LoginBody.self)
        guard let user = try await User.query(on: req.db)
                .filter(\.$username == body.username).first(),
              try Bcrypt.verify(body.password, created: user.passwordHash) else {
            throw Abort(.unauthorized, reason: "Invalid credentials.")
        }
        return try await issueToken(for: user, req: req)
    }

    // MARK: - Private

    private func issueToken(for user: User, req: Request) async throws -> AuthResponse {
        let payload = UserToken(
            subject: .init(value: try user.requireID().uuidString),
            expiration: .init(value: Date().addingTimeInterval(60 * 60 * 24 * 7)) // 7 days
        )
        let token = try await req.jwt.sign(payload)
        return AuthResponse(token: token, user: try user.toPublic())
    }
}

// MARK: - Response DTO

struct AuthResponse: Content {
    let token: String
    let user: User.Public
}
