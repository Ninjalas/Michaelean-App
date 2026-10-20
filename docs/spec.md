# Michaelean — Product Spec

This is the detailed product specification for Michaelean. `CLAUDE.md` holds the working rules; this file holds what to build.

Read the section for the feature you are working on before building it. Do not implement the whole spec at once.

Institution (used in mock data and identity tags): **Saint Michael's College of Laguna** (short form: SMCL).

## 1. Application Structure

Michaelean has two role-specific experiences sharing one design system.

Student bottom navigation:

`Home | Student Life | Profile`

Teacher bottom navigation:

`Home | Michaelean Life | Profile`

Requirements:

- Home is the initial destination after successful sign-in.
- Student Life and Michaelean Life are feature hubs, not initial landing screens.
- Keep navigation consistent across destinations.
- Preserve navigation state where appropriate.
- Reuse shared components instead of duplicating student and teacher implementations.
- Adapt content and available actions to the user's role.
- Support development previews for both roles without implementing production authentication.
- Never treat a development role selector as a security mechanism.

## 2. Design System

Create a polished, modern mobile interface with an editorial, campus-oriented visual identity.

Priorities:

- Clear typography and visual hierarchy.
- Consistent spacing, padding, corner radii, and iconography.
- Restrained accent colors.
- Clean cards, lists, and information layouts.
- Appropriate touch targets and accessibility.
- Responsive behavior across mobile screen sizes.
- Proper safe-area and keyboard handling.
- Smooth, purposeful animations.
- Consistent pop-ups, modal behavior, and transitions.
- Appropriate loading, empty, unavailable, and error states.

Avoid unnecessary decoration, redundant sections, excessive dashboard cards, and nonfunctional controls.

Do not arbitrarily redesign previously approved concepts. Preserve the intended functionality and visual direction while improving implementation quality.

### 2.1 Visual Direction

Status: **proposed**. Refine during Phase 1 when the theme is built, then treat it as approved.

**Reference:** Luma iOS screenshots in `assets/images/luma_screens/` (from Mobbin). Study their principles only. Do not copy Luma's screens one-to-one, its wordmark, icons, or branding. Michaelean has its own identity built on the SMCL emblem and school colors.

Not a reference: `luma_screens/image 3.png` is an earlier Michaelean concept (blue gradient header, colored metric chips, floating + button, card-per-item feed). It is the generic dashboard style this direction moves away from.

#### What the reference does (observed)

- **Near-monochrome UI.** White backgrounds, black/ink text, grays for meta. Color appears almost only in small status labels (Going, Invited, Waitlisted, Hosting) and prices. Content images supply most of the color.
- **Typography carries hierarchy.** One clean sans family. Large medium-weight section titles ("Your Events ›", "Picked for You"), 2-line event titles, small muted meta lines. Date group headers are two-tone: `19 July` in ink, `/ Sunday` in muted gray.
- **Rows, not cards.** Event list items are rows: rounded square thumbnail on the left; a tiny host avatar + host name line; title; then meta lines with a clock icon (time) and a pin icon (venue). Thin hairlines separate rows. A small status pill overlaps the bottom of the thumbnail.
- **Floating, soft chrome.** The header is avatar + wordmark on the left and a single white pill holding `+` and the bell on the right, with a soft shadow. The bottom navigation is a floating, rounded, translucent pill detached from the screen edge; the active tab sits in its own filled pill. The back button is a floating circle.
- **Scroll behavior.** Content scrolls under a blurred, translucent header. On detail pages the title moves into a compact pill next to the back button once scrolled.
- **Event detail.** Large rounded square cover image, big title, date/time line, then a row of three equal tonal action buttons (primary action, Contact, More). Below: sections introduced by small muted labels over a hairline ("Location", "Hosts", "121 Going", "About Event"), a rounded map, host rows with avatars, an overlapping avatar stack with "+117" and a names line. The whole page takes on a tint from the cover image.
- **Profiles.** Large circular avatar, left-aligned name, handle, one-line bio, "Joined" line with a small icon, inline stats ("2 Hosted 2 Attended"), then sections ("Hosting ›", "Past Events ›") reusing the same event rows. Settings use grouped, rounded inset lists with small icons and muted section labels.
- **Pop-ups.** Rounded bottom sheets with a grab handle, a round X button, an icon in a soft circle, a title, one sentence, and one full-width pill button. Filters open a compact rounded menu with an icon per option; an active filter changes the filter button's color.
- **Forms.** Borderless inputs filled in light gray with fully rounded corners; muted labels above. Option rows with icons and toggles. One full-width pill button at the bottom; the disabled state is plain gray.
- **Empty states.** A simple outline icon in gray, a short title ("Nothing Here, Yet"), one muted sentence.
- **Segmented controls** as pills (Upcoming | Past) at the top of list screens.

