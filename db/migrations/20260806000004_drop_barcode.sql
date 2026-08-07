-- migrate:up

-- The manufacturer barcode field is no longer used: products are identified
-- only by their internal SKU (encoded in the QR label). Dropping the column
-- also drops its UNIQUE constraint.
alter table products drop column if exists barcode;

-- migrate:down

alter table products add column barcode text unique;
