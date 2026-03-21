# CLAUDE.md — MiniGamesHub Agentic Guidelines

This file defines conventions, architecture, and working rules for Claude (or any AI agent)
contributing to this project. Read this before making any changes.

---

## Project Overview

**MiniGamesHub** is a SwiftUI app for iPhone and Mac (via Catalyst / native Mac target) that
presents a central hub where players can select and play various mini-games. A Vapor (Swift)
backend handles user accounts and leaderboards.

### Repository Layout

```
/
├── CLAUDE.md                  # This file
├── README.md
├── .gitignore
├── iOS/                       # SwiftUI client app (iPhone + Mac)
│   └── MiniGamesHub/
│       ├── App/               # Entry point, root navigation
│       ├── Hub/               # Game selection hub screen
│       ├── Games/             # One sub-folder per mini-game
│       │   ├── TicTacToe/
│       │   ├── Snake/
│       │   └── MemoryMatch/
│       ├── Leaderboard/       # Global + per-game leaderboard UI
│       ├── Auth/              # Sign-in / account screens
│       ├── Models/            # Shared Swift data models (DTOs)
│       └── Services/          # API + Auth service layer
└── Backend/                   # Vapor 4 server
    ├── Sources/App/
    │   ├── Controllers/       # Route handlers
    │   ├── Models/            # Fluent models
    │   ├── Migrations/        # Database migrations
    │   ├── routes.swift
    │   └── configure.swift
    ├── Tests/AppTests/
    └── Package.swift
```

---

## Architecture Principles

### iOS App

- **Pattern:** MVVM. Each screen has a `View` (SwiftUI) and a `ViewModel` (`@Observable` or
  `ObservableObject`). Business logic lives in ViewModels, not Views.
- **Navigation:** Use a single `NavigationStack` rooted in `HubView`. Push game views onto it.
  Use `NavigationPath` for type-safe routing.
- **State management:** Prefer `@Observable` (iOS 17+) for ViewModels. Use `@EnvironmentObject`
  sparingly — only for truly app-wide state (auth session, theme).
- **Game protocol:** Every mini-game must conform to `MiniGame` (defined in
  `iOS/MiniGamesHub/Games/MiniGame.swift`):
  ```swift
  protocol MiniGame {
      var id: String { get }
      var displayName: String { get }
      var iconName: String { get }   // SF Symbol name
      var description: String { get }
      associatedtype GameView: View
      func makeView() -> GameView
  }
  ```
- **Networking:** All API calls go through `APIService`. Never call URLSession directly from
  a ViewModel. Use `async/await`.
- **Error handling:** Surface errors via a `@Published var error: AppError?` on the ViewModel.
  The View shows an `.alert` driven by this property.
- **No third-party dependencies in the iOS app.** Use only Apple frameworks.

### Backend (Vapor 4)

- **Database:** PostgreSQL via Fluent. Use migrations for all schema changes — never mutate the
  DB directly.
- **Auth:** JWT-based. Issue tokens on `/auth/register` and `/auth/login`. All protected routes
  require `UserAuthenticator` middleware.
- **API versioning:** Prefix all routes with `/api/v1/`.
- **Validation:** Validate all incoming request bodies with `Validatable` conformance on request
  DTOs.
- **No business logic in routes.swift.** Routes register controllers only. Logic goes in
  controllers or services.
- **Environment config:** All secrets (DB URL, JWT secret) come from environment variables.
  Document required vars in `Backend/.env.example`.

---

## Adding a New Mini-Game

1. Create a folder `iOS/MiniGamesHub/Games/<GameName>/`.
2. Add `<GameName>View.swift` (SwiftUI View) and `<GameName>ViewModel.swift`.
3. Conform a small struct in `<GameName>Game.swift` to the `MiniGame` protocol.
4. Register the game in `iOS/MiniGamesHub/Hub/GameRegistry.swift` — the hub auto-discovers
   games from this registry.
5. If the game has a score, post it via `APIService.submitScore(gameId:score:)` on game-over.

---

## API Endpoints (planned)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/v1/auth/register` | No | Create account |
| POST | `/api/v1/auth/login` | No | Login, returns JWT |
| GET | `/api/v1/users/me` | Yes | Current user profile |
| GET | `/api/v1/leaderboard` | No | Global top scores |
| GET | `/api/v1/leaderboard/:gameId` | No | Per-game top scores |
| POST | `/api/v1/scores` | Yes | Submit a score |

---

## Git Workflow

- Branch naming: `claude/<short-description>-<session-id>` for agent branches.
  Feature branches: `feature/<short-description>`, bug fixes: `fix/<short-description>`.
- Commits: imperative mood, present tense. E.g. `Add SnakeViewModel with collision detection`.
- Never force-push `main` or `master`.
- PRs require: passing CI, no build warnings, all new public APIs documented.

---

## Code Style

- Swift: follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).
  4-space indentation, `// MARK: -` sections to organise files over ~100 lines.
- Vapor: match existing file structure and naming. Controllers are classes, not structs.
- No commented-out code in commits.
- No `print()` statements in production code — use `Logger`.
- Avoid force-unwrap (`!`) except in unit tests. Prefer `guard let` or `if let`.

---

## Testing

- **iOS:** Unit-test ViewModels. Do NOT test SwiftUI Views directly.
  Target: `MiniGamesHubTests`.
- **Backend:** Integration-test each controller endpoint with `XCTVapor`.
  Target: `AppTests`. Use an in-memory SQLite DB for tests.
- All new features must include at least one test.

---

## Common Commands

```bash
# Run the Vapor backend locally (from Backend/)
swift run

# Run backend tests
swift test

# Build backend for release
swift build -c release
```

Xcode is required to build and run the iOS app. Open `iOS/MiniGamesHub.xcodeproj`.

---

## Out of Scope (do not add without discussion)

- Third-party analytics or ad SDKs
- In-app purchases / monetisation
- Android / cross-platform layers
- Real-time multiplayer (future milestone)
