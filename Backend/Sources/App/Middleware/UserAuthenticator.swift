import Vapor
import JWT

struct UserAuthenticator: AsyncBearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        let payload = try await request.jwt.verify(bearer.token, as: UserToken.self)
        guard let userId = UUID(uuidString: payload.subject.value),
              let user = try await User.find(userId, on: request.db) else {
            return
        }
        request.auth.login(user)
    }
}
