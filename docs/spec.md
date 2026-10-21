# Michaelean — Product Spec

This is the detailed product specification for Michaelean. `CLAUDE.md` holds the working rules; this file holds what to build.

Read the section for the feature you are working on before building it. Do not implement the whole spec at once.

Institution (used in mock data and identity tags): **Saint Michael's College of Laguna** (short form: SMCL).

Revised 2026-10-21 after a full design review with the user. The rebuild follows §13.

## 1. Application Structure

Michaelean is one app with two role-specific experiences sharing one design system.

### 1.1 Start flow

1. **Opening video** (`assets/videos/app_opening.mp4`) is the first thing shown when the app opens. It is short and has no Skip button (decided 2026-10-21); it moves on to sign-in by itself.
2. **Sign-in preview screen:** SMCL emblem, a `Sign in with Microsoft (preview)` button, and a choice of Student preview or Teacher preview. Clearly labeled as a preview, never real authentication (§4).
3. **Home.**

### 1.2 Bottom navigation

Student: `Home | Student Life | Profile`

Teacher: `Home | Michaelean Life | Profile`

- Home is the initial destination after sign-in.
- Student Life and Michaelean Life are feature hubs, not landing screens.
- Bottom tabs keep their state.
- Reuse shared components; adapt content and actions to the role. No duplicated student/teacher screens.
- The development role switch lives in the Settings pop-up (§11) and on the sign-in preview screen. It is never a security mechanism.

### 1.3 Quick QR (long-press)

Long-pressing the second tab (Student Life / Michaelean Life) opens the user's QR sheet, for both roles.

- The first time the app is used, show a one-time hint: `Tip: hold Student Life to show your QR` (or `Michaelean Life` for teachers).
- Students can also open the same QR from `Show QR` in Class (§7.1). There is no QR on Profile.
- The QR sheet shows a scan-friendly code and `Show this code to your teacher.` (students) or a neutral identity line (teachers).
- QR content is a random mock token per mock account (for example `MOCK-7F3K9Q`), never a real name, student/staff ID, or email. One token per account, used everywhere.
- Showing the QR never verifies identity or attendance.

## 2. Design System

The goal: a **premium** mobile app in the spirit of Luma, with Michaelean's own SMCL identity.

Premium comes from four things, in this order:

1. **Real imagery.** Every event, news item, and organization has a real photo or logo. Photos carry most of the color.
2. **Typography.** Large, confident titles, clear hierarchy, generous spacing.
3. **Motion.** Smooth, purposeful transitions (§2.5).
4. **Depth.** Layers that feel physical: soft, large-blur shadows, elements floating above the page, sheets rising over dimmed content. Glass/blur is **not** required.

Screens must feel **full, not thin**. Not crowded, but rich:

- **Rich rows:** each item shows a photo or thumbnail, the source's avatar and name, time, place, tags, and a status pill when relevant, not only a title.
- **More sections** where they add real content (for example School News and the campus feed on Home).
- **4–5 items per section** before `See all ›`, not 2–3.

Also required: consistent spacing and radii, touch targets ≥ 48 × 48 px, safe-area and keyboard handling, responsive layouts across phone sizes, and loading, empty, unavailable, and error states.

Avoid: card grids, rows of metric chips as decoration, gradient headers, floating action buttons, corporate admin layouts, nonfunctional controls.

**Light mode only** for now. Dark mode comes later; the theme file keeps it possible.

### 2.1 Visual Direction

**Reference:** Luma iOS screenshots in `assets/images/luma_screens/` (from Mobbin). Follow Luma closely in layout and feel, but never copy its wordmark, icons, or branding. Michaelean uses the SMCL emblem and school colors.

Not a reference: `luma_screens/image 3.png` (an earlier Michaelean concept with a gradient header and metric chips).

What Michaelean takes from Luma:

- **Rows, not cards.** Rounded square thumbnail on the left; source avatar + name; title; meta lines with icons (clock, pin). Hairlines between rows. A small status pill overlapping the thumbnail.
- **Two-tone date headers:** `24 October` in ink, `/ Friday` in muted gray.
- **Floating chrome.** Header with emblem + `Michaelean` wordmark on the left and the bell in a soft white pill on the right. Floating rounded pill bottom navigation, active tab in a filled pill. Floating circular back button.
- **Detail pages.** Large rounded cover image, big title, date line, a row of tonal action buttons, then sections introduced by small muted labels over a hairline. On scroll, the title moves into a compact pill beside the back button. A light wash from the cover at the top of the page fades into white.
- **Profiles.** Large photo, left-aligned name, inline stats, sections reusing the same rows. Settings as grouped, rounded inset lists.
- **Pop-ups.** Rounded bottom sheets with a grab handle, round X, dimmed background, outside-tap and Back to close.
- **Forms.** Borderless, light-gray, fully rounded inputs with muted labels above. One full-width pill button at the bottom; disabled state is plain gray.
- **Segmented controls** as pills. **Filter pills** that change color when active.
- **Empty states:** outline icon in gray, short title, one muted sentence.

