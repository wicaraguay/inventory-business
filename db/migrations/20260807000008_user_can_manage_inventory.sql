-- migrate:up
-- Per-employee toggle: when true, this employee may also manage inventory
-- (create/edit products and register stock movements). Owners always can.
ALTER TABLE users
  ADD COLUMN can_manage_inventory boolean NOT NULL DEFAULT false;

-- migrate:down
ALTER TABLE users DROP COLUMN can_manage_inventory;
