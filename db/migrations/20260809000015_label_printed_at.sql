-- migrate:up

-- Track whether a product's QR label has been printed AND physically applied.
-- NULL = pending (not labeled yet); a timestamp = done. Existing products are
-- assumed already labeled (the owner printed them before this feature); new
-- ones start pending until explicitly marked.
alter table products add column label_printed_at timestamptz;
update products set label_printed_at = now();

-- migrate:down

alter table products drop column if exists label_printed_at;
