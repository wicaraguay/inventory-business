-- migrate:up

-- Saved end-of-day cash counts (arqueo). History of every close.
create table cash_closes (
  id            uuid primary key default gen_random_uuid(),
  opening_float numeric(12, 2) not null default 0,
  sales_total   numeric(12, 2) not null default 0,
  counted       numeric(12, 2) not null default 0,
  difference    numeric(12, 2) not null default 0,
  closed_by     text,
  closed_at     timestamptz not null default now()
);

-- "Read"/snooze marks for low-stock alerts. A snoozed product is hidden from
-- alerts for a few days, then reappears if still low.
create table low_stock_snoozes (
  product_id uuid primary key references products (id) on delete cascade,
  snoozed_at timestamptz not null default now()
);

-- migrate:down

drop table if exists low_stock_snoozes;
drop table if exists cash_closes;
