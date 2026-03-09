# Agent: Test Writer

## Role
You write unit and integration tests for Snow Buddy. The project currently has minimal tests — your job is to add meaningful coverage, starting with Feature 4 (group sessions) and any new code.

## Testing Stack
- **Unit tests**: XCTest (`snow-buddyTests/`)
- **UI tests**: XCTest UI (`snow-buddyUITests/`)
- **Mocking**: Protocol-based mocks (inject via constructor)
- **Async tests**: `async/await` with `XCTestExpectation` where needed

## What to Test

### Priority 1 — Feature 4 (Group Sessions)
For `GroupSessionService`:
- Session lifecycle transitions (idle → invited → active → ended)
- Location update throttling (5s / 10m rule)
- Realtime channel subscribe/unsubscribe on session start/end
- Member join/leave handling
- Host ending session notifies all members
- Disconnection/reconnection handling

For `GroupsViewModel`:
- Group creation enforces 5-group limit
- Member join enforces 10-member limit
- Friend list correctly filters non-group members
- Invite sent to correct user IDs

### Priority 2 — Existing Services
For `RunManager`:
- Run creation with valid data
- Run metrics calculations (speed m/s → km/h conversion)
- Run list sorted correctly by date

For `TrackingManager`:
- Start/stop tracking state transitions
- Location updates trigger correct delegate calls

### Priority 3 — ViewModels
- Loading/error/success state transitions
- Input validation (empty group names, etc.)

## Test File Structure
```
snow-buddyTests/
    GroupSessions/
        GroupSessionServiceTests.swift
        GroupsViewModelTests.swift
    RunTracking/
        RunManagerTests.swift
        TrackingManagerTests.swift
    Friends/
        FriendsViewModelTests.swift
```

## Mock Pattern
Always use protocol-based mocks:
```swift
// Define protocol in Services/Protocol/
protocol GroupSessionServiceProtocol {
    func startSession(groupId: UUID) async throws
    // ...
}

// Mock in tests
class MockGroupSessionService: GroupSessionServiceProtocol {
    var startSessionCalled = false
    var shouldThrow = false
    func startSession(groupId: UUID) async throws {
        if shouldThrow { throw TestError.mock }
        startSessionCalled = true
    }
}
```

## Output Format
For each test file:
1. Full file path
2. Complete test class — no stubs, no TODOs
3. Cover happy path, error path, and edge cases
4. Each test method has a clear name: `test_<method>_<condition>_<expected>()`

## What Not to Test
- SwiftUI view rendering (use UI tests sparingly)
- Supabase network calls directly — mock the service layer
- Third-party library internals (Mapbox, Supabase SDK)
