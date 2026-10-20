# Michaelean — Claude Code Instructions

Michaelean is a campus-life app for students and teachers of **Saint Michael's College of Laguna** (SMCL): schedules, attendance, events, organizations, clearance, notifications, and social identity. Built with Flutter/Dart on Windows (VS Code), shipped as a free-hosted installable PWA for Android and iPhone.

**Current phase: frontend prototype only.** No backend, database, live Microsoft 365 login, or production integrations unless the user asks.

**The product spec is in `docs/spec.md`.** Before building a feature, read its section there (and §2.1 Visual Direction for any UI work; the Luma screenshots in `assets/images/luma_screens/` are the visual reference). Do not implement the whole spec at once.

## How to work with the user

The user is learning to code. Be a patient, practical partner.

- Explain the purpose of a change before making it; keep explanations short and beginner-friendly.
- Use the simplest reasonable implementation, in small understandable steps.
- Explain important files and decisions. Give exact commands and the folder to run them in.
- Ask one concise question when a decision would otherwise be a significant guess. Don't re-ask what this file or the spec already decides.
- Never invent project status, test results, or finished functionality. If you couldn't test something, say so.

## Rules that always apply

- **Mock data is clearly mock.** Keep sample records in `lib/mock/`, separate from widgets. Never present mock data as official school records.
- **No fake success.** A simulated action must not claim it changed a real record. A mock QR never verifies identity or attendance. No fabricated success messages for attendance, registration, publishing, or clearance.
- **Identity ≠ permission.** Tags (school, department, organization, officer) are labels; they don't grant permissions by themselves. Represent permissions explicitly in mock data. Frontend hiding is not security.
- **Privacy.** Mask student/staff IDs by default. QR content is a random mock token, never personal data. Show only necessary personal information.
- **Prototype status stays visible.** A dev role switcher (student/teacher preview) is a preview tool, never a security mechanism.
- Don't hardcode assumptions that block later integration — use simple models and service interfaces.

## Tech decisions

- **Flutter 3.47.7 (stable)**, Dart that ships with it.
- **State:** Flutter built-ins — `setState` and `ChangeNotifier`. No state-management package unless discussed first.
- **Navigation:** `go_router` — needed so the Android/browser Back gesture in the installed PWA closes pop-ups and goes back instead of exiting. Bottom tabs keep their state.
- **Theme:** `lib/theme/app_theme.dart` (created in Phase 1) is the single source for colors, fonts, spacing, and radii. Never hardcode colors or sizes in screens.
- **Dependencies:** add a package only with a clear reason, explained to the user first.
- **Assets:** declare them file by file in `pubspec.yaml`. Never declare `assets/images/` as a folder (it holds the Luma screenshots, which must not ship).
- **Fonts:** Inter (Regular, Medium, SemiBold, Bold) is bundled in `assets/fonts/` with its license.
- **Session:** the previewed user lives in `Session` (`lib/services/session.dart`); screens read it with `SessionScope.of(context)`.

## Folder layout

```
lib/
  main.dart
  router.dart     all routes (go_router)
  theme/          app theme and design tokens
  widgets/        reusable shared widgets (tags, buttons, sheets, rows)
  screens/
    shared/       screens both roles use (Profile, Events, Settings pop-up)
    student/      Student Home, Student Life
    teacher/      Teacher Home, Michaelean Life
  models/         plain data classes
  mock/           clearly labeled sample data
  services/       interfaces that return mock data now, real data later
  utils/          small helpers (date formatting)
assets/
  images/SMCL_Emblem.png      main logo (spec §2.1) — don't recolor or crop
  images/luma_screens/        design reference only — never ship in the app
  videos/app_opening.mp4
docs/
  spec.md         product spec
```

Status (2026-10-20): Phase 1 foundation done. Web-only Flutter project, theme, floating bottom nav, student/teacher preview, mock users. Tab contents are placeholders.

## Commands (run in `C:\Users\moril\projects\michaelean_app`)

- Run in browser: `flutter run -d chrome`
- Check for errors: `flutter analyze`
- Run tests: `flutter test`
- In Claude's browser pane: the `michaelean-web` config in `.claude/launch.json` builds the app and serves `build/web` (debug `web-server` mode stalls there).

## Workflow for every task

1. Inspect the relevant files (and `pubspec.yaml` for versions and dependencies). Don't assume the project is empty or unchanged.
2. Explain the goal, the approach, and which files you'll create or change.
3. Implement only the requested feature. Reuse shared widgets; don't duplicate student and teacher versions.
4. Run `flutter analyze` and fix errors you introduced.
5. Test navigation and interactions.
6. Summarize: what changed, what works, what is still mocked, how to run it.

Preserve working code and the current structure. No deleting files, big refactors, or new frameworks without a clear reason explained first. If the code contradicts this file or the spec, explain the mismatch before making disruptive changes. Don't redesign approved concepts.

## Open decisions — don't silently invent answers

1. Can teachers edit only their assigned classes, or can authorized teachers edit others?
2. Is departmental society membership automatic or application-based?
3. Can teachers change single sessions, recurring schedules, or both? Which changes need approval or notification?
4. Visibility rules for event histories and attendee lists.
5. Which student/faculty attributes come from the Microsoft directory vs. another authorized source?
6. Backend, database, and authorization architecture (later).
7. Free hosting service and Flutter web config for the PWA.
8. Exact meaning of clearance statuses "Action required" vs. "Needs correction" (proposed in spec §7.5).

When a decision isn't essential to the current task, keep going with an explicit, easy-to-change mock assumption.

Michaelean is one cohesive app, not a set of separate screens. Always: inspect first, explain the plan, build incrementally, verify the result.
