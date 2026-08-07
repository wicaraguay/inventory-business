-- migrate:up

-- One optional image per product (compressed JPEG, stored inline). Kept in a
-- side table so the product list query never drags the blob around.
create table product_images (
  product_id   uuid primary key references products (id) on delete cascade,
  data         bytea not null,
  content_type text not null default 'image/jpeg',
  updated_at   timestamptz not null default now()
);

-- migrate:down

drop table if exists product_images;
