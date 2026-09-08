-- Elimina el módulo de centros de costos (cost centers) del esquema.
-- Se eliminan todas las FK que referencian a cost_centers y la tabla misma.
-- Nota: al droppear las columnas, PostgreSQL elimina automáticamente
-- los índices definidos sobre ellas (idx_req_cost_center,
-- idx_employee_cost_center, idx_dn_cost_center, idx_user_cost_center).

ALTER TABLE requisitions    DROP COLUMN IF EXISTS cost_center_id;
ALTER TABLE employees       DROP COLUMN IF EXISTS cost_center_id;
ALTER TABLE dispatch_notes  DROP COLUMN IF EXISTS cost_center_id;
ALTER TABLE app_user        DROP COLUMN IF EXISTS cost_center_id;
ALTER TABLE invite_tokens   DROP COLUMN IF EXISTS cost_center_id;
ALTER TABLE purchase_orders DROP COLUMN IF EXISTS cost_center_id;

DROP TABLE IF EXISTS cost_centers;
