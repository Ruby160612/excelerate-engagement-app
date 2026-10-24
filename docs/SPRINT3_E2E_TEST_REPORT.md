# Sprint 3 End-to-End Test Report

## Environment

- Project: Excelerate Talent Hub (Flutter)
- Browser: Chrome
- Integration branch: `sprint2-integration`
- Merge commit: `5d20126`
- Test date: `2026-10-24`
- Test mode: record whether `USE_MOCK=true` or configured API mode was used before sign-off.

## Automated verification

| Check | Recorded result | Evidence |
|---|---|---|
| `flutter pub get` | PASS | Completed successfully; package resolution reported newer versions available but no dependency-resolution failure. |
| `flutter analyze` | PASS | `No issues found!` |
| `flutter test` | PASS | `00:09 +65: All tests passed!` |
| Browser launch | PASS | User confirmed application is running in Chrome. |

## Manual end-to-end matrix

Set each result to **PASS**, **FAIL**, **BLOCKED**, or **NOT RUN**. Include evidence or a short note. Automated tests passing does not automatically pass a manual-only case.

| ID | Scenario | Expected result | Result | Notes / evidence |
|---|---|---|---|---|
| E2E-01 | Start app in mock mode | App opens without an uncaught exception | NOT RUN | |
| E2E-02 | Load program list from JSON/mock service | Program list renders expected entries | NOT RUN | |
| E2E-03 | Open a listed program | Detail page matches selected program | NOT RUN | |
| E2E-04 | Open an unknown/missing program ID | Controlled not-found/error UI; no crash | NOT RUN | |
| E2E-05 | Open registration and submit empty form | Required-field messages appear | NOT RUN | |
| E2E-06 | Enter invalid email | Expected email validation message appears | NOT RUN | Expected text reported by tests: `Please enter your email` |
| E2E-07 | Submit valid registration | Implemented success/next state appears | NOT RUN | |
| E2E-08 | Submit feedback with required fields missing | Inline validation appears; invalid submission is blocked | NOT RUN | |
| E2E-09 | Submit valid feedback | Implemented success/submission state appears | NOT RUN | |
| E2E-10 | Observe delayed request | Loading indicator/state is visible | NOT RUN | |
| E2E-11 | Simulate unavailable API or malformed/missing data | Clear error state appears; app remains usable | NOT RUN | |
| E2E-12 | Retry after removing failure condition | Request retries and data loads successfully | NOT RUN | |
| E2E-13 | Navigate between listing, detail, dashboard, forms | Routes remain usable and selected data is consistent | NOT RUN | |
| E2E-14 | Inspect Chrome DevTools Console | No unexpected uncaught errors | NOT RUN | |
| E2E-15 | Restart app in mock mode | Expected mock-state reset behavior is understood | NOT RUN | |

## Defects

Record defects with steps to reproduce, expected result, actual result, severity, and issue/PR link.

| ID | Defect | Severity | Status | Reference |
|---|---|---|---|---|
| â€” | No new defect details supplied in this report template | â€” | Needs tester sign-off | â€” |

## Sign-off

- [ ] All manual scenarios have a final status.
- [ ] All critical/high defects are fixed or explicitly accepted.
- [ ] README and changelog are current.
- [ ] Demo video is recorded, reviewed, and linked/committed.
- [ ] Git branch and working tree have been checked.
- [ ] `flutter analyze` and `flutter test` were rerun after final code changes.

Tester: ____________________  
Date: ____________________  
Reviewer/team lead: ____________________
