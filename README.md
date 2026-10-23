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

The program listing and the program details screens read data through one layer, so the data source can change without touching the screens.

```text
Screen (ProgramsListView / ProgramDetailsLoader)
  -> ProgramRepository   (lib/services/program_repository.dart)
    -> ApiService        (HTTP)
      -> mock API when USE_MOCK=true, otherwise the real backend
```

| File | Role |
| --- | --- |
| `lib/models/program.dart` | `Program` model (`fromJson` / `toJson`) |
| `lib/services/program_repository.dart` | `ProgramRepository` and `ApiProgramRepository`, plus the `ProgramException` error types |
| `lib/services/mock_api.dart` | In-memory API used in mock mode |
| `assets/data/programs.json` | Sample programs served by the mock API |
| `lib/views/learner/programs_list.dart` | Listing with search, category filter and Register |
| `lib/views/shared/program_details_loader.dart` | Loads one program by id and opens the details screen |

Routes: the listing is `/learner/programs` and details is `/program-details/<id>`. Details loads the program by id, so it does not depend on the list.

### Endpoints

| Method | Endpoint | Notes |
| --- | --- | --- |
| GET | `/programs` | Array of programs. `is_registered` reflects the signed-in user |
| GET | `/programs/:id` | One program. `404` if it does not exist |
| POST | `/programs/:id/register` | Learner only. Returns the program with `is_registered: true`. `403` for admins |

### Program record

Required: `id`, `title`, `start_date` (ISO 8601) and `category` (for example `course`, `workshop`, `webinar` or `internship`).
Optional: `description`, `end_date`, `schedule`, `eligibility` (array of strings), `outcomes` (array of strings), `image_url`, `is_registered`.

### Errors

| Kind | When | What the user sees |
| --- | --- | --- |
| Not found | `404` for a program id | "This program could not be found." with a back button |
| Invalid data | Body is not JSON, wrong shape, a record is missing required fields, or the returned id does not match | Details: "This program's information is incomplete or invalid." In the list, broken records are skipped and a notice says how many ("The programs data is invalid." if the whole response is not a list) |
| Unavailable | Offline, timeout or server error | "Unable to load ... Please try again." with Retry |

### Working with the data layer

- To change the sample programs, edit `assets/data/programs.json`.
- To use a real backend, set `API_BASE_URL`. If its responses differ, only `ApiProgramRepository` needs to change.
- The program list, the selected program and registration state are held by `ProgramStore` (see State Management below), which sits on top of `ProgramRepository`. `ProgramDetailsLoader` still loads one program by id on its own.
- Registration goes through `ProgramStore.register`, so the list and the details screen show the same registered state.
- Tests: `test/program_repository_test.dart` (repository against mocked HTTP and the mock API), `test/programs_list_test.dart`, `test/program_details_loader_test.dart` and `test/program_routes_test.dart`. Use `MockApi(programLoader: ...)` to inject bad data. `test/flutter_test_config.dart` pre-reads the sample programs for every test file.

### Mock mode sign-in

Run with `--dart-define=USE_MOCK=true` and sign in with:

| Role | Email | Password |
| --- | --- | --- |
| Learner (completes the profile step first) | `learner@example.com` | `learner123` |
| Learner (profile completed) | `member@example.com` | `member123` |
| Admin | `admin@example.com` | `admin123` |

The signup invitation code in mock mode is `EXCEL2026`. The mock backend lives in memory, so registrations and sessions reset when the app restarts or the browser page is refreshed.

## State Management

The app uses Provider. Two classes in `lib/state/` hold the shared state so screens do not keep duplicate copies of it.

| File | Role |
| --- | --- |
| `lib/state/program_store.dart` | `ProgramStore`: the program list (idle / loading / loaded / error), the selected program and registration. A quiet refresh keeps the current list if it fails. A second register call for the same program is ignored while one is running |
| `lib/state/submission_controller.dart` | `SubmissionController`: form values, per-field validators and error messages, and the submit status |

Submit status flow: `idle -> validating -> submitting -> success`, or `idle -> validating -> error`. While a request is running, further submits are ignored. `reset()` returns the form to idle and clears the values (or keeps them with `reset(keepValues: true)`), so an error never stays stuck after a retry.

Using the controller in a form:

```dart
final form = SubmissionController(
  initialValues: {'email': ''},
  validators: {'email': (v) => v.isEmpty ? 'Enter your email' : null},
);

form.setValue('email', text);                 // on every change
final ok = await form.submit((values) async { // validates, then runs the action
  await api.send(values);
});
// Read form.status, form.isSubmitting, form.errorOf('email') and form.message in the UI.
```

Screens that read the state: `ProgramsListView` and `ProgramDetailsView` (Register). Forms being connected to `SubmissionController` under the state management task: the sign-up form (`lib/widgets/auth_form.dart`) and the Feedback form.

Tests: `test/program_store_test.dart` and `test/submission_controller_test.dart` cover the state transitions, repeated submits and reset behaviour.

## Design Documentation

Refer to the product and UX design rationale here:

- `docs/SPRINT2_DESIGN.md`

## Repository

- GitHub: https://github.com/Ruby160612/excelerate-engagement-app