### 2.2 Color

School colors from the SMCL emblem, in deeper, calmer shades. Navy is used **confidently**; red only for attention.

| Token | Hex | Use |
|---|---|---|
| `navy` | `#242A5E` | The one bold color: primary buttons, active tab, links, stat numbers, selected states, identity tags, and the solid navy **Up next** card (white text) on Home. |
| `red` | `#B3242E` | Attention only: `URGENT`, notification dot, Needs correction. One per screen region at most. |
| `white` | `#FFFFFF` | Screen background, surfaces, sheets, pills. |
| `ink` | `#16171D` | Primary text. |
| `muted` | `#6E7079` | Secondary text, meta, date suffix. |
| `hairline` | `#ECECEE` | Dividers, indented to the text column in thumbnail lists. |
| `fill` | `#F3F3F4` | Soft gray tiles, inputs, active nav pill, placeholders. |

Rule of thumb: **one navy hero per screen**; everything else stays white/gray and lets photos supply color.

Status tints (soft background + darker text): green for Cleared/Attended/Present, amber for In review/On hold/Full, navy for Invited/Registered, red for Needs correction/Cancelled/Absent, gray for Not started/Not applicable. Check WCAG AA contrast.

### 2.3 Typography

Luma uses Apple's SF Pro, which can't be bundled for Android. Michaelean uses its closest free equivalent:

- **Inter Display** for large titles: screen titles, the Up next class, event names on detail pages, the School News hero headline, profile name. Tight letter spacing.
- **Inter** for all other text (body, meta, buttons, labels).

Both are free (OFL) and bundled as asset files so they work offline. Inter is already in `assets/fonts/`; Inter Display files are added in Phase 1. No serif.

### 2.4 Shape, spacing, depth

- 4-point spacing scale; 20 px screen margins; 24–32 px between sections.
- Radius: 12 for thumbnails and small elements; 20 for cover images, sheets, modals, and the Up next card; full pill for buttons, inputs, tags, and the nav bar.
- Depth: soft, large-blur, low-opacity shadows on floating elements (header pill, nav bar, back button, Up next card, sheets). Layers should read clearly: page → floating chrome → sheets.

### 2.5 Motion

200–300 ms, ease-out:

- Sheets slide/spring up over a dimming background.
- A list image expands into the event detail cover.
- The Home header collapses smoothly on scroll.
- Tab and page transitions are smooth, never abrupt.
- The scan flash on the attendance camera (§9.1).

### 2.6 Imagery

- Real SMCL photos, posters, and logos come from the user.
- Until then, use **stock photos** as clearly labeled placeholders, listed in one place (mock data) so they are easy to swap.
- Declare every image file by file in `pubspec.yaml`.

### 2.7 Logo and brand assets

- **Main logo:** `assets/images/SMCL_Emblem.png`. Used in the header, on the sign-in preview screen, and as the source for the PWA home-screen icon.
- The emblem is detailed and hard to read at very small sizes. A simplified small mark may be needed later; don't invent one without asking.
- Don't recolor, stretch, crop, or add effects to the emblem.

## 3. Scope and Mock Data

The current phase is a frontend prototype.

Use clearly identified mock data. Keep sample records separate from widgets and presentation logic. Define simple models and service interfaces that can later connect to real data.

Do not:

- Implement a real backend or database.
- Implement live Microsoft 365 authentication.
- Pretend mock data represents official school records.
- Claim a simulated operation changed a real record.
- Claim a mock QR verified a real person's identity.
- Display fabricated success messages for attendance, registration, publishing, or clearance.
- Hardcode assumptions that prevent later integration.

A frontend interaction may demonstrate the intended workflow, but its prototype status must remain clear.

## 4. Authentication and Institutional Identity

The institution manages Microsoft 365 accounts for students and teachers.

Intended production flow:

1. Authenticate through the institution's Microsoft tenant.
2. Verify the account belongs to the approved institution.
3. Match the account's stable identifier to an authorized student or faculty record.
4. Retrieve verified academic or faculty information.
5. Assign the appropriate identity tags and permissions.
6. Open Home.

