-- migrate:up

-- Supplier ("costo") price — what the shop paid. Owner-only (the API never
-- sends it to employees). Nullable.
alter table products add column supplier_price numeric(12, 2);

-- Group the sizes of one model together. Every product belongs to a model; a
-- single loose product is just a model with one size. New bulk loads share one
-- model_id across their sizes. Existing rows each become their own model (the
-- default fills a unique id per row — no retroactive grouping).
alter table products add column model_id uuid not null default gen_random_uuid();
create index products_model_id_idx on products (model_id);

-- migrate:down

drop index if exists products_model_id_idx;
alter table products drop column if exists model_id;
alter table products drop column if exists supplier_price;