#### How Michaelean applies it

- **Keep the calm, monochrome base.** Paper/white backgrounds, ink text, gray meta. School color is used with intent, never as large decorative blocks or gradient headers.
- **Header:** SMCL emblem + "Michaelean" wordmark on the left; greeting and date below; the notification bell in a soft white pill on the right. Collapses on scroll as §6 and §8 describe.
- **Bottom navigation:** floating rounded pill, three tabs (§1), active tab in a soft filled pill. Our own icons.
- **Feed and lists:** rows with thumbnails and two-tone date headers for events, news, classes, and event history. The one prominent School News item (§6) is the main exception and gets a large image.
- **Status pills on thumbnails/rows:** Registered, Invited, Attended, Full, Cancelled, and the clearance statuses (§7.5), each a soft tint with darker text. Never show a status the mock data doesn't support (§3).
- **Event detail:** large rounded cover image, title, date line, a row of tonal action buttons, then labeled sections (Venue, Host, Attendees, About). Instead of Luma's full-page image tint, use a light wash at the top of the page that fades into paper.
- **Profile (§10):** same left-aligned identity layout, with the photo↔QR coin as the centerpiece and identity tags under the name in place of a handle.
- **Pop-ups:** the notification pop-up, settings pop-up, and organization feature modals share one rounded sheet/modal style (dimmed background, X, Back, outside tap).

#### Color

School colors, taken from the SMCL emblem (red, navy, white), in deeper, calmer shades. Starting values, estimated by eye from the emblem:

| Token | Hex | Use |
|---|---|---|
| `navy` | `#242A5E` | Primary buttons, active tab, selected states, links, identity tags. |
| `red` | `#B3242E` | Attention only: `URGENT`, notification dot, Needs correction. One per screen region at most. |
| `white` | `#FFFFFF` | Surfaces, sheets, pills. |
| `paper` | `#F7F6F3` | Screen background. |
| `ink` | `#16171D` | Primary text. |
| `muted` | `#6E7079` | Secondary text, meta, date suffix ("/ Sunday"). |
| `hairline` | `#E7E5E0` | Dividers. |
| `fill` | `#F1F0EC` | Input and tonal button backgrounds. |

Status tints (soft background + darker text): green for Cleared/Attended, amber for In review/On hold/Full, navy for Invited/Registered, red for Needs correction/Cancelled, gray for Not started/Not applicable. Check WCAG AA contrast when building the theme.

#### Typography

Luma uses a single sans family. Michaelean uses:

- **Inter** (sans) for all UI text, with weight and size creating hierarchy, as in the reference.
- **Fraunces** (serif), optional, only for the largest editorial titles (screen titles, the featured news headline) to give the campus identity a bit more character. If it feels off once built, drop it and use Inter everywhere. That is the simpler option.

Both fonts are free (OFL) and bundled as asset files so they work offline.

#### Shape, spacing, motion

- 4-point spacing scale; 20 px screen margins; 24–32 px between sections.
- Radius: 12 for thumbnails and small elements; 20 for cover images, sheets, and modals; full pill for buttons, inputs, tags, and the nav bar.
- Soft, large-blur, low-opacity shadows, only on floating elements (header pill, nav bar, back button).
- Touch targets ≥ 48 × 48 px.
- Motion 200–300 ms ease-out: sheets slide up, list image expands into event detail, header collapses smoothly. The profile coin flip (§10.1) is the signature animation.

#### Logo and brand assets