Microsoft authentication alone does not guarantee access to every academic attribute. Missing information must come from an authorized institutional data source.

Do not implement this integration during the frontend phase. The sign-in preview screen (§1.1) only demonstrates the flow and lets the user pick a mock student or teacher profile.

## 5. Institutional Hierarchy and Tags

Institution
  └── School/College
       └── Department/Program

Organization memberships and assigned roles are additional identity tags.

Schools/colleges: **SON**, **SBMIT**, **SEAS**.

Every student and teacher receives institution and school/college labels. Additional labels may include department or program, confirmed organization membership, official organization officer role, and other authorized institutional roles.

Example:

`[Saint Michael's College of Laguna] [SBMIT] [Department of Computer Studies] [Dance Company] [Dance Company Officer]`

These are illustrative labels, not fixed mappings.

Rules:

- All assigned tags are visible to students and teachers using Michaelean.
- Tags are readable, compact, and responsive.
- Users cannot assign themselves academic, membership, or officer labels.
- Membership labels reflect confirmed memberships; officer labels reflect authorized role assignments.
- A department is distinct from its student society.
- Departmental society membership is not assumed automatic; the policy is undecided.
- Tags do not grant permissions by themselves.

## 6. Student Home

Purpose: "what's next for me today", then what's happening on campus. A continuously scrolling page.

Order, top to bottom:

1. **Header:** emblem + wordmark, a brief personalized greeting, current date, bell pill.
2. **Stats row:** one compact row of four, always visible (not expandable): Class attendance %, Event attendance %, Events completed, Requirements progress (for example `3/6 cleared`). Each stat taps through to its detail (class attendance, event history, clearance).
3. **Up next:** a solid navy card with the next class: subject, time, room, teacher. If no more classes today, show the next future class.
4. **Pending tasks:** actionable items only, such as clearance corrections or outstanding event requirements.
5. **Announcements:** compact layout.
6. **School News:** one large hero story with a photo, then 2–3 smaller rows.
7. **Campus feed:** a mixed, continuously scrolling stream of department, organization, and event updates (for example "Event moved to 3 PM"). Urgent organization posts get an `URGENT` label and are pinned to the top of the feed.

On scroll, the detailed header (date, stats) collapses; the greeting and bell stay accessible.

Rules:

- Personalize using the mock student's affiliations and confirmed memberships.
- Don't duplicate content across sections.
- No events discovery or "registered events" section on Home; that lives in Student Life.

**Notifications:** the bell opens a tall bottom sheet grouped by `Today / Earlier`. Each item has an icon or avatar, one line, and a time. Tapping navigates to the related screen without modifying any record. Back, X, and outside tap close it.

## 7. Student Life

Purpose: the student's feature hub for browsing campus services.

Title: `Student Life`. Subtitle: `Your campus, beyond the classroom.`

Layout: **live previews**. Each feature shows a real peek at its content, with `See all ›`:

- **Class:** next class and today's schedule.
- **Events:** a horizontal strip of upcoming events with photos.
- **Organizations:** the student's organizations (logos).
- **Clearance:** progress, or `Clearance Unavailable`.

The hub is for browsing; Home is for today and alerts. They don't repeat each other.

### 7.1 Class

- `Show QR` button at the top (opens the shared QR sheet, §1.3).
- **Day strip:** Mon–Sat pills, today selected. Below it, that day's classes as rows: subject, teacher, start–end time, room.
- **Attendance:** overall %, a % per subject, and recent records (Present / Absent per session).

### 7.2 Attendance Rules

The intended production workflow requires an authorized teacher to scan the student's QR against the official enrolled roster and an active session.

- Valid enrolled students may be marked Present.
- Unknown or unenrolled students must not be marked present.
- Reject scans before the session starts or after it closes.
- Duplicate scans do not count twice.
- Late arrivals count as Present; there is no separate Late category.
- Unscanned students remain unchecked until the teacher finishes the session.
- The teacher reviews the roster and confirms finalization.
- Network or save failures must not create false success states.
- Attendance percentages use finalized official records only.

### 7.3 Events

- Segmented control: **Discover | My events**. My events shows registered events, then past ones.
- On Discover: filter pills **All / School-wide / Department / My Orgs**, events grouped under two-tone date headers as photo rows.
- Show only events the user is eligible for. Deduplicate events matching multiple filters.

