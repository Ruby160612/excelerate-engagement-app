# Excelerate Talent Hub

A private Flutter/Dart starter for talent development and recruitment. Uses
Provider for state and dependency injection, `http` for API calls,
`shared_preferences` for session persistence, `file_picker` for CV selection,
`flutter_svg` for badges, and `intl` for dates.

## Run

Requires Flutter 3.27+ and Dart 3.6+. Dependencies are installed and the resolved
versions are recorded in `pubspec.lock`; commit the lockfile with this application.

```sh
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=https://your-api.example.com/api
```

The login screen runs without a backend. Authentication and data operations
require your API; there are no embedded demo accounts or credentials. Replace
`API_BASE_URL` with your server, including its API prefix. Use HTTPS; a web backend
must allow the application's origin through its CORS configuration. `dart-define`
values are compiled into the application and must not contain secrets.

## Structure

```text
lib/
  main.dart
  models/
    user.dart
    profile.dart
    job_opportunity.dart
    assessment.dart
    badge.dart
  views/
    auth/
      login.dart
      signup.dart
      profile_creation.dart
    learner/
      dashboard.dart
      cv_upload.dart
      programs_list.dart
      assessments.dart
      badges.dart
      applications.dart
    admin/
      post_opportunity.dart
      application_review.dart
      candidate_shortlisting.dart
      interview_scheduler.dart
  services/
    api_service.dart
    auth_service.dart
    storage_service.dart
  widgets/
    app_button.dart
    app_card.dart
    badge_widget.dart
    page_layout.dart
    auth_form.dart
    api_form.dart
    api_collection_view.dart
  utils/
    constants.dart
    themes.dart
    app_router.dart
assets/icons/badge.svg
test/
android/  ios/  web/  linux/  macos/  windows/
pubspec.yaml
pubspec.lock
analysis_options.yaml
```

`lib/main.dart` initializes preferences and providers. `/` restores and validates
a saved session, then shows login, profile onboarding, or the role's dashboard.
Every private named route observes auth state and checks its required role.
Learners must complete onboarding before accessing their workspace. Admin roles
come from the server; signup does not accept a client-selected role.

## Backend contract

The following paths are relative to `API_BASE_URL`. This is an assumed REST
contract to implement or adapt in the services; this project does not contain
a backend. JSON lists are bare arrays and JSON objects are unwrapped. JSON
requests use `Content-Type: application/json`. Authenticated requests include
`Authorization: Bearer <token>`. Failed requests may return `{"message":"..."}`.

| Method | Endpoint | Request / response |
| --- | --- | --- |
| POST | `/auth/login` | `email`, `password`; returns `{token, user}` |
| POST | `/auth/signup` | `name`, `email`, `password`, `invitation_code`; returns `{token, user}` |
| GET | `/auth/me` | Returns the current user; `401` for an expired/invalid session |
| PUT | `/profiles/me` | Profile JSON; successful save marks onboarding complete |
| POST | `/profiles/me/cv` | Multipart `cv` field; accepts PDF/DOC/DOCX up to 5 MB; returns JSON or `204` |
| GET | `/programs` | Array of `{id, title, description}` |
| GET | `/assessments/me` | Array of assessment JSON objects |
| GET | `/badges/me` | Array of badge JSON objects |
| GET | `/applications/me` | Array of `{id, opportunity_title, status, created_at}` |
| POST | `/opportunities` | `title`, `company`, `location`, `description`, `deadline`; server assigns ID |
| GET | `/applications` | Array of `{id, candidate_name, opportunity_title, status}`; admin only |
| PUT | `/applications/:id` | `{status: "shortlisted"}`; admin only |
| GET | `/applications?status=shortlisted` | Filtered admin application array |
| POST | `/interviews` | `application_id`, `location`, `scheduled_at`; admin only |

User JSON: `{id, name, email, role, profile_completed}`. Role is `learner` or
`admin`. Profile JSON: `{user_id, headline, bio, skills, cv_url}`. Skills are an
array of strings. Assessment JSON: `{id, title, duration_minutes, completed,
score}`; score may be null. Badge JSON: `{id, name, description, earned_at}`;
earned date may be null. Job JSON matches the opportunity request plus `id`.
Dates are ISO 8601; date/time submissions use UTC and displays use device-local
time. A deadline is the end of the selected day in the device's timezone.

Programs, assessments, and learner applications provide initial list screens.
Program enrollment, assessment questions/submission, opportunity browsing and
application submission can be added using the models and API service. Admin
review currently shows a submission summary and a shortlist action; detailed
candidate/CV review can be added as a separate screen.

## Session and platform configuration

Session tokens are stored in shared preferences as requested; passwords are
never persisted. Shared preferences do not encrypt tokens. For production,
replace token persistence in `StorageService` with secure platform storage or
an appropriate web session mechanism, and implement refresh/revocation if the
backend requires it. Logout currently clears the local session. Server-side
invitation validation, role enforcement, ownership checks, and CV content/size
validation must accompany the client checks.

All six platform runners are generated. Android release internet access and
macOS outbound network/user-selected file access are enabled. Platforms use the
standard Flutter launcher icons; customize these before distribution. Android
release currently uses the Flutter template's debug signing configuration;
configure your release signing before shipping. iOS/macOS builds require macOS
and Xcode; native targets also require their platform toolchains.

## Checks

```sh
dart format lib test
flutter analyze
flutter test
flutter build web --dart-define=API_BASE_URL=https://your-api.example.com/api
```

Tests exercise invitation form validation, protected routing, role checks,
session restoration/expiry/logout, HTTP error handling, and CV validation.
API tests use mock HTTP responses; they do not establish live backend
compatibility or exercise native file-picker dialogs.
