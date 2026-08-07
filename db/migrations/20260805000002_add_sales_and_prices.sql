-- migrate:up

-- Prices on products: normal sale price + minimum ("último") price.
alter table products add column sale_price numeric(12, 2);
alter table products add column min_price numeric(12, 2);

-- Sales: each row is one sale at a chosen unit price. Decrements stock.
create table sales (
  id         uuid primary key default gen_random_uuid(),
  product_id uuid not null references products (id) on delete cascade,
  quantity   integer not null check (quantity > 0),
  unit_price numeric(12, 2) not null check (unit_price >= 0),
  total      numeric(12, 2) not null,
  created_at timestamptz not null default now()
);

create index sales_product_id_idx on sales (product_id);
create index sales_created_at_idx on sales (created_at);

-- Stock now also subtracts sales: (entries - exits) - sold.
create or replace view product_stock as
select
  p.id as product_id,
  (
    coalesce((
      select sum(case when m.type = 'entry' then m.quantity else -m.quantity end)
      from stock_movements m where m.product_id = p.id
    ), 0)
    - coalesce((
      select sum(s.quantity) from sales s where s.product_id = p.id
    ), 0)
  )::int as current_stock
from products p;

-- migrate:down

drop view if exists product_stock;
create view product_stock as
select
  p.id as product_id,
  coalesce(sum(case when m.type = 'entry' then m.quantity
                    when m.type = 'exit'  then -m.quantity
                    else 0 end), 0)::int as current_stock
from products p
left join stock_movements m on m.product_id = p.id
group by p.id;

drop table if exists sales;
alter table products drop column if exists min_price;
alter table products drop column if exists sale_price;
