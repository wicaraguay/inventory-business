-- migrate:up

create extension if not exists "pgcrypto"; -- gen_random_uuid()

-- Flat model: each product IS a sellable item (e.g. "Botín de cuero" size 40).
-- No variants. Stock is derived from movements.
create table products (
  id                  uuid primary key default gen_random_uuid(),
  name                text not null,
  detail              text,                          -- "talle 40 · negro" (optional)
  sku                 text not null unique,          -- internal code -> QR label
  barcode             text unique,                   -- manufacturer EAN/UPC (optional)
  low_stock_threshold integer not null default 0 check (low_stock_threshold >= 0),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create table stock_movements (
  id         uuid primary key default gen_random_uuid(),
  product_id uuid not null references products (id) on delete cascade,
  quantity   integer not null check (quantity > 0),
  type       text not null check (type in ('entry', 'exit')),
  note       text,
  created_at timestamptz not null default now()
);

create index stock_movements_product_id_idx on stock_movements (product_id);

-- Current stock is DERIVED, never stored.
create view product_stock as
select
  p.id as product_id,
  coalesce(sum(case when m.type = 'entry' then m.quantity
                    when m.type = 'exit'  then -m.quantity
                    else 0 end), 0)::int as current_stock
from products p
left join stock_movements m on m.product_id = p.id
group by p.id;

-- Products at or below their threshold -> feed in-app low-stock alerts.
create view low_stock_products as
select ps.product_id, ps.current_stock, p.low_stock_threshold,
       p.name, p.detail, p.sku
from product_stock ps
join products p on p.id = ps.product_id
where ps.current_stock <= p.low_stock_threshold;

-- migrate:down

drop view if exists low_stock_products;
drop view if exists product_stock;
drop table if exists stock_movements;
drop table if exists products;
