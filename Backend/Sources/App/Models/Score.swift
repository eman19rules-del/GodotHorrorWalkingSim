import Fluent
import Vapor

final class Score: Model, Content {
    static let schema = "scores"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "game_id")
    var gameId: String

    @Field(key: "value")
    var value: Int

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(id: UUID? = nil, userID: UUID, gameId: String, value: Int) {
        self.id = id
        self.$user.id = userID
        self.gameId = gameId
        self.value = value
    }
}
