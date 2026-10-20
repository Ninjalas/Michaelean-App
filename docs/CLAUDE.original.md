# Michaelean — Claude Code Project Instructions

## 1. Project Identity

Michaelean is a campus-life application for students and teachers. It centralizes campus information, academic schedules, attendance, events, organizations, clearance, notifications, and social identity.

**Current priority: FRONTEND DEVELOPMENT ONLY.**

Use Flutter and Dart. Develop on Windows using VS Code. The intended distribution is an installable Progressive Web App (PWA) for Android and iPhone, with a home-screen icon, basic offline support, and strictly free hosting. Free-tier limitations are acceptable; a paid upgrade must not be required.

Do not implement the backend, database, live Microsoft authentication, or production integrations unless explicitly requested later.

## 2. How You Must Work

The user is learning and may have limited coding experience. Be a patient, practical development partner.

- Explain the purpose of a change before making it.
- Keep explanations direct, beginner-friendly, and concise.
- Use the simplest reasonable implementation.
- Break substantial work into small, understandable steps.
- Explain important files, components, and architectural decisions.
- Provide exact commands and the directory in which to run them.
- Never skip essential setup, testing, or verification steps.
- Do not overwhelm the user with unrelated information.
- Ask one concise question when a decision is necessary to avoid a significant incorrect assumption.
- Do not repeatedly ask about decisions already documented in this file.
- Do not invent project status, test results, or completed functionality.

The user prefers to understand the development process rather than receive an unexplained code dump.

## 3. Mandatory Project Inspection

Before implementing anything:

1. Inspect the existing project structure.
2. Read `pubspec.yaml` and identify Flutter/Dart versions and dependencies.
3. Inspect existing entry points, navigation, theme, screens, reusable widgets, and state management.
4. Identify existing conventions and working functionality.
5. Explain the proposed changes and affected files.
6. Implement only the requested scope.

Preserve the current architecture wherever practical.

Do not replace working code, delete files, introduce major dependencies, or restructure the entire project without a clear reason. Do not assume the project is empty.

If the existing code contradicts an assumption in this document, inspect it and explain the discrepancy before making disruptive changes.

## 4. Application Structure

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

## 5. Design System

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

## 6. Scope and Mock Data

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

## 7. Authentication and Institutional Identity

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

## 8. Institutional Hierarchy and Tags

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

`[Institution Name] [SBMIT] [Department of Computer Studies] [Dance Company] [Dance Company Officer]`

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

## 9. Student Home

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

## 10. Student Life

Purpose: a feature hub for accessing campus services.

Title: `Student Life`

Subtitle: `Your campus, beyond the classroom.`

Include an Explore section with a slightly prominent Events navigation card and a Your Student Life section containing:

- Class
- Organizations
- Clearance

Use a clean editorial layout and avoid duplicating the Home feed.

### 10.1 Class

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

### 10.2 Attendance Rules

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

### 10.3 Events

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

### 10.4 Organizations

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

### 10.5 Clearance

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

Not applicable differs from Not started. Overdue does not automatically mean rejected or cleared.

Evidence is required only when specified. Provide rejection reasons and resubmission paths.

Authorized staff scan the student's QR, review the relevant records or physical documents, and explicitly record an outcome.

A QR scan or evidence upload never automatically approves clearance. Staff may process only requirements they are authorized to manage.

## 11. Teacher Home

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

## 12. Michaelean Life

Purpose: the teacher's feature hub, with the section heading `Teaching & Campus`.

Include three principal features:
1. Class Management.
2. Events.
3. Clearance.

### 12.1 Class Management

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

### 12.2 Events Management

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

### 12.3 Clearance Verification

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

## 13. Shared Profile

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

### 13.1 Photo-to-QR Coin Flip

The photo and QR code occupy the same display area.

- The front face displays the profile photo.
- Tapping or swiping horizontally triggers a smooth 3D coin-like flip around the vertical axis.
- The reverse face displays the QR code.
- Tapping or swiping again returns to the photo.
- Avoid accidental repeated flips.
- Once flipped, the QR face remains stationary and readable.

The interaction is identical for students and teachers.

Use a mock QR for the frontend prototype. Do not expose unnecessary personal information through QR content.

### 13.2 Profile Information

Show the institutional hierarchy, department/program, confirmed organization memberships, and assigned roles.

All assigned tags are visible to students and teachers using Michaelean.

Users cannot freely edit academic identity, membership, officer roles, or official identifiers.

Include an optional concise About section.

### 13.3 Event History

Display recorded event participation:
- Event name.
- Date.
- Relevant image.
- Attendance or participation status.
- Recorded role, such as Participant, Organizer, Host, or Volunteer.

Roles must come from the event record. Creating an event does not automatically make someone its host. Registration alone does not count as attendance.

Tapping an event opens its details when available.

### 13.4 Edit Profile

Allow editing of appropriate personal and presentation details, such as the profile photo.

Do not allow free editing of authoritative academic information, official identifiers, memberships, roles, or attendance history.

## 14. Settings Pop-Up

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

## 15. Permissions and Privacy

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

## 16. Code Quality and Architecture

Follow the existing project conventions.

- Prefer simple, readable Dart.
- Build reusable widgets for shared elements.
- Separate screens, components, models, mock data, and supporting logic where appropriate.
- Keep presentation separate from data access.
- Use the existing state-management approach unless there is a strong reason to change it.
- Avoid unnecessary dependencies and overengineering.
- Keep code maintainable for a developing programmer.
- Ensure navigation and UI states work on realistic mobile sizes.
- Avoid broad refactors when a small change will suffice.

Do not introduce a new state-management package, routing system, or architectural framework without inspecting the project and explaining why it is needed.

## 17. Implementation Workflow

Implement one requested feature at a time.

For each task:

1. Inspect the relevant files.
2. Explain the goal and proposed approach.
3. Identify the files to create or modify.
4. Implement the requested feature only.
5. Check compilation and analyze errors introduced by the change.
6. Test navigation and interactions.
7. Summarize what changed, what works, what remains mocked, and how to run it.

Do not silently skip testing. If testing cannot be performed, say so.

Do not implement all screens from this document in one operation. Wait for the user's requested feature or implementation phase.

## 18. Planned Development Order

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

## 19. Current Unresolved Decisions

Do not silently invent answers to these questions:

1. Can teachers edit only assigned classes, or can authorized teachers edit other classes?
2. Is departmental society membership automatic or application-based?
3. Can teachers change individual sessions, recurring schedules, or both? Which changes require approval or notification?
4. What are the precise visibility rules for event histories and attendee lists?
5. Which student/faculty attributes are available through the institution's Microsoft directory, and which require another authorized data source?
6. What backend, database, and authorization architecture will be selected later?
7. Which free hosting service and Flutter web configuration will be used for the installable PWA?

Continue frontend work when these decisions are not essential to the current task. Use explicit mock assumptions where safe, and keep them easy to change.

## 20. Final Instruction

Michaelean is one cohesive campus-life application, not a collection of unrelated screens.

Preserve its shared navigation, social identity, institutional hierarchy, personalized content, and distinct student/teacher experiences.

The current goal is a functional, polished frontend prototype built incrementally with Flutter and Dart. Prioritize correctness, clarity, maintainability, and a smooth path to future integration.

**Always inspect first, explain the plan, implement incrementally, and verify the result.**