**Event detail** (Luma style): large cover photo, title, date and time, a row of action buttons (Register, Share, More), then labeled sections: **Venue** (with map), **Host**, **Attendees** (overlapping avatar stack, for example `+42`, with roles where allowed), **About**. Registration deadline and capacity when applicable.

Rules:

- Prevent duplicate registrations.
- Don't confirm registration for full, closed, or ineligible events.
- Registration is not attendance or completion. Only official attendance confirmation counts toward history and metrics.
- Leaving an organization hides member-exclusive events from discovery but preserves registrations and history.
- Authorized teachers can invite eligible students. Teacher invitations register recipients automatically, without accept/decline. Cancellations notify affected students.
- Attendee visibility follows the eventual privacy rules (open decision).

### 7.4 Organizations

**Directory**, three groups:

- The student's departmental society, where applicable.
- Approved school-wide clubs.
- My Organizations (confirmed memberships).

Each entry shows logo, name, and member count. Don't treat a department as its society, and don't list other departments' societies as school-wide clubs.

**Organization page:** cover photo, logo, name, tags, and membership status (Member / Join), then **tabs**: About, Schedule, Events, News, Officers.

- The Events tab lists the organization's events; tapping one opens the shared event detail, with Back preserved.
- Only authorized officers can publish or manage organization content. Administrators manage memberships and officer assignments. When an officer role ends, management permissions are revoked but historical posts remain.

### 7.5 Clearance

Clearance types are seasonal: Semester, Graduation, Document request, other configured categories.

**During an active period:**

- Top: period name (for example `1st Semester Clearance`), deadline, and a big progress bar or ring (`3 / 6 cleared`).
- One row per requirement: office icon, office name (Library, Accounting, …), status pill.
- Tapping a row opens its detail: what to do, the reason if returned, and a resubmit path.
- Bottom: **Past clearances**.

**Outside a period:** a calm `Clearance Unavailable` empty state. Processing is locked; history stays visible below.

Statuses: Not started, Action required, In review, Needs correction, Cleared, On hold, Not applicable.

Action required means the student has something to do for the first time. Needs correction means staff reviewed a submission and returned it with a reason. (Proposed definition — confirm.)

Not applicable differs from Not started. Overdue does not automatically mean rejected or cleared. Evidence is required only when specified.

Authorized staff scan the student's QR, review the records or documents, and explicitly record an outcome. A QR scan or evidence upload never approves clearance automatically. Staff process only requirements they are authorized to manage.

## 8. Teacher Home

Same layout and components as Student Home (§6), with teacher content:

1. **Header:** emblem + wordmark, greeting, date, bell pill.
2. **Stats row:** compact, always visible: Classes today, Sessions awaiting finalization, Upcoming events.
3. **Up next:** solid navy card with the next class (subject, time, room) and a **Start attendance** button. If no more classes today, the next future class or an empty state.
4. **Pending tasks:** finalize an attendance session, review a schedule change, other authorized teaching tasks. Only show pending attendance when a session genuinely needs teacher action; a scheduled class alone is not a task.
5. **Today's classes.**
6. **Announcements**, **School News**, event notices, and schedule or classroom changes, in the same feed style as students.

Header collapses on scroll as on Student Home. No publishing button on Home; management lives in Michaelean Life.

## 9. Michaelean Life

Purpose: the teacher's feature hub. Section heading: `Teaching & Campus`.

Layout: **live previews**, the same pattern as Student Life, with `See all ›`:

- **Classes:** today's classes, each with a Start attendance button.
- **Events you manage:** upcoming and drafts, as photo rows.
- **Clearance:** the teacher's assigned office and its pending count, or `Clearance Unavailable`.

### 9.1 Class Management

Access to: assigned classes, today's classes and schedule, class details, student roster, attendance scanning, review and finalization, schedule and room editing, recent sessions.

**Attendance scan flow:**

1. Tap **Start attendance** (from Home, the hub, or a class).
2. **Full-screen camera view** (mock), with a live counter at the bottom: `Present 18 · Unchecked 7`.
3. Each scan briefly flashes the student's photo and name, then the camera is ready again.
4. **Finish** opens the roster review: unchecked students listed.
5. **Confirm finalization.**

Mock scanning is clearly labeled and never represented as real verification or a saved official record. The scanner is only reached through Start attendance; it is not on the long-press shortcut.

Schedule editing may include date or recurrence, start/end times, room, optional reason, and Save Changes. The scope of teacher editing permissions remains undecided; don't assume all teachers can edit all classes. Distinguish single-session from recurring changes if both are supported.

### 9.2 Events Management

