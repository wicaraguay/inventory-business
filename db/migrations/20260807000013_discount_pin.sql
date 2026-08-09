-- migrate:up

-- Bcrypt hash of the "PIN de descuento" — separate from any login password, so
-- the owner can share it with a trusted employee (and change it) without
-- exposing their account.
alter table app_settings add column discount_pin_hash text;

-- migrate:down

alter table app_settings drop column if exists discount_pin_hash;
