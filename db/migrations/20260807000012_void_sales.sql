-- migrate:up

-- Voiding a sale never deletes it: it's marked here (kept for the record),
-- excluded from totals, and its stock is restored with a compensating entry.
alter table sales add column voided_at timestamptz;
alter table sales add column voided_by text;

-- migrate:down

alter table sales drop column if exists voided_by;
alter table sales drop column if exists voided_at;
