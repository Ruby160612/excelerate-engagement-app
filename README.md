\# Excelerate Talent Hub



A Flutter-based engagement platform designed to support learners through program discovery, registration, feedback, and dashboard navigation.



\## Features



\* User authentication forms with validation.

\* Learner dashboard.

\* Program listing and program details.

\* Registration form with input validation.

\* Learner feedback form.

\* Submission state management.

\* Error handling and user feedback.



\## Technology Stack



\* \*\*Frontend:\*\* Flutter and Dart

\* \*\*State management:\*\* Application state controllers

\* \*\*Data:\*\* Mock/JSON data or configured API services

\* \*\*Testing:\*\* Flutter test framework

\* \*\*Platforms:\*\* Web, Android, iOS, Windows, Linux, and macOS, subject to platform configuration.



\## Prerequisites



Install Flutter and configure your development environment.



Verify the installation:



```bash

flutter --version

flutter doctor

```



\## Installation



Clone the repository:



```bash

git clone https://github.com/Ruby160612/excelerate-engagement-app.git

cd excelerate-engagement-app

```



Switch to the integration branch:



```bash

git switch sprint2-integration

git pull origin sprint2-integration

```



Install dependencies:



```bash

flutter pub get

```



\## Run the Application



To run the application in Chrome:



```bash

flutter run -d chrome

```



If the project uses a mock/API configuration, use the environment flags supported by the current implementation. Confirm those flags in the source code before using them.



\## Testing



Run static analysis:



```bash

flutter analyze

```



Run the automated tests:



```bash

flutter test

```



\### Latest recorded verification



\* Dependency installation: successful.

\* Static analysis: no issues found.

\* Automated tests: 65 passed.

\* Browser launch: successful in Chrome.



Run these checks again after making further code changes.



\## Architecture Overview



The application is organized into feature-oriented folders:



\* `lib/state/` â€” state controllers and submission state management.

\* `lib/utils/` â€” application utilities, routing, constants, and validation helpers.

\* `lib/views/` â€” application screens, including learner-facing screens.

\* `lib/widgets/` â€” reusable interface components.

\* `test/` â€” automated Flutter tests.



Refer to the source code for the exact service, data-loading, and state-management implementations.



\## Sprint 3 Scope



Sprint 3 includes:



\* Learner feedback form integration.

\* Shared validation helpers.

\* Submission state management.

\* Dashboard and routing integration.

\* Updated widget validation tests.

\* Flutter API deprecation fixes.



See \[CHANGELOG.md](CHANGELOG.md) for the Sprint 3 change summary.



\## End-to-End Testing



The manual testing checklist is available in \[docs/SPRINT3\_E2E\_TEST\_REPORT.md](docs/SPRINT3\_E2E\_TEST\_REPORT.md).



The checklist covers program loading, program details, registration, feedback submission, validation, loading states, error handling, retry behavior, and browser-console errors.



Only mark a scenario as passed after verifying its actual behavior.



\## Demo Video



The Sprint 3 demonstration should cover:



1\. Program listing and details.

2\. Registration validation and submission.

3\. Feedback validation and submission.

4\. Error handling and recovery.

5\. Dashboard navigation.



See \[docs/SPRINT3\_DEMO\_SCRIPT.md](docs/SPRINT3\_DEMO\_SCRIPT.md) for the recording guide.



Add the recorded video or the approved team-sharing link before final submission.



\## Sprint 3 Integration



\* Integration branch: `sprint2-integration`

\* Sprint 3 branch: `sprint3/integration-state-management`

\* Merge commit: `5d20126`



\## Contribution and Handoff



Before submitting changes:



```bash

git status

git diff --check

flutter analyze

flutter test

```



Review the changed files and commit only the intended project changes.
