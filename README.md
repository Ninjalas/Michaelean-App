# Michaelean

A campus-life app for students and teachers of **Saint Michael's College of Laguna (SMCL)**: class schedules, attendance, events, organizations, clearance, notifications, and a social profile, all in one app.

Built with **Flutter/Dart**. The goal is a free-hosted, installable **PWA** (Progressive Web App) that students and teachers add to the home screen on Android and iPhone.

> **Status (2026-10-21): frontend prototype.** Everything runs on clearly labeled **sample data**. There is no backend, no database, and no real Microsoft 365 sign-in yet. The app is being **rebuilt screen by screen** to a revised design (see [Rebuild plan and progress](#rebuild-plan-and-progress)). **Phases 1–3 of 11 are done.**

---

## Contents

1. [Getting started](#getting-started)
2. [What the app does today](#what-the-app-does-today)
3. [The overall plan of the app](#the-overall-plan-of-the-app)
4. [Rebuild plan and progress](#rebuild-plan-and-progress)
5. [Recent changes](#recent-changes)
6. [Project structure](#project-structure)
7. [Design system](#design-system)
8. [Rules everyone must follow](#rules-everyone-must-follow)
9. [Testing](#testing)
10. [Open decisions](#open-decisions)
11. [Known issues and things to know](#known-issues-and-things-to-know)
12. [How to continue the work](#how-to-continue-the-work)

---

## Getting started

### What you need

- **Flutter 3.47.7 (stable channel)**, which includes Dart. Check with `flutter --version`.
- **Google Chrome**, to run the app in the browser.
- **VS Code** with the Flutter and Dart extensions (recommended; any editor works).
- Windows is what the project was built on, but macOS and Linux work too.

### First run

Open a terminal **in the project folder** (the one containing `pubspec.yaml`) and run:

```bash
flutter pub get
```

```bash
flutter run -d chrome
```

The app opens in Chrome. Use the browser's phone view (DevTools → device toolbar, e.g. 375 × 812) to see it at phone size; the app is designed for phones.

### Everyday commands (run in the project folder)

| What | Command |
|---|---|
| Run in Chrome | `flutter run -d chrome` |
| Check for errors and warnings | `flutter analyze` |
| Run all tests | `flutter test` |
| Build the web version | `flutter build web` (output in `build/web`) |

Before every commit, `flutter analyze` should say **No issues found!** and `flutter test` should say **All tests passed!**

---

## What the app does today

The flow when you open the app:

1. **Opening intro.** The SMCL emblem fades and scales in, then "Michaelean" and the school name rise in. After about 2.4 seconds it moves on by itself; **Skip** (top right) jumps ahead. It plays on **every** app open, including browser reloads. With "reduce motion" turned on, it shows the finished logo without movement.
2. **Sign-in preview.** Pick **Student** or **Teacher** in the pill switch, then press **Sign in with Microsoft (preview)**. This is **not** a real sign-in: it loads a mock student (Nicolas) or mock teacher (Mark). The screen says so in plain words.
3. **The app**, with a floating bottom bar of three tabs:
   - Students: **Home | Student Life | Profile**
   - Teachers: **Home | Michaelean Life | Profile**
4. **Quick QR.** Long-press the middle tab (Student Life / Michaelean Life) to open your QR sheet. The first time, a tip above the nav bar says so.

What's behind each tab right now:

| Screen | State |
|---|---|
| Opening intro, Sign-in preview | **New design (rebuilt).** |
| Home (both roles), notifications sheet, QR sheet | **New design (rebuilt).** Stats row, navy Up next card, pending tasks, today's classes (teachers), announcements, School News, campus feed. Stats and Start attendance open "Coming soon" pages until their phases are built. |
| Student Life / Michaelean Life | Old design: a list of features that open "Coming soon" pages. To be rebuilt in Phase 4. |
| Profile + Settings sheet | Old design: photo that flips to a QR "coin", tags, masked ID, event history, settings sheet with Log Out. To be rebuilt in Phase 5. |
| Class, Events, Organizations, Clearance | **Not built yet** ("Coming soon" placeholders). Phases 6–9. |

---

## The overall plan of the app

The full product spec is **[`docs/spec.md`](docs/spec.md)**. **Read the spec section for a feature before you build it.** Below is a summary so you know the whole picture.

### One app, two roles

Michaelean is **one app** with a **student** experience and a **teacher** experience that share the same design and components. Screens are shared and adapt their content to the role; never build separate copies of a screen for students and teachers.

### Start flow (spec §1.1)

Opening intro/video (with Skip) → Sign-in preview screen → Home.

In production, sign-in will go through the school's **Microsoft 365** accounts: sign in, verify the account belongs to SMCL, match it to an official student/faculty record, load the verified info, assign tags and permissions, then open Home (spec §4). **Not part of the prototype.**

### Navigation (spec §1.2, §1.3)

- Floating pill bottom bar with three tabs. Tabs keep their state when you switch.
- **Quick QR:** long-pressing the middle tab (Student Life / Michaelean Life) opens the user's QR sheet. A one-time hint teaches this. The QR holds a **random mock token** (e.g. `MOCK-7F3K9Q`), never personal data, and showing it never verifies anything.

### Identity tags (spec §5)

Everyone gets labels like `[Saint Michael's College of Laguna] [SBMIT] [Department of Computer Studies] [Dance Company] [Dance Company Officer]`. Schools: **SON, SBMIT, SEAS**. Tags are **labels only; they never grant permissions.** Users can't give themselves tags.

### Student features

- **Home (§6):** what's next for me today, then what's happening on campus. Header with greeting and date; a row of 4 stats (class attendance %, event attendance %, events completed, requirements `3/6 cleared`); a navy **Up next** class card; pending tasks; announcements; School News (one big story + smaller rows); a campus feed (urgent org posts pinned with `URGENT`). The bell opens notifications grouped **Today / Earlier**.
- **Student Life hub (§7):** live previews of Class, Events, Organizations, Clearance, each with `See all ›`.
- **Class (§7.1–7.2):** `Show QR`, a Mon–Sat day strip with that day's classes, and attendance (overall %, per subject, recent sessions). Attendance only counts when an authorized teacher scans and finalizes the session.
- **Events (§7.3):** **Discover | My events**; filter pills (All / School-wide / Department / My Orgs); events grouped by date. Luma-style **event detail** (cover photo, Register/Share/More, Venue with map, Host, Attendees, About). Registration ≠ attendance.
- **Organizations (§7.4):** directory (departmental society, school-wide clubs, my organizations) and an organization page with tabs About, Schedule, Events, News, Officers.
- **Clearance (§7.5):** seasonal clearance with progress (`3 / 6 cleared`), one row per office with a status pill, detail and resubmit path, past clearances. Outside a clearance period: "Clearance Unavailable". Statuses: Not started, Action required, In review, Needs correction, Cleared, On hold, Not applicable.

### Teacher features

- **Home (§8):** same layout as students: stats (classes today, sessions awaiting finalization, upcoming events), navy **Up next** with **Start attendance**, pending tasks, today's classes, announcements and news.
- **Michaelean Life hub (§9):** live previews of Classes (with Start attendance), Events you manage, Clearance (assigned office + pending count).
- **Class management (§9.1):** roster, schedule/room editing, and the **attendance scan flow**: full-screen mock camera → counter `Present 18 · Unchecked 7` → each scan flashes the student → Finish → review unchecked students → confirm finalization. Always labeled as mock.
- **Events management (§9.2):** Upcoming, Past, Drafts, Create/Edit (Luma form style), Invite students, View registrations, Cancel. Save draft vs Publish.
- **Clearance verification (§9.3):** scan a student's QR, pick the requirement, record Cleared / Needs Correction / On Hold with a reason, confirm. Mock only.

### Shared

- **Profile (§10):** large photo, name, role, academic/faculty info, **masked ID** (`2023-****-12`), tags, inline stats, Edit Profile, About, Classes I teach (teachers), event history as photo rows. **No QR on Profile** in the new design.
- **Settings sheet (§11):** grouped list: Personal Information, Account & Security, Notifications, Help & Support, About Michaelean, **preview role switch** (labeled as a preview tool), Log Out.
- **Permissions and privacy (§12):** permissions are explicit in data, separate from tags. Hiding a button is not security; the future backend enforces it. Mask IDs, keep personal info minimal.

### Later, only when the group decides (Phase 11)

Real Microsoft 365 sign-in, school-record mapping, a backend and database, official records, memberships and permissions, clearance workflows, real notifications, real QR verification, PWA deployment and offline caching, and choosing the free hosting service.

---

## Rebuild plan and progress

On 2026-10-21 a full design review found the first build looked thin and didn't match the vision, so **`docs/spec.md` was rewritten** and the screens are being **rebuilt** in this order (spec §13). Models, services, and mock data from the first build are kept. Do **one phase at a time**, and review it before starting the next.

| # | Phase | Spec | Status |
|---|---|---|---|
| 1 | Theme and shared pieces | §2 | ✅ **Done** |
| 2 | Opening intro and sign-in preview | §1.1, §4 | ✅ **Done** (intro is a stand-in for a real video, see below) |
| 3 | Home, both roles, incl. notifications sheet, long-press QR, one-time hint | §6, §8, §1.3 | ✅ **Done** |
| 4 | Hubs: Student Life and Michaelean Life live previews | §7, §9 | ⏳ **Next** |
| 5 | Profile and Settings | §10, §11 | To do |
| 6 | Class: student Class screen + teacher class management with attendance scan | §7.1, §9.1 | To do |
| 7 | Events: discovery, detail, teacher management | §7.3, §9.2 | To do |
| 8 | Organizations: directory and tabbed organization page | §7.4 | To do |
| 9 | Clearance: student clearance and teacher verification | §7.5, §9.3 | To do |
| 10 | Frontend testing: navigation, responsive layouts, empty/error states, validation, role UI, permissions, QR, motion | all | To do |
| 11 | Later integration (only when requested): auth, backend, hosting, PWA | §4, §13 | Later |

### The phases in order

Each phase is one piece of work, reviewed by the group before the next one starts. Every new screen needs loading, empty, unavailable, and error states, works for both roles where it applies, and follows the [rules](#rules-everyone-must-follow) (especially "no fake success").

#### Phase 1: Theme and shared pieces ✅ Done

**Spec:** §2 (Design System). **Goal:** the shared look and building blocks every later screen uses.

- Color tokens (navy, red, ink, muted, hairline, fill) and status-pill tints in `lib/theme/app_theme.dart`.
- Fonts: **Inter Display** for big titles, **Inter** for everything else, bundled in `assets/fonts/`.
- Spacing, radii, soft floating shadows, and motion timing (`AppMotion`, 200–300 ms, ease-out); smooth page transitions.
- Shared widgets: list rows (`ContentRow`, with the status pill overlapping the thumbnail), `StatusPill`, `TwoToneDate`, bottom sheets (`AppSheetPage`), floating nav bar, round icon buttons.

#### Phase 2: Opening intro and sign-in preview ✅ Done

**Spec:** §1.1, §4. **Goal:** what users see when they open the app.

- **Opening intro** (`opening_screen.dart`): animated SMCL emblem with a **Skip** button. Plays on every app open, including reloads. Stands in for a real SMCL opening video.
- **Sign-in preview** (`preview_screen.dart`): emblem, **Student | Teacher** pill switch (`SegmentedPills`), `Sign in with Microsoft (preview)` button, and a visible note that it is a preview with sample data, not a real sign-in.

#### Phase 3: Home, both roles ✅ Done

**Spec:** §6 (Student Home), §8 (Teacher Home), §1.3 (Quick QR). **Goal:** "what's next for me today", then what's happening on campus. One shared Home screen (`screens/shared/home_screen.dart`) that adapts to the role.

- **Header:** emblem + `Michaelean` wordmark and the bell in a white pill. On scroll it collapses to your photo, greeting, and date; the bell stays.
- **Stats row** (`widgets/stats_row.dart`), always visible. Students: class attendance %, event attendance %, events completed, requirements cleared (`3/6`). Teachers: classes today, to finalize, upcoming events. "Events completed" opens the Profile's event history; the others open "Coming soon" pages until Phases 6, 7, and 9.
- **Up next** (`widgets/up_next_card.dart`): solid **navy** card with the next class (subject, time, room, and the teacher for students or the section for teachers). Teachers with the `manageAssignedClasses` permission get **Start attendance** (a "Coming soon" page until Phase 6). With no class ahead: a calm "No upcoming classes" state.
- **Pending tasks:** actionable items only. A teacher's "Finalize attendance" appears only after a scanned class has ended and isn't finalized.
- **Teachers:** **Today's Classes** (with `To finalize`, `Now`, or `Ended` pills) and **Schedule & Room Changes**.
- **Announcements** (4), **School News** (one big photo story + 3 rows), and the **Campus Feed** (department, organization, and event updates; `URGENT` posts pinned first). No post appears in two sections.
- **Notifications sheet:** grouped **Today / Earlier**, an icon per kind, time on the right. Tapping opens the related post (or a "Coming soon" page); it changes no record.
- **Quick QR** (`screens/shared/qr_sheet.dart`, route `/qr`): long-press the middle tab. Shows a large QR of the account's random mock token, the user's name, `Show this code to your teacher.` (students) or `Your Michaelean identity code.` (teachers), and a note that it verifies nothing. Back closes it.
- **One-time tip** above the nav bar: `Tip: hold Student Life to show your QR` (or `Michaelean Life`). Shown once per device, remembered with `shared_preferences` (`services/hint_store.dart`); hides after 8 seconds or with its X.
- No `See all ›` links on Home: each section already shows everything there is, and the spec forbids buttons that do nothing.

#### Phase 4: Hubs (Student Life and Michaelean Life) ⏳ Next

**Spec:** §7, §9. **Goal:** each role's feature hub, for browsing. Replace the feature list in `screens/shared/life_hub_screen.dart` with **live previews**, each a real peek at its content with `See all ›`.

- **Student Life** (subtitle `Your campus, beyond the classroom.`): Class (next class and today's schedule), Events (horizontal strip of upcoming events with photos), Organizations (the student's org logos), Clearance (progress, or `Clearance Unavailable`).
- **Michaelean Life** (heading `Teaching & Campus`): Classes (today's classes, each with Start attendance), Events you manage (upcoming and drafts), Clearance (assigned office and pending count, or `Clearance Unavailable`).
- Features the teacher is not authorized for stay disabled, with an explanation.
- The hub is for browsing; Home is for today and alerts. They don't repeat each other.

#### Phase 5: Profile and Settings

**Spec:** §10, §11. **Goal:** a social identity page in Luma's profile layout, the same for both roles.

- **Profile:** large photo, left-aligned name, Student/Teacher designation, academic or faculty info, masked ID (`2023-****-12`), identity tags, inline stats (students `12 Attended · 3 Orgs`; teachers `4 Classes · 6 Hosted`), Edit Profile button, settings icon, About, **Classes I teach** (teachers), **event history** as photo rows (status + recorded role).
- **Remove the QR coin from Profile:** the QR now lives on the long-press sheet and in Class. `widgets/profile_coin.dart` can be reused for the QR sheet or deleted.
- **Edit Profile:** only photo and About. Academic info, IDs, memberships, roles, and history can't be edited.
- **Settings sheet:** grouped, rounded inset list: Personal Information, Account & Security, Notifications, Help & Support, About Michaelean, **preview role switch** (reuse `SegmentedPills`, labeled as a preview tool), Log Out. Closes with X, outside tap, or Back. Unbuilt items show clear placeholders.

#### Phase 6: Class (student Class + teacher class management)

**Spec:** §7.1, §7.2, §9.1. **Goal:** schedules and attendance.

- **Student Class screen:** `Show QR` button at the top; a **Mon–Sat day strip** (today selected) with that day's classes (subject, teacher, start–end time, room); **attendance**: overall %, % per subject, recent records (Present / Absent).
- **Teacher class management:** assigned classes, today's schedule, class details, student roster, recent sessions, schedule and room editing (date or recurrence, times, room, reason, Save Changes). Who may edit what is open decision 1 and 3.
- **Attendance scan flow (mock):** Start attendance → full-screen mock camera with a live counter `Present 18 · Unchecked 7` → each scan briefly flashes the student's photo and name → **Finish** → roster review of unchecked students → **Confirm finalization**.
- **Rules (§7.2):** only enrolled students can be marked Present; no scans before the session starts or after it closes; duplicate scans don't count twice; late counts as Present; percentages use finalized records only. Mock scanning is always labeled and never shown as real verification or a saved official record.

#### Phase 7: Events (discovery, detail, teacher management)

**Spec:** §7.3, §9.2. **Goal:** finding, registering for, and managing events.

- **Discover | My events** segmented control. Discover: filter pills **All / School-wide / Department / My Orgs**; events grouped under two-tone date headers as photo rows; only events the user is eligible for, no duplicates. My events: registered, then past.
- **Event detail** (Luma style): large cover photo (expands from the list image), title, date and time, action buttons (Register, Share, More), then **Venue** (with map), **Host**, **Attendees** (overlapping avatars, e.g. `+42`), **About**; deadline and capacity when they apply.
- **Teacher management:** Upcoming, Past, Drafts, Create Event, Edit Event, Invite Students, View Registrations, Cancel Event. **Create/Edit** is one scrolling Luma-style form (cover photo picker, name, date, times, venue, audience, deadline, capacity, description) with **Save draft** and **Publish**.
- **Rules:** no duplicate registrations; no registration for full, closed, or ineligible events; registration is not attendance; editing updates the same event; no real publishing, registration, or notifications in the prototype.

#### Phase 8: Organizations

**Spec:** §7.4. **Goal:** campus organizations.

- **Directory**, three groups: the student's departmental society, approved school-wide clubs, My Organizations. Each entry shows logo, name, and member count.
- **Organization page:** cover photo, logo, name, tags, membership status (Member / Join), then tabs **About, Schedule, Events, News, Officers**. An event in the Events tab opens the shared event detail, and Back returns to the organization.
- **Rules:** a department is not its society; only authorized officers manage organization content.

#### Phase 9: Clearance (student clearance + teacher verification)

**Spec:** §7.5, §9.3. **Goal:** seasonal clearance (Semester, Graduation, Document request, …).

- **Student, during an active period:** period name and deadline, a big progress bar or ring (`3 / 6 cleared`), one row per office (Library, Accounting, …) with a status pill. Tapping a row shows what to do, the reason if it was returned, and a resubmit path. **Past clearances** at the bottom.
- **Student, outside a period:** a calm `Clearance Unavailable` empty state; history stays visible.
- **Statuses:** Not started, Action required, In review, Needs correction, Cleared, On hold, Not applicable (Action required vs Needs correction is open decision 8).
- **Teacher/staff verification:** assigned office, pending requirements, **Scan Student QR**, student details, pick a requirement, record **Cleared / Needs Correction / On Hold** with a reason, confirm. Mock only.
- **Rules:** a QR scan or upload never approves clearance automatically; staff process only the requirements they're authorized for.

#### Phase 10: Frontend testing

**Spec:** all sections. **Goal:** make the whole prototype solid before any real integration.

- Navigation and state: Back gesture, tabs keeping their state, sheets closing.
- Responsive layouts on small and large phones; touch targets at least 48 × 48 px.
- Loading, empty, unavailable, and error states on every screen.
- Form validation (event form, schedule editing, Edit Profile).
- Role-specific UI and permission-dependent controls.
- QR (mock token only) and motion (smooth, 200–300 ms).

#### Phase 11: Later integration (only when the group decides)

**Spec:** §4, §13. **Not part of the prototype.**

- Microsoft 365 sign-in through the school's tenant, and mapping accounts to official student/faculty records.
- Backend, database, and authorization (permissions enforced on the server).
- Official records, memberships, roles, clearance workflows, real notifications, production QR verification.
- PWA deployment on free hosting, home-screen icon from the SMCL emblem, offline caching.

---

## Recent changes

Newest first.

- **Rebuild Phase 3: Home, both roles.**
  - Home rebuilt to spec §6/§8: always-visible stats row, navy Up next card, today's classes for teachers, campus feed with urgent posts pinned, more mock announcements and news so sections feel full.
  - New shared widgets `StatsRow` and `UpNextCard`; removed the old `ExpandableOverview`.
  - Notifications sheet grouped Today / Earlier with icons; fixed "59m ago" showing instead of "1h ago".
  - Quick QR: long-press the middle tab opens a QR sheet (`/qr`); one-time tip saved on the device with the new `shared_preferences` package.
  - Mock data: Nicolas now has his own class schedule (with invented teacher names); notifications have kinds; the teacher's "awaiting finalization" class only counts after it has ended.
  - The nav bar tabs now expose tap and long-press to screen readers.
  - "Coming soon" pages no longer claim every feature is "planned for Phase 5".
  - Tests: stats row, Up next for both roles, Start attendance permission, Today / Earlier grouping, long-press QR and Back, tip shown once and above the nav bar, student next class, teacher's today's classes.
- **Intro plays on every app open, including reloads** (`2efd845`). A browser reload kept the last address (e.g. `/#/home`) and skipped the intro. The router now always starts at `/opening` (`overridePlatformDefaultLocation: true` in `lib/router.dart`). Logging out still goes straight to sign-in.
- **Rebuild Phase 2: opening intro and sign-in preview** (`5d99a80`).
  - New `lib/screens/shared/opening_screen.dart`: animated SMCL emblem intro with Skip. It replaced a first attempt that played `assets/videos/app_opening.mp4`, because that video turned out to be a recording of Luma's app (its logo and slogan), which the spec forbids. The `video_player` package was removed again.
  - Rebuilt `lib/screens/shared/preview_screen.dart`: Student/Teacher pill switch, `Sign in with Microsoft (preview)` button, visible "preview only, sample data" note. The emblem glides in from the intro (a `Hero` animation).
  - New shared `lib/widgets/segmented_pills.dart` (pill segmented control).
  - Router opens on `/opening`. Tests updated for the new flow, plus a Skip test.
- **Rebuild Phase 1: theme and shared pieces** (`c285f73`).
  - Added **Inter Display** (SemiBold, Bold) for large titles, from the official Inter 4.1 release (same OFL license as Inter).
  - Theme: status-pill tint colors moved into `app_theme.dart`; new `AppMotion` timing tokens (200–300 ms, ease-out); section gap 32 px; smooth page transitions (iPhone keeps its native swipe-back slide).
  - `ContentRow`: the status pill now overlaps the thumbnail (Luma style).
  - New `TwoToneDate` widget (`21 October / Wednesday`).
  - Profile history: the role moved to the date line so the pill fits.
- **Spec rewrite after the full design review** (`e44dc7b`): `docs/spec.md` revised; rebuild order defined in §13.

### The first build (before the redesign)

Kept in git history: Phase 1 foundation (project, theme, navigation, role previews), Student Home feed, Teacher Home, a first Luma-style pass on Home, Phase 3 feature hubs, Phase 4 Profile with the photo-to-QR coin. Its models, services, and mock data are still used.

---

## Project structure

```
lib/
  main.dart          app entry: creates the Session and the router
  router.dart        every route (go_router); redirects based on the previewed user
  theme/
    app_theme.dart   THE single source of colors, fonts, spacing, radii, shadows, motion
  widgets/           shared building blocks (see Design system)
  screens/
    shared/          screens both roles use (opening, sign-in preview, Home, hubs, Profile, sheets)
    student/         planned: student-only screens (folder not created yet)
    teacher/         planned: teacher-only screens (folder not created yet)
  models/            plain data classes: UserProfile, IdentityTag, Permission, feed items, EventRecord
  mock/              CLEARLY LABELED sample data (mock_users.dart, mock_home.dart)
  services/          interfaces that return mock data now, real data later
                     (UserService, HomeService) + Session (who is being previewed)
                     + HintStore (remembers one-time tips on the device)
  utils/dates.dart   date formatting helpers
test/                widget and unit tests
assets/
  fonts/             Inter + Inter Display (.ttf) and their license (Inter-OFL.txt)
  images/            SMCL_Emblem.png (main logo), SMCL_MAP.png, events/, profiles/
  images/luma_screens/   design reference screenshots: NOT in git (see Known issues)
  videos/app_opening.mp4 NOT used; a Luma recording (see Known issues)
docs/
  spec.md            the product spec: what to build
  CLAUDE.original.md the original, longer project brief (historical)
  plans/             old phase plans (historical)
web/                 PWA files: index.html, manifest.json, icons
CLAUDE.md            working rules for Claude Code (AI assistant); also a good summary of the rules
.claude/launch.json  config that lets Claude Code preview the web build
```

### How data flows

Screens never read mock data directly. They ask a **service** (e.g. `HomeService.loadHome(user)`), and `MockHomeService` / `MockUserService` return sample data from `lib/mock/`. Later, a real implementation (Microsoft 365 + school records) can replace the mock service **without changing the screens**.

The previewed user lives in `Session` (`lib/services/session.dart`). Any screen gets it with `SessionScope.of(context)`.

### Key decisions

- **State:** Flutter built-ins only (`setState`, `ChangeNotifier`). No state-management package unless the group agrees first.
- **Navigation:** `go_router`, so the Android/browser **Back** gesture closes pop-ups and goes back instead of leaving the app. Pop-up sheets are router pages (`AppSheetPage`) for the same reason.
- **Packages:** `go_router` (navigation), `qr_flutter` (QR codes), `shared_preferences` (remembers one-time tips on the device). Add a package only with a clear reason.
- **Light mode only** for now; the theme keeps dark mode possible later.

---

## Design system

The look follows **Luma** (an events app for iPhone) closely in layout and feel, with SMCL's own identity: emblem, navy and red, never Luma's logo or branding. "Premium" comes from: **real photos**, **strong typography**, **smooth motion**, and **soft depth** (big soft shadows, things floating above the page). Screens should feel **full, not thin**: rich rows with a photo, source, time, place and status, and 4–5 items per section before `See all ›`. Avoid card grids, decorative metric chips, gradient headers, and floating action buttons. Details: spec §2.

### Tokens (all in `lib/theme/app_theme.dart`; never hardcode colors or sizes in screens)

| Token | Value | Use |
|---|---|---|
| `AppColors.navy` | `#242A5E` | The one bold color: primary buttons, active states, Up next card. **One navy hero per screen.** |
| `AppColors.red` | `#B3242E` | Attention only: `URGENT`, notification dot, Needs correction |
| `AppColors.ink` / `muted` | `#16171D` / `#6E7079` | Main text / secondary text |
| `AppColors.hairline` / `fill` | `#ECECEE` / `#F3F3F4` | Dividers / soft gray tiles, inputs |
| Status tints | green, amber, navy, red, gray | Status pills (Cleared, In review, Registered, Needs correction, Not started) |
| `AppSpacing` | 4-point scale; `screen` 20, `section` 32 | Margins and gaps |
| `AppRadius` | `small` 12, `large` 20, `pill` | Thumbnails / covers, sheets / buttons, tags, nav |
| `AppColors.floatShadow` | soft, large blur | Floating pieces only |
| `AppMotion` | `fast` 200, `normal` 250, `slow` 300 ms, ease-out | All animations |

**Fonts:** **Inter Display** for big titles (`displaySmall`, `headlineMedium`, `headlineSmall` in the theme); **Inter** for everything else. Both are bundled, so they work offline. No serif.

**Logo:** `assets/images/SMCL_Emblem.png`. Don't recolor, stretch, crop, or add effects.

### Shared widgets (`lib/widgets/`): use these before writing new ones

| Widget | What it is |
|---|---|
| `ContentRow` | The standard list row: thumbnail (pill overlaps it), source avatar + name, title, meta line with icon |
| `StatusPill` | Small tinted status label (`PillTone.green/amber/navy/red/neutral`) |
| `TwoToneDate` | `24 October / Friday` date header |
| `SectionHeader` | Section title with consistent spacing |
| `SegmentedPills` | Pill segmented control (Student/Teacher, Discover/My events, …) |
| `AppSheetPage` | Rounded bottom sheet as a router page: grab handle, round X, dimmed background, Back closes it |
| `FloatingNavBar` | The floating pill bottom navigation |
| `RoundIconButton` | Floating white circle button (bell, back), optional red dot |
| `UserAvatar` | Round photo or initials |
| `StatsRow` | Compact row of tappable stats with navy numbers (Home) |
| `UpNextCard` | Solid navy "Up next" class card, optional Start attendance button, empty state |
| `ProfileCoin` | Photo that flips to a QR; leaves Profile in Phase 5 |

---

## Rules everyone must follow

These come from the spec and keep the prototype honest. They apply to every screen.

1. **Mock data is clearly mock.** Sample records live only in `lib/mock/`, never inside widgets. Never present them as official school records.
2. **No fake success.** A simulated action must never claim it changed a real record. No fabricated "Attendance saved", "Registered", "Published", or "Cleared" messages. A mock QR never verifies identity or attendance.
3. **Identity ≠ permission.** Tags (school, department, organization, officer) are labels. Permissions are separate and explicit (`Permission` in `lib/models/user_profile.dart`, checked with `user.can(...)`). Hiding a button is not security.
4. **Privacy.** Mask student/staff IDs by default. QR content is a random mock token. Show only necessary personal information.
5. **Prototype status stays visible.** The sign-in preview and role switch are preview tools, clearly labeled, never security.
6. **Every screen handles** loading, empty, unavailable, and error states. Touch targets at least 48 × 48 px. Works on small and large phones.
7. **Assets are declared file by file** in `pubspec.yaml`. **Never** declare `assets/images/` as a whole folder (the Luma screenshots must not ship).
8. **Don't build things that block real integration later.** Use simple models and service interfaces.
9. **Don't decide open questions silently** (see [Open decisions](#open-decisions)). If one blocks you, use a clearly labeled, easy-to-change mock assumption and note it.

---

## Testing

```bash
flutter test
```

29 tests currently pass. They cover:

- **Navigation:** student and teacher previews land on the right Home and tabs; Log Out returns to sign-in without replaying the intro; Skip leaves the intro; a reload at a saved address still plays the intro first.
- **Home:** the stats row shows and a stat opens its detail; Up next for students (with the teacher's name, no attendance button) and teachers (Start attendance, today's classes); notifications sheet opens and closes (X and system Back), groups Today / Earlier, and a notification opens its post; long-press opens the QR sheet and Back closes it; the tip shows only once and sits above the nav bar; a load failure shows Retry (never fake content).
- **Home data:** the student sees their department/society posts only, urgent posts first, the student's own next class with its teacher, the teacher's classes for today only, teacher sections, the attendance task appears only for an unfinalized session, next-class logic, no post in two sections.
- **Hubs:** Student Life lists its features; Michaelean Life disables features the teacher isn't authorized for.
- **Profile:** identity, masked ID, tags, event history; the QR holds only the mock token; settings opens and closes; Log Out ends the preview.

When you rebuild a screen, update its tests and add tests for new logic, especially permissions, status rules, and "no fake success" behavior.

---

## Open decisions

Don't silently invent answers to these. Ask the group (or the school) and record the decision in `docs/spec.md`.

1. Can teachers edit only their assigned classes, or can authorized teachers edit others?
2. Is departmental society membership automatic or application-based?
3. Can teachers change single sessions, recurring schedules, or both? Which changes need approval or notification?
4. Visibility rules for event histories and attendee lists.
5. Which student/faculty info comes from the Microsoft directory vs. another official source?
6. Backend, database, and authorization architecture (later).
7. Which free hosting service, and the Flutter web/PWA configuration.
8. Exact meaning of clearance statuses **Action required** vs **Needs correction** (proposed in spec §7.5: first-time task vs. returned by staff with a reason).

---

## Known issues and things to know

- **The Luma reference screenshots are not in the repo.** The spec points to `assets/images/luma_screens/` as the visual reference, but that folder is git-ignored (third-party images, kept locally). **Ask the repo owner for a copy**, or look up Luma's iOS app screens on Mobbin. Keep them out of git and never declare them in `pubspec.yaml`.
- **`assets/videos/app_opening.mp4` is a recording of Luma's app** (its logo and slogan). It is **not used** and not declared in `pubspec.yaml`. The animated emblem intro stands in until there is a real SMCL opening video. To use a real video later: replace the file, add the video back to `pubspec.yaml`, run `flutter pub add video_player`, and switch `opening_screen.dart` to play it. Browsers block autoplay with sound, so play it muted.
- **Profile photos in `assets/images/profiles/` are of real people.** Use them only with their consent, and only as clearly labeled sample data. Event posters in `assets/images/events/` are placeholders too. The spec wants stock or real SMCL photos listed in one place in mock data so they are easy to swap.
- **PWA settings are still Flutter defaults.** `web/manifest.json` has name `michaelean_app`, Flutter's blue color, and Flutter's icons. Set the name, colors, and icons (from the SMCL emblem) when the group picks the hosting (open decision 7).
- **Hubs and Profile still use the old design** until Phases 4–5. Some old pieces contradict the new spec on purpose until then (e.g. the QR coin on Profile).
- **Long-press needs a real hold.** Hold the mouse button (or your finger) on Student Life / Michaelean Life for about half a second. Automated widget tests cover it.
- **On narrow phones the quick-QR tip wraps to two lines.** It's readable; shorten the wording if the group prefers one line.
- **Git warnings "LF will be replaced by CRLF"** on Windows are harmless.
- **`docs/CLAUDE.original.md` and `docs/plans/`** are historical. `docs/spec.md` is the source of truth.

---

## How to continue the work

1. **Pull the latest `main`**, then run `flutter pub get`, `flutter analyze`, and `flutter test`. They should all be clean before you start.
2. **Pick the next phase** from the [progress table](#rebuild-plan-and-progress) (Phase 4 is next). Agree in the group who does what. Work on **one phase at a time** and avoid two people editing the same files at once.
3. **Work on a branch**, e.g. `git checkout -b phase-3-home`.
4. **Read the spec sections** for that phase, plus §2 (design) and §12 (permissions and privacy).
5. **Build it**, reusing the shared widgets and theme tokens. Keep mock data in `lib/mock/` and go through the services.
6. **Check it:** `flutter analyze` clean, `flutter test` passing, and click through it in Chrome at phone size, for **both** roles.
7. **Update this README:** mark the phase done in the table and add a line to [Recent changes](#recent-changes).
8. **Merge into `main`** after someone in the group has looked at it.

