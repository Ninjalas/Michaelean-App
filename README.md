# Michaelean

A campus-life app for students and teachers of **Saint Michael's College of Laguna (SMCL)**: class schedules, attendance, events, organizations, clearance, notifications, and a social profile, all in one app.

Built with **Flutter/Dart**. The goal is a free-hosted, installable **PWA** (Progressive Web App) that students and teachers add to the home screen on Android and iPhone.

> **Status (2026-10-21): frontend prototype.** Everything runs on clearly labeled **sample data**. There is no backend, no database, and no real Microsoft 365 sign-in yet. The app is being **rebuilt screen by screen** to a revised design (see [Rebuild plan and progress](#rebuild-plan-and-progress)). **Phases 1–6 of 11 are done.**

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

1. **Opening intro.** The SMCL emblem fades and scales in, then "Michaelean" and the school name rise in. After about 2.4 seconds it moves on by itself (there is no Skip button). It plays on **every** app open, including browser reloads. With "reduce motion" turned on, it shows the finished logo without movement.
2. **Sign-in preview.** Pick **Student** or **Teacher** in the pill switch, then press **Sign in with Microsoft (preview)**. This is **not** a real sign-in: it loads a mock student (Nicolas) or mock teacher (Mark). The screen says so in plain words.
3. **The app**, with a floating bottom bar of three tabs:
   - Students: **Home | Student Life | Profile**
   - Teachers: **Home | Michaelean Life | Profile**
4. **Quick QR.** Long-press the middle tab (Student Life / Michaelean Life) to open your QR sheet. The first time, a tip above the nav bar says so.

What's behind each tab right now:

| Screen | State |
|---|---|
| Opening intro, Sign-in preview | **New design (rebuilt).** |
| Home (both roles), notifications sheet, QR sheet | **New design (rebuilt).** Stats row, navy Up next card, pending tasks, today's classes (teachers), announcements, School News, campus feed. Teachers with the `postToCampusFeed` permission get a **+ button** to post announcements, School News, and campus updates (preview only), and can edit or delete their own posts. |
| Student Life / Michaelean Life | **New design (rebuilt).** Live previews of Class, Events, Organizations, and Clearance (students) or Classes, Events You Manage, and Clearance (teachers). Every `See all ›` opens its real screen. |
| Profile, Edit Profile, Settings sheet | **New design (rebuilt).** Luma-style profile with inline stats, tags, About, Classes I Teach (teachers), and Event History (each record opens its event); Edit Profile (About only, saved in this preview); grouped Settings with five pages (Personal Information, Account & Security, Notifications, Help & Support, About), the preview role switch, and Log Out. |
| Class (students), Classes + class page + attendance scanner (teachers) | **New (built in Phase 6).** Weekly schedule, attendance from finalized records, mock scanner with the attendance rules, review and finalize, single-session changes. |
| Events (students: Discover / My events / event detail; teachers: Upcoming / Past / Drafts, create, edit, invite, registrations, cancel) | **New (built in Phase 7).** Registration, invitations, publishing, and cancelling change this preview only and say so. |
| Organizations directory and organization page (students) | **New (built in Phase 8).** Three groups, tabbed organization page, honest "Request to join". |
| Clearance (students) and Clearance Verification (teachers with the `processClearance` permission) | **New (built in Phase 9).** Progress, requirement details, honest resubmit; mock QR scan, outcome with reason, honest save. |

---

## The overall plan of the app

The full product spec is **[`docs/spec.md`](docs/spec.md)**. **Read the spec section for a feature before you build it.** Below is a summary so you know the whole picture.

### One app, two roles

Michaelean is **one app** with a **student** experience and a **teacher** experience that share the same design and components. Screens are shared and adapt their content to the role; never build separate copies of a screen for students and teachers.

### Start flow (spec §1.1)

Opening intro/video (no Skip button) → Sign-in preview screen → Home.

In production, sign-in will go through the school's **Microsoft 365** accounts: sign in, verify the account belongs to SMCL, match it to an official student/faculty record, load the verified info, assign tags and permissions, then open Home (spec §4). **Not part of the prototype.**

### Navigation (spec §1.2, §1.3)

- Floating pill bottom bar with three tabs. Tabs keep their state when you switch.
- **Quick QR:** long-pressing the middle tab (Student Life / Michaelean Life) opens the user's QR sheet. A one-time hint teaches this. The QR holds a **random mock token** (e.g. `MOCK-7F3K9Q`), never personal data, and showing it never verifies anything.

### Identity tags (spec §5)

Everyone gets labels like `[Saint Michael's College of Laguna] [SBMIT] [Department of Computer Studies] [Dance Company] [Dance Company Officer]`. Schools: **SON, SBMIT, SEAS**. Tags are **labels only; they never grant permissions.** Users can't give themselves tags.

### Student features

- **Home (§6):** what's next for me today, then what's happening on campus. Header with greeting and date; a row of 4 stats (class attendance %, event attendance %, events completed, requirements `3/6 cleared`); a navy **Up next** class card; pending tasks; announcements; School News (one big story + smaller rows); a campus feed (urgent org posts pinned with `URGENT`). The bell opens notifications grouped **Today / Earlier**; its red dot shows only while something you can see there is unread.
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
| 4 | Hubs: Student Life and Michaelean Life live previews | §7, §9 | ✅ **Done** |
| 5 | Profile and Settings | §10, §11 | ✅ **Done** |
| 6 | Class: student Class screen + teacher class management with attendance scan | §7.1, §9.1 | ✅ **Done** |
| 7 | Events: discovery, detail, teacher management | §7.3, §9.2 | ✅ **Done** |
| 8 | Organizations: directory and tabbed organization page | §7.4 | ✅ **Done** |
| 9 | Clearance: student clearance and teacher verification | §7.5, §9.3 | ✅ **Done** |
| 10 | Frontend testing: navigation, responsive layouts, empty/error states, validation, role UI, permissions, QR, motion | all | ✅ **Done** |
| 11 | Later integration (only when requested): auth, backend, hosting, PWA | §4, §13 | Later (the prototype is complete) |

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

- **Opening intro** (`opening_screen.dart`): animated SMCL emblem; moves on by itself after about 2.4 s (the Skip button was removed later, see Recent changes). Plays on every app open, including reloads. Stands in for a real SMCL opening video.
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

#### Phase 4: Hubs (Student Life and Michaelean Life) ✅ Done

**Spec:** §7, §9. **Goal:** each role's feature hub, for browsing. `screens/shared/life_hub_screen.dart` shows **live previews**: real peeks at each feature's content, each section with `See all ›` (a "Coming soon" page until that feature's phase).

- **Student Life** (subtitle `Your campus, beyond the classroom.`):
  - **Class:** today's classes with `Ended`, `Now`, or `Next` pills (time, subject, room, teacher). With no class today: a line naming the next class.
  - **Events:** a horizontal strip of photo cards (cover, day and time, title, venue) for published events the student is eligible for, soonest first.
  - **Organizations:** the student's confirmed organizations (from their organization tags) with logo or initials and member count.
  - **Clearance:** period name, deadline, a navy progress bar with `3/6`, and a red `1 needs correction` pill; outside a period, a calm `Clearance Unavailable` tile.
- **Michaelean Life** (subtitle `Teaching & Campus`):
  - **Classes:** today's classes. **Start attendance** appears only on classes that haven't ended (no scans after a session closes, spec §7.2); ended ones show `To finalize` or `Ended`.
  - **Events You Manage:** photo rows of upcoming events and drafts the teacher may manage, with a `Draft` pill.
  - **Clearance:** the assigned office and pending count, or `Clearance Unavailable`.
- **Permissions, not the Teacher label, decide what's usable.** A section the user isn't authorized for stays visible with a lock icon and the reason, and has no `See all ›`. The mock teacher can manage classes and events but has no clearance area.
- Data comes from the new `CampusService` (`services/campus_service.dart`) and `MockCampusService`, with sample events, organizations, and clearance in `mock/mock_campus.dart`.
- One loading skeleton and one error state (with Retry) for the whole hub.

#### Phase 5: Profile and Settings ✅ Done

**Spec:** §10, §11. **Goal:** a social identity page in Luma's profile layout, the same for both roles.

- **Profile** (`screens/shared/profile_screen.dart`): large photo (left) with the settings icon, the name in the big title font, Student/Teacher and program, masked ID in the spec's format (`2023-****-21`), **inline stats counted from records** (students `3 Attended · 2 Orgs`; teachers `3 Classes · 1 Hosted`, where only events whose record says *host* count), official tags, **Edit Profile**, About, **Classes I Teach** (teachers, each class listed once), and **Event History** photo rows (status pill + recorded role).
- **No QR on Profile.** The QR coin was removed (`widgets/profile_coin.dart` deleted); the QR lives on the long-press sheet.
- **Edit Profile** (`screens/shared/edit_profile_screen.dart`, route `/profile/edit`): only **About** is editable (rounded gray field, 160 characters). **Save** stays gray until something changes, then updates this preview only and says so: "Saved in this preview only. Nothing was sent to the school." Name, program, ID, and tags are shown locked as "Set by the school". Changing the photo is explained as not available in the preview yet (it needs a file picker).
- **Settings sheet** (`screens/shared/settings_sheet.dart`): grouped, rounded inset lists: Personal Information, Account & Security, Notifications | Help & Support, About Michaelean | **Preview tools** with a Student / Teacher switch (labeled "Not a sign-in and not a security feature") | Log Out. Unbuilt items open "Coming soon" pages. X, outside tap, and Back close it.
- **Role switch refreshes every tab.** Home, the hub, and Profile reload when the previewed account changes, so no tab keeps the old user's data.
- Theme: shared Luma-style text fields (borderless, light gray, rounded) and a plain-gray disabled button.

#### Phase 6: Class (student Class + teacher class management) ✅ Done

**Spec:** §7.1, §7.2, §9.1. **Goal:** schedules and attendance.

- **Weekly timetable** (`mock/mock_classes.dart`): classes with weekdays, times, rooms, and assigned teachers, plus a 12-student roster per section (invented names, masked IDs, random mock QR tokens). Nicolas is in BSCS 3A, which Mark teaches CS 302. Past sessions come pre-finalized with a few seeded absences; today's CS 301 comes pre-scanned (10 of 12) so the teacher has a real "Finalize attendance" task.
- **Student Class** (`screens/student/class_screen.dart`, route `/life/class`): `Show QR`, then top to bottom: **Attendance this semester** (overall %, and % **by subject** like "20 of 21 · 95%"); the **Schedule**, with the month, a **Today** button, and a day strip that **scrolls sideways across the whole semester** (Mon–Sat, opens centered on today) plus the selected day's classes; and the **Records** of the selected day (each class Present / Absent, or "Not finalized yet" / "Upcoming"). Everything counts **finalized sessions only**; Home's "Class attendance" stat uses the same numbers. The **mock semester** sits around today (about 10 weeks back, 8 weeks ahead) so the prototype always works; real dates will come from the school calendar.
- **Teacher Classes** (`screens/teacher/classes_screen.dart`, `/life/classes`): assigned classes with days and times.
- **Class page** (`class_detail_screen.dart`, `/life/classes/:classId`): today's or the next session with the right action (**Start attendance**, **Review & finalize**, or **Attendance finalized**), **Change this session**, the **roster** (masked IDs), and **recent sessions** (`Finalized`, `To finalize`, or `Not taken`). Another teacher's class shows "You can't manage this class."
- **Mock scanner** (`attendance_scan_screen.dart`, `/attendance/:sessionId`, full screen, reached only through Start attendance or a finalize task): labeled **MOCK SCANNER · no camera is used**. **Simulate scan** (next unchecked student) and **Unknown code**. Each result flashes for about 1.4 s (photo or initials, name, result), and a live counter shows `Present 3 · Unchecked 9`.
- **Attendance rules** (spec §7.2, enforced in `CampusService.recordScan`): unknown or other-section codes are not marked; a second scan counts once; scans before the start or after the end are rejected ("Attendance opens at 10:30 AM"). A clearly labeled **preview tool** ("Open anyway") lets you demo outside class hours; it skips only the time check.
- **Review & finalize** (`attendance_review_screen.dart`, `/attendance/:sessionId/review`): present/unchecked counts, the unchecked list ("will be marked Absent"), and **Confirm finalization**. The confirmation says "finalized in this preview only. Not an official record." A failed save shows an error and never success.
- **Change one session** (`edit_session_screen.dart`): start/end time, room, optional reason; validated (ends after it starts, room required). **Mock assumption for open decisions 1 and 3:** a teacher may change a *single session* of their own assigned classes; recurring changes aren't offered. The confirmation says students were not notified.
- **Shared state:** attendance (scans, finalizations, changes) lives in memory in `MockCampusService`, for this preview only, and resets when the app reloads. Home now gets classes from the same service, and `Session.refresh()` makes every screen reload after a change, so finalizing removes Home's task right away.

#### Phase 7: Events (discovery, detail, teacher management) ✅ Done

**Spec:** §7.3, §9.2. **Goal:** finding, registering for, and managing events.

- **Events list** (`screens/shared/events_screen.dart`, route `/life/events`, from the hub's `See all ›`).
  - Students: **Discover | My events**. Discover has filter pills **All / School-wide / Department / My Orgs** and shows only published, upcoming events the student is eligible for, as photo rows under two-tone date headers. Each event appears once. My events lists the student's registrations (upcoming, then **Past**), including cancelled ones, and notes that registering isn't attendance.
  - Teachers with the `manageEvents` permission see **Events You Manage**: **Upcoming | Past | Drafts**, with a round **+** to create an event. Teachers without the permission see a locked message.
  - Row pills: `Going`, `Invited`, `Registered` (past), `Full`, `Closed` (deadline passed), `Draft`, `Cancelled`.
- **Event detail** (`event_detail_screen.dart`, `/life/events/:eventId`), Luma style: square cover photo, title, date and time, a row of three action tiles, then **Venue** (with the campus map), **Host**, **Attendees** (blank avatar stack + count), **Registration** (deadline, capacity, spots left), and **About**.
  - Students: **Register / Share / More**. Register is disabled with the reason shown when the event is full, closed, started, or not for them. After registering, the tile says `Registered` and the page says "You're registered". More → **Cancel registration**. Share says it isn't available in the preview.
  - Managers: **Edit / Invite / More** (More → **View registrations**, **Cancel event** with a confirmation dialog).
  - If a published event's time or venue changed, an amber "Updated" note shows on it.
- **Create / Edit Event** (`screens/teacher/event_form_screen.dart`, `/life/events/new` and `/life/events/:eventId/edit`): one scrolling Luma-style form: cover picker (bundled photos or none), name, date, start/end, venue, audience (School-wide or the teacher's department), optional registration deadline and capacity, description. **Save draft** and **Publish**; a published event shows **Save Changes** instead and stays published. Problems are explained under the form and disable the buttons.
- **Invite Students** (`event_invite_screen.dart`): pick whole sections you teach; invited students are **registered automatically** (no accept/decline) and marked `Invited`.
- **Registrations** (`event_registrations_screen.dart`): managers only; names with masked IDs and an `Invited` pill.
- **Rules** (enforced in `CampusService`, not just hidden in the UI): no duplicate registrations; no registration for full, closed, ineligible, draft, or cancelled events; registration is never attendance; editing changes the same event (never a copy); only an event's managers can edit, invite, cancel, or see names; validation is checked again by the service. Every confirmation says "in this preview only" and that **no one was notified**.
- **Mock assumptions (easy to change):**
  - Open decision 4: everyone sees the registration **count**, and only the event's managers see **names**.
  - Teachers invite whole sections they teach (not individuals or departments yet), and those students count as eligible for the teacher's department events.
  - A new event is hosted by the teacher's department.
- **Mock data** (`mock/mock_campus.dart`): events now have end times, descriptions, deadlines, and capacities; one full event (Blood Donation Drive), one closed (Society Coding Challenge), two past events; starting registrations (Nicolas is going to the Intramurals opening); counts from people outside the mock rosters so numbers look real.
- **Not done:** the cover photo doesn't animate from the list into the detail (a `Hero` like the emblem's). Events created or changed reset when the app reloads.

#### Phase 8: Organizations ✅ Done

**Spec:** §7.4. **Goal:** campus organizations.

- **Directory** (`screens/student/organizations_screen.dart`, route `/life/organizations`, from Student Life's `See all ›`), three groups:
  - **Your Department Society**: the society of the student's department (CSS for Computer Studies). A department is not its society; they're separate records.
  - **School-wide Clubs**: approved clubs. Other departments' societies (e.g. the invented Nursing Students Association) are **never** listed here.
  - **My Organizations**: confirmed memberships (the student's organization tags).
  - Each row (shared `widgets/org_row.dart`, also used by the hub) shows logo, name, member count, and a `Member` pill.
- **Organization page** (`organization_screen.dart`, `/life/organizations/:orgId`): cover photo with the logo overlapping it, name, member count, tags (`Departmental society` / `School-wide club`, the department, `Member`), then tabs:
  - **About**: description.
  - **Schedule**: regular meetings (what, when, where).
  - **Events**: the organization's upcoming events the student may see. Tapping one opens the **shared event page**, and **Back returns to the organization** on the same tab.
  - **News**: the organization's posts, newest first, `URGENT` pinned label; tapping opens the post (`/life/organizations/:orgId/post/:postId`).
  - **Officers**: names and positions (listing someone doesn't give them app permissions).
- **Members-only content:** non-members don't see members-only events or posts; the page says "Some events and posts are for members only." Another department's society isn't available at all.
- **Request to Join** (mock assumption for open decision 2): records a request in this preview only. The message says nothing was sent and you're **not a member**; the button becomes `Request saved`. Membership stays a confirmed tag that only administrators assign (spec §5).
- **Mock data** (`mock/mock_campus.dart`): five organizations with kind (society/club), department, About text, meetings, and officers (invented names; Mark is listed as CSS adviser). Only CSS has a real logo and cover.
- **Not done:** officer tools (posting news, managing the schedule). The spec allows only authorized officers to manage content, and no mock account is an officer yet, so this waits until someone decides who the mock officer is.

#### Phase 9: Clearance (student clearance + teacher verification) ✅ Done

**Spec:** §7.5, §9.3. **Goal:** seasonal clearance and its verification.

- **Student Clearance** (`screens/student/clearance_screen.dart`, route `/life/clearance`, from the hub, Home's "Cleared" stat, and Home's clearance tasks):
  - During a period: period name and deadline, a big `3 / 7 cleared` with a progress bar, then one row per requirement (office icon, office, requirement, status pill). **Not applicable** items don't count toward the total.
  - Outside a period: the calm `Clearance Unavailable` state (shared `ClearanceUnavailable` widget).
  - **Past Clearances** at the bottom either way.
- **Requirement detail** (`clearance_item_screen.dart`, `/life/clearance/:itemId`): what to do, whether evidence is needed, the **reason** if the office returned it or put it on hold, and a status note. For Not started / Action required / Needs correction there is **I've Done This** or **Resubmit for Review**, which only moves it to **In review** and says "Nothing was uploaded, and it isn't cleared until the office reviews it."
- **Clearance Verification** for staff (`screens/teacher/clearance_desk_screen.dart`, `/life/verify`): the assigned office, the period, the pending students (name, masked ID, section, what's waiting), and **Scan Student QR**, a mock scanner labeled "no camera is used" (**Simulate scan** reads the first pending student's mock code; **Unknown code** matches nobody). Scanning only finds the student.
- **Verify Requirement** (`clearance_case_screen.dart`, `/life/verify/:studentId`): student identification (photo or initials, name, masked ID, section), this office's requirements to pick from, the outcome (**Cleared / Needs Correction / On Hold**), a reason (required unless Cleared), and a confirmation dialog. Saved "in this preview only. Not an official clearance record."
- **Statuses** (shared `clearancePill` in `widgets/clearance_widgets.dart`): Not started, Action required, In review, Needs correction, Cleared, On hold, Not applicable.
- **Rules** (enforced in `CampusService`): a QR scan or a student's submission never clears anything; only staff with the `processClearance` permission, and only for **their own office's** requirements; a reason is required for Needs Correction and On Hold; processing needs an active period.
- **Home agrees:** the "Cleared" stat and the student's clearance tasks (e.g. "Library clearance · Needs correction") now come from the same clearance data, and the tasks open the requirement.
- **Mock assumptions (easy to change):**
  - Mark (the mock teacher) has `processClearance` for the **Department of Computer Studies** requirements (`mockClearanceOffices` in `mock/mock_campus.dart`, permission in `mock/mock_users.dart`).
  - Open decision 8 is still open; the screens use the proposed meanings (Action required = first-time task; Needs correction = returned with a reason).
  - Requirements, offices, and past clearances are invented sample data.
- **Not done:** evidence upload (needs a file-picker package), a real camera scanner, and deadlines (overdue doesn't change any status, as the spec requires).

#### Phase 10: Frontend testing ✅ Done

**Spec:** all sections. **Goal:** make the whole prototype solid before any real integration.

- **Screen audit** (`test/screens_audit_test.dart`): visits **every screen of both roles** (34 routes) three ways:
  1. On a **small phone (320 × 568) with large text (130 %)**, scrolled to the bottom: no overflow or layout error anywhere. Each problem is reported with its route and the file and line that caused it.
  2. On a normal phone against Flutter's accessibility guidelines: every tappable thing is **at least 48 × 48 px** and **has a label** for screen readers.
  3. With **every service failing**: each screen shows a "Couldn't load…" message, never a crash, an endless spinner, or fake content.
- **What the audit found and fixed:**
  - Segmented pill buttons (Discover / My events, Student / Teacher, …) were 44 px tall; now 48.
  - The sign-in screen and the attendance scanner didn't fit short screens; they now scroll when needed.
  - Overflows with large text: Home's header, the Up next date pill, the Class day strip (now grows with the text size), Edit Profile's title, the event form's time fields, the event page's attendees row.
  - The attendance scanner spun forever when loading failed (an unhandled error); it now says it couldn't load.
  - Change Session, Edit Event, Invite Students, and Verify Requirement said "you can't…" when loading failed, which blames permissions; they now say "Couldn't load…". The post page now shows an error when loading fails.
- **No more dead ends:** Home's "Event attendance" stat opens the event history on Profile; the "Event requirements" and "Review schedule change" tasks open Events and the class page; the clearance and attendance notifications open their screens. (Settings items were built afterwards; see Recent changes.)
- **Fixed the midnight test:** the notifications test now uses a fixed noon clock, so it passes at any hour.
- **Web app identity:** the installed app is named **Michaelean**, uses navy and white, and its icons and favicon are made from the SMCL emblem (whole emblem on white; the maskable icon has extra margin for phones that crop icons into shapes).
- **Already covered by earlier phases' tests:** Back closing sheets and pages, tabs keeping their state, form validation (event form, session change, Edit Profile, clearance outcome), role-specific UI and permission locks, the QR as a mock token only, and reduced motion on the intro.

#### Phase 11: Later integration (only when the group decides)

**Spec:** §4, §13. **Not part of the prototype.**

- Microsoft 365 sign-in through the school's tenant, and mapping accounts to official student/faculty records.
- Backend, database, and authorization (permissions enforced on the server).
- Official records, memberships, roles, clearance workflows, real notifications, production QR verification.
- PWA deployment on free hosting, home-screen icon from the SMCL emblem, offline caching.

---

## Recent changes

Newest first.

- **Consultation export follows the official form** (decided 2026-10-31). The Excel file now copies SMCL's **Academic Consultation Form, F-QMS-14 Rev5 (11/25/24)**: school name and address, ACADEMIC CONSULTATION FORM, the department ticks (DBA, DCS, SEAS, DHMAC, SN, SHS, JHS, GS), Name / Course / Grade / Faculty and Time / Date / Venue on lines, the six-line Reason/s for Consultation | Intervention Made table, Expected Outcome on two lines, both signatures above Student's Signature and Instructor's/Professor's Signature, and the form code. A small line below the form says it's from the preview. Close to the printed form, not a pixel copy.
  - The consultation form now asks for a **Department** (the teacher picks one; required) and a **Venue** (required), and allows **up to 6** reasons, like the official table. The consultation page shows them.
  - The export no longer has a Student ID line (the official form has none); the app's pages still show the masked ID.
  - Tests: the Excel test checks the official labels, the ticked department, the form code and preview note order, no Student ID, and the signature positions; a new test checks department, venue, and the 6-row limit.
- **Club officers manage their club** (decided 2026-10-31). A student with an officer position in a club (President, PRO, Captain…) gets a **Manage club** button on the club's page and can do what the adviser does: club posts, club events (published directly), join requests and members, officer positions (including removing officers), and About and meetings.
  - **Officer + explicit list:** being an officer comes from the club's member list (what the adviser keeps; the "… Officer" tag only shows it), and `mockOfficerPowers` in `lib/mock/mock_campus.dart` lists what officers may do. Removing a power there takes it from every officer. This keeps the project rule that tags aren't permissions.
  - **Nicolas is now CSS's Public Relations Officer** in the sample data, so the student preview can try it.
  - Giving up your own position, or leaving the club, asks "You'll lose access to managing this club" first and closes Manage club.
  - Club events made from Manage club remember their club (`CampusEvent.clubId`), so the adviser and every officer can edit them. Older sample club events (like CSS General Assembly) keep working as before: students still register for them.
  - Officers invite clubs and single students, not class sections. "Registered by a teacher's invitation" now reads "Registered by invitation".
  - Fixed along the way: closing Manage club after losing access now refreshes in the right order (the router listens to the refresh signal, so the page closes first).
  - Tests: `test/officers_test.dart` (the explicit list, members/positions/About, another club and a plain member refused, posting, events and who can edit them, giving up your position, the Manage club button and the confirm step); the screen audit covers Nicolas's Manage club pages.
- **Photos moved from announcements to campus updates** (decided 2026-10-31). **Campus updates** now get the Add photos option (like School News); **announcements are text only**, in the form and in the service. Club posts keep their photos. The sample "Updated campus map" announcement no longer shows the map.
- **Start consultation after the first e-signature** (decided 2026-10-31). Uploading a signature from the New Consultation gate shows a **Start consultation** button that opens a fresh scanner page; Back from there returns to the Consultations list.
- **Consultations** (suggested by the professors, decided 2026-10-30). Teachers fill in a consultation form with a student, and both sign it with an e-signature.
  - **Michaelean Life › Consultations** (teachers with the new `holdConsultations` permission; Mark has it): your consultations, newest first. **+** starts one: the student **shows their QR** (mock scanner: sample QR buttons, no camera, nothing verifies identity), or you **find them by name**.
  - **The form:** header filled in for you (date and time, student name and section, masked ID), **paired Reason / Intervention rows** (add up to 5), and **Expected outcome**.
  - **Signatures:** everyone uploads a photo of their signature in **Settings › My e-signature**. A teacher **needs one to start a consultation**: without it, **+** shows "Add your e-signature before starting a consultation" with an **Add e-signature** button (decided 2026-10-31). Once it's uploaded there, a **Start consultation** button opens a fresh scanner page. The student's is added **when they scan their QR**, and only if they have one on file ("Nicolas needs to add an e-signature first" otherwise; the form stays unsigned). Found by name? The saved form shows **Scan QR to Sign**, and only that student's QR signs it.
  - **A form keeps the signatures it was made with,** through edits and later changes in Settings. Teachers may remove theirs; that only stops new consultations.
  - **Editing anytime;** a form changed after the student signed says "Edited after the student signed".
  - **Export to Excel:** downloads that one consultation as a filled-in sheet in SMCL navy, following the professors' layout, with both signature pictures (`lib/utils/consultation_excel.dart`). A simple design until the school's official template arrives. Marked as a preview, not an official record.
  - **Student Life › Consultations:** students read the ones held with them (no editing or export). Only that teacher and that student see a consultation.
  - New package **`excel_plus`** (MIT): writes .xlsx files with pictures, and downloads them in the browser. Its pictures are re-pinned by two corners (with **`archive`**, which came with excel_plus) because iPhone's Files preview put one-corner pictures at the top-left (fixed 2026-10-31); merged boxes keep their full borders.
  - Mock: no sample consultations (each needs real uploaded signatures); signatures and forms live in memory only.
  - Tests: `test/consultation_test.dart` (signing by scan and later, the wrong QR, editing after signing, who sees it, row checks, the Excel cells and pictures, the screens for both roles, uploading a signature); the screen audit covers the new pages.
- **Event covers are uploaded too** (decided 2026-10-30). In the event form (new or editing), the cover's button opens the same picker as posts (phone: gallery or camera; computer: file chooser) instead of the 4 sample covers. An **X** on the cover removes it. The event page, lists, and Michaelean Life show the uploaded cover. Kept in memory only, like post photos.
  - The gallery/camera menu is now one shared helper (`lib/widgets/photo_source.dart`) used by posts and events. The sample covers (`mockEventCovers`, `eventCovers`) are gone.
  - Tests: one more in `test/post_photos_test.dart` (add, remove, re-add, save, and the event page shows it).
- **Invite whole clubs and single students to an event** (decided 2026-10-30). An event's Invite page now has three tabs: **Sections** (yours, as before), **Clubs** (every school-wide club, all its members), and **Students** (search any sample student by name). Picks add up and each student counts once; the button says e.g. "Invite 6 Students".
  - **Eligible students only:** for a members-only event, others are greyed out with the reason ("Not a member of Dance Company"); a club or section counts only who can come ("6 members · 5 can be invited"). "Already going" students aren't counted. If the spots left don't cover everyone, nobody is invited and the page says how many spots are left.
  - Invited students are still registered automatically and can't decline, and now get a **bell notice** ("Mark Villanueva registered you for Department Assembly."), which opens the event. Preview only; nothing is really sent.
  - **Sample member lists** for SMCL Chorale (7), Dance Company (8), and Campus Ministry Volunteers (7), made from the sample class lists, so "all members" means exactly who's listed. Their member counts and officers now follow the lists (before: invented counts like 64). The Nursing Students Association has no sample students, so it isn't offered.
  - Service: `loadInviteOptions` and `invite(sections:, orgIds:, studentIds:)` replace `inviteSections`.
  - Tests: `test/invite_test.dart` (a section and a club counted once, a single student and their notice, members-only events, spots, the club lists, the page adding up a club and a student); older invite tests use the new call.
- **Posts can have photos** (decided 2026-10-30). Announcements, School News, and club posts get an **Add photos** button: up to **4 photos**, picked from the device. On a phone it asks **Choose from gallery** or **Take a photo**; on a computer it opens the file chooser. Each thumbnail has an **X** to remove it; **hold and drag** to change the order (the first is the cover). The post shows them in the swipeable carousel, and lists show the cover. Campus updates stay text only.
  - **Preview only:** photos are kept in the app's memory (`lib/services/photo_store.dart`), never sent anywhere, and gone when the app reloads, like the posts themselves. The form says so.
  - New package **`image_picker`** (by the Flutter team): opens the gallery or camera on phones and the file chooser on the web. Photos are shrunk to 1600 px wide on the device.
  - `PostImage` (`lib/widgets/post_image.dart`) shows a bundled photo or an uploaded one, so Home, lists, and the post page work with both. The 4 sample cover photos are gone from the form.
  - Not tested: the camera itself (only works on a real phone).
  - Tests: `test/post_photos_test.dart` (add from gallery and camera, remove, drag to reorder, the 4-photo limit, the post's carousel, campus updates without photos); one older test scrolls past the photos to the preview.
- **The bell now shows what's new on campus** (decided 2026-10-30). Instead of a hand-written list, the bell builds its notices from the posts and events themselves, from the **last 7 days**, for students and teachers:
  - new **announcements** ("New announcement: …"), **department news** for your department, and **club posts** for clubs you belong to ("Computer Science Society: …"). Urgent ones start with "Urgent:" and show even if that type is switched off.
  - **new events you can join** ("New event: Blood Donation Drive · Wed, 11 Nov"), which open the event page. Not events you manage or already registered for. Events now record when they were published (`postedAt`), including ones a teacher publishes in this preview.
  - **School News stays out** of the bell (it's on Home). The real DCS posts are older than 7 days, so they don't show either.
  - Every announcement made in this preview now notifies its audience, not only urgent ones. Never your own posts.
  - Settings › Notifications has a new **New events** switch; "School news" is now labelled **Department news**.
  - Fixed: the teacher notice "Department assembly moved" pointed to a post deleted earlier; it now opens the Department Assembly event.
  - Tests: `test/bell_test.dart` (what each role sees, the 7-day limit, members only, registered and managed events, a newly published event); three older tests use the new counts.
- **Department news now shows real posts too** (decided 2026-10-26). Four posts from the Computer Science Society's Facebook page (`assets/computer_science_society_posts.docx`) are posted as the **Department of Computer Studies**, for DCS students: Ma'am Aliza Lyca Gonzales-Lacson's MSCS, HUEFest 2026, the "LOOK" hackathon story (4 photos), and the DCS Innovation Contest (4 photos). They show in DCS students' Home feed, newest first.
  - They replace the three invented text-only department/society posts (thesis consultation hours, coding challenge registration, assembly moved). The urgent CSS venue change and the CS 302 room change stay, as the samples of urgent notices and schedule changes.
  - **Links** (the contest's Google Form and guide) show in navy like on Facebook but don't open anything in this preview.
  - Emoji, bold captions and the photo carousel work as for School News; this time the emoji showed correctly in Claude's browser pane. Dates are estimates from the events.
  - Photos are in `assets/images/dcs/`, declared one by one.
  - Tests: in `test/school_posts_test.dart` (the four posts, their audience and photos, the removed and kept samples, links in navy); two older tests now scroll by content instead of a fixed distance.

- **School News now shows SMCL's real posts** (decided 2026-10-26). The four invented School News stories are replaced by seven real posts from SMCL's official Facebook page, from `assets/school_posts.docx`: the Archangels volleyball team, the iACADEMY hackathon, the psychometricians' 100% passing rate, Michaelmas 2026, the Milagros L. Limaco paper presentation and its keynote speaker, and the PITLC delegation in Baguio. Posted as **Saint Michael's College of Laguna** with the emblem, newest first; the newest is Home's featured story. The hackathon post (**Michaelean Innovation and Excellence**) is dated 21 October so it's the featured one; Beyond the Cold took its 9 October date.
  - **Captions** keep the school's wording: Facebook's styled bold letters became plain letters shown in the app's bold font (`widgets/rich_caption.dart`), hashtags are navy, and the small emoji pictures in the document became real emoji. Titles drop their emoji.
  - **Several photos per post:** the two psychology posts (same caption, two graphics) are one post whose photos swipe sideways, with a "1/2" counter and dots (`widgets/photo_carousel.dart`, `Post.extraImages`).
  - **Times** everywhere: "Just now", "5m ago", "3h ago" or "1d ago" for about the last day, then the date ("16 October", with the year if it isn't this year).
  - The volleyball post's date is from the Facebook page; the others are estimates from their events (in `mock/mock_home.dart`).
  - Photos are in `assets/images/news/`, declared one by one. The conversion was done once by a script; to add more posts, edit `mock_home.dart`.
  - **Not verified:** emoji rely on Flutter downloading an emoji font from Google on first use; Claude's browser pane didn't download it, so emoji showed as boxes there. Check on a real phone.
  - Also fixed, found because today is a weekday: the teacher's "Start attendance" button in Michaelean Life overflowed with large text inside the new cards (now capped), and an events test now scrolls to its link.
  - Tests: `test/school_posts_test.dart` (time rules; the seven posts, newest first, every photo present and declared; bold and navy hashtags; swiping the psychology post's photos).

- **New look, step 5 of 5: everything else.** The rest of the app now follows direction B (spec §2.1): rows sit together in white cards on the soft page.
  - **List pages:** Events (each day in its own card under its date), Organizations, Classes (with class icon tiles), People and search, Privacy's blocked list, Clearance (requirements and past clearances), the class schedule and records, Event History, Going lists, class rosters and recent sessions, attendance review, registrations, the clearance desk, Manage club and Add member, and the grade table.
  - **Detail pages** keep their photo or cover as the hero; their action tiles and summary cards were already white. **Forms:** Edit Profile's school-set details are a card too. **Pop-ups** (Settings, Notifications) were checked: their white cards read on the white sheet thanks to the soft shadow.
  - **Fixes the new layout needed:** the Clearance progress bars' empty part was white (invisible on a white card), now track grey; roster and attendance-review rows cap the masked ID's width, so with large text on a small phone it shrinks instead of overflowing (the audit caught it).
  - This finishes the five-step new look.
  - Tests: `test/surfaces_test.dart` (Events, Organizations, Clearance and Grades rows sit in cards).

- **New look, step 4 of 5: Student Life, Michaelean Life and Profile.** All three main tabs now open on the navy hero.
  - **Student Life:** the title and subtitle in white, with this semester's **Grades card hanging over the navy's edge**. The card now names itself ("Grades ›") instead of sitting under a separate Grades heading; tapping it opens the Grades page. While loading, a plain white card holds its place.
  - **Michaelean Life (teachers):** the same hero ("Teaching & Campus"), without a card over it, since teachers have no grades.
  - **Profile:** "Profile" and the Settings button on the navy, with your **photo in a white ring hanging half over its edge**; the name and everything below follow as before.
  - Tests: `test/home_hero_test.dart` checks the Profile photo straddling the navy's edge with Settings on it; `test/life_hub_test.dart` checks the Grades card straddling the edge above Class.

- **New look, step 3 of 5: Home.** Home opens on the **navy hero**: emblem, wordmark and bell, then the greeting and date in white, with the **stats card hanging over the navy's bottom edge** (students: attendance and clearance; teachers: today at a glance). Once the greeting has scrolled away, a **compact navy bar** stays pinned at the top (photo, greeting, date, bell).
  - **Up next** is now a white card with a thin red accent bar and a red `UP NEXT` label, since the header is Home's one navy hero (spec §2.2). The date chip is navy on a soft navy tint; Start attendance is the usual navy button.
  - **Icon tiles:** text-only rows (Pending Tasks, Today's Classes, Schedule & Room Changes, Announcements) get a small navy tile on the left, e.g. a checklist for clearance tasks. Shared: `ContentRow(icon: …)`.
  - Shared tweaks: `TwoToneDate` can lighten its "/ Sunday" part on navy; `Pressable` cards clip their content to the rounded corners.
  - Tests: `test/home_hero_test.dart` (the hero from the very top, white greeting, the stats straddling the navy's edge, the red label, icon tiles, the compact bar appearing and leaving, the teacher's stats). `test/back_navigation_test.dart` now scrolls only when an item isn't already tappable, since scrolling a stat to the very top puts it under the pinned bar.

- **New look, step 2 of 5: the shared navy hero header** (`widgets/navy_hero.dart`). Deep navy from the very top of the screen (behind the phone's status bar), a faint red glow from the emblem's red in the top-right corner, rounded bottom corners, and white text and icons inside by default. An optional card can hang 36 px over its bottom edge (Home's stats, in step 3). Not on any screen yet: Home gets it in step 3, Student Life, Michaelean Life and Profile in step 4.
  - Tests: `test/navy_hero_test.dart` (navy reaches behind the status bar while the text starts below it; the glow; white text; the overlap hangs exactly 36 px; no overflow with large text on a small phone).

- **New look, step 1 of 5: foundation (direction B, "Navy hero").** Decided 2026-10-25 and recorded in `docs/spec.md` §2: navy hero headers on the main tabs (steps 2–4), a soft blue-grey page with white cards, and red for attention plus a few small accents. Replaces the old "no coloured header" and "rows, not cards" rules.
  - **New colours** (`theme/app_theme.dart`): `page` `#F4F5F9` (screen background), `track` `#E9EBF1` (controls on the page: unselected chips, day pills, the switch track, loading boxes, neutral pills), `trackText` `#5A5C66` (grey text on track; the usual grey is only 4.1:1 there), and `cardShadow` (an even softer shadow under white cards).
  - **White cards:** the stats tile, Clearance and Grades cards, the GWA card, event action tiles, session and clearance summaries, "unavailable" boxes and Settings' grouped lists. Section lists on Home, Student Life, Profile, a student's profile, a club and Manage club now sit together in one white card (`widgets/surface_card.dart`).
  - **Inputs** are white with a thin outline, so they show on the page and on white pop-ups; tappable form fields (date and time pickers) match.
  - **Browser:** the top bar is navy (`theme-color`), and the installed app's splash uses the page colour.
  - **Fixes the new layout needed:** club rows' request pill is capped so it can't push past a small screen with large text (the audit caught it).
  - **Not yet:** Events, People, Classes and the other list pages still have rows straight on the page; they get cards in step 5.
  - Tests: `test/theme_contrast_test.dart` checks that every text and background pair in the theme meets 4.5:1 (the screen audit checks tap targets, not contrast).

- **Grades use SMCL's grading scale; Grades moves to the top of Student Life.** Decided 2026-10-25 (spec §7.6).
  - **SMCL's scale** (99–100 → 1.00 Excellent … 75–77 → 3.00 Barely Passing, 70–74 → 4.00 Conditional Fail, below 70 → 5.00 Failed) lives once in `models/grades.dart` (`smclScale`, `gradePointFor`). The US 4.00 GPA column of SMCL's table isn't shown.
  - **Each course average** shows its grade point under it (90 over 1.75). A 4.00 gets an amber `Conditional fail` tag, a 5.00 the red `Failed` tag.
  - **The GWA** is now worked out from the grade points (the registrar's way): it's the big number on the card (e.g. **2.26**), with the percentage average smaller beside it (85.76%). By units: each point × its units, ÷ the total units.
  - **The pop-up** shows each step as `90 → 1.75 × 3 = 5.25`, the result (`38.50 ÷ 17 units = 2.26`), the percentage by the same method, and SMCL's scale for reference. With large text, the lines wrap instead of running off the screen (the audit caught this).
  - **Student Life:** Grades is now the first section, above Class; its card shows the GWA and the percentage.
  - **Sample data:** CS 203 (71) is now a 4.00 conditional fail, and MATH 202 in 2nd Sem 25–26 became 66 / 68 → 67, a 5.00, so both tags show.
  - Tests: `test/grades_test.dart` checks every boundary of the scale and the grade-point GWA (38.50 ÷ 17 = 2.26; simple 2.21); the page, pop-up and Student Life tests use the new numbers and check the order of the sections.

- **Grades, step 4 of 4: the Grades section in Student Life.** Student Life now ends with a **Grades** section (after Clearance): a grey card with this semester's name and overall average (GWA) so far, which grades are out ("Midterms out · 1 of 5 finals"), and what the number means ("Overall average so far (GWA), from 1 of 5 courses"). Tapping the card or `See all` opens the Grades page. Teachers' Michaelean Life has no Grades section (spec §7.6: nothing for teachers yet).
  - In `screens/shared/life_hub_screen.dart` (`_GradesTile`); the hub now also loads grades for students.
  - Tests: in `test/life_hub_test.dart` (the card's numbers, opening the page, no section for teachers). `test/people_screens_test.dart` now scrolls to the Connect button itself instead of a fixed distance, since the page got longer.
  - This finishes the grades feature (spec §7.6).

- **Grades, step 3 of 4: how the average is counted.** Tapping the overall average (it now has a › arrow, once there is an average) opens a pop-up, "How your average is counted", for that semester:
  - A switch: **By units (GWA)** (the default; "courses with more units count more") or **Simple average** ("every course counts the same").
  - Every step of the sum from the averages shown on the page: by units, `90 × 3 … 270` per course, the total (1458, 17 units) and `1458 ÷ 17 units = 85.76`; simple, the averages, `518 ÷ 6 courses = 86.33`.
  - Courses not counted yet are listed ("Not counted yet (a grade isn't out): CS 302, …").
  - A router page (`/life/grades/average?sem=N`), like the other pop-ups, so Back closes it; it reloads the grades by semester number, so it also works after a browser reload. In `screens/student/grades_screen.dart` (`AverageSheet`).
  - Tests: in `test/grades_screen_test.dart` (the full working for a past semester both ways, closing it, and this semester's "not counted yet"); the screen audit covers the pop-up.

- **Grades, step 2 of 4: the Grades page** (`/life/grades`, `screens/student/grades_screen.dart`). Semester chips at the top (short names like "1st Sem 25–26"; they scroll sideways as semesters pile up), the overall average by units (GWA) in a grey card ("Based on 1 of 5 courses · 3 units" while finals are still coming), then the table: Course · Units · Midterm · Final · Average.
  - A grade not out yet shows "—"; grades below 75 are red and a failed course gets a red `Failed` tag. Numbers use equal-width digits so the columns line up; with large text, cells shrink to fit instead of overflowing.
  - Screen readers hear one row at a time ("CS 203, 3 units, midterm 72, final 70, average 71, failed").
  - Labelled "Sample grades, not official records". Teachers see "No grades to show."
  - **Shared widget:** `FilterChips` (`widgets/filter_chips.dart`), moved out of Discover so both pages use the same chips.
  - Not yet: tapping the average (step 3) and the Student Life section that opens this page (step 4). For now the page is reached by its address.
  - Tests: `test/grades_screen_test.dart` (this semester with "—"s and 94.00; a past semester with 85.76, red grades and Failed; the row read aloud; the heading lines up; teachers); the screen audit covers the page for both roles.

- **Grades, step 1 of 4: decisions and data.** The grades feature is decided and recorded in `docs/spec.md` §7.6: students see their own grades (course code, units, midterm, final, average) in Student Life › Grades; whole-number grades, passing 75; course average rounded; an overall average to 2 decimals that explains itself (by units or simple); current and past semesters; only the student sees them. Nothing on screen yet.
  - **Model:** `models/grades.dart`: `CourseGrade` (its `average` waits for both grades; `failed` below 75) and `SemesterGrades` (`overall(byUnits | simple)`, counting only finished courses, from the averages as shown).
  - **Sample data:** `mock/mock_grades.dart`, labelled as invented. This semester matches the student's timetable (midterms out; only GE 104's final so far); two complete past semesters, one with a failed course. Semester names follow the school year (June–May).
  - **Service:** `CampusService.loadGrades(student)`, newest semester first; teachers get none.
  - Tests: `test/grades_test.dart` (rounding, waiting for both grades, the 75 line, 1458 ÷ 17 = 85.76 by units and 86.33 simple, the sample semesters).

- **More animations, step 5 of 5: Home's stats count up.** The numbers on Home's stats (94%, 3, 3/7, …) **count up from 0** the first time they show (300 ms). Only the first number in a stat counts ("0/7" → "3/7"). A reload with the same numbers doesn't replay it; a number that changes eases from the old value to the new one. Digits are equal-width, so the number doesn't wobble while counting. Screen readers hear the final number. Instant with reduce motion. In `widgets/stats_row.dart`. Tests: `test/stats_count_test.dart`.
  - This finishes the five-step animation plan (nav bar, press feedback, shimmer, page slide, count-up).

- **Fix: a way back on days without classes.** On the student Class page, the "Today" button (back to today after scrolling the day strip) never showed on Sundays, since Sunday has no classes and isn't in the strip. Now, on a day without classes, the button names the next class day ("Monday") and jumps there, the same day the page opens on. On class days it still says "Today". `test/class_test.dart` checks whichever applies on the day it runs (it used to fail on Sundays).

- **More animations, step 4 of 5: pages slide in from the right.** Every page you open now slides in from the right (the page underneath shifts slightly left) and slides back out on Back, the same on Android and iPhone. Before, Android and the web used a fade, and only iPhone slid. You can also swipe from the left edge to go back. With reduce motion, pages simply appear.
  - **How:** the theme's page transition (`SlidePageTransitions` in `theme/app_theme.dart`) uses the iOS slide on every platform. Pop-up sheets keep their own slide-up.
  - Tests: `test/page_slide_test.dart` (a new page is partway in, then in place, on Android; reduce motion shows it at once).

- **More animations, step 3 of 5: loading shimmer.** The grey placeholder boxes shown while Home and the Life hub load now have a **soft band of light sweeping across them** (one pass every 1.2 s), so the page reads as "loading", not "stuck". The sweep runs across all the boxes together and stops as soon as the page has loaded. With reduce motion the boxes stay still.
  - **Shared widget:** `LoadingBoxes` (`widgets/loading_boxes.dart`), which replaces the two copies of the box code in Home and the Life hub.
  - **Not changed:** other pages show a thin progress bar while loading, which already moves.
  - Tests: `test/loading_boxes_test.dart` (the light keeps sweeping while loading and stops after; reduce motion keeps the boxes still).

- **More animations, step 2 of 5: press feedback.** Tappable cards and rows now **shrink slightly (to 97%) while pressed** and spring back when you let go, on top of the usual ripple.
  - **Shared widget:** `Pressable` (`widgets/pressable.dart`), used instead of `InkWell` for cards and rows. It follows the ripple's own pressed state, so starting to scroll a list doesn't shrink the row under your finger, and disabled rows don't react. Cards with a fill (Up Next, the Clearance and office tiles, the event action tiles) shrink as a whole, background included. No shrink with reduce motion.
  - **Where:** every shared row (content, person, organization, settings rows), Home's stats, Up Next and featured post, Life hub cards and class rows, event action tiles and the Going faces row, notifications, clearance items, roster, registrations, the clearance desk and Manage club members.
  - **Not used** on small controls that already show a selected state (filter chips, the class day picker) or on form fields.
  - Tests: `test/pressable_test.dart` (shrinks while pressed and still taps; scrolling doesn't shrink; disabled doesn't react; reduce motion keeps the size).

- **More animations, step 1 of 5: the nav bar.** The grey pill behind the selected tab now **glides** to the tab you tap (250 ms), and that tab's icon gives a **tiny bounce** (it grows to 115% and settles back). Before, the pill only faded from one tab to the other, and it ignored "reduce motion"; now both are instant with reduce motion. No bounce on the first load. In `widgets/floating_nav_bar.dart`. Tests: `test/nav_bar_test.dart` (midway the pill is between the tabs and the icon is larger; settled, both are back to normal; reduce motion is instant).
  - **Planned next** (decided 2026-10-24): press feedback on cards and rows, a loading shimmer, pages sliding in from the right, and Home's numbers counting up.
- **Fix: person-row buttons sit at the right edge again.** Connect, Cancel, and the ✕/✓ on requests sat near the middle of the row since the Connect feature: the button area shared the row 50/50 with the name. Now the name takes the space and the button is only capped in width (so large text still can't push it off screen). Affects every person list (Profile's Connections, People, Going, Privacy's blocked list). Test: `test/person_row_test.dart`.

- **Back returns where you tapped.** Before, Home's shortcuts (like *Classes today*) switched to the Michaelean Life tab, so Back stayed there. Now a page opened from Home or Profile **opens inside that tab**: the tab stays highlighted and Back walks back to where you were, step by step. The Michaelean Life tab keeps its own pages, untouched.
  - **Covered:** Home's stats, Up Next, Today's Classes, Pending Tasks, and notifications from the bell; Profile's Classes I Teach and Event History. Links inside those pages (a class's student, an event's Going list, …) stay in the same tab.
  - **New page:** *Event attendance* and *Events completed* on Home open an **Event History** page in Home (the same list as on Profile).
  - **How:** `lib/utils/tab_path.dart` lists which Michaelean Life pages Home and Profile also have (`tabCopies`). `router.dart` builds those pages once and adds them to each tab, and `inTab()` turns a `/life/...` link into the same page in the current tab. Profile's event pages moved from `/profile/event/…` to `/profile/events/…`, like the other tabs.
  - **Still switches tabs:** a notice that opens Profile itself, and the Life-only pages (club management, clearance desk).
  - Tests: `test/back_navigation_test.dart` (Back from Home's shortcuts and Profile's classes returns to them, the tab stays highlighted, Michaelean Life keeps its own pages); the screen audit covers the new Home and Profile pages.

- **Animations, step 4 of 4: small state changes.** Controls that change their state no longer flip at once (200 ms, instant with reduce motion):
  - **Buttons crossfade** to their new state: Connect → Pending (in lists and on a student's profile, where the full-width button stays full width), Register → Registering… → Registered on an event.
  - **The bell's red dot** shrinks and fades away when everything is read, and grows back when something new arrives.
  - **Unread dots** in the notifications sheet fade out when a notice is opened.
  - **Shared widget:** `StateFade` (in `widgets/fade_switch.dart`), a crossfade that runs whenever the state it's given changes.
  - Tests: `test/state_fade_test.dart` (a button crossfades and keeps its width; reduce motion is instant; the bell's dot is midway while shrinking, then gone, then back).

- **Animations, step 3 of 4: list changes.** When an action changes a list, rows no longer jump: a row that's gone **fades and folds away** while the rows below slide up, and a new row **fades and unfolds in** (250 ms).
  - **Shared widget:** `AnimatedRows` (`widgets/animated_rows.dart`). It compares each new version of a list with the last one, matching rows by their key (a student's id), keeps leaving rows long enough to fold them away, and puts them where they were. Nothing animates on the first build (the page fade covers that), and nothing at all with reduce motion. A row that comes back while leaving simply stays.
  - **Used on:** Profile (requests, connections, sent: accepting a request folds it out of Requests while it fades into Connections), Manage club (members, also when filtering by search, and requests), Privacy's blocked students, Student Life's People suggestions and the People page (someone you asked folds away and the next suggestion fades in), and Add member's results (someone you added folds away).
  - **Not used** where rows only change their label (the Going list's Pending/Connected) — that's step 4.
  - Tests: `test/animated_rows_test.dart` (a row folds away and the list shrinks by exactly one row and divider; a new row fades in between its neighbours; no animation on the first build; a returning row stays; reduce motion is instant) and, on Profile, accepting a request shows the student leaving Requests and arriving in Connections at the same time.

- **Animations, step 2 of 4: tab fade and loading fade.**
  - **Switching tabs:** the new tab fades in (200 ms) instead of snapping; the bottom bar stays put (`AppShell`).
  - **Loading → content:** placeholders and progress bars fade into the content (250 ms) instead of swapping at once, using one shared widget, `FadeSwitch` (`widgets/fade_switch.dart`), and `fadeOnLoad` for FutureBuilder builders. It fades only when loading finishes; a reload after an action updates the content in place.
  - **Covered:** Home, Student/Michaelean Life, Profile, the notifications pop-up, Events, an event, Going, People, a profile, Privacy, Help, Class, Clearance and a requirement, Organizations and a club page, Classes and a class, Clearance Verification, Manage club, Add member, and event registrations.
  - **Not covered (still swap at once):** forms and short review pages that show a progress bar for a moment: post page, attendance review, clearance case, edit club info, the event, post, and invite forms, and change session.
  - **Side effect, on purpose:** Home, Student/Michaelean Life, and Profile now build all their sections at once (so the whole page can fade in together) instead of only the ones near the screen. They're short pages, so it doesn't slow them down noticeably. Several tests now scroll a row clear of the bottom bar before tapping, or look only inside the notifications pop-up.
  - Tests: `test/animations_test.dart`: midway through, both loading and content are there; a reload doesn't fade; reduce motion makes it instant; switching tabs fades the tab in.

- **Animations, step 1 of 4: tab re-tap** (decided 2026-10-24: quick and subtle, 200–300 ms ease-out per spec §2.5, and the phone's "reduce motion" setting is respected).
  - **Tapping the tab you're on again** (Home, Student/Michaelean Life, Profile): deeper inside the tab, it goes **back to the tab's first page** with the normal Back animation (it used to jump there instantly). On the first page, it **glides back to the top** (300 ms). From far down it first jumps to one screen from the top, then glides the rest, so it never drags.
  - **How:** `AppShell` pops the tab's own navigator, or tells the page through `TabReselect` (`widgets/tab_reselect.dart`); each tab's first page wraps its list in `ScrollToTopOnTabTap`. `scrollToTop()` does the glide.
  - **`AppMotion.of(context, duration)`** (theme): the duration, or none when the phone's reduce-motion setting is on. Every animation from now on uses it.
  - Tests: `test/tab_reselect_test.dart`: the glide is still moving one frame in (so it isn't a jump) and ends at the top; on an inner page the first tap goes back and the second goes to the top; Life and Profile too; with reduce motion it's at the top on the very next frame.
  - Coming next (steps 2–4): a fade when switching tabs and when content finishes loading, rows that fade and fold away after actions, and small state changes (buttons, the bell's dot, unread dots).

- **Advisers see their clubs' members-only events** (decided 2026-10-24). A club's adviser now counts as a member for that club's members-only events, so Mark can open the CSS General Assembly, see it in Events, and see who's going. It's one rule (`_eligible` in `CampusService`), so every event list and page follows it. Advising still isn't membership otherwise (no Member badge, no member tag). Recorded in spec §7.4. Test in `clubs_test.dart`.

- **Connect, step 4 of 4: Going lists and teacher entry points** (spec §10.1). Connect is now complete.
  - **Event pages:** the placeholder "Attendees" section (blank circles, "names for managers only") is replaced by **Going**: up to four photos and a sentence like "You, Carlo and 239 others are going", connections first. Tapping it opens the full list (`screens/shared/going_screen.dart`, `/life/events/<id>/going` and `/profile/event/<id>/going`): each person with Connect, Pending, Asked you, or Connected, and at the end how many aren't named and why (their privacy settings, or sample registrations without names). Managers keep a **Registrations ›** link for their tools.
  - **After the event** it becomes **Went**, built from attendance records (registration isn't attendance), and follows each person's Event history setting.
  - **The rule** (`CampusService.loadEventAttendees`): only people whose setting lets the viewer see them are named; everyone else, including blocked students and unnamed sample registrations, is counted. Teachers see everyone named. The viewer shows as "You".
  - **Teachers open any student's full profile** by tapping them in: a class's roster, attendance review (the profile opens over the review, `/attendance/<session>/review/people/<id>`), an event's registrations, and Manage club's members and requests. Michaelean Life has a **People** section that opens the search. `EventRegistrant` gained an `id` for this.
  - Fixes found by the tests: an "else" that attached to the wrong "if" (upcoming events listed nobody), and a Going list that overflowed on a small phone with large text ("Wants to connect" is now "Asked you", and row buttons can shrink).
  - Tests: 5 more service tests (who is named and counted, Only me, teachers, Went, blocking, the summary sentence) and 5 more screen tests (the event's Going line and list, Went, teachers opening students from a class and from Manage club, the teacher People section). The screen audit covers the Going pages and the profile over attendance review.

- **Connect, step 3 of 4: finding people and privacy** (spec §10.1).
  - **Student Life › People:** up to three "people you may know", each with a **Connect** button; **See all ›** opens **People** (`screens/shared/people_screen.dart`, `/life/people`): search students by name. With no search, students see suggestions and teachers see all students (view only, no buttons). Someone you just asked leaves the suggestions.
  - **Club Members tab** (spec §7.4): club pages with a member list (CSS, Robotics) gain a **Members (n)** tab; tapping a member opens their profile, with Connect where it applies. Blocked students are left out. `OrganizationPage.members` carries the list.
  - **Settings › Privacy** (students only, `screens/shared/privacy_screen.dart`, `/profile/privacy`): Upcoming events, Event history, and Connections, each **Public / Connections / Only me**, saved as soon as you choose (put back with a message if saving fails). Below: **Blocked students** with **Unblock**. It says name, photo, section, tags, and About are always shown.
  - Shared: `connectAction` in `widgets/person_row.dart`: the Connect button (or Pending, Wants to connect, Connected) for any list of people, and the honest "Request sent to … in this preview only." message.
  - Tests: 6 more in `test/people_screens_test.dart` (Connect from Student Life; search; teachers browse view-only; club Members tab; Privacy saving and unblocking; no Privacy row for teachers). The screen audit covers People and Privacy. Three older tests now scroll past the new People section and the club's sixth tab.

- **Connect, step 2 of 4: profiles and connecting** (spec §10.1).
  - **Other students' profiles** (`screens/shared/person_screen.dart`, routes `/life/people/<id>` and `/profile/people/<id>`, so Back stays in the tab you came from). The same layout as Profile: photo, name, section, masked ID, connections and mutual counts, tags, About, Mutual Connections, **Going To**, **Event History**, and **Connections**. Each of the last three shows only if their privacy settings allow it; otherwise it says "Hidden by <name>'s privacy settings."
  - **Buttons by where you stand:** **Connect** → **Pending · Cancel request**; when they asked you, **Accept** / **Decline**; when connected, a quiet **Connected**. The **⋯** menu has **Remove connection** and **Block** (each asks first). A blocked profile shows the name only, with **Unblock**. Every message says it's this preview only, and that declining or removing isn't told to the other person.
  - **Teachers** see every section, whatever the settings, with no Connect buttons or menu.
  - **Your Profile** (students) now has a **Connections** section above Event History: **Requests** with Accept (✓) and Decline (×), your connections, and **Sent** requests with Cancel. Tapping anyone opens their profile.
  - **Bell:** "… wants to connect." opens Profile; "… accepted your request to connect." opens their profile.
  - New shared widget: `widgets/person_row.dart` (photo, name, section, mutual count, optional button), reused later by search and Going lists. `tagTone` moved to a shared function in `profile_screen.dart`, so both profiles color tags the same.
  - Tests: `test/people_screens_test.dart` (accept from Profile; a connection's and a stranger's view; Connect → Pending; block and unblock; teacher view; the bell's accepted notice). The screen audit covers three profile pages. Two older tests now scroll past the Connections section to reach Event History.

- **Connect, step 1 of 4: data and privacy rules** (decided 2026-10-24, spec §10.1). Students will connect with students like LinkedIn's Connect: a mutual connection by request and acceptance. This step builds everything underneath; the screens come in steps 2–4.
  - **Decisions recorded** in `docs/spec.md` (new §10.1 Connect; club page tabs gain **Members**, §7.4; visibility rules, §12) and in CLAUDE.md, which closes open decision 4.
  - **Privacy settings** per student (`models/people.dart`): Upcoming events, Event history, and Connections list, each **Public / Connections / Only me**, default Connections.
  - **One visibility rule** (`_mayView` in `CampusService`): the student sees everything of their own; **every teacher sees everything** (decided); a block hides each from the other; otherwise Public shows to all, Connections to connections, Only me to no one. A blocked profile shows the name only. Members-only events stay hidden from people who can't see them.
  - **Actions** in `CampusService`: `loadPerson`, `loadConnections`, `searchPeople`, `loadSuggestions` (mutual connections, then same section, then shared clubs; up to 6), `sendConnectRequest` (connects at once if they already asked), `cancelConnectRequest`, `answerConnectRequest` (declining is silent), `removeConnection` (silent), `blockStudent` / `unblockStudent` / `loadBlocked`, `loadPrivacy` / `savePrivacy`, `loadConnectNotices`. Only students connect; teachers get "Only students connect with each other."
  - **Bell:** a new notification type, **Connections** (with its own switch in Settings › Notifications). Waiting requests show as "Bea Villareal wants to connect."; accepting tells the sender.
  - **Sample data** (`lib/mock/mock_people.dart`): the 35 students from the sample class lists are the people. Nicolas starts with 4 connections (Andrea, Carlo, Erika, Diego), 2 requests to answer (Bea, Aira), and 1 sent (Alyssa). Several students have different privacy settings, sample event history, and upcoming registrations, so every case can be tried. Where sample people now register by name (ev1, ev3, ev5), the anonymous counts were lowered by the same number, so every event's total is unchanged.
  - The screens for this arrived in step 2 (above).
  - Tests: `test/people_test.dart` (20): every viewer case (connection, Only me, stranger, Public, teacher, self, members-only events), mutual connections, each action and its refusals, blocking both ways, search, suggestions, privacy saving, unchanged event totals, and the bell notices. Tests counting unread notifications now include the two requests.

- **Teachers get role tags** (feature refinement). A teacher's tags now show what the school assigned them, as a new tag kind, **Role** (green pill; "Assigned role" in Personal Information):
  - **`<Club> Adviser`** for each club they advise, e.g. `[Computer Science Society Adviser]` `[SMCL Robotics Club Adviser]`.
  - **`<Office> Clearance Staff`** when they process clearance, e.g. `[Department of Computer Studies Clearance Staff]`.
  - They're built from the assignments each time a preview account loads (`CampusService.withAffiliations`, renamed from `withMemberships`), so they follow any change. Like all tags, they're labels: permissions still come from `Permission` and assignments, never from a tag.
  - Classes taught and event managing don't get tags (decided: Profile already lists Classes I Teach).
  - Tests: Mark gets exactly these three tags and no duplicates, students get none, and his Profile shows them. The screen audit now loads real tags, so long ones are checked on a small phone.

- **Club advisers can manage their clubs** (feature refinement, decided 2026-10-23). This changes spec §7.4, which said administrators manage memberships.
  - **Who:** a teacher **assigned** as a club's adviser (`Organization.adviserIds`), not anyone labeled Teacher. Mark advises the **Computer Science Society** and a new sample **SMCL Robotics Club** (`org6`).
  - **Michaelean Life › Clubs You Advise** lists them with how many students are waiting. Tapping one opens **Manage club** (`/life/clubs/<id>`, `screens/teacher/club_manage_screen.dart`) with tabs:
    - **Members:** search, **Add member** (searches the sample students; `club_add_member_screen.dart`), a menu per member to **Set position** (President, Vice President, Secretary, Treasurer, Auditor, PRO, or none) or **Remove from club** (asks first, optional reason), and **Copy list** (names, positions, sections, masked IDs).
    - **Requests:** students who tapped "Request to Join", oldest first, with **Accept** / **Decline** (optional reason).
    - **Posts:** **New club post** reuses the post form in club mode: posted *as the club*, to **its members** or **everyone**, with Urgent (notifies who can see it). Edit and delete from the post page.
    - **Events:** **New club event** reuses the event form; the club is the host, members-only by default.
    - **Info:** About and the meeting schedule, edited in `club_info_screen.dart`.
  - **Students:** accepting or adding someone makes them a member right away (Member badge, My Organizations, members-only posts and events). Removing undoes it. They get a bell notice ("Your request to join … was accepted", "…declined. Reason: …", "You were added to / removed from …"), in this preview only. An officer position also adds an "<Club> Officer" tag.
  - **How membership works now:** clubs with an adviser have a member list (`mockClubMembers`, `mockJoinRequests` in `mock_campus.dart`; names come from the sample class rosters). It's the source of truth for those clubs; a student's organization tags are rebuilt from it when their preview account loads (`CampusService.withMemberships`, called by `MockUserService(campus: …)`). Clubs without an adviser still use tags. The officers on a club page now come from member positions plus the adviser.
  - Every adviser action is checked in the service: anyone who doesn't advise that club gets "You don't advise this club."
  - Tests: `test/clubs_test.dart` (who advises what; only the adviser can act; accept, decline with reason, remove, positions and officer tags, add and search, club info, members-only and urgent club posts, club events; the screens for listing, accepting, removing, adding, and a student seeing the decision). The screen audit covers all the new pages.

- **Urgent announcements notify students** (feature refinement). When a teacher posts an announcement marked **Urgent**, everyone who can see it (everyone, the department, or the class, but not the author) gets it in their **bell**, titled `Urgent: <title>`, unread and shown even if they switched announcements off. Only urgent announcements notify; other posts just appear on Home.
  - **Editing** the post updates the notification (`Updated: <title>`) and makes it **unread again**. Switching Urgent off or **deleting** the post removes it.
  - It's built from the posts in `MockHomeService.loadNotifications`; each edit gives the notification a new id, which is how it becomes unread again. Nothing is really sent: the form, the confirmation, and the post page say the notification exists in this preview only.
  - To try it: post an urgent announcement as Mark, then Settings → Preview as **Student**, and open the bell.
  - Tests: a student's bell shows a teacher's urgent post and opens it; a service test covers the audience, the author, edit (unread again), Urgent off, and delete.

- **Teachers can post from Home** (feature refinement, decided 2026-10-23). A navy **+ button** (a floating action button) sits bottom-right on Home, above the bottom bar:
  - **Who sees it:** users with the new `Permission.postToCampusFeed` (Mark has it in `mock_users.dart`). Students never see it. The service refuses posts from anyone without it, so hiding the button isn't the only check.
  - **Tapping it** opens a *speed dial* (`screens/teacher/create_menu.dart`): the page dims, the + turns into an ×, and three options fan out: **Announcement**, **School News**, **Campus update**. Back, the ×, or a tap on the dimmed page closes it. It's a router page (`/home/create`), like the other pop-ups, so the Android/browser Back gesture works.
  - **The form** (`screens/teacher/post_form_screen.dart`, `/home/compose/<kind>`): title, message, **who sees it** (everyone at SMCL, your department, or one of your classes; School News always goes to everyone), an **urgent** switch for announcements (shown first with an `URGENT` label), and a sample **cover photo** for School News. A live **preview** shows the row as it will appear on Home. Posting says "Posted in this preview only. Not sent to anyone."
  - **Who receives it:** a department post only shows for people with that department tag; a class post only for students in that class (and the teacher). The author always sees their own posts.
  - **Your own posts:** the post page shows "Posted to: …", the preview-only note, and **Edit** (`/home/post/<id>/edit`, then marked **Edited**) and **Delete** (asks first). Sample posts can't be edited.
  - **Model and service:** `Post` gained `authorId`, `classId`, `sentTo`, `edited`, and `PostKind.campusUpdate`. `HomeService` gained `savePost`, `deletePost`, and `postCovers`. Posts live in memory and reset on reload.
  - **Also decided that day** (recorded in `CLAUDE.md`): teachers edit only their own classes, change one class meeting at a time, and all teachers can see event attendee lists. The last one isn't built yet; today only the event's manager can open its registrations.
  - Tests: `test/campus_posts_test.dart` (no + for students; menu opens and Back closes it; post an urgent class announcement; edit and delete; who sees which post and who may post). The screen audit covers the menu and the three forms.

- **Unread notifications** (feature refinement). The bell's red dot now means "you have unread notifications", not just "there are notifications":
  - Each notification is **unread** (bold title, small red dot on its row) or **read**. Opening one marks it read; **Mark all as read** at the top of the pop-up marks the rest. When nothing is unread, the bell has no dot and its label is plain "Notifications" (otherwise e.g. "Notifications, 2 unread" for screen readers).
  - Read state is **saved on this device, per user** (`notify.read.<userId>` in `services/notification_prefs.dart`), so it survives reloads. If storage is blocked, it stays read until the page is reloaded.
  - Types switched off in Settings don't count toward the dot; urgent ones always do. Changing a switch refreshes the dot.
  - Sample start state: today's notifications are unread, yesterday's recap (`m4`) starts read (`read: true` in `mock_home.dart`).
  - `HomeService` gained `markNotificationsRead` and `countUnread`; `HomeFeed.notifications` was removed (the bell asks the service instead).
  - Tests: `test/flutter_test_config.dart` gives every test a fresh, empty fake device storage (with the one-time QR tip already seen). New test: the dot clears as notifications are read, and stays cleared after reopening the app.

- **Settings pages** (spec §11). Every Settings item now opens a real page (routes under `/profile/…`):
  - **Personal Information** (`personal_info_screen.dart`): read-only name, role, program/faculty, **masked** ID, school email, and official tags, marked as coming from school records ("contact the Registrar to correct"). The two sample accounts got clearly fake emails (`@smcl.example`).
  - **Account & Security** (`account_security_screen.dart`): an honest status page: Microsoft 365 sign-in, **not connected in this preview**, the current preview session, and what the QR holds, with **Show my QR**. Passwords and two-step verification belong to Microsoft 365.
  - **Notifications** (`notification_settings_screen.dart`): a switch per type (Announcements, School news, Organizations, Schedule changes, Attendance, Clearance), **saved on this device** (`services/notification_prefs.dart`). Switched-off types are hidden from the bell; **urgent ones always show**; the bell says how many are hidden, with a **Change** link. If storage is slow or blocked, the app waits at most 2 seconds and treats everything as on. No real notifications are sent.
  - **Help & Support** (`help_screen.dart`): five short FAQ answers (QR, class attendance, registration vs attendance, clearance statuses, "preview only") and sample office contacts (`mockSupportContacts`, through `CampusService.loadSupportContacts`).
  - **About Michaelean** (`about_screen.dart`): emblem, version 0.1.0 · Prototype, what the app is, its prototype status, and **Open-source licenses** (Flutter's license page). The Inter font license is now bundled and registered in `main.dart`, as its license requires.
  - New shared `widgets/inset_list.dart` (`InsetGroup`, `InsetRow`, `InsetField`), taken from the Settings sheet. The Profile tab's "Coming soon" route was removed; only Home keeps one as a safety fallback.
  - Tests: one per page, the bell filter with an urgent exception, and the screen audit now covers all five pages.
- **Event history and event check-in.**
  - **Event History opens the event page.** Each record now links to its event (`eventId`); the sample history's events were added as past events (Git seminar, Start-up pitching talk, Iris dataset workshop, Web development bootcamp). The page shows **"Your record: Attended · Participant"** and the first button reads Attended (or Ended) instead of a disabled Register. Opened from Profile, it stays in the Profile tab (`/profile/event/:eventId`).
  - **One source of event history.** History moved from `UserService` to `CampusService.loadEventHistory`, so Profile, Home, My events, and check-in agree. My events' Past list includes recorded events with an `Attended` pill; "registered but no attendance recorded" is said plainly.
  - **Home's event stats are counted:** Events completed = records; Event attendance % = recorded ÷ past events you registered for or attended (the sample student: 3 of 4 = 75 %). The fixed sample numbers were removed.
  - **Event check-in for managers** (`screens/teacher/event_checkin_screen.dart`, `/life/events/:eventId/checkin`, from the event's More › Take attendance): mock scanner like the class one; only registered students are marked; a repeat counts once; open from 30 minutes before the start until the end (with the "Open anyway" preview tool). **Finalize** adds an Attended · Participant record to each scanned student's Event History, in this preview only. The manager's event page shows "Attendance finalized · N attended".
  - **Share** copies the event's name, date, time, and venue as text ("Event details copied."). No link yet, since the app isn't online.
  - Tests: history → event with record, check-in rules and finalize, counted Home stats, Share; the screen audit now also visits the check-in screen and history event pages.
- **Rebuild Phase 10: Frontend testing.**
  - New `test/screens_audit_test.dart`: every screen of both roles on a small phone with large text, against the tap-target and label guidelines, and with failing services.
  - Fixed everything it found (see Phase 10 above): 48 px segmented pills, scrolling sign-in and scanner, seven large-text overflows, the scanner's unhandled load error, and honest "Couldn't load" messages on four forms and the post page.
  - Home stats, tasks, and notifications now open real screens.
  - The midnight-dependent notifications test now uses a fixed clock.
  - `web/manifest.json` and `web/index.html`: name Michaelean, SMCL colors, description; new icons and favicon from the emblem.
- **Rebuild Phase 9: Clearance.**
  - New screens: student Clearance, requirement detail, staff Clearance Verification (with a mock QR scanner), and Verify Requirement.
  - `CampusService` gained `loadClearanceView`, `markSubmitted`, `loadClearanceDesk`, `findStudentByQr`, `loadClearanceCase`, and `recordOutcome`; `loadClearance` and `loadClearanceOffice` are now counted from the requirements.
  - Models: `ClearanceStatus`, `ClearanceItem`, `ClearancePeriod`, `PastClearance`, `ClearanceView`, `ClearanceStudent`, `ClearanceCase`, `ClearanceDesk`.
  - Mock data: eight sample requirements with every status, past clearances, pending department items for a few roster students; **Mark now has `processClearance`** for the department (mock assumption, chosen by the group owner).
  - Home: the "Cleared" stat and clearance tasks come from the clearance data; tasks open the requirement.
  - Shared `clearance_widgets.dart` (status pill, office icon, Clearance Unavailable). Every hub `See all` now opens a real screen, so the hub's "Coming soon" route was removed.
  - Tests: submitting never clears, scans only find students, office-only processing, reason required, counts update; widget tests for the student resubmit flow and the staff scan → outcome → confirmation flow.
- **Rebuild Phase 8: Organizations.**
  - New screens: Organizations directory (three groups) and the tabbed organization page (About, Schedule, Events, News, Officers).
  - `CampusService` gained `loadOrganizationDirectory`, `loadOrganization`, and `requestToJoin`; organization news comes from the same mock posts as Home.
  - Models: `Organization` has kind (society/club), department, cover, About, meetings (`OrgMeeting`), and officers (`OrgOfficer`); new `OrgDirectory` and `OrganizationPage`.
  - New shared `OrgRow` widget (moved out of the hub).
  - Links wired: Student Life's Organizations `See all` and organization rows.
  - Tests: directory groups (no other department's society among clubs), members-only events and posts, other departments' societies hidden, join request never makes a member; widget tests for the directory, the tabs, event → Back → organization, and the honest join request.
- **Rebuild Phase 7: Events.**
  - New screens: Events list (both roles), event detail, Create/Edit Event, Invite Students, Registrations.
  - `CampusService` gained `loadEvents` (Discover / My events / managed), `loadEvent`, `register`, `cancelRegistration`, `saveEvent`, `cancelEvent`, `loadRegistrations`, `inviteSections`, and `eventCovers`. Events and registrations live in memory in `MockCampusService`.
  - Models: `CampusEvent` has end time, description, deadline, capacity, an update note, and a `cancelled` status; new `EventDetail`, `EventList`, `EventRegistrant`, and the shared `eventFormProblem` validator (used by the form and the service).
  - Links wired: the hubs' Events `See all` and event rows, and Home's teacher "Upcoming events" stat.
  - Theme: bottom sheets, dialogs, and date/time pickers are plain white instead of Material's navy-tinted default.
  - Fixed while testing: the audience dropdown overflowed on phones; the start/end time fields wrapped; the event page went blank while reloading after Register.
  - Tests: registration rules (duplicate, closed, full, ineligible), My events order, drafts → publish → edit keeps one event and marks time changes, managers only, service-side validation, section invitations, cancelling; widget tests for discover → filter → register → My events, a full event, create → publish → invite, and refusing to edit someone else's event.
- **Class screen: semester view.** Order is now Attendance (overall + by subject, whole semester) → Schedule (day strip scrolls through the whole semester, with a Today button) → Records of the selected day. New `CampusService.loadSemester` and `mockSemester` (placed around today); attendance records now cover the semester. (A calendar-heatmap version was tried and removed.)
- **Rebuild Phase 6: Class and attendance.**
  - New screens: student Class (day strip, schedule, attendance), teacher Classes list, class page, mock attendance scanner, review & finalize, change one session.
  - Weekly timetable and rosters replace the old "today and tomorrow" class mock (`mock/mock_classes.dart`); new models in `models/attendance.dart`.
  - `CampusService` gained schedule, class page, attendance records, scanning (with the §7.2 rules), finalizing, and single-session changes; Home reads classes and class attendance from it, so everything agrees.
  - `Session.refresh()` / `dataKey`: screens reload after shared data changes.
  - Links wired: Home's Start attendance, class stats, finalize task, and class rows; the hubs' `See all` and class rows; Profile's Classes I Teach.
  - Fixed while testing: finalizing reopened the review screen (the refresh ran before the screens closed). Tests now check that closed screens are really gone.
  - New `BackHeader` widget; date helpers `weekdayShort` and `formatMinutesRange`.
  - Tests: attendance rules, finalization and records, permissions, class page, single-session changes, Home task removal, plus widget tests for the Class screen, the full scan → review → finalize flow, and the session form.
- **Rebuild Phase 5: Profile and Settings.**
  - Profile rebuilt in Luma's layout; inline stats are counted from records; Classes I Teach for teachers; QR coin removed.
  - New Edit Profile page (About only; honest "preview only" confirmation; locked school fields).
  - Settings rebuilt as grouped inset lists with a **Student / Teacher preview switch**.
  - Fixed: Home and the hub kept the previous user's data after a role change; they now reload when the account changes.
  - Mock data: masked IDs in the spec's format (`2023-****-21`, `2015-****-93`); the mock teacher has one event recorded as **host**.
  - `Session.update` (for Edit Profile) and `UserProfile.withAbout`; theme text-field and disabled-button styles.
  - Tests: profile identity and stats for both roles, no QR on Profile, Edit Profile save rules, Settings items, and a role switch that refreshes Home, hub, and Profile.
- **Stopped sharing `CLAUDE.md`** in the repo (it's in `.gitignore` and stays on the owner's computer).
- **Removed the Skip button from the opening intro.** The intro is about 2.4 seconds and moves on to sign-in by itself. Spec §1.1 updated to match.
- **Rebuild Phase 4: Student Life and Michaelean Life hubs.**
  - Hubs rebuilt to spec §7/§9 as live previews with `See all ›`: classes, an events photo strip, organizations, and clearance progress for students; classes with Start attendance, events you manage (with drafts), and clearance for teachers.
  - New `CampusService` + `MockCampusService` and models in `models/campus.dart` (`CampusEvent`, `Organization`, `ClearanceSummary`, `ClearanceOffice`); sample data in `mock/mock_campus.dart`.
  - Mock data: sample upcoming events (CSS events use the society's cover image; others use a placeholder tile), three organizations, a 1st Semester Clearance period. The mock student is now also a member of the invented `SMCL Chorale` (a labeled mock assumption).
  - `SectionHeader` can show a `See all ›` link (read by screen readers as "See all <section>").
  - `MichaeleanApp` now takes a `campusService` too.
  - The events strip grows with the phone's text size instead of overflowing.
  - Tests: hub previews for both roles, eligibility (no events for clubs you're not in, no drafts for students), managed events and drafts, organizations from tags, clearance and permission lock, hub error state.
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
    shared/          screens both roles use (opening, sign-in preview, Home, hubs, Events, event detail,
                     Profile, sheets)
    student/         student-only screens (Class, Organizations, organization page, Clearance,
                     clearance requirement)
    teacher/         teacher-only screens (Classes, class page, scanner, review, change session,
                     event form, invite students, event registrations, clearance verification)
  models/            plain data classes: UserProfile, IdentityTag, Permission, feed items,
                     EventRecord, campus data (CampusEvent, Organization, clearance)
  mock/              CLEARLY LABELED sample data (mock_users.dart, mock_home.dart, mock_campus.dart,
                     mock_classes.dart)
  services/          interfaces that return mock data now, real data later
                     (UserService, HomeService, CampusService) + Session (who is being previewed)
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
CLAUDE.md            working rules for Claude Code (AI assistant); kept locally, not in git (.gitignore)
.claude/launch.json  config that lets Claude Code preview the web build
```

### How data flows

Screens never read mock data directly. They ask a **service** (e.g. `HomeService.loadHome(user)`), and `MockHomeService` / `MockUserService` / `MockCampusService` return sample data from `lib/mock/`. Later, a real implementation (Microsoft 365 + school records) can replace the mock service **without changing the screens**.

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
| `SectionHeader` | Section title with consistent spacing; optional `See all ›` link |
| `SegmentedPills` | Pill segmented control (Student/Teacher, Discover/My events, …) |
| `AppSheetPage` | Rounded bottom sheet as a router page: grab handle, round X, dimmed background, Back closes it |
| `FloatingNavBar` | The floating pill bottom navigation |
| `RoundIconButton` | Floating white circle button (bell, back), optional red dot (the bell: unread notifications) |
| `UserAvatar` | Round photo or initials |
| `StatsRow` | Compact row of tappable stats with navy numbers (Home) |
| `UpNextCard` | Solid navy "Up next" class card, optional Start attendance button, empty state |
| `BackHeader` | Top of a pushed page: round back button, title, optional action (e.g. `Show QR`) |
| `InsetGroup`, `InsetRow`, `InsetField` | Luma's grouped rounded lists (Settings and its pages): tappable rows and read-only label/value rows |

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

264 tests currently pass, at any time of day. They cover:

- **Navigation:** student and teacher previews land on the right Home and tabs; Log Out returns to sign-in without replaying the intro; the intro has no Skip button and moves on by itself; a reload at a saved address still plays the intro first.
- **Home:** the stats row shows and a stat opens its detail; Up next for students (with the teacher's name, no attendance button) and teachers (Start attendance, today's classes); notifications sheet opens and closes (X and system Back), groups Today / Earlier, and a notification opens its post; long-press opens the QR sheet and Back closes it; the tip shows only once and sits above the nav bar; a load failure shows Retry (never fake content).
- **Home data:** the student sees their department/society posts only, urgent posts first, the student's own next class with its teacher, the teacher's classes for today only, teacher sections, the attendance task appears only for an unfinalized session, next-class logic, no post in two sections.
- **Hubs:** Student Life shows class, events, organizations, and clearance previews, and `See all` opens its page with Back; Michaelean Life shows classes, managed events with drafts, and the teacher's clearance office; a load failure shows Retry.
- **Class and attendance:** an enrolled scan is Present once and a repeat counts once; unknown or other-section codes aren't marked; scans before the start or after the end are rejected (the preview tool skips only the clock); finalizing closes the session and only finalized sessions count; teachers manage only their assigned classes; class page roster and recent sessions; single-session changes are validated and move only that session; finalizing removes Home's task; the Class screen's day strip and Show QR; the full scan → review → finalize flow (scanner and review really close); the session form's validation and honest confirmation; another teacher's class is refused.
- **Events:** registering works once and never for full, closed, or ineligible events; My events lists upcoming then past registrations; a draft is hidden from students, publishing and editing keep one event and mark time changes; only managers edit, see names, invite, or cancel; the service re-checks form rules; inviting a section registers its students; a cancelled event leaves Discover but stays in My events. Widget tests: discover → My Orgs filter → register → My events; a full event can't be registered; create → publish → invite a section → registration count; editing someone else's event is refused.
- **Screen audit (Phase 10):** all 34 screens of both roles fit a 320 × 568 phone at 130 % text with no layout errors; every tappable thing is at least 48 × 48 px and labeled; with failing services every screen shows a "Couldn't load…" message instead of crashing or spinning forever.
- **Clearance:** progress counts skip Not applicable; submitting only sends for review; a QR scan only finds the student; staff process only their office's requirements and must give a reason unless Cleared; widget tests for the student resubmit flow and the staff scan → outcome → confirmation flow.
- **Organizations:** directory groups (another department's society is never a school-wide club), members-only events and posts hidden from non-members, other departments' societies unavailable, a join request never makes a member; widget tests for the directory, tabs, event → Back → organization, and the join request.
- **Campus data:** students see only published events they're eligible for, soonest first; managed events are only the teacher's own (drafts included, none without permission); organizations come from membership tags; clearance per user; no clearance office without permission.
- **Event history and check-in:** each history record opens its event (even one the user can't see in Discover) with "Your record"; check-in marks only registered students, counts a repeat once, respects the event's hours (preview tool aside), and finalizing adds Attended records to Event History exactly once; Home's event stats are counted from records; Share copies the event details.
- **Clubs:** only a club's adviser can manage it; accepting, declining, adding, and removing update membership, tags, and the student's bell; officer positions show on the club page; club posts reach members only when chosen.
- **Campus posts:** urgent announcements reach only their audience's bell, come back unread after an edit, and disappear when deleted or no longer urgent; only permitted users get the + button; the menu opens and Back closes it; posting is honest and shows on Home; you can edit and delete only your own posts; department and class posts reach only their audience.
- **Settings pages:** Personal Information is read-only with the ID masked; Account & Security says nothing is connected and opens the QR; switching a notification type off hides it from the bell while urgent ones stay; Help answers questions and lists offices; About shows the version and the licenses page.
- **Profile:** identity, masked ID, counted stats, tags, and event history for students; Classes I Teach and hosted count for teachers; no QR on Profile; Edit Profile enables Save only after a change and confirms "preview only"; Settings items, Back closes it, Log Out ends the preview; switching role in Settings refreshes Home, the hub, and Profile.

When you rebuild a screen, update its tests and add tests for new logic, especially permissions, status rules, and "no fake success" behavior.

---

## Open decisions

Don't silently invent answers to these. Ask the group (or the school) and record the decision in `docs/spec.md`.

1. ~~Class editing scope.~~ **Decided 2026-10-23:** teachers edit only their own assigned classes (for now).
2. Is departmental society membership automatic or application-based?
3. ~~Single sessions or schedules.~~ **Decided 2026-10-23:** one class meeting at a time (for now). Which changes need approval or notification is still open.
4. ~~Visibility of event histories and attendee lists.~~ **Decided 2026-10-24** with Connect (spec §10.1): each student chooses Public / Connections / Only me; Going lists name only who the viewer may see and count the rest; every teacher sees everything.
5. Which student/faculty info comes from the Microsoft directory vs. another official source?
6. Backend, database, and authorization architecture (later).
7. Which free hosting service, and the Flutter web/PWA configuration.
8. Exact meaning of clearance statuses **Action required** vs **Needs correction** (proposed in spec §7.5: first-time task vs. returned by staff with a reason).

---

## Known issues and things to know

- **The Luma reference screenshots are not in the repo.** The spec points to `assets/images/luma_screens/` as the visual reference, but that folder is git-ignored (third-party images, kept locally). **Ask the repo owner for a copy**, or look up Luma's iOS app screens on Mobbin. Keep them out of git and never declare them in `pubspec.yaml`.
- **`assets/videos/app_opening.mp4` is a recording of Luma's app** (its logo and slogan). It is **not used** and not declared in `pubspec.yaml`. The animated emblem intro stands in until there is a real SMCL opening video. To use a real video later: replace the file, add the video back to `pubspec.yaml`, run `flutter pub add video_player`, and switch `opening_screen.dart` to play it. Browsers block autoplay with sound, so play it muted.
- **Profile photos in `assets/images/profiles/` are of real people.** Use them only with their consent, and only as clearly labeled sample data. Event posters in `assets/images/events/` are placeholders too. The spec wants stock or real SMCL photos listed in one place in mock data so they are easy to swap.
- **PWA name, colors, and icons are set** (Michaelean, navy/white, icons from the SMCL emblem in `web/icons/` and `web/favicon.png`). Hosting is still open decision 7. To remake the icons after changing the emblem, center the whole emblem on white (about 86 % of the square; 66 % for the maskable ones).
- **Changing the profile photo isn't built.** It needs a file-picker package; Edit Profile says so instead of showing a button that does nothing.
- **Event covers are placeholders.** CSS events reuse the society's cover image; other events show a navy-tint tile. The form's cover picker offers the bundled photos (`mockEventCovers` in `lib/mock/mock_campus.dart`). Replace them with real SMCL event photos when the group has them; a real photo upload needs a file-picker package.
- **Posts made with the + button reset on reload**, like event changes. So do club changes (members, requests, positions, info).
- **Member counts changed for the two advised clubs.** CSS showed "248 members" from a made-up number; it now counts its sample member list (9). Other clubs still show their sample counts.
- **Event changes reset on reload.** Registrations, new events, edits, invitations, and cancellations live in memory for this preview only.
- **The first-time QR tip covers the + button** for its 8 seconds on a teacher's very first visit. Close the tip, or wait.
- **A snackbar can briefly cover the bottom button** of the next form (for example, right after Publish, on Invite Students). It goes away after about 4 seconds.
- **Long-press needs a real hold.** Hold the mouse button (or your finger) on Student Life / Michaelean Life for about half a second. Automated widget tests cover it.
- **On narrow phones the quick-QR tip wraps to two lines.** It's readable; shorten the wording if the group prefers one line.
- **Git warnings "LF will be replaced by CRLF"** on Windows are harmless.
- **`docs/CLAUDE.original.md` and `docs/plans/`** are historical. `docs/spec.md` is the source of truth.

---

## How to continue the work

1. **Pull the latest `main`**, then run `flutter pub get`, `flutter analyze`, and `flutter test`. They should all be clean before you start.
2. **Pick the next phase** from the [progress table](#rebuild-plan-and-progress) (all prototype phases are done; Phase 11 only when the group decides). Agree in the group who does what. Work on **one phase at a time** and avoid two people editing the same files at once.
3. **Work on a branch**, e.g. `git checkout -b phase-3-home`.
4. **Read the spec sections** for that phase, plus §2 (design) and §12 (permissions and privacy).
5. **Build it**, reusing the shared widgets and theme tokens. Keep mock data in `lib/mock/` and go through the services.
6. **Check it:** `flutter analyze` clean, `flutter test` passing, and click through it in Chrome at phone size, for **both** roles.
7. **Update this README:** mark the phase done in the table and add a line to [Recent changes](#recent-changes).
8. **Merge into `main`** after someone in the group has looked at it.

