# Excelerate Talent Hub â€” Design System & Branding Guide

**Sprint 2 Deliverable: Global Branding, Responsive UI, Shared Components & Seamless Navigation**

---

## 1. Executive Summary & Design Principles

The **Excelerate Talent Hub** design system establishes a cohesive, accessible, and responsive user experience across both **Learner** and **Admin** portals.

Built strictly on **Material 3**, this system preserves Excelerate's signature vibrant orange brand while introducing structured neutrals, clear semantic feedback colors, a crisp typography scale, reusable UI components, and mobile-first responsive breakpoints.

### Core Principles
1. **Preserve Established Identity**: Excelerate Orange (`#FF4500`) serves as the unambiguous primary brand anchor across buttons, active states, accents, and branding elements.
2. **One Centralized Theme**: A single, comprehensive `ThemeData` configuration in [`lib/utils/themes.dart`](file:///d:/project/excelerate-engagement-app-main/lib/utils/themes.dart) powers the entire application via the root `MaterialApp` in [`lib/main.dart`](file:///d:/project/excelerate-engagement-app-main/lib/main.dart). No secondary `MaterialApp` or conflicting theme systems are permitted.
3. **Responsive by Design**: Every layout adapts seamlessly from compact mobile screens (< 600px) to tablets (600â€“1199px) and large desktop monitors (â‰¥ 1200px) through content width clamping, flexible grids, and overflow-resilient containers.
4. **Shared Visual Hierarchy**: Both Learner and Admin journeys share identical typography, button geometry, card borders, and status indicators while cleanly separating role-specific business logic.

---

## 2. Color Palette & Design Tokens

All colors are exposed through the `AppColors` namespace in [`lib/utils/themes.dart`](file:///d:/project/excelerate-engagement-app-main/lib/utils/themes.dart).

```dart
import 'package:excelerate_engagement_app/utils/themes.dart';

// Example: Using tokens in custom widgets
Container(
  color: AppColors.primaryLight,
  child: Text('Active', style: TextStyle(color: AppColors.primaryDark)),
);
```

### 2.1 Primary Brand Palette (Excelerate Orange)
* **`AppColors.primary` (`#FF4500`)**: The signature Excelerate Orange. Used for primary call-to-action buttons, active navigation states, interactive icons, and focus rings.
* **`AppColors.primaryDark` (`#C73600`)**: A deeper, high-contrast orange used for active text, dark button press states, and contrast-compliant accents.
* **`AppColors.primaryLight` (`#FFF0E8`)**: A soft orange tint used for icon container backgrounds, active list selections, and highlight chips.
* **`AppColors.primaryLighter` (`#FFF8F2`)**: An ultra-soft tint for subtle page accents or card backgrounds.
* **`AppColors.primaryBorder` (`#FFD9C7`)**: Delicate border color for orange-tinted containers and badges.

### 2.2 Secondary & Neutral Palette (Slate & Grays)
* **`AppColors.secondary` (`#1E293B`)**: Dark Slate for secondary actions, dark headers, and high-emphasis contrasting elements.
* **`AppColors.secondaryLight` (`#F1F5F9`)**: Light slate background for secondary containers and hover states.
* **`AppColors.secondaryDark` (`#0F172A`)**: Deep navy-slate for highest contrast dark surfaces.
* **`AppColors.background` (`#F6F7FB`)**: Soft cool off-white scaffold background, reducing eye strain and making white cards stand out.
* **`AppColors.surface` (`#FFFFFF`)**: Pure white for cards, dialogs, drawers, and modal surfaces.
* **`AppColors.surfaceVariant` (`#F8FAFC`)**: Alternative soft surface for secondary panels and nested card sections.
* **`AppColors.border` (`#E2E5ED`)**: Subtle 1px neutral border for cards, inputs, and dividers.
* **`AppColors.borderLight` (`#F2F4F7`)**: Light border for subtle sub-elements.
* **`AppColors.borderFocus` (`#FF4500`)**: Active 2px input focus border.

### 2.3 Typography Colors
* **`AppColors.textPrimary` (`#1D2433`)**: High-contrast near-black for primary headings, card titles, and body copy.
* **`AppColors.textSecondary` (`#525D70`)**: Medium slate-gray for subtitles, secondary descriptions, and metadata.
* **`AppColors.textMuted` (`#667085`)**: Muted gray for timestamps, breadcrumbs, helper notes, and captions.
* **`AppColors.textHint` (`#98A2B3`)**: Placeholder and disabled text.

### 2.4 Semantic Status & Feedback Palette
| Status | Main Color | Background Tint | Border Color | Typical Usage |
| :--- | :--- | :--- | :--- | :--- |
| **Success** | `AppColors.success` (`#12B76A`) | `AppColors.successLight` (`#ECFDF3`) | `AppColors.successBorder` (`#A6F4C5`) | Approved applications, shortlisted candidates, completed assessments |
| **Warning** | `AppColors.warning` (`#F79009`) | `AppColors.warningLight` (`#FEF0C7`) | `AppColors.warningBorder` (`#FEDF89`) | In-progress reviews, pending actions, deadlines |
| **Error** | `AppColors.error` (`#D92D20`) | `AppColors.errorLight` (`#FEF3F2`) | `AppColors.errorBorder` (`#FECDCA`) | Form validation errors, rejected applications, network failures |
| **Info** | `AppColors.info` (`#0BA5EC`) | `AppColors.infoLight` (`#F0F9FF`) | `AppColors.infoBorder` (`#B9E6FE`) | Scheduled interviews, announcement tags, general notices |

---

## 3. Typography & Text Hierarchy

Typography is mapped to standard Material 3 `TextTheme` slots to ensure out-of-the-box compatibility with native widgets and explicit `Theme.of(context).textTheme` consumption.

| Text Style Slot | Font Size | Weight | Letter Spacing | Color | Primary Usage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`headlineLarge`** | 30px | Bold (700) | -0.5px | `AppColors.textPrimary` | Top-level dashboard greetings, landing headers |
| **`headlineMedium`**| 24px | Bold (700) | -0.25px| `AppColors.textPrimary` | Program title in details view, modal headers |
| **`headlineSmall`** | 20px | Bold (700) | Normal | `AppColors.textPrimary` | Major section headers, card group titles |
| **`titleLarge`**    | 18px | Bold (700) | Normal | `AppColors.textPrimary` | AppBar titles, dialog headings, card titles |
| **`titleMedium`**   | 16px | Semi-bold (600)| Normal| `AppColors.textPrimary` | List item titles, section labels, form section headers |
| **`titleSmall`**    | 14px | Semi-bold (600)| Normal| `AppColors.textPrimary` | Sub-card headers, table columns |
| **`bodyLarge`**     | 16px | Regular (400)| Normal (1.5 h)| `AppColors.textPrimary`| Long-form program descriptions, announcement bodies |
| **`bodyMedium`**    | 14px | Regular (400)| Normal (1.4 h)| `AppColors.textSecondary`| Standard card body copy, input text |
| **`bodySmall`**     | 12px | Regular (400)| Normal | `AppColors.textMuted` | Timestamps, metadata footnotes |
| **`labelLarge`**    | 14px | Semi-bold (600)| Normal | `AppColors.textPrimary` | Button labels, interactive tab text |
| **`labelMedium`**   | 12px | Medium (500) | Normal | `AppColors.textMuted` | Chip text, badge labels, form field captions |

---

## 4. Spacing System & Layout Helpers

The `AppSpacing` class provides standard 8-point grid sizing tokens and pre-instantiated `SizedBox` widgets:

```dart
// Pre-built vertical and horizontal spacers
AppSpacing.verticalSm;   // SizedBox(height: 8)
AppSpacing.verticalMd;   // SizedBox(height: 16)
AppSpacing.verticalLg;   // SizedBox(height: 24)
AppSpacing.verticalXl;   // SizedBox(height: 32)
AppSpacing.verticalXxl;  // SizedBox(height: 48)

AppSpacing.horizontalSm; // SizedBox(width: 8)
AppSpacing.horizontalMd; // SizedBox(width: 16)
AppSpacing.horizontalLg; // SizedBox(width: 24)
```

| Spacing Token | Pixels | Common Application |
| :--- | :--- | :--- |
| **`xs`** | 4px | Micro-spacing between icon and small label, badge inner padding |
| **`sm`** | 8px | Gap between related form elements, chip padding, badge gaps |
| **`md`** | 16px | Standard card padding, standard gap between distinct fields |
| **`lg`** | 24px | Page padding, major section gaps, dialog inner margins |
| **`xl`** | 32px | Separation between distinct page sections or card groups |
| **`xxl`**| 48px | Top-level hero margins, auth screen vertical offsets |

---

## 5. Responsive Breakpoints & Adaptive Layouts

Defined in `AppBreakpoints` ([`lib/utils/themes.dart`](file:///d:/project/excelerate-engagement-app-main/lib/utils/themes.dart)):

| Breakpoint | Width (px) | Device Target | Layout Strategy |
| :--- | :--- | :--- | :--- |
| **Mobile** | `< 600px` | Phones (portrait/landscape) | Single-column linear flow, full-width buttons, collapsible menus, drawer navigation. |
| **Tablet** | `600px â€“ 1199px` | Tablets, foldables, small laptops | Two-column cards, constrained forms (max 680px), multi-tile dashboard grids. |
| **Desktop**| `â‰¥ 1200px` | Laptops, external widescreen monitors | Centered container clamping (max 900â€“1040px) to prevent over-stretched reading lines. |

### Responsive Implementation Rules:
1. **Width Constraints (`ConstrainedBox`)**:
   - Authentication forms: Clamped to `maxWidth: 520px` and centered on desktop.
   - Profile & data entry forms: Clamped to `maxWidth: 680px` via [`ApiForm`](file:///d:/project/excelerate-engagement-app-main/lib/widgets/api_form.dart) and [`ProfileCreationView`](file:///d:/project/excelerate-engagement-app-main/lib/views/auth/profile_creation.dart).
   - Standard content pages: Clamped to `maxWidth: 900px` via [`PageLayout`](file:///d:/project/excelerate-engagement-app-main/lib/widgets/page_layout.dart).
   - Multi-column catalogs (e.g. Programs): Clamped to `maxWidth: 1040px` with a 2-column responsive wrap on widths â‰¥ 700px.
2. **Horizontal Overflow Prevention**:
   - Navigation links, tags, and footer rows use `Wrap` with `WrapAlignment.center` rather than rigid `Row` widgets so items wrap cleanly on small screens (down to 320px) or enlarged accessibility font sizes.
   - Any text sitting beside an icon or badge inside a `Row` is wrapped in `Expanded` to prevent flex overflow.
3. **Vertical Scroll Safety**:
   - All page layouts wrap their body inside a `SingleChildScrollView` to prevent keyboard or small-screen vertical overflow errors.

---

## 6. Material 3 Component Specifications

All standard Material widgets are pre-styled in `AppThemes.light`:

### 6.1 Buttons
* **Height**: 48px standard touch target height (`minimumSize: Size(0, 48)`).
* **Corner Radius**: 8px rounded rectangle border (`BorderRadius.circular(8)`).
* **Typography**: 15px Semi-bold (600).
* **Filled / Elevated Button**: Background `AppColors.primary` (`#FF4500`), foreground `Colors.white`, elevation 0.
* **Outlined Button**: Foreground `AppColors.primary`, 1px border `AppColors.border`, elevation 0.
* **Text Button**: Foreground `AppColors.primary`, 14px Semi-bold.

### 6.2 Input Fields & Form Controls
* **Fill Color**: `#FFFFFF` with `filled: true`.
* **Corner Radius**: 8px (`BorderRadius.circular(8)`).
* **Padding**: Horizontal 16px, vertical 14px.
* **Default Border**: 1px solid `AppColors.border` (`#E2E5ED`).
* **Focused Border**: 2px solid `AppColors.primary` (`#FF4500`).
* **Error Border**: 1px / 2px solid `AppColors.error` (`#D92D20`).
* **Hint Style**: 14px `AppColors.textHint`.

### 6.3 Cards & Containers
* **Background**: Pure white (`#FFFFFF`).
* **Elevation**: 0 (clean flat design with crisp borders).
* **Border Radius**: 12px (`BorderRadius.circular(12)`).
* **Border**: 1px solid `AppColors.border` (`#E2E5ED`).
* **Clip Behavior**: `Clip.antiAlias` to prevent nested contents from bleeding over corners.

### 6.4 AppBars & Navigation
* **AppBar**: Pure white background, zero elevation, subtle `scrolledUnderElevation: 1`, title style `AppColors.textPrimary` 18px Bold.
* **Dialogs**: 16px corner radius, white background, elevation 4, clean header typography.

---

## 7. Shared Reusable UI Components

Located under [`lib/widgets/`](file:///d:/project/excelerate-engagement-app-main/lib/widgets/):

### 7.1 `AppButton` ([`lib/widgets/app_button.dart`](file:///d:/project/excelerate-engagement-app-main/lib/widgets/app_button.dart))
Standardized button component supporting four variants and an integrated loading state:
* **Variants**: `AppButtonVariant.primary`, `AppButtonVariant.secondary`, `AppButtonVariant.outlined`, `AppButtonVariant.text`.
* **Loading State**: Automatically displays an indicator spinner with matched contrast while disabling clicks.
* **Icon Support**: Optional `icon: IconData` rendered with standard 8px spacing.
* **Full Width**: `isFullWidth: true` expands the button across the parent container width.

```dart
AppButton(
  text: 'Register for Program',
  icon: Icons.check_circle_outline,
  variant: AppButtonVariant.primary,
  isFullWidth: true,
  isLoading: isSubmitting,
  onPressed: () => handleRegister(),
)
```

### 7.2 `AppCard` ([`lib/widgets/app_card.dart`](file:///d:/project/excelerate-engagement-app-main/lib/widgets/app_card.dart))
The core content card used across both Learner and Admin dashboards:
* Clean 12px border radius with `AppColors.border`.
* Branded icon avatar box with soft orange background (`AppColors.primaryLight`) and vibrant orange icon (`AppColors.primary`).
* Supports `title`, `subtitle`, arbitrary `child`, `trailing` widget, and `statusBadge`.
* Optional `onTap` for interactive cards.

### 7.3 `StatusBadge` ([`lib/widgets/status_badge.dart`](file:///d:/project/excelerate-engagement-app-main/lib/widgets/status_badge.dart))
A semantic pill badge for application statuses, verification states, and candidate scores:
* Pre-configured factories:
  - `StatusBadge.success(text: 'Enrolled')` / `('Shortlisted')`
  - `StatusBadge.warning(text: 'Under Review')` / `('Pending')`
  - `StatusBadge.error(text: 'Rejected')` / `('Deadline Passed')`
  - `StatusBadge.info(text: 'Interview Scheduled')`
  - `StatusBadge.primary(text: 'Active')`
  - `StatusBadge.neutral(text: 'Draft')`

### 7.4 `EmptyStateWidget` ([`lib/widgets/empty_state.dart`](file:///d:/project/excelerate-engagement-app-main/lib/widgets/empty_state.dart))
Displayed whenever collections, lists, or filter results are empty:
* Centered icon within a circular neutral background.
* Clear title and explanatory body text.
* Optional call-to-action button (e.g. "Browse Programs" or "Post an Opportunity").

### 7.5 `SectionContainer` ([`lib/widgets/section_container.dart`](file:///d:/project/excelerate-engagement-app-main/lib/widgets/section_container.dart))
Section wrapper for organizing dashboard groups:
* Displays a bold section title, optional subtitle, and right-aligned action widget (e.g., "View All").
* Automatically handles card wrapping when `wrapInCard: true`.

### 7.6 `PageLayout` ([`lib/widgets/page_layout.dart`](file:///d:/project/excelerate-engagement-app-main/lib/widgets/page_layout.dart))
Root scaffolding for all views:
* Automatically includes an `AppBar` with the view title, optional custom title, and drawer.
* Displays a sign-out icon button whenever a user session is active.
* Top-centers content within a `ConstrainedBox(maxWidth: maxWidth)` (defaults to 900px).
* Embeds a `SingleChildScrollView` with 24px padding.

---

## 8. Admin vs. Learner Screen Consistency

Both user journeys share a single visual design language while addressing distinct user goals:

| Feature / Pattern | Learner Journey | Admin Journey |
| :--- | :--- | :--- |
| **Primary Goal** | Self-service discovery, learning, and skill advancement. | Management, shortlisting, candidate review, and scheduling. |
| **Color Application** | Excelerate Orange accents, success badges for achievements, info badges for active sessions. | Identical orange accents, status badges for candidate evaluation states. |
| **Dashboard Layout** | Announcements banner, quick progress stats, navigation tiles (Programs, Badges, Applications, CV Upload). | Announcements banner, quick management tiles (Post Opportunity, Shortlisting, Review, Scheduler). |
| **Program Experience** | Responsive catalog grid with 1-click details view and real-time registration action. | Previews same details screen with an Admin Preview banner and back navigation. |
| **Form Layout** | Clean card-wrapped inputs for profile creation and CV upload drop-zones. | Clean card-wrapped inputs for posting opportunities and scheduling interviews. |
| **Listings & Reviews**| Applications & Assessments with clear `StatusBadge` pills. | Application Review & Candidate Shortlisting with candidate initials, status pills, and score tags. |

---

## 9. Verified Navigation Flow

The complete end-to-end user navigation flow is verified and working:

```
[Login Screen] (AppRoutes.login)
       â”‚
       â–¼ (Authenticate as Learner or Admin)
[Home / Dashboard] (AppRoutes.dashboard or AppRoutes.adminDashboard)
       â”‚
       â–¼ (Tap "Programs" tile or drawer option)
[Programs Catalog] (AppRoutes.programs)
       â”‚
       â–¼ (Tap any Program card â€” passes Program object)
[Program Details Screen] (AppRoutes.programDetails)
       â”‚
       â–¼ (Learner taps "Register for Program")
[Real-Time Registration via ApiService]
       â”‚
       â–¼ (Tap AppBar back arrow)
[Returns to Programs Catalog]
```

* Program details are dynamically populated from the selected [`Program`](file:///d:/project/excelerate-engagement-app-main/lib/models/program.dart) model (title, category, date range, schedule, outcomes, and eligibility).
* Learner registration calls `POST /programs/:id/register` via the authenticated `ApiService` and displays real-time feedback with instant "Enrolled" badge updates.
* Route guards ([`AuthGuard`](file:///d:/project/excelerate-engagement-app-main/lib/utils/app_router.dart)) protect role-restricted pages and cleanly redirect unauthorized users.
