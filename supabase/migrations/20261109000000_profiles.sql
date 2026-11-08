-- Stage 0: one profile per account (docs/backend-plan.md).
-- Accounts are created only by tool/create_accounts.dart (public sign-up is off).
-- Names are real (department enrollment list); masked IDs and QR tokens are samples.

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role text not null default 'student' check (role in ('student', 'teacher')),
  email text not null unique,
  first_name text not null,
  last_name text not null,
  suffix text,                          -- 'Jr.', 'III'; shown, not in the email
  program text check (program in ('ACT-CS', 'ACT-IT', 'ACS', 'BSCS')),
  year_level smallint check (year_level between 1 and 4),
  masked_id text not null,              -- generated sample, e.g. '2024-****-37'
  about text check (char_length(about) <= 160), -- same limit as Edit Profile
  created_at timestamptz not null default now(),
  -- Students always have a program and year; teachers (later) don't.
  check (role <> 'student' or (program is not null and year_level is not null))
);

-- QR tokens live in their own table so students can't read each other's
-- (that would let someone show another student's QR). Random, never personal data.
create table public.qr_tokens (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  token text not null unique
    default ('MOCK-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)))
);

-- Security rules (Row Level Security). With RLS on, nothing is allowed
-- unless a policy below allows it. Signed-out visitors (anon) get nothing.
alter table public.profiles enable row level security;
alter table public.qr_tokens enable row level security;

-- Any signed-in user can see profiles (People search, members, Going lists).
create policy "Signed-in users read profiles" on public.profiles
  for select to authenticated using (true);

-- You may edit only your own profile...
create policy "Users update own profile" on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

-- ...and only the About text (spec §10: names, IDs, program are locked).
revoke insert, update, delete on public.profiles from anon, authenticated;
grant update (about) on public.profiles to authenticated;

-- You may read only your own QR token. No one edits tokens from the app.
create policy "Users read own QR token" on public.qr_tokens
  for select to authenticated using ((select auth.uid()) = user_id);
revoke insert, update, delete on public.qr_tokens from anon, authenticated;

-- When the script creates an account, make its profile and QR token in the
-- same step. If the details are missing or wrong, the account isn't created
-- either, so there is never an account without a profile.
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, role, email, first_name, last_name, suffix, program, year_level, masked_id)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'role', 'student'),
    new.email,
    new.raw_user_meta_data ->> 'first_name',
    new.raw_user_meta_data ->> 'last_name',
    nullif(new.raw_user_meta_data ->> 'suffix', ''),
    new.raw_user_meta_data ->> 'program',
    (new.raw_user_meta_data ->> 'year_level')::smallint,
    new.raw_user_meta_data ->> 'masked_id'
  );
  insert into public.qr_tokens (user_id) values (new.id);
  return new;
end;
$$;

-- Only the trigger runs this function; the app can't call it directly.
revoke execute on function public.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
