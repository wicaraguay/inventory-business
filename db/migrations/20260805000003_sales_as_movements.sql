-- migrate:up

-- Every stock change is now a movement. A sale creates an 'exit' movement
-- (note 'Venta') PLUS its sales row (for the price). Stock = entries - exits.

-- Backfill exit movements for existing sales so stock stays the same.
insert into stock_movements (product_id, quantity, type, note, created_at)
select product_id, quantity, 'exit', 'Venta', created_at
from sales;

-- Stock is now purely derived from movements (sales already counted as exits).
create or replace view product_stock as
select
  p.id as product_id,
  coalesce(sum(case when m.type = 'entry' then m.quantity
                    when m.type = 'exit'  then -m.quantity
                    else 0 end), 0)::int as current_stock
from products p
left join stock_movements m on m.product_id = p.id
group by p.id;

-- migrate:down

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

delete from stock_movements where note = 'Venta';
