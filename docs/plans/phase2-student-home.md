# Phase 2a — Student Home plan

Spec: `docs/spec.md` §6 (Student Home) and §2.1 (Visual Direction).
Status: **proposed**, waiting for approval.

## Goal

Replace the Home placeholder for students with a real, scrolling campus feed for the mock student Nicolas Santos. Everything shown is clearly sample data. Teacher Home stays a placeholder (Phase 2b).

## The screen, top to bottom

1. **Header**
   - Row: SMCL emblem + "Michaelean" on the left; bell in a soft white pill on the right (red dot if there are notifications).
   - "Good morning, Nicolas" (morning/afternoon/evening from the real clock).
   - Today's date in muted text, e.g. "Tuesday, 20 October".
   - On scroll: the emblem row, date and overview scroll away; a slim pinned bar stays with the small avatar, "Good morning, Nicolas", and the bell.

2. **Attendance Overview** (expandable, part of the header area)
   - Collapsed: one quiet line, e.g. `92% class · 80% events · 5 events · 3/6 cleared` with a chevron.
   - Expanded: four labeled rows (Class Attendance, Event Attendance, Events Completed, Event Requirements) with a thin progress line each.
   - A small "Sample data" label. Tapping a metric opens a "Coming in Phase 5" page (the detail screens don't exist yet).

3. **Pending Tasks**: rows with a status pill, e.g. "Library clearance · Needs correction", "Event requirements · 3 more to clear". Tapping opens a placeholder. Hidden entirely when there are none.

4. **Announcements**: compact text rows (office, title, time ago). No images.

5. **School News**: one featured item with a large rounded image, then 2 smaller rows with thumbnails.

6. **For You** (the mixed feed): department, organization, and event updates matched to Nicolas's mock affiliations. Organization posts from CSS show its logo as the source avatar. An urgent org post gets a red `URGENT` pill and appears first in this section.

No item appears in more than one section. No Upcoming Events section (events live in Student Life).

## Pop-ups and detail pages

- **Notifications pop-up**: tapping the bell opens the shared rounded sheet (dimmed background, X, outside tap, Back closes it). About 5 recent notifications as rows. Tapping one goes to the related page (a post, or a placeholder). It doesn't change any record (no fake "marked as done").
- **Post detail**: tapping an announcement or news item opens a simple page: image (if any), title, source + date, body text. Back returns to Home at the same scroll position.

## States

- Loading: simple placeholder blocks while the mock service "loads".
- Error: a short message with a Retry button (the mock can simulate a failure in tests).
- Empty sections are hidden; if the whole feed is empty, show an empty state ("Nothing new yet").

## New and changed files

| File | What |
|---|---|
| `lib/models/feed.dart` | `Post` (kind, title, body, source, image, time, urgent, audience), `PendingTask`, `AttendanceSummary`, `AppNotification` |
| `lib/mock/mock_home.dart` | Sample posts, tasks, metrics, notifications (marked MOCK DATA) |
| `lib/services/home_service.dart` | `HomeService` interface + `MockHomeService`; picks posts that match the user's tags (personalization lives here, not in widgets) |
| `lib/widgets/section_header.dart` | Section title ("School News") |
| `lib/widgets/status_pill.dart` | Soft tinted label (Needs correction, URGENT…) |
| `lib/widgets/content_row.dart` | Thumbnail + source line + title + meta row, reused later for events |
| `lib/widgets/app_sheet.dart` | Shared rounded pop-up (used again for Settings and org modals) |
| `lib/widgets/user_avatar.dart` | Photo, or initials when there's no photo |
| `lib/screens/student/student_home_screen.dart` | The screen itself |
| `lib/screens/shared/post_detail_screen.dart` | Post detail page |
| `lib/router.dart` | `/home` shows Student Home for students; adds `/home/post/:id` |
| `pubspec.yaml` | Adds the images used, file by file |
| `test/home_service_test.dart` | Personalization: Nicolas sees his department/CSS posts, not other departments' |
| `test/student_home_test.dart` | Greeting shows "Nicolas"; bell opens and closes the pop-up; tapping a post opens detail and Back returns |

## Images used

- `profiles/nicolas.jpg`: header avatar.
- `profiles/css_profile.jpg`: CSS logo as the post source avatar.
- `events/css_commitevent.jpg`, `css_startupevent.jpg`, `css_unpackingevent.jpg`: news and org post images.
- `SMCL_MAP.png`: an announcement image (e.g. a campus map notice).

## Decisions to confirm

1. **Nicolas's organization.** The CSS images fit better than the spec's illustrative "Dance Company". Proposal: Nicolas is a *confirmed* Computer Science Society member (no officer role). This is a mock assumption; it doesn't decide whether society membership is automatic (open decision 2).
2. **Real posters and real people.** The event posters show real SMCL events and real names. Proposal: use them as images, but write invented, clearly-marked sample text for the posts, so the app doesn't claim facts about real events.
3. **Mock teacher's last name.** The teacher is also "Santos" (Mark Santos), which could look like they're related. Proposal: rename him to Mark Villanueva.

## Verify

- `flutter analyze` clean, `flutter test` passes.
- In the browser at phone size: header collapses on scroll, overview expands/collapses, bell pop-up opens/closes (X, outside tap, Back), post detail opens and Back returns to the same spot, teacher preview still shows its placeholder.

## Not in this step

Teacher Home, real metric/clearance/event detail screens, read/unread notification state, pull-to-refresh, dark mode.
