# CLAUDE.md — Snow Buddy iOS

## What This App Does
Skiing/snowboarding tracker. Automatically detects and records runs (speed, distance, elevation, GPS route). Social layer: friends, groups, and live location sharing during active group sessions.

## Stack
- **UI**: SwiftUI
- **Async**: Swift Concurrency (async/await) — no Combine
- **Maps**: Mapbox
- **Local DB**: SwiftData (all run data lives here — never synced to backend)
- **Backend**: Supabase Swift client (auth, friends, groups, realtime location only)
- **Config**: `.xcconfig` files per environment (Development / Local / Production) — all gitignored

## Architecture: MVVM
```
Features/<FeatureName>/
    View/           # SwiftUI views only — zero business logic
    ViewModel/      # @Observable, owns state + logic, calls services
Services/           # RunManager, TrackingManager, SupabaseService, GroupSessionService
Model/              # SwiftData models + plain Swift structs
Shared/Components/  # Reusable UI only
Config/             # SupabaseConfig.swift + xcconfig
```

## Data Boundaries — CRITICAL
| Data | Storage | Notes |
|------|---------|-------|
| Run history, metrics, GPS routes | SwiftData (on-device only) | Never sent to Supabase |
| User account + auth | Supabase auth | |
| Friends list | Supabase `friendships` | |
| Group metadata + membership | Supabase `groups`, `group_members` | |
| Live location during session | Supabase Realtime broadcast (ephemeral) | Not persisted to DB |

## Key Models
- `Run` (SwiftData): id, startTime, endTime, topSpeed, avgSpeed, distance, verticalDescent, avgSlope, routePoints
- `RoutePoint`: latitude, longitude, altitude, timestamp
- `UserModel`: id, username, email
- All speeds stored in **m/s** — convert to km/h at the view layer only

## Feature Modules
- `Home` — session dashboard with live stats
- `RunList` — run history grouped by day
- `RunDetails` — per-run charts, map, shareable card
- `Map` — Mapbox mountain view + run overlays
- `SpeedTracker` — real-time speed display
- `Login` — Supabase auth + profile completion
- `Friends` — search, requests, friend list
- `Groups` — group management + active session live map (Feature 4)

## Feature 4: Group Sessions (active rework — priority)
See `agents/feature4-spec.md` for full architecture spec.

Core design:
- `GroupSessionService.swift` — single source of truth for all session state
- Supabase Realtime **broadcast** channel per group: `group-session:{groupId}`
- Location updates: every **5 seconds OR 10 meters** moved (whichever first)
- Session lifecycle: `idle → invited → active → ended`
- Members appear as animated pins on Mapbox map during active session
- Session ends when host ends it OR all members leave

## Free Tier Limits (enforce in app AND Supabase RLS/functions)
- Max friends: 50
- Max groups owned: 5
- Max members per group: 10
- Must be easy to change in one place per platform

## Branching
- Features → `develop`
- Releases → `main`
- Naming: `feature/<name>`, `fix/<name>`

## Rules — Never Violate
- NEVER sync run data to Supabase
- NEVER use Combine — async/await only
- NEVER modify existing migrations — create new ones
- NEVER hardcode secrets — use xcconfig
- NEVER use UIKit unless SwiftUI literally cannot do it
- ALL new tables need RLS enabled + policies defined before use
