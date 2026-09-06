-- ============================================================
-- CampusLink — Supabase schema
-- Paste this whole file into the Supabase SQL Editor and run it.
-- ============================================================

-- ---------- Users & auth ----------
create table if not exists users (
  user_id        text primary key,
  institution    text not null,
  user_type      text not null check (user_type in ('admin','teacher','student','guest')),
  email          text,
  password_hash  text,              -- bcrypt; NULL for guests
  avatar_media_id uuid,
  created_at     timestamptz not null default now()
);

create table if not exists fcm_tokens (
  username    text primary key,
  token       text not null,
  updated_at  timestamptz not null default now()
);

-- ---------- People ----------
create table if not exists students (
  id                   text primary key,
  institution          text not null,
  name                 text not null,
  username             text,
  password_hash        text,        -- bcrypt
  grade                text,
  section              text,
  contact              text,
  email                text,
  fingerprint_enrolled text not null default 'NO' check (fingerprint_enrolled in ('NO','PENDING','YES')),
  created_at           timestamptz not null default now()
);
create index if not exists students_institution_idx on students (institution);

create table if not exists teachers (
  id            text primary key,
  institution   text not null,
  name          text not null,
  username      text,
  password_hash text,
  subject       text,
  qualification text,
  experience    text,
  contact       text,
  email         text,
  created_at    timestamptz not null default now()
);
create index if not exists teachers_institution_idx on teachers (institution);

-- ---------- Attendance (written by the fingerprint device sync) ----------
create table if not exists attendance (
  id         bigserial primary key,
  institution text not null,
  student_id text not null,
  username   text,
  status     text not null check (status in ('present','late','absent')),
  timestamp  timestamptz,
  date       date not null
);
create index if not exists attendance_date_idx on attendance (institution, date);
create unique index if not exists attendance_unique on attendance (institution, student_id, date);

-- ---------- Events ----------
create table if not exists events (
  id              uuid primary key default gen_random_uuid(),
  institution     text not null,
  title           text not null,
  event_date      timestamptz not null,
  description     text default '',
  location        text default '',
  location_detail text default '',
  schedule        jsonb not null default '[]'::jsonb,
  coordinators    jsonb not null default '[]'::jsonb,
  created_at      timestamptz not null default now()
);
create index if not exists events_institution_date_idx on events (institution, event_date);

-- ---------- Community posts & media ----------
create table if not exists media (
  id          uuid primary key default gen_random_uuid(),
  institution text,
  file_name   text,
  mime_type   text,
  data        bytea not null,
  created_at  timestamptz not null default now()
);

create table if not exists posts (
  id          bigserial primary key,
  institution text not null,
  user_id     text not null,
  content     text default '',
  media_id    uuid references media (id),
  likes_count integer not null default 0,
  created_at  timestamptz not null default now()
);
create index if not exists posts_institution_idx on posts (institution, created_at desc);

-- ---------- Chatroom ----------
create table if not exists chat_messages (
  id          bigserial primary key,
  institution text not null,
  sender      text not null,
  text        text not null,
  created_at  timestamptz not null default now()
);
create index if not exists chat_institution_idx on chat_messages (institution, created_at);

-- ---------- Chatbot ----------
create table if not exists chatbot_questions (
  id            bigserial primary key,
  category      text not null,
  question_text text not null,
  keywords      text not null,
  created_at    timestamptz not null default now()
);

create table if not exists chatbot_answers (
  id          uuid primary key default gen_random_uuid(),
  institution text not null,
  question_id bigint not null references chatbot_questions (id) on delete cascade,
  answer      text not null,
  active      boolean not null default true,
  updated_at  timestamptz not null default now(),
  unique (institution, question_id)
);

-- ---------- Fingerprint device ----------
create table if not exists devices (
  device_id   text primary key,
  device_name text,
  last_ip     text,
  last_seen   timestamptz
);

create table if not exists device_commands (
  id         bigserial primary key,
  device_id  text not null default 'default',
  command    text not null check (command in ('enroll','delete')),
  student_id text,
  status     text not null default 'pending' check (status in ('pending','sent','in_progress','done')),
  result     jsonb,
  created_at timestamptz not null default now(),
  sent_at    timestamptz,
  result_at  timestamptz
);
create index if not exists device_commands_pending_idx on device_commands (device_id, status, created_at);

-- ---------- Seed: default predefined questions ----------
insert into chatbot_questions (category, question_text, keywords)
select * from (values
  ('admissions',  'What courses do you offer?',              'courses,programs,admissions,offer'),
  ('admissions',  'What are the eligibility criteria?',      'eligibility,criteria,admission,requirements'),
  ('academics',   'What is the class schedule?',             'schedule,timetable,class,timing'),
  ('facilities',  'What facilities are available on campus?','facilities,library,lab,campus,hostel'),
  ('placements',  'How are the placements at your college?', 'placement,job,recruitment,company'),
  ('contact',     'How can I contact the administration?',   'contact,phone,email,administration,office')
) as seed(category, question_text, keywords)
where not exists (select 1 from chatbot_questions);
