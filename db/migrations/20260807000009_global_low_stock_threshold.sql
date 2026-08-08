-- migrate:up

-- The low-stock threshold is now a single GLOBAL setting (app_settings), not a
-- per-product value. Redefine the alerts view to compare every product's stock
-- against that global threshold, so changing it in Configuración affects all
-- products at once. The per-product column stays but is no longer used here.
create or replace view low_stock_products as
select ps.product_id,
       ps.current_stock,
       s.default_threshold as low_stock_threshold,
       p.name, p.detail, p.sku
from product_stock ps
join products p on p.id = ps.product_id
cross join app_settings s
where ps.current_stock <= s.default_threshold;

-- migrate:down

create or replace view low_stock_products as
select ps.product_id, ps.current_stock, p.low_stock_threshold,
       p.name, p.detail, p.sku
from product_stock ps
join products p on p.id = ps.product_id
where ps.current_stock <= p.low_stock_threshold;
