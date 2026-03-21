# Architecture Overview

## System Diagram

```
┌──────────────────────────────────────────────────┐
│                  MiniGamesHub App                 │
│           (SwiftUI · iPhone + Mac)                │
│                                                   │
│  ┌────────┐   NavigationStack   ┌──────────────┐  │
│  │HubView │ ──────────────────> │ Game Screens │  │
│  └────────┘                     └──────────────┘  │
│       │                               │           │
│       └──────────┐    ┌──────────────┘           │
│                  ▼    ▼                           │
│             ┌──────────┐                          │
│             │APIService│  (async/await, URLSession)│
│             └────┬─────┘                          │
└──────────────────┼───────────────────────────────┘
                   │  HTTPS / JSON
                   ▼
┌──────────────────────────────────────────────────┐
│               Vapor 4 Backend                     │
│                                                   │
│  /api/v1/auth/*     AuthController               │
│  /api/v1/scores     ScoreController (JWT auth)   │
│  /api/v1/leaderboard LeaderboardController       │
│                                                   │
│            Fluent ORM                             │
│                  │                                │
│            PostgreSQL                             │
└──────────────────────────────────────────────────┘
```

## iOS App Layers

| Layer | Responsibility | Key Files |
|-------|---------------|-----------|
| **App** | Entry point, environment injection | `MiniGamesHubApp.swift`, `ContentView.swift` |
| **Hub** | Game discovery & navigation | `HubView`, `HubViewModel`, `GameRegistry` |
| **Games** | Individual game logic & UI | `Games/<Name>/` |
| **Auth** | Sign-in / registration flow | `AuthView`, `AuthViewModel`, `AuthSession` |
| **Leaderboard** | Score display | `LeaderboardView`, `LeaderboardViewModel` |
| **Services** | Network layer | `APIService` |
| **Models** | Shared DTOs | `User`, `Score`, `AuthResponse` |

## Backend Layers

| Layer | Responsibility | Key Files |
|-------|---------------|-----------|
| **Controllers** | HTTP request handlers | `AuthController`, `ScoreController`, `LeaderboardController` |
| **Models** | Fluent ORM entities | `User`, `Score`, `UserToken` |
| **Migrations** | Schema version control | `CreateUser`, `CreateScore` |
| **Middleware** | Auth, validation | `UserAuthenticator` |

## Data Flow: Score Submission

```
Game Over
   │
   ▼
ViewModel calls APIService.submitScore(gameId:value:)
   │
   ▼
POST /api/v1/scores  { game_id, value }
   Bearer: <jwt>
   │
   ▼
UserAuthenticator verifies JWT → loads User from DB
   │
   ▼
ScoreController.submit → saves Score row
   │
   ▼
200 OK → Score JSON returned
```

## Adding a Mini-Game (Checklist)

- [ ] Create `iOS/MiniGamesHub/Games/<Name>/` folder
- [ ] Add `<Name>Game.swift` (MiniGame conformance)
- [ ] Add `<Name>View.swift` (SwiftUI)
- [ ] Add `<Name>ViewModel.swift` (@MainActor ObservableObject)
- [ ] Register in `GameRegistry.games`
- [ ] Call `APIService.submitScore` on game-over
- [ ] Add ViewModel unit tests

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | PostgreSQL connection string |
| `JWT_SECRET` | Yes | HMAC secret for JWT signing |

See `Backend/.env.example` for a template.
