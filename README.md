# Excelerate Talent Hub

Flutter-based engagement platform for learners and admins.

## Overview

Excelerate Talent Hub is a Flutter application designed to support onboarding, programme discovery, and role-based engagement for Excelerate users. The app includes learner and admin dashboards, protected routes, user authentication flows, and programme listing/detail experiences.

## Features

- Secure login and sign-up flow
- Role-aware learner and admin dashboards
- Programme listing and search experience
- Programme details with eligibility, outcomes, and schedule information
- Mock API-backed flow for local development and testing
- Responsive design aligned with the Excelerate design system

## Screenshots

The screenshots below show key UI screens from the app. The image files are stored in `docs/screenshots/` and the README references the uploaded filenames.

### 1. Login Screen

![Login screen](docs/screenshots/login.png.png)

### 2. Learner Dashboard

![Learner dashboard](docs/screenshots/dashboard.png.png)

### 3. Programme Listing

![Programme listing](docs/screenshots/programs.png.png)

### 4. Programme Details

![Programme details](docs/screenshots/program_details.png.png)

## Tech Stack

- Flutter
- Dart
- Provider for state management
- SharedPreferences for local session storage
- Mock API for local development and testing

## Prerequisites

- Flutter SDK installed
- Android Studio / Xcode / Chrome for device or browser testing
- Optional: Android Emulator, iOS Simulator, or Chrome for running the app

## Getting Started

1. Clone the repository:

   ```bash
   git clone https://github.com/Ruby160612/excelerate-engagement-app.git
   cd excelerate-engagement-app
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Run with the mock backend:

   ```bash
   flutter run --dart-define=USE_MOCK=true
   ```

4. Run against a real backend (if configured):

   ```bash
   flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://your-api-url
   ```

5. Run the test suite:

   ```bash
   flutter test
   ```

## Project Structure

- `lib/` — Flutter application source code
- `test/` — widget and unit tests
- `docs/` — project documentation and design guidance
- `docs/screenshots/` — UI screenshots referenced in the repository documentation

## Program Data Flow

Program list, detail, registration and learner dashboard counts use typed models:

```text
Program screens -> ProgramStore -> ProgramRepository -> ProgramService
Detail loader / dashboard -> ProgramRepository -> ProgramService
  -> MockProgramService -> existing MockApi + assets/data/programs.json
  -> ApiProgramService -> existing HTTP API
  -> FirebaseProgramService (placeholder; not enabled by default)
```

`ExcelerateApp(programService: ...)` accepts another implementation without screen changes.
Mock mode keeps the existing per-learner state, loading, search/category filters,
empty states and manual retry controls. Registrations update subsequent reads;
duplicates produce a typed `alreadyRegistered` error. Mock state resets on restart.

See [Program API contract](docs/PROGRAM_API_CONTRACT.md) for typed response shapes,
legacy HTTP compatibility, database relationships, error/retry rules, the inspection
inventory and the Firebase teammate handoff. Serialization uses the existing manual
`fromJson` / `toJson` pattern; no code generator or live Firebase is required by tests.

### Mock mode sign-in

Run with `--dart-define=USE_MOCK=true` and sign in with:

| Role | Email | Password |
| --- | --- | --- |
| Learner (completes the profile step first) | `learner@example.com` | `learner123` |
| Learner (profile completed) | `member@example.com` | `member123` |
| Admin | `admin@example.com` | `admin123` |

The signup invitation code in mock mode is `EXCEL2026`. The mock backend lives in memory, so registrations and sessions reset when the app restarts or the browser page is refreshed.

## Design Documentation

Refer to the product and UX design rationale here:

- `docs/SPRINT2_DESIGN.md`

## Repository

- GitHub: https://github.com/Ruby160612/excelerate-engagement-app
