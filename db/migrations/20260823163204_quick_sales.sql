-- migrate:up
alter table sales alter column product_id drop not null;
alter table sales add column description text;
alter table sales add column size_label text;

-- migrate:down
delete from sales where product_id is null;
alter table sales drop column if exists size_label;
alter table sales drop column if exists description;
alter table sales alter column product_id set not null;
