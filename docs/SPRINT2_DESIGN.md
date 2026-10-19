# Sprint 2 Design & Development Decisions

## 1. Overview

Sprint 2 focused on turning the Excelerate Talent Hub concept into a usable, branded Flutter experience for both learners and admins. The app was designed to feel purposeful, modern, and trustworthy while supporting the real everyday needs of Excelerate users: exploring programmes, applying for opportunities, checking eligibility, and navigating a role-based dashboard.

Core objectives for Sprint 2:
- a single, consistent design language
- a responsive and mobile-first UI system
- structured onboarding and session-aware navigation
- role-based dashboards for learners and admins
- reusable program and opportunity content patterns
- a testable mock API setup for local development and validation

This work aligns with the app bootstrap in `lib/main.dart` where session state is restored and route-based navigation is configured.

---

## 2. Product Goals and User Needs

Sprint 2 aims to enable users to access information and take action with minimal friction.

Learner goals:
- Discover relevant programmes and learning opportunities
- Understand programme schedules, outcomes, and eligibility criteria
- Progress through onboarding and account setup
- View personalised learning and application recommendations
- Access a motivating, easy-to-navigate dashboard

Admin goals:
- Publish and manage opportunities
- Review applications and monitor recruitment activity
- Access centralised operational metrics
- Work within workflows that exclude irrelevant learner functionality

Shared goals:
- One clear visual identity across screens
- Consistent navigation and actions
- Simple role-aware UX
- Ability to run the app with either a mock or a real backend

---

## 3. Design System Decisions

