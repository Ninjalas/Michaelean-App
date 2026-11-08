# Backend plan: 55-student test (Supabase)

Goal: a month-long test with the 55 students of the Department of Computer
Studies. Each student signs in to their own pre-made account and sees their
own profile. What one student does (Connect, clubs, events, posts) shows up
for the others. Teachers come after the students.

## Decisions (2026-11-08)

- **Shared backend:** one database for everyone, not separate copies on each phone.
- **Supabase, free plan.** Auth for logins, Postgres for data, Row Level Security
  for "who may see what", Storage for photos later. No paid features.
- **Public sign-up is off.** Only the accounts our script creates can exist.
- **Real names, invented grades.** Names, year level and section come from the
  department master list. Grades, attendance and IDs are generated sample data,
  and the app keeps labeling them as samples.
- **Login email:** `FirstName.LastName@smcl.edu.ph`, e.g. `Christopher.Cruz@smcl.edu.ph`.
  We use it only as a username. No email is ever sent to it.
- **Passwords are given by us.** The script makes a random password for each
  student, and the professor hands them out privately.
- **Change password in Settings.** Students can change it while signed in.
  The screen reminds them not to reuse their Microsoft password.
- **Students first, teachers second.** Clubs, orgs and officer positions come
  from a second list the team will send.

## Where things live

| What | Where | In Git? |
|---|---|---|
| Master list (real names) | `private/students.csv` | **No** (`/private/` is ignored) |
| Club / officer list | `private/orgs.csv` | **No** |
| Generated passwords | `private/passwords.csv` | **No** |
| Supabase secret key (`service_role`) | `private/.env` | **No**. Never put it in the app. |
| Supabase URL + public `anon` key | app config | Yes. It's public by design; the security rules protect the data. |
| Table definitions and security rules | `supabase/` (SQL files) | Yes |
| Account-creation script | `tool/` | Yes. It reads from `private/`. |

## Master list format

Copied from the official enrollment list (1st Semester A.Y. 2026–2027,
55 students), one row per student. Only the columns we need:

```
last_name,first_name,suffix,program,year_level
Diolata,Rufino,III,BSCS,3
```

Programs: ACT-CS 1 (6), ACT-IT 1 (8), ACS 2 (13), BSCS 3 (16), BSCS 4 (12).
The list has no sections, so each program and year counts as one block
(assumption). Middle initials and sex are left out because the app doesn't
need them. No student numbers: the app shows generated, masked sample IDs.

## Email rules (decided 2026-11-08)

- The full first name is used, with spaces and periods removed: `Stephen Michael Hadi` → `StephenMichael.Hadi@smcl.edu.ph`, `Ma. Diane Zulueta` → `MaDiane.Zulueta@smcl.edu.ph`.
- `ñ` becomes `n`, and accents are dropped.
- Suffixes such as `Jr.` and `III` are left out of the email but stay in the shown name.
- **Two students with the same name:** the script stops and lists them, so we decide by hand.

## Stages

Each stage gets tested before the next one starts.

0. **Setup. ✅ Done 2026-11-09.** Supabase project `xxmicigqharmocbwpafz`; migration
   `supabase/migrations/20261109000000_profiles.sql` (profiles, private QR tokens,
   auto-profile trigger, security rules, all self-tested); public sign-up confirmed
   off; `tool/create_accounts.dart` created all 55 accounts (55 profiles, 55 unique
   QR tokens). Passwords are in `private/passwords.csv`.
1. **Sign-in. Built 2026-11-09, waiting for a real sign-in check by the team.**
   `supabase_flutter` package; `SupabaseUserService` (lib/services/) signs in,
   remembers the sign-in on the device, reads `profiles` + `qr_tokens`.
   Sign-in screen: school email + password, then "or preview with sample data"
   (kept for teachers until Stage 4; remove at launch). Settings: Log Out signs
   out for real and hides the sample-account switcher; Account & Security ›
   Change password (checks the current one, at least 8 characters).
   Still sample data after sign-in: schedule (empty for real students),
   grades (same sample set for everyone), events, clubs. About edits aren't
   saved to the database yet (Stage 2).
2. **My data.** Profile, schedule (by section), sample grades and attendance
   come from the database, per student.
3. **Shared features, one at a time:** Connect → clubs and officers → events →
   posts and photos.
4. **Teachers.** Teacher accounts, advisers, attendance scanning, consultations.
5. **Launch.** Host the PWA online (open decision 7) and write a short tester guide.

## Supabase setup (done by the team, not by Claude)

Claude can't create accounts. One team member does this once:

1. Sign up at supabase.com and create a project on the **Free** plan. Pick the
   region closest to the Philippines (Southeast Asia / Singapore). Save the
   database password in a password manager.
2. **Authentication → Sign In / Providers:** turn **off** "Allow new users to sign up".
3. **Email provider:** turn **off** "Confirm email" and "Secure password change",
   so Supabase never emails the `@smcl.edu.ph` addresses.
4. **Project Settings → API:** copy the Project URL and the `anon` key for the app.
   Put the `service_role` key only in `private/.env`.

(Menu names may differ slightly in Supabase's current dashboard.)

## Watch out for

- **Free projects pause after about a week with no activity.** Before the test
  starts, sign in once to wake the project up.
- Free-plan limits are far above 55 users, but check them on supabase.com
  before the test.
- The frontend hides things, but the security rules in the database are what
  actually protect the data. Every table gets rules before students use it.

## Still open

- Club and officer list (coming from the team).
- Teacher accounts: who, and their email format.
- PWA hosting (open decision 7).