- **Main logo:** `assets/images/SMCL_Emblem.png` (the Saint Michael's College of Laguna shield: red, navy, white). Use it in the app header, on the splash/opening screen, and as the source for the PWA home-screen icon.
- The emblem is detailed and includes text, so it becomes hard to read at very small sizes (favicon, small icons). A simplified small-size mark may be needed later; don't invent one without asking.
- Don't recolor, stretch, crop, or add effects to the emblem.
- `assets/videos/app_opening.mp4`: opening video; where it is used is not yet decided.

Avoid: generic school dashboards, card grids, rows of metric chips, gradient headers, floating action buttons, corporate admin layouts.

## 3. Scope and Mock Data

The current phase is a frontend prototype.

Use clearly identified mock data to demonstrate the interface. Separate sample records from widgets and presentation logic.

Where appropriate, define simple models and service interfaces that can later connect to real data.

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

The intended production flow is:

1. Authenticate through the institution's Microsoft tenant.
2. Verify the account belongs to the approved institution.
3. Match the account's stable identifier to an authorized student or faculty record.
4. Retrieve verified academic or faculty information.
5. Assign the appropriate identity tags and permissions.
6. Open Home.

Microsoft authentication alone does not guarantee access to every academic attribute. Missing information must come from an authorized institutional data source.

Do not implement this integration during the frontend phase.

For previews, use clearly identified mock student and teacher profiles.

## 5. Institutional Hierarchy and Tags

Michaelean's identity hierarchy is:

Institution
  └── School/College
       └── Department/Program

Organization memberships and assigned roles are additional identity tags associated with the person.

The institution has three schools/colleges:

- SON
- SBMIT
- SEAS

Every student and teacher should receive the appropriate institution and school/college labels.

Additional labels may include:

- Department or program.
- Confirmed organization membership.
- Official organization officer role.
- Other authorized institutional roles.

Example:

`[Saint Michael's College of Laguna] [SBMIT] [Department of Computer Studies] [Dance Company] [Dance Company Officer]`

These are illustrative labels, not fixed mappings. Use verified mock records and do not assume all academic affiliations from the examples.

Rules:

- All assigned tags are visible to students and teachers using Michaelean.
- Tags must be readable, compact, and responsive.
- Users cannot freely assign themselves academic, membership, or officer labels.
- Membership labels reflect confirmed memberships.
- Officer labels reflect authorized role assignments.
- A department is distinct from its student society.
- Departmental society membership must not be assumed automatic; the membership policy remains undecided.
- Displayed tags do not independently grant permissions.

## 6. Student Home

Purpose: a personalized, continuously scrolling campus feed.

Header:
- Michaelean branding.
- Personalized greeting.
- Current date.
- Notification bell.
- Expandable Attendance Overview.

On scroll, collapse the detailed header while keeping the greeting and notification bell accessible.

Attendance Overview contains:
- Class Attendance percentage.
- Event Attendance percentage.
- Events Completed count.
- Event Requirements progress, such as 3/6 cleared.

Metrics link to relevant details when available.

Pending Tasks shows actionable items requiring attention, such as clearance corrections or outstanding event requirements.

Announcements use a compact layout.

School News displays one prominent official news item and smaller additional entries.

The mixed feed may contain:
- Institutional announcements.
- School news.
- Department news.
- Organization news.
- Event-related updates.

Personalize content using the mock student's affiliations and confirmed memberships. Urgent organization news may receive an `URGENT` label and temporary prominence.

Do not duplicate content across sections. Do not add a separate Upcoming Events section; event discovery belongs under Student Life.

The notification bell opens a compact recent-notifications pop-up. Notifications navigate to relevant screens without automatically modifying records.

## 7. Student Life

Purpose: a feature hub for accessing campus services.

Title: `Student Life`

Subtitle: `Your campus, beyond the classroom.`

Include an Explore section with a slightly prominent Events navigation card and a Your Student Life section containing:

- Class
- Organizations
- Clearance

Use a clean editorial layout and avoid duplicating the Home feed.

### 7.1 Class

Display:
- Upcoming classes in chronological order.
- Subject.
- Professor.
- Start and end time.
- Classroom.
- Full schedule access.
- Attendance summary and history.

If no more classes remain today, display the next scheduled future class.

Provide `Show QR for Attendance`, displaying a scan-friendly code and the instruction:

`Show this code to your teacher.`

The profile QR and Class QR should represent the same account identity concept. The QR can be shown at any time.

Use a mock QR during frontend development. Never claim that displaying it verifies attendance.

### 7.2 Attendance Rules

The intended production workflow requires an authorized teacher to scan the student's QR against the official enrolled roster and an active session.

Rules:
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

Provide filters:
- All
- School-wide
- Department
- My Organizations

Show only events relevant to the user's eligibility. Deduplicate events matching multiple categories.

Event details include:
- Image.
- Name.
- Host or organizer.
- Date and time.
- Venue.
- Description.
- Registration deadline and capacity when applicable.
- Registration or joining action when appropriate.
- Relevant host and attendee information.

The event experience supports social discovery. Users can identify hosts and view appropriate attendee identities and roles, subject to the eventual privacy rules.

Rules:
- Prevent duplicate registrations.
- Do not confirm registration for full, closed, or ineligible events.
- Registration is not attendance or completion.
- Only official attendance confirmation contributes to event history and completion metrics.
- Leaving an organization hides member-exclusive events from current discovery but preserves registration and historical records.

Authorized teachers can invite eligible students. Teacher-issued invitations automatically register recipients without an accept/decline step. Cancellations notify affected students.

### 7.4 Organizations

The directory contains:
- The student's departmental society where applicable.
- Approved school-wide clubs.
- My Organizations, containing confirmed memberships.

Do not treat a department as its student society. Do not list other departments' societies as school-wide clubs.

Organization profiles contain five features:
- About
- Schedule
- Events
- News
- Officers

Feature details may open rounded modal pop-ups over the current screen, with a dimmed background, close button, outside-tap dismissal, Back support, and internal scrolling.

Complex membership or editing flows may use dedicated screens.

The Events feature opens the shared Events destination filtered to the organization, preserving back navigation.

Only authorized officers can publish or manage organization content. Administrators manage memberships and officer assignments. When an officer role ends, management permissions are revoked but historical posts remain.

### 7.5 Clearance

All clearance types are seasonal:
- Semester
- Graduation
- Document request
- Other configured categories

Outside an active period, display:

`Clearance Unavailable`

Processing remains locked, but history is available.

During an active period, show progress, applicable requirements, deadlines, and statuses:

- Not started
- Action required
- In review
- Needs correction
- Cleared
- On hold
- Not applicable

Action required means the student has something to do for the first time (for example, submit a document). Needs correction means staff already reviewed a submission and returned it with a reason. (Proposed definition — confirm.)

Not applicable differs from Not started. Overdue does not automatically mean rejected or cleared.

Evidence is required only when specified. Provide rejection reasons and resubmission paths.

Authorized staff scan the student's QR, review the relevant records or physical documents, and explicitly record an outcome.

A QR scan or evidence upload never automatically approves clearance. Staff may process only requirements they are authorized to manage.

## 8. Teacher Home

Purpose: a personalized dashboard for teaching responsibilities and campus updates.

Header:
- Michaelean branding.
- Personalized greeting.
- Current date.
- Notification bell.
- Expandable Today's Overview.

Collapse the detailed overview on scroll while keeping the greeting and notification bell accessible.

Today's Overview:
- Classes today.
- Attendance sessions awaiting finalization.
- Upcoming events.

Only show pending attendance when a session genuinely requires teacher action. A scheduled class alone does not create an attendance task.

Next Class displays the next scheduled class, subject, time, and classroom. If there are no more classes today, show the next scheduled future class or an appropriate empty state.

Pending Tasks may include:
- Finalize an attendance session.
- Review a schedule change.
- Complete another authorized teaching task.

Include relevant announcements, official school news, event notices, and schedule or classroom changes.

Do not add a separate publishing button to Home. Management actions belong in Michaelean Life.

## 9. Michaelean Life

Purpose: the teacher's feature hub, with the section heading `Teaching & Campus`.

Include three principal features:
1. Class Management.
2. Events.
3. Clearance.

### 9.1 Class Management

Provide access to:
- Assigned classes.
- Today's Classes and Schedule.
- Class details.
- Attendance scanning.
- Student roster.
- Attendance review and finalization.
- Schedule and classroom-location editing.
- Recent sessions.

Attendance flow:

1. Open a class.
2. Start or access an appropriate attendance session.
3. Scan or simulate scanning a student's QR.
4. View Present and Unchecked counts.
5. Review the roster.
6. Finish Attendance.
7. Review unchecked students and confirm finalization.

Mock scanning must not be represented as real verification or a saved official record.

Schedule editing may include date or recurrence, start/end times, classroom, optional reason, and Save Changes.

The scope of teacher editing permissions remains undecided. Do not assume all teachers can edit all classes. Distinguish individual-session changes from recurring schedule changes if both are supported.

### 9.2 Events Management

Provide:
- Upcoming.
- Past.
- Drafts.
- Create Event.
- Manage Event.
- Edit Event.
- Invite Students.
- View Registrations.
- Cancel Event.

Event forms may include name, image, description, date, start/end time, venue, audience, deadline, and optional capacity.

Support draft and publish states as distinct frontend interactions.

Invitations may target individuals, classes/sections, eligible departments, or other explicitly supported groups.

Editing must update the same event, not create a duplicate. Important changes and cancellations should be clearly represented.

Teachers can manage only events they are authorized to manage.

Do not implement actual publishing, registration, or notifications during the frontend phase.

### 9.3 Clearance Verification

Provide:
- Assigned office or clearance area.
- Pending requirements.
- Scan Student QR.
- Relevant student identification details.
- Individual requirement selection.
- Outcome recording.
- Reason or notes.
- Confirmation.

Valid outcomes include Cleared, Needs Correction, and On Hold.

Outside an active clearance period, processing is unavailable. QR scanning and saving are mock interactions only.

Only explicitly authorized staff can process requirements.

## 10. Shared Profile

Purpose: a social identity page inspired by Facebook profiles and Luma event identities, not a conventional settings menu.

Both students and teachers use the same general structure, with role-specific information.

Display:
- Prominent profile photo.
- Name.
- Student or teacher designation.
- Academic or faculty information.
- Masked student or staff identifier.
- Official identity tags.
- Edit Profile action.

### 10.1 Photo-to-QR Coin Flip

The photo and QR code occupy the same display area.

- The front face displays the profile photo.
- Tapping or swiping horizontally triggers a smooth 3D coin-like flip around the vertical axis.
- The reverse face displays the QR code.
- Tapping or swiping again returns to the photo.
- Avoid accidental repeated flips.
- Once flipped, the QR face remains stationary and readable.

The interaction is identical for students and teachers.

Use a mock QR for the frontend prototype. Do not expose unnecessary personal information through QR content.

Mock QR content: a random mock token per mock account (for example `MOCK-7F3K9Q`), never a real name, student/staff ID, or email. The same token is used for the profile QR and the Class attendance QR.

### 10.2 Profile Information

Show the institutional hierarchy, department/program, confirmed organization memberships, and assigned roles.

All assigned tags are visible to students and teachers using Michaelean.

Users cannot freely edit academic identity, membership, officer roles, or official identifiers.

Include an optional concise About section.

### 10.3 Event History

Display recorded event participation:
- Event name.
- Date.
- Relevant image.
- Attendance or participation status.
- Recorded role, such as Participant, Organizer, Host, or Volunteer.

Roles must come from the event record. Creating an event does not automatically make someone its host. Registration alone does not count as attendance.

Tapping an event opens its details when available.

### 10.4 Edit Profile

Allow editing of appropriate personal and presentation details, such as the profile photo.

Do not allow free editing of authoritative academic information, official identifiers, memberships, roles, or attendance history.

## 11. Settings Pop-Up

The Profile screen contains a settings icon.

Tapping it opens a pop-up over the existing screen with a dimmed background.

Include:
- Personal Information.
- Account & Security.
- Notifications.
- Help & Support.
- About Michaelean.
- Log Out.

Support closing with the X button, tapping outside, or pressing Back where appropriate.

Reuse shared settings components across student and teacher profiles.

Actual account changes and logout are outside the current frontend-only scope. Use clear placeholders for destinations that have not been implemented.

## 12. Permissions and Privacy

Identity and authorization are different.

A teacher, student leader, or organization officer does not automatically receive all administrative capabilities associated with that title.

Examples:
- Only authorized teachers can manage applicable classes.
- Only authorized event managers can publish or modify applicable events.
- Only staff assigned to the relevant clearance area can process its requirements.
- Only authorized organization officers can manage organization content.

Represent permissions explicitly in mock data.

The eventual backend must enforce permissions; frontend visibility alone is not security.

Privacy principles:
- Assigned tags are visible to all Michaelean students and teachers.
- Mask student IDs by default.
- Protect QR content.
- Avoid unnecessary personal information.
- Establish appropriate visibility rules for event histories and attendee details.
- Hide or disable unauthorized actions with an explanation where useful.

The precise visibility rules for event history and attendee lists remain to be finalized.

## 13. Planned Development Order

Phase 1 — Foundation:
- Inspect existing project.
- Establish shared theme and reusable components.
- Implement shared bottom navigation.
- Add student and teacher preview modes.
- Establish mock-data conventions.

Phase 2 — Home:
- Student Home.
- Teacher Home.

Phase 3 — Feature hubs:
- Student Life.
- Michaelean Life.

Phase 4 — Profiles:
- Student Profile.
- Teacher Profile.
- Photo-to-QR animation.
- Identity tags.
- Event history.
- Settings pop-up.

Phase 5 — Feature details:
- Class schedules and attendance interfaces.
- Event discovery and management.
- Organization profiles and membership interfaces.
- Clearance interfaces.

Phase 6 — Frontend testing:
- Navigation and state preservation.
- Responsive layouts.
- Loading, empty, unavailable, and error states.
- Form validation.
- Role-specific UI.
- Permission-dependent controls.
- QR and animation behavior.

Phase 7 — Later integration, only when requested:
- Microsoft 365 authentication.
- School-record mapping.
- Backend and database.
- Official attendance and event records.
- Organization memberships and permissions.
- Clearance workflows.
- Real notifications.
- Production QR verification.
- PWA deployment and offline caching.
