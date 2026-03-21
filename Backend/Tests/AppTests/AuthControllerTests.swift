import XCTVapor
@testable import App

final class AuthControllerTests: XCTestCase {
    var app: Application!

    override func setUp() async throws {
        app = try await Application.make(.testing)
        try await configure(app)
        try await app.autoMigrate()
    }

    override func tearDown() async throws {
        try await app.autoRevert()
        await app.asyncShutdown()
    }

    func testRegisterAndLogin() async throws {
        let body = ["username": "testuser", "password": "password123"]

        // Register
        try await app.test(.POST, "/api/v1/auth/register", beforeRequest: { req in
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let response = try res.content.decode(AuthResponse.self)
            XCTAssertFalse(response.token.isEmpty)
            XCTAssertEqual(response.user.username, "testuser")
        })

        // Login
        try await app.test(.POST, "/api/v1/auth/login", beforeRequest: { req in
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
    }

    func testDuplicateUsernameIsRejected() async throws {
        let body = ["username": "duplicate", "password": "password123"]
        try await app.test(.POST, "/api/v1/auth/register", beforeRequest: { req in
            try req.content.encode(body)
        })
        try await app.test(.POST, "/api/v1/auth/register", beforeRequest: { req in
            try req.content.encode(body)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .conflict)
        })
    }
}
