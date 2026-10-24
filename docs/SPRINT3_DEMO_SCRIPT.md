# Sprint 3 Demo Video â€” Recording Script

**Target length:** 2â€“4 minutes  
**Target:** Chrome running the app in the configured test mode  
**Suggested filename:** `sprint3-demo.mp4`

## Before recording

1. Start from a clean app launch.
2. Use mock mode unless the team has approved and configured a test API.
3. Close unrelated tabs and hide personal notifications.
4. Keep the browser zoom and window size consistent.
5. Prepare one known valid program and test registration/feedback data.
6. If demonstrating retry, prepare a repeatable failure/recovery method. Do not fake a successful retry.

## Shot list

1. **Opening (5â€“10 seconds):** Show the app name and learner landing/dashboard.
2. **Program listing (15â€“25 seconds):** Show the populated list and briefly scroll/search if supported.
3. **Program details (15â€“25 seconds):** Open a program and show its details correspond to the selected item.
4. **Registration validation (20â€“30 seconds):** Submit empty values, then enter an invalid email and show the exact validation message.
5. **Valid registration (15â€“25 seconds):** Submit valid test values and show the implemented success/next state.
6. **Feedback validation and submission (25â€“35 seconds):** Show invalid submission blocked, then submit valid feedback and show the result.
7. **Error recovery (20â€“30 seconds):** Show a missing program ID or controlled request failure. If reproducible, correct the condition and use Retry to recover.
8. **Closing (5â€“10 seconds):** Return to the dashboard and end the recording.

## Review before handoff

- [ ] Video plays from beginning to end.
- [ ] Text and validation messages are readable.
- [ ] No personal data, secrets, tokens, or private notifications are visible.
- [ ] The error/retry flow is genuine and reproducible.
- [ ] The demo matches the current branch/build.
- [ ] Video file or approved share link is included in the README/handoff.

If no repeatable API failure mechanism exists, demonstrate the controlled missing-ID error and document retry as blocked/not applicable rather than pretending it was tested.
