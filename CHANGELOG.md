# Changelog

Notable project changes are documented here. This file covers the Sprint 3 integration handoff; it is not intended to replace the detailed Git history.

## Sprint 3 — Form validation and feedback integration

### Added
- Shared validation helpers in `lib/utils/validators.dart`.
- Learner feedback form in `lib/views/learner/feedback.dart`.
- Submission state handling in `lib/state/submission_controller.dart`.

### Changed
- Connected feedback/dashboard flow to the relevant application routes and state.
- Updated authentication form validation behavior in `lib/widgets/auth_form.dart`.
- Updated widget-test expectation to match the registration email validation message: `Please enter your email`.
- Replaced deprecated Flutter APIs in the feedback form:
  - `DropdownButtonFormField.value` with `initialValue`.
  - `Color.withOpacity(...)` with `Color.withValues(alpha: ...)`.

### Verification recorded
- `flutter pub get` completed successfully.
- `flutter analyze` reported `No issues found!`.
- `flutter test` passed all 65 tests.
- Sprint 3 changes were merged into `sprint2-integration` in merge commit `5d20126`.

### Handoff follow-ups
- Complete and sign off the manual end-to-end matrix in `docs/SPRINT3_E2E_TEST_REPORT.md`.
- Record and review the Sprint 3 demo video.
- Re-run analysis and tests after documentation changes and before submission.