### 3.1 Brand identity
- Primary accent: Excelerate Orange (#FF4500) for CTAs, active states, and focus rings.
- Neutral palette: dark slate and soft neutrals for text and surfaces.
- Tokens and centralized theme live in `lib/utils/themes.dart`.

### 3.2 Material 3 foundation
- App follows Material 3 principles for predictability and scalability.
- Centralized `ThemeData` applied at the root `MaterialApp`.
- Card-based surfaces, clear spacing, and readable typography.

### 3.3 Component and token usage
- Reusable components: ProgramCard, DashboardOverview, AnnouncementBanner, standard form controls.
- Spacing and typographic scale are consistent across screens.
- Minimum tap target: 48x48 dp for touchable elements.

---

## 4. Responsive UI Strategy

Breakpoints and behavior:
- Mobile: < 600 px — single-column, stacked content.
- Tablet: 600–1199 px — two-column layouts where helpful.
- Desktop: >= 1200 px — max-width content containers and multi-column dashboards.

Key patterns:
- Content width clamping to avoid overly wide text lines.
- Flexible grids for program lists.
- LayoutBuilder + MediaQuery to adapt component arrangements.

---

## 5. Screens and User Flows

Delivered screens:
- Login & signup (with invitation flow)
- Learner dashboard
- Admin dashboard
- Program listing (cards)
- Program details (rich content)
- Apply / register flow (scaffolded)

For each screen:
- Purpose: the main goal the user should accomplish there.
- Primary components: lists, CTAs, forms, and metrics.
- Entry → primary action → next step mapped in route definitions.

Protected routes:
- Guests redirected to login/signup.
- AuthService and StorageService control access.

---

## 6. Program Listing & Details Content Structure

Canonical fields required to power listing + details:
- id (string)
- title (string)
- short_description (string)
- overview (string / long)
- schedule (array of strings or objects)
- eligibility (array of strings)
- outcomes (array of strings)
- start_date (ISO date string)
- application_deadline (ISO date string)
- tags (array of strings)
- contact (object: email, phone, location)
- optionally: format, duration_weeks, location, application_url

Example JSON record:
{
  "id": "prog-001",
  "title": "Digital Skills Bootcamp",
  "short_description": "A 6-week hands-on bootcamp teaching practical digital skills.",
  "overview": "A six-week intensive program designed to equip participants with practical digital skills...",
  "schedule": [
    "Week 1: Digital literacy",
    "Week 2: Spreadsheets",
    "... "
  ],
  "eligibility": ["Aged 18+", "Basic English literacy"],
  "outcomes": ["Certificate", "1:1 CV support"],
  "start_date": "2026-11-01",
  "application_deadline": "2026-10-25",
  "tags": ["digital","skills"],
  "contact": {"email":"programs@excellerate.org","phone":"+44 20 1234 5678"}
}

Storage recommendations:
- lib/data/programs.json (or assets/data/programs.json) as source-of-truth for mock mode.
- services/mock_api.dart should return these JSON records for GET /programs and GET /programs/:id.

---

## 7. Architecture & Implementation Notes

Bootstrapping:
- `lib/main.dart` sets up providers and restores session state on startup.

Key services:
- StorageService: wraps SharedPreferences for persistence.
- ApiService: central HTTP interface with timeout and session token support.
- AuthService: manages authentication, role-aware state, and restoreSession.

Configuration:
- USE_MOCK toggles mock mode: bool.fromEnvironment('USE_MOCK')
- API_BASE_URL provides a backend base URL: String.fromEnvironment('API_BASE_URL')

Models:
- Program model should include fromJson/toJson helpers for mapping.

State management:
- Provider for DI, ChangeNotifier-based services for mutable state.

---

## 8. Mock API & Test Strategy

Mock API purpose:
- Allow deterministic UI development and automated tests without a live backend.

Behavior:
- MockApi exposes login, signup, programs, announcements endpoints.
- Use MockApi.baseUrl and inject MockApi.client into ApiService for tests.

Testing approach:
- Widget tests use SharedPreferences.setMockInitialValues and MockApi(latency: Duration.zero).
- Tests validate route protection, program listing, and program details UI.
- Add unit tests for ApiService error handling and response mapping.

---

## 9. Accessibility & UX Standards

Accessibility priorities:
- Maintain sufficient color contrast for text and states.
- Minimum 48x48 dp tap targets.
- Semantic labels on interactive widgets (for screen readers).
- Clear validation/error messaging on forms.

UX clarity:
- Show clear dates, required fields, and next steps on program details.
- Use progressive disclosure for long content (expandable sections for schedule/eligibility).
- Use consistent CTAs (Apply/Register) and confirm submission states.

---

## 10. Quality & Success Criteria

Sprint 2 acceptance checks:
- Theme and branding applied consistently across major screens.
- Learner and admin roles see distinct dashboards after sign-in.
- Guest users are redirected from protected routes to login.
- Program listing shows at least title, short_description, and CTA.
- Program details render overview, schedule, eligibility, outcomes, and contact.
- All widget tests that rely on MockApi run deterministically and pass.

---

## 11. Next Steps & Recommendations

Suggested immediate next work:
1. Add a curated `lib/data/programs.json` with full content for each programme.
2. Wire `services/mock_api.dart` to read programs.json so UI uses real content in mock mode.
3. Enhance ProgramDetailsView with clear sections, contact CTA, and an “Apply” flow.
4. Add application submission UI and API contract validation.
5. Standardise backend API contract (fields, status codes) to simplify integration.
6. Add a CI workflow to run `flutter test` and optionally a build step for web.

---

## 12. Related Files & References

Primary implementation files:
- `lib/main.dart`
- `lib/utils/constants.dart`
- `lib/utils/themes.dart`
- `services/mock_api.dart`
- `lib/views/shared/program_details.dart` (view to render the structure above)
- `test/widget_test.dart`, `test/*` for route and UI tests

---

## Summary

Sprint 2 delivered a coherent expression of the Excelerate Talent Hub: a branded, responsive, role-aware Flutter app with a central design system, program discovery and detail flows, and a mock-first development strategy that supports deterministic testing and safe demos. The document above is a working source of truth for product, design, and engineering decisions made in Sprint 2.

If you want, I can:
- Commit this file to docs/SPRINT2_DESIGN.md on a new branch,
- Produce the `lib/data/programs.json` example next,
- Or update `services/mock_api.dart` to serve the new content.

Tell me which edit or follow-up you want and I’ll do it next.
