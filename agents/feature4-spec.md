# Feature 4: Group Sessions — Full Architecture Spec

## What It Does
Friends on the mountain can start a group session. During the session, all members see each other's live location on a shared Mapbox map. When the session ends, locations are discarded — nothing is persisted.

## Key Design Decisions
- **Live location = Realtime broadcast only** — never inserted into the database
- **Session state lives in `group_sessions` table** — only metadata (who, when, status)
- **iOS is source of truth for its own location** — Supabase just relays it
- **Single channel per group**: `group-session:{groupId}` — all members pub/sub here
- **Host controls the session** — only host can start/end it

---

## Supabase Schema (new migrations needed)

### `group_sessions` table
```sql
CREATE TABLE group_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    host_id UUID NOT NULL REFERENCES users(id),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'ended')),
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE group_sessions ENABLE ROW LEVEL SECURITY;

-- Members can read sessions for their groups
CREATE POLICY "group members can view sessions"
ON group_sessions FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM group_members
        WHERE group_members.group_id = group_sessions.group_id
        AND group_members.user_id = auth.uid()
    )
);

-- Host can insert
CREATE POLICY "host can start session"
ON group_sessions FOR INSERT
TO authenticated
WITH CHECK (host_id = auth.uid());

-- Host can update (to end session)
CREATE POLICY "host can end session"
ON group_sessions FOR UPDATE
TO authenticated
USING (host_id = auth.uid());

GRANT SELECT, INSERT, UPDATE ON group_sessions TO authenticated;
```

### `group_members` table additions
Add `role` column if not present:
```sql
ALTER TABLE group_members ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'member'
    CHECK (role IN ('host', 'member'));
```

### Free tier enforcement (DB function)
```sql
-- Check member limit before join
CREATE OR REPLACE FUNCTION check_group_member_limit()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(*) FROM group_members WHERE group_id = NEW.group_id) >= 10 THEN
        RAISE EXCEPTION 'Group has reached the maximum of 10 members';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_group_member_limit
BEFORE INSERT ON group_members
FOR EACH ROW EXECUTE FUNCTION check_group_member_limit();

-- Check group ownership limit before create
CREATE OR REPLACE FUNCTION check_group_ownership_limit()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(*) FROM groups WHERE created_by = NEW.created_by) >= 5 THEN
        RAISE EXCEPTION 'User has reached the maximum of 5 groups';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_group_ownership_limit
BEFORE INSERT ON groups
FOR EACH ROW EXECUTE FUNCTION check_group_ownership_limit();
```

---

## Realtime Channel Design

Channel name: `group-session:{groupId}`

### Message types (broadcast)
```json
// Location update (sent by each member every 5s or 10m)
{
    "type": "location_update",
    "userId": "uuid",
    "username": "jake",
    "latitude": 46.1234,
    "longitude": 7.5678,
    "altitude": 2100.0,
    "speed": 12.5,
    "timestamp": "2025-01-15T10:30:00Z"
}

// Member joined active session
{
    "type": "member_joined",
    "userId": "uuid",
    "username": "jake"
}

// Member left / went offline
{
    "type": "member_left",
    "userId": "uuid"
}

// Host ended the session
{
    "type": "session_ended",
    "endedBy": "uuid"
}
```

---

## iOS Architecture

### New Files
```
Features/Groups/
    View/
        GroupsListView.swift          # List of user's groups
        GroupDetailView.swift         # Group info + start session button
        ActiveSessionView.swift       # Mapbox map with live member pins
        GroupInviteView.swift         # Invite friends to group
    ViewModel/
        GroupsViewModel.swift         # Groups list + creation
        GroupDetailViewModel.swift    # Group detail + session management
        ActiveSessionViewModel.swift  # Live session state + map updates
Services/
    GroupSessionService.swift         # All Realtime logic lives here
    Protocol/
        GroupSessionServiceProtocol.swift
Model/
    GroupModels.swift                 # Group, GroupMember, GroupSession structs
    SessionModels.swift               # BroadcastMessage types, MemberLocation
```