Provide: Upcoming, Past, Drafts, Create Event, Manage Event, Edit Event, Invite Students, View Registrations, Cancel Event.

**Create / Edit Event:** one scrolling page in Luma's form style:

- Cover photo picker at the top.
- Name, date, start/end time, venue, audience, deadline, optional capacity, description, as soft gray rounded fields.
- **Save draft** and **Publish** at the bottom.

Rules:

- Draft and publish are distinct frontend states.
- Invitations may target individuals, classes/sections, eligible departments, or other explicitly supported groups.
- Editing updates the same event, never a duplicate. Important changes and cancellations are clearly represented.
- Teachers manage only events they are authorized to manage.
- No real publishing, registration, or notifications in the frontend phase.

### 9.3 Clearance Verification

Provide: assigned office or clearance area, pending requirements, Scan Student QR, relevant student identification details, individual requirement selection, outcome recording (Cleared, Needs Correction, On Hold), reason or notes, confirmation.

Outside an active period, processing is unavailable. Scanning and saving are mock interactions only. Only explicitly authorized staff can process requirements.

## 10. Shared Profile

Purpose: a social identity page in Luma's profile layout, not a settings menu. Same structure for both roles. **No QR coin** (the QR lives on the long-press shortcut and in Class).

Top to bottom:

- Large profile photo, left-aligned name, Student or Teacher designation, academic or faculty information, masked ID (for example `2023-****-12`).
- Official identity tags.
- Inline stats: students `12 Attended · 3 Orgs`; teachers `4 Classes · 6 Hosted`.
- Edit Profile button and the settings icon.
- Optional concise **About**.
- Teachers only: **Classes I teach**.
- **Event history** as photo rows: event name, date, image, attendance status, recorded role (Participant, Organizer, Host, Volunteer). Roles come from the event record; creating an event doesn't make someone its host; registration alone isn't attendance. Tapping opens the event detail.

**Edit Profile:** edit presentation details such as the photo and About. Academic information, identifiers, memberships, roles, and attendance history cannot be edited.

## 11. Settings Pop-Up

The settings icon on Profile opens a sheet over the screen with a dimmed background, in Luma's grouped, rounded inset-list style:

- Personal Information
- Account & Security
- Notifications
- Help & Support
- About Michaelean
- Preview role switch (Student / Teacher), labeled as a preview tool
- Log Out

Close with X, outside tap, or Back. Real account changes and logout are out of scope; unbuilt destinations show clear placeholders.

## 12. Permissions and Privacy

Identity and authorization are different. A teacher, student leader, or officer does not automatically receive every capability associated with that title.

- Only authorized teachers can manage applicable classes.
- Only authorized event managers can publish or modify applicable events.
- Only staff assigned to a clearance area can process its requirements.
- Only authorized officers can manage organization content.

Represent permissions explicitly in mock data. The eventual backend enforces permissions; frontend visibility is not security.

Privacy:

- Assigned tags are visible to all Michaelean students and teachers.
- Mask student and staff IDs by default.
- QR content is a random token, never personal data.
- Avoid unnecessary personal information.
- Hide or disable unauthorized actions, with an explanation where useful.
- Visibility rules for event history and attendee lists remain to be finalized.

## 13. Development Order (rebuild)

The existing models, services, and mock data are kept; screens are rebuilt to this spec. One phase per session, reviewed by the user before moving on.

1. **Theme and shared pieces:** tokens (§2.2), Inter Display + Inter (§2.3), depth and shadows, rows, status pills, sheets, floating header and nav, motion basics.
2. **Opening video and sign-in preview** (§1.1).
3. **Home**, both roles (§6, §8), including the notifications sheet, long-press QR, and one-time hint (§1.3).
4. **Hubs:** Student Life and Michaelean Life live previews (§7, §9).
5. **Profile and Settings** (§10, §11).
6. **Class:** student Class screen and teacher class management with the attendance scan flow (§7.1, §9.1).
7. **Events:** discovery, detail, and teacher management (§7.3, §9.2).
8. **Organizations:** directory and tabbed organization page (§7.4).
9. **Clearance:** student clearance and teacher verification (§7.5, §9.3).
10. **Frontend testing:** navigation and state, responsive layouts, empty/unavailable/error states, form validation, role-specific UI, permission-dependent controls, QR and motion.
11. **Later integration, only when requested:** Microsoft 365 auth, school-record mapping, backend and database, official records, memberships and permissions, clearance workflows, real notifications, production QR verification, PWA deployment and offline caching.
