# Home announcements API

The admin and learner home screens read `GET /announcements` through the existing
`ApiService`, with the signed-in user's bearer token. The live backend must
implement this endpoint; this repository contains the Flutter client and an
in-memory mock implementation only.

Return a JSON array of notices visible to the authenticated account:

```json
[
  {
    "id": "notice-001",
    "title": "Welcome to Excelerate",
    "body": "Explore Programs to find your next learning opportunity.",
    "published_at": "2026-10-16T09:00:00Z",
    "audience": "all"
  }
]
```

`audience` supports `all`, `admin`, or `learner`, and defaults to `all` when
omitted. Dates use ISO 8601. The home screen sorts notices newest first, initially
shows three, and offers expansion for longer lists. It includes loading, empty,
refresh, and retry states. Dates display the calendar date supplied by the server.

The backend must authenticate requests and filter audiences before returning
notices. Client filtering is an additional display check, not access control.

Run with `flutter run --dart-define=USE_MOCK=true` to see sample role-specific
notices from `lib/services/mock_data.dart`. Publishing and editing announcements
are outside the home screen's current scope.