### `GroupSessionService.swift` responsibilities
```swift
// Core interface
protocol GroupSessionServiceProtocol {
    var memberLocations: [UUID: MemberLocation] { get }
    var sessionStatus: SessionStatus { get }
    
    func startSession(groupId: UUID) async throws -> GroupSession
    func joinSession(groupId: UUID, sessionId: UUID) async throws
    func endSession(sessionId: UUID) async throws
    func leaveSession() async
    func sendLocationUpdate(_ location: CLLocation) async
    func subscribeToChannel(groupId: UUID)
    func unsubscribeFromChannel()
}
```

### Session state machine
```
idle
 └─(host taps Start Session)──► starting
                                    └─(session created in DB + channel subscribed)──► active
                                                                                          ├─(host taps End)──► ending──► ended──► idle
                                                                                          └─(all members leave)──► ended──► idle
```

### `ActiveSessionViewModel.swift` responsibilities
- Subscribe to `GroupSessionService` state changes via `@Observable`
- Convert `[UUID: MemberLocation]` → Mapbox annotation models
- Update annotations on each location broadcast (diff, not full reload)
- Show member name + speed as annotation callout
- Handle session ended → navigate back + show summary

### Location update throttling
```swift
// In GroupSessionService
private var lastSentLocation: CLLocation?
private var lastSentTime: Date = .distantPast

func shouldSendUpdate(for location: CLLocation) -> Bool {
    let timePassed = Date().timeIntervalSince(lastSentTime) >= 5.0
    let distanceMoved = lastSentLocation.map { location.distance(from: $0) >= 10.0 } ?? true
    return timePassed || distanceMoved
}
```

### Reconnection handling
```swift
// Subscribe with presence tracking
channel.onClose { [weak self] in
    Task { await self?.handleDisconnect() }
}

private func handleDisconnect() async {
    // Show "Reconnecting..." state in UI
    // Attempt reconnect with exponential backoff (1s, 2s, 4s, max 30s)
    // Re-subscribe to channel on reconnect
}
```

---

## UI Flow

### Starting a session (host)
1. Host opens group detail → taps "Start Session"
2. App creates `group_sessions` row in DB (status: active)
3. App subscribes to `group-session:{groupId}` broadcast channel
4. App broadcasts `member_joined` with host info
5. `ActiveSessionView` opens — shows mountain map, host pin visible

### Joining a session (member)
1. Member opens group detail → sees "Session Active" banner
2. Member taps "Join Session"
3. App subscribes to channel + broadcasts `member_joined`
4. `ActiveSessionView` opens — all current member pins appear

### Live tracking
- `TrackingManager` feeds location to `GroupSessionService`
- Service applies throttle check (5s or 10m)
- If passes: broadcast `location_update` on channel
- Service receives others' `location_update` → updates `memberLocations` dict
- `ActiveSessionViewModel` observes `memberLocations` → updates Mapbox pins

### Ending a session
1. Host taps "End Session" → confirmation alert
2. App broadcasts `session_ended`
3. App updates `group_sessions` row (status: ended, ended_at: now)
4. App unsubscribes from channel
5. All members' `ActiveSessionView` receives `session_ended` → shows session summary → navigates back

### Member leaves early
1. Member taps "Leave Session"
2. Broadcasts `member_left`
3. Unsubscribes from channel
4. Other members' map removes their pin

---

## What the Current Bad Architecture Likely Has (avoid these)
- Storing location updates as DB rows (causes write storms, not designed for this)
- Not unsubscribing from Realtime channels (memory/connection leaks)
- Session state split across multiple places (ViewModel + Service + DB)
- No session lifecycle — sessions that never end
- Location sent on every GPS update regardless of movement

---

## Implementation Order
1. **Supabase**: Write migration for `group_sessions` + triggers
2. **iOS Models**: `GroupModels.swift`, `SessionModels.swift`
3. **iOS Service**: `GroupSessionServiceProtocol` + `GroupSessionService`
4. **iOS ViewModels**: `GroupDetailViewModel` → `ActiveSessionViewModel`  
5. **iOS Views**: `GroupDetailView` → `ActiveSessionView`
6. **Tests**: `GroupSessionServiceTests` + `ActiveSessionViewModelTests`
7. **Review**: Run `code-reviewer` agent against all new files
8. **Push**: Use `git-pusher` agent — migrations to `dev`, iOS to `develop`
