import Vapor
import JWT

struct UserToken: JWTPayload {
    var subject: SubjectClaim       // user ID
    var expiration: ExpirationClaim

    func verify(using algorithm: some JWTAlgorithm) async throws {
        try expiration.verifyNotExpired()
    }
}
