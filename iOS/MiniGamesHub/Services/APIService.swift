import Foundation

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidResponse
    case serverError(Int, String)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:       return "Invalid server response."
        case .serverError(let c, let m): return "Server error \(c): \(m)"
        case .decodingFailed(let e): return "Decoding failed: \(e.localizedDescription)"
        }
    }
}

// MARK: - APIService

final class APIService {
    static let shared = APIService()
    private init() {}

    /// Override in tests or staging by setting this before first use.
    var baseURL = URL(string: "http://localhost:8080/api/v1")!

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    // MARK: - Auth

    func register(username: String, password: String) async throws -> AuthResponse {
        struct Body: Encodable { let username: String; let password: String }
        return try await post("/auth/register", body: Body(username: username, password: password), token: nil)
    }

    func login(username: String, password: String) async throws -> AuthResponse {
        struct Body: Encodable { let username: String; let password: String }
        return try await post("/auth/login", body: Body(username: username, password: password), token: nil)
    }

    // MARK: - Leaderboard

    func leaderboard(gameId: String? = nil) async throws -> [Score] {
        let path = gameId.map { "/leaderboard/\($0)" } ?? "/leaderboard"
        return try await get(path, token: nil)
    }

    // MARK: - Scores

    func submitScore(gameId: String, value: Int, token: String) async throws {
        let body = ScoreSubmission(gameId: gameId, value: value)
        let _: Score = try await post("/scores", body: body, token: token)
    }

    // MARK: - Private helpers

    private func get<T: Decodable>(_ path: String, token: String?) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "GET"
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        return try await perform(request)
    }

    private func post<Body: Encodable, Response: Decodable>(
        _ path: String, body: Body, token: String?
    ) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        return try await perform(request)
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? ""
            throw APIError.serverError(http.statusCode, message)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
}
