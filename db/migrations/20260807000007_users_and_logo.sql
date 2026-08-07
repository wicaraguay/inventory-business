-- migrate:up

-- System users with roles (owner / employee).
create table users (
  id            uuid primary key default gen_random_uuid(),
  username      text not null unique,
  password_hash text not null,
  role          text not null check (role in ('owner', 'employee')),
  display_name  text not null,
  created_at    timestamptz not null default now()
);

-- Business logo (shown on the login screen and the sidebar).
alter table app_settings add column logo bytea;
alter table app_settings add column logo_updated_at timestamptz;

-- migrate:down

alter table app_settings drop column if exists logo_updated_at;
alter table app_settings drop column if exists logo;
drop table if exists users;
