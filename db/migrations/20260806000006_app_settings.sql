-- migrate:up

-- Single-row business settings, shared by every device (web + mobile).
create table app_settings (
  id                integer primary key default 1 check (id = 1),
  business_name     text not null default 'Inventy',
  default_threshold integer not null default 0 check (default_threshold >= 0),
  updated_at        timestamptz not null default now()
);

insert into app_settings (id) values (1) on conflict do nothing;

-- migrate:down

drop table if exists app_settings;
