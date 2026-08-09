-- migrate:up

-- Rename the "talle" prefix on existing product details to "Talla"
-- (e.g. "talle 40 · negro" -> "Talla 40 · negro"). Cosmetic data fix so the
-- inventory reads "Talla" everywhere; new products already use "Talla".
update products set detail = replace(detail, 'talle ', 'Talla ')
where detail like '%talle %';

-- migrate:down

update products set detail = replace(detail, 'Talla ', 'talle ')
where detail like '%Talla %';
