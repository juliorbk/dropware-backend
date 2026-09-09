-- ════════════════════════════════════════════════════════════════════
-- VISCO-SG — Datos de demostración para nutrir el dashboard
-- ════════════════════════════════════════════════════════════════════
-- Genera Requisiciones, Órdenes de Compra, Recepciones, Despachos y
-- Movimientos de Almacén, referenciando productos/proveedores/almacenes/
-- empleados/usuarios/centros de costo ya existentes en la BD.
--
-- Es idempotente: elimina los registros de demostración previos
-- (identificados por los prefijos RQ-DEMO/OC-DEMO/RC-DEMO/DS-DEMO y
-- reason 'Seed ...') antes de volver a insertarlos.
--
-- Ejecutar:  .\scripts\seed-demo-data.ps1
--            o docker exec -i visco_db_dev psql -U visco_admin -d visco_db < scripts\seed-demo-data.sql
-- ════════════════════════════════════════════════════════════════════

BEGIN;

-- ── Limpieza de datos de demostración previos (idempotencia) ─────────
DELETE FROM inventory_movements
 WHERE reason LIKE 'Goods receipt - RC-DEMO-%'
    OR reason LIKE 'Dispatch: DS-DEMO-%'
    OR reason LIKE 'Seed %';

DELETE FROM good_receipt_items
 WHERE good_receipt_id IN (SELECT id FROM good_receipts WHERE receipt_number LIKE 'RC-DEMO-%');
DELETE FROM good_receipts WHERE receipt_number LIKE 'RC-DEMO-%';

DELETE FROM dispatch_note_items
 WHERE dispatch_note_id IN (SELECT id FROM dispatch_notes WHERE dispatch_number LIKE 'DS-DEMO-%');
DELETE FROM dispatch_notes WHERE dispatch_number LIKE 'DS-DEMO-%';

DELETE FROM purchase_order_items
 WHERE purchase_order_id IN (SELECT id FROM purchase_orders WHERE order_number LIKE 'OC-DEMO-%');
DELETE FROM purchase_orders WHERE order_number LIKE 'OC-DEMO-%';

DELETE FROM requisition_items
 WHERE requisition_id IN (SELECT id FROM requisitions WHERE requisition_number LIKE 'RQ-DEMO-%');
DELETE FROM requisitions WHERE requisition_number LIKE 'RQ-DEMO-%';

-- ════════════════════════════════════════════════════════════════════
-- 1. REQUISICIONES
-- ════════════════════════════════════════════════════════════════════

-- RQ-DEMO-0001/2026 — DRAFT
INSERT INTO requisitions (requisition_number, description, status, requested_by_id, cost_center_id, created_at, updated_at, version)
VALUES ('RQ-DEMO-0001/2026', 'REPOSICION DE INSUMOS DE LIMPIEZA PARA TALLERES', 'DRAFT',
        '05ad310e-4cff-48fc-84e7-90fdd8cb56a8', 293, '2026-08-20 09:00:00', '2026-08-20 09:00:00', 0);
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 1962, 150, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0001/2026';

-- RQ-DEMO-0002/2026 — PENDING
INSERT INTO requisitions (requisition_number, description, status, requested_by_id, cost_center_id, created_at, updated_at, version)
VALUES ('RQ-DEMO-0002/2026', 'ADQUISICION DE HERRAMIENTAS MANUALES PARA MANTENIMIENTO', 'PENDING',
        '6c4f539a-6660-44fd-8aa6-02e12cbe2334', 404, '2026-09-02 10:15:00', '2026-09-02 10:15:00', 0);
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 9, 25, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0002/2026';
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 41, 150, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0002/2026';

-- RQ-DEMO-0003/2026 — AWAITING_APPROVAL
INSERT INTO requisitions (requisition_number, description, status, requested_by_id, cost_center_id, created_at, updated_at, version)
VALUES ('RQ-DEMO-0003/2026', 'COMPRA DE ACIDOS Y REACTIVOS PARA LABORATORIO', 'AWAITING_APPROVAL',
        '74c9d767-f359-45fa-90e5-8b30de957776', 5, '2026-09-03 08:30:00', '2026-09-03 08:30:00', 0);
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 373, 100, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0003/2026';
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 928, 60, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0003/2026';
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 930, 40, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0003/2026';

-- RQ-DEMO-0004/2026 — APPROVED
INSERT INTO requisitions (requisition_number, description, status, requested_by_id, approved_by_id, approved_at, cost_center_id, created_at, updated_at, version)
VALUES ('RQ-DEMO-0004/2026', 'REPOSICION DE PINTURAS Y SELLADORES PARA INFRAESTRUCTURA', 'APPROVED',
        '21a54729-7925-4138-b8fd-c2511c619679', 'e6e0728c-ea74-4abf-9d04-abcf3594ad9e', '2026-09-04 11:00:00', 422, '2026-09-01 09:00:00', '2026-09-04 11:00:00', 0);
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 219707, 90, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0004/2026';
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 219708, 25, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0004/2026';

-- RQ-DEMO-0005/2026 — REJECTED
INSERT INTO requisitions (requisition_number, description, status, requested_by_id, approved_by_id, approved_at, rejection_reason, cost_center_id, created_at, updated_at, version)
VALUES ('RQ-DEMO-0005/2026', 'SOLICITUD DE EQUIPOS DE COMPUTO ADICIONALES', 'REJECTED',
        '57ff9479-46bf-454c-90f4-3ea5c2eae099', 'e6e0728c-ea74-4abf-9d04-abcf3594ad9e', '2026-08-18 15:00:00', 'Presupuesto no disponible para este trimestre', 464, '2026-08-15 10:00:00', '2026-08-18 15:00:00', 0);
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 9, 10, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0005/2026';

-- RQ-DEMO-0006/2026 — CONVERTED
INSERT INTO requisitions (requisition_number, description, status, requested_by_id, approved_by_id, approved_at, cost_center_id, created_at, updated_at, version)
VALUES ('RQ-DEMO-0006/2026', 'ADQUISICION DE ACEITES LUBRICANTES PARA FLOTA DE CAMIONES', 'CONVERTED',
        'f93cd1a6-b098-4a0d-a88e-5e416c8b1bf9', 'f93cd1a6-b098-4a0d-a88e-5e416c8b1bf9', '2026-03-28 09:00:00', 404, '2026-03-25 09:00:00', '2026-03-28 09:00:00', 0);
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 1802, 60, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0006/2026';

-- RQ-DEMO-0007/2026 — CONVERTED
INSERT INTO requisitions (requisition_number, description, status, requested_by_id, approved_by_id, approved_at, cost_center_id, created_at, updated_at, version)
VALUES ('RQ-DEMO-0007/2026', 'COMPRA DE GRAPAS Y MATERIAL DE FIJACION PARA EMBALAJE', 'CONVERTED',
        '465abcfd-feb5-4006-afdb-64e646a937cb', 'e6e0728c-ea74-4abf-9d04-abcf3594ad9e', '2026-04-25 09:00:00', 406, '2026-04-22 09:00:00', '2026-04-25 09:00:00', 0);
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 22142, 400, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0007/2026';
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 393957, 300, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0007/2026';

-- RQ-DEMO-0008/2026 — CONVERTED
INSERT INTO requisitions (requisition_number, description, status, requested_by_id, approved_by_id, approved_at, cost_center_id, created_at, updated_at, version)
VALUES ('RQ-DEMO-0008/2026', 'REPOSICION DE CONSUMIBLES ELECTRICOS PARA PARADA DE PLANTA', 'CONVERTED',
        'f93cd1a6-b098-4a0d-a88e-5e416c8b1bf9', 'e6e0728c-ea74-4abf-9d04-abcf3594ad9e', '2026-05-28 09:00:00', 406, '2026-05-25 09:00:00', '2026-05-28 09:00:00', 0);
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 219711, 100, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0008/2026';
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 219712, 60, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0008/2026';
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 219713, 150, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0008/2026';
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 219714, 80, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0008/2026';

-- RQ-DEMO-0009/2026 — APPROVED
INSERT INTO requisitions (requisition_number, description, status, requested_by_id, approved_by_id, approved_at, cost_center_id, created_at, updated_at, version)
VALUES ('RQ-DEMO-0009/2026', 'ADQUISICION DE EQUIPOS MEDICOS PARA AMBULATORIO', 'APPROVED',
        '6c4f539a-6660-44fd-8aa6-02e12cbe2334', 'e6e0728c-ea74-4abf-9d04-abcf3594ad9e', '2026-07-02 09:00:00', 5, '2026-06-28 09:00:00', '2026-07-02 09:00:00', 0);
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 219701, 2, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0009/2026';
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 219702, 2, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0009/2026';

-- RQ-DEMO-0010/2026 — PENDING
INSERT INTO requisitions (requisition_number, description, status, requested_by_id, cost_center_id, created_at, updated_at, version)
VALUES ('RQ-DEMO-0010/2026', 'SOLICITUD DE DISCOS DE CORTE Y ESMERILADO', 'PENDING',
        '57ff9479-46bf-454c-90f4-3ea5c2eae099', 55, '2026-09-05 14:00:00', '2026-09-05 14:00:00', 0);
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 41, 250, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0010/2026';
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 48, 180, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0010/2026';

-- RQ-DEMO-0011/2026 — CANCELLED
INSERT INTO requisitions (requisition_number, description, status, requested_by_id, rejection_reason, cost_center_id, created_at, updated_at, version)
VALUES ('RQ-DEMO-0011/2026', 'COMPRA DE VALVULAS PARA SISTEMA DE RIEGO', 'CANCELLED',
        '74c9d767-f359-45fa-90e5-8b30de957776', 'Solicitud duplicada', 293, '2026-08-10 09:00:00', '2026-08-11 09:00:00', 0);
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 5, 200, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0011/2026';

-- RQ-DEMO-0012/2026 — APPROVED
INSERT INTO requisitions (requisition_number, description, status, requested_by_id, approved_by_id, approved_at, cost_center_id, created_at, updated_at, version)
VALUES ('RQ-DEMO-0012/2026', 'REPOSICION DE HERRAMIENTAS Y CONSUMIBLES VARIOS', 'APPROVED',
        '21a54729-7925-4138-b8fd-c2511c619679', 'e6e0728c-ea74-4abf-9d04-abcf3594ad9e', '2026-09-01 08:00:00', 422, '2026-08-30 09:00:00', '2026-09-01 08:00:00', 0);
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 219707, 30, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0012/2026';
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 219708, 15, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0012/2026';
INSERT INTO requisition_items (requisition_id, product_id, quantity, notes)
SELECT id, 41, 120, NULL FROM requisitions WHERE requisition_number = 'RQ-DEMO-0012/2026';

-- ════════════════════════════════════════════════════════════════════
-- 2. ÓRDENES DE COMPRA
-- ════════════════════════════════════════════════════════════════════

-- OC-DEMO-0001/2026 — DELIVERED (Abr)
INSERT INTO purchase_orders (order_number, description, status, type, payment_method, supplier_id, destination_warehouse_id, created_by_id, requisition_id, incoterm, lead_time, created_at, updated_at, version)
VALUES ('OC-DEMO-0001/2026', 'ADQUISICION DE ACEITES LUBRICANTES PARA FLOTA DE CAMIONES', 'DELIVERED', 'MATERIALS', 'BANK_TRANSFER',
        350, 3, 'e6e0728c-ea74-4abf-9d04-abcf3594ad9e',
        (SELECT id FROM requisitions WHERE requisition_number = 'RQ-DEMO-0006/2026'),
        'CIF', 12, '2026-04-05 09:00:00', '2026-04-05 09:00:00', 0);
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 1802, 60, 1020.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0001/2026';
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 5, 100, 15.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0001/2026';

-- OC-DEMO-0002/2026 — DELIVERED (Abr)
INSERT INTO purchase_orders (order_number, description, status, type, payment_method, supplier_id, destination_warehouse_id, created_by_id, incoterm, lead_time, created_at, updated_at, version)
VALUES ('OC-DEMO-0002/2026', 'REPOSICION DE INSUMOS DE LIMPIEZA PARA TALLERES', 'DELIVERED', 'MATERIALS', 'USDT',
        30, 4, '05ad310e-4cff-48fc-84e7-90fdd8cb56a8', 'FOB', 8, '2026-04-12 09:00:00', '2026-04-12 09:00:00', 0);
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 1962, 200, 35.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0002/2026';
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 219703, 50, 5.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0002/2026';

-- OC-DEMO-0003/2026 — DELIVERED (May)
INSERT INTO purchase_orders (order_number, description, status, type, payment_method, supplier_id, destination_warehouse_id, created_by_id, requisition_id, incoterm, lead_time, created_at, updated_at, version)
VALUES ('OC-DEMO-0003/2026', 'COMPRA DE GRAPAS Y MATERIAL DE FIJACION PARA EMBALAJE', 'DELIVERED', 'MATERIALS', 'CASH',
        289, 3, 'e6e0728c-ea74-4abf-9d04-abcf3594ad9e',
        (SELECT id FROM requisitions WHERE requisition_number = 'RQ-DEMO-0007/2026'),
        'FOB', 10, '2026-05-02 09:00:00', '2026-05-02 09:00:00', 0);
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 22142, 400, 25.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0003/2026';
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 393957, 300, 10.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0003/2026';

-- OC-DEMO-0004/2026 — COMPLETED (May)
INSERT INTO purchase_orders (order_number, description, status, type, payment_method, supplier_id, destination_warehouse_id, created_by_id, requisition_id, incoterm, lead_time, created_at, updated_at, version)
VALUES ('OC-DEMO-0004/2026', 'COMPRA DE ACIDOS Y REACTIVOS PARA LABORATORIO', 'COMPLETED', 'MATERIALS', 'BANK_TRANSFER',
        6, 3, '74c9d767-f359-45fa-90e5-8b30de957776',
        (SELECT id FROM requisitions WHERE requisition_number = 'RQ-DEMO-0003/2026'),
        'EXW', 6, '2026-05-15 09:00:00', '2026-05-15 09:00:00', 0);
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 373, 150, 18.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0004/2026';
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 928, 80, 12.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0004/2026';
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 930, 60, 45.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0004/2026';

-- OC-DEMO-0005/2026 — PARTIALLY_DELIVERED (Jun)
INSERT INTO purchase_orders (order_number, description, status, type, payment_method, supplier_id, destination_warehouse_id, created_by_id, requisition_id, incoterm, lead_time, created_at, updated_at, version)
VALUES ('OC-DEMO-0005/2026', 'REPOSICION DE PINTURAS Y SELLADORES PARA INFRAESTRUCTURA', 'PARTIALLY_DELIVERED', 'MATERIALS', 'USDT',
        30, 3, 'e6e0728c-ea74-4abf-9d04-abcf3594ad9e',
        (SELECT id FROM requisitions WHERE requisition_number = 'RQ-DEMO-0004/2026'),
        'CIF', 15, '2026-06-01 09:00:00', '2026-06-01 09:00:00', 0);
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 219707, 90, 55.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0005/2026';
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 219708, 25, 28.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0005/2026';

-- OC-DEMO-0006/2026 — DELIVERED (Jun)
INSERT INTO purchase_orders (order_number, description, status, type, payment_method, supplier_id, destination_warehouse_id, created_by_id, requisition_id, incoterm, lead_time, created_at, updated_at, version)
VALUES ('OC-DEMO-0006/2026', 'REPOSICION DE CONSUMIBLES ELECTRICOS PARA PARADA DE PLANTA', 'DELIVERED', 'MATERIALS', 'CASH',
        140, 7, 'f93cd1a6-b098-4a0d-a88e-5e416c8b1bf9',
        (SELECT id FROM requisitions WHERE requisition_number = 'RQ-DEMO-0008/2026'),
        'DAP', 9, '2026-06-10 09:00:00', '2026-06-10 09:00:00', 0);
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 219711, 100, 1.87 FROM purchase_orders WHERE order_number = 'OC-DEMO-0006/2026';
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 219712, 60, 21.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0006/2026';
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 219713, 150, 1.42 FROM purchase_orders WHERE order_number = 'OC-DEMO-0006/2026';
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 219714, 80, 17.99 FROM purchase_orders WHERE order_number = 'OC-DEMO-0006/2026';

-- OC-DEMO-0007/2026 — IN_TRANSIT (Jul)
INSERT INTO purchase_orders (order_number, description, status, type, payment_method, supplier_id, destination_warehouse_id, created_by_id, requisition_id, incoterm, lead_time, created_at, updated_at, version)
VALUES ('OC-DEMO-0007/2026', 'ADQUISICION DE EQUIPOS MEDICOS PARA AMBULATORIO', 'IN_TRANSIT', 'CAPITAL_EQUIPMENT', 'BANK_TRANSFER',
        348, 3, '6c4f539a-6660-44fd-8aa6-02e12cbe2334',
        (SELECT id FROM requisitions WHERE requisition_number = 'RQ-DEMO-0009/2026'),
        'DDP', 25, '2026-07-03 09:00:00', '2026-07-03 09:00:00', 0);
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 219701, 2, 2500.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0007/2026';
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 219702, 2, 2400.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0007/2026';

-- OC-DEMO-0008/2026 — HELD_AT_CUSTOMS (Jul)
INSERT INTO purchase_orders (order_number, description, status, type, payment_method, supplier_id, destination_warehouse_id, created_by_id, incoterm, lead_time, created_at, updated_at, version)
VALUES ('OC-DEMO-0008/2026', 'COMPRA DE HERRAMIENTAS Y ABRASIVOS', 'HELD_AT_CUSTOMS', 'MATERIALS', 'USDT',
        16, 3, '05ad310e-4cff-48fc-84e7-90fdd8cb56a8', 'FOB', 18, '2026-07-14 09:00:00', '2026-07-14 09:00:00', 0);
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 9, 40, 85.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0008/2026';
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 41, 200, 8.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0008/2026';

-- OC-DEMO-0009/2026 — DELIVERED (Jul)
INSERT INTO purchase_orders (order_number, description, status, type, payment_method, supplier_id, destination_warehouse_id, created_by_id, incoterm, lead_time, created_at, updated_at, version)
VALUES ('OC-DEMO-0009/2026', 'COMPRA DE DISCOS DE CORTE Y MATERIAL DE REPARACION', 'DELIVERED', 'MATERIALS', 'CASH',
        24, 5, '57ff9479-46bf-454c-90f4-3ea5c2eae099', 'EXW', 7, '2026-07-22 09:00:00', '2026-07-22 09:00:00', 0);
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 48, 150, 22.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0009/2026';
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 43, 120, 40.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0009/2026';

-- OC-DEMO-0010/2026 — WAITING_PAYMENT (Ago)
INSERT INTO purchase_orders (order_number, description, status, type, payment_method, supplier_id, destination_warehouse_id, created_by_id, incoterm, lead_time, created_at, updated_at, version)
VALUES ('OC-DEMO-0010/2026', 'COMPRA DE COMPUESTOS Y SELLADORES PARA MANTENIMIENTO', 'WAITING_PAYMENT', 'MATERIALS', 'BANK_TRANSFER',
        35, 3, '74c9d767-f359-45fa-90e5-8b30de957776', 'CIF', 11, '2026-08-01 09:00:00', '2026-08-01 09:00:00', 0);
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 45, 300, 12.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0010/2026';

-- OC-DEMO-0011/2026 — APPROVED (Ago)
INSERT INTO purchase_orders (order_number, description, status, type, payment_method, supplier_id, destination_warehouse_id, created_by_id, requisition_id, incoterm, lead_time, created_at, updated_at, version)
VALUES ('OC-DEMO-0011/2026', 'SOLICITUD DE DISCOS DE CORTE Y ESMERILADO', 'APPROVED', 'MATERIALS', 'USDT',
        140, 3, 'e6e0728c-ea74-4abf-9d04-abcf3594ad9e',
        (SELECT id FROM requisitions WHERE requisition_number = 'RQ-DEMO-0010/2026'),
        'FOB', 8, '2026-08-08 09:00:00', '2026-08-08 09:00:00', 0);
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 41, 250, 8.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0011/2026';
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 48, 180, 22.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0011/2026';

-- OC-DEMO-0012/2026 — PENDING (Ago)
INSERT INTO purchase_orders (order_number, description, status, type, payment_method, supplier_id, destination_warehouse_id, created_by_id, incoterm, lead_time, created_at, updated_at, version)
VALUES ('OC-DEMO-0012/2026', 'COMPRA DE CONEXIONES PARA SISTEMAS HIDRAULICOS', 'PENDING', 'MATERIALS', 'CASH',
        3, 4, '05ad310e-4cff-48fc-84e7-90fdd8cb56a8', 'EXW', 5, '2026-08-15 09:00:00', '2026-08-15 09:00:00', 0);
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 5, 500, 15.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0012/2026';

-- OC-DEMO-0013/2026 — AWAITING_APPROVAL (Ago)
INSERT INTO purchase_orders (order_number, description, status, type, payment_method, supplier_id, destination_warehouse_id, created_by_id, incoterm, lead_time, created_at, updated_at, version)
VALUES ('OC-DEMO-0013/2026', 'COMPRA DE PARCHOS Y MATERIALES PARA NEUMATICOS', 'AWAITING_APPROVAL', 'MATERIALS', 'USDT',
        36, 3, '74c9d767-f359-45fa-90e5-8b30de957776', 'FOB', 6, '2026-08-25 09:00:00', '2026-08-25 09:00:00', 0);
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 8, 1000, 7.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0013/2026';

-- OC-DEMO-0014/2026 — DELIVERED (Sep)
INSERT INTO purchase_orders (order_number, description, status, type, payment_method, supplier_id, destination_warehouse_id, created_by_id, requisition_id, incoterm, lead_time, created_at, updated_at, version)
VALUES ('OC-DEMO-0014/2026', 'REPOSICION DE HERRAMIENTAS Y CONSUMIBLES VARIOS', 'DELIVERED', 'MATERIALS', 'BANK_TRANSFER',
        30, 3, 'e6e0728c-ea74-4abf-9d04-abcf3594ad9e',
        (SELECT id FROM requisitions WHERE requisition_number = 'RQ-DEMO-0012/2026'),
        'CIF', 9, '2026-09-01 09:00:00', '2026-09-01 09:00:00', 0);
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 219707, 30, 55.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0014/2026';
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 219708, 15, 28.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0014/2026';
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 41, 120, 8.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0014/2026';

-- OC-DEMO-0015/2026 — IN_TRANSIT (Sep)
INSERT INTO purchase_orders (order_number, description, status, type, payment_method, supplier_id, destination_warehouse_id, created_by_id, requisition_id, incoterm, lead_time, created_at, updated_at, version)
VALUES ('OC-DEMO-0015/2026', 'REPOSICION DE ACEITES LUBRICANTES PARA FLOTA DE CAMIONES', 'IN_TRANSIT', 'MATERIALS', 'BANK_TRANSFER',
        350, 3, 'f93cd1a6-b098-4a0d-a88e-5e416c8b1bf9',
        (SELECT id FROM requisitions WHERE requisition_number = 'RQ-DEMO-0006/2026'),
        'CIF', 12, '2026-09-03 09:00:00', '2026-09-03 09:00:00', 0);
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity, unit_price)
SELECT id, 1802, 40, 1020.00 FROM purchase_orders WHERE order_number = 'OC-DEMO-0015/2026';

-- OC-DEMO-0016/2026 — CANCELLED (Sep, sin items)
INSERT INTO purchase_orders (order_number, description, status, type, payment_method, supplier_id, destination_warehouse_id, created_by_id, rejection_reason, incoterm, lead_time, created_at, updated_at, version)
VALUES ('OC-DEMO-0016/2026', 'COMPRA DE EQUIPOS DE ILUMINACION PARA VIALIDAD', 'CANCELLED', 'CAPITAL_EQUIPMENT', 'BANK_TRANSFER',
        14, 6, '57ff9479-46bf-454c-90f4-3ea5c2eae099', 'Proveedor no pudo garantizar tiempo de entrega', 'DDP', 30, '2026-09-05 09:00:00', '2026-09-05 09:00:00', 0);

-- ════════════════════════════════════════════════════════════════════
-- 3. RECEPCIONES (Good Receipts)
-- ════════════════════════════════════════════════════════════════════

-- RC-DEMO-0001/2026 ← OC-DEMO-0001
INSERT INTO good_receipts (receipt_number, purchase_order_id, received_at, notes, closed, destination_warehouse_id, received_by_id, version)
VALUES ('RC-DEMO-0001/2026',
        (SELECT id FROM purchase_orders WHERE order_number = 'OC-DEMO-0001/2026'),
        '2026-04-08 14:00:00', 'Recepcion completa sin novedades', true, 3, 'e6e0728c-ea74-4abf-9d04-abcf3594ad9e', 0);
INSERT INTO good_receipt_items (good_receipt_id, product_id, expected_quantity, received_quantity, location_id)
SELECT id, 1802, 60, 60, 481 FROM good_receipts WHERE receipt_number = 'RC-DEMO-0001/2026';
INSERT INTO good_receipt_items (good_receipt_id, product_id, expected_quantity, received_quantity, location_id)
SELECT id, 5, 100, 100, 481 FROM good_receipts WHERE receipt_number = 'RC-DEMO-0001/2026';

-- RC-DEMO-0002/2026 ← OC-DEMO-0002
INSERT INTO good_receipts (receipt_number, purchase_order_id, received_at, notes, closed, destination_warehouse_id, received_by_id, version)
VALUES ('RC-DEMO-0002/2026',
        (SELECT id FROM purchase_orders WHERE order_number = 'OC-DEMO-0002/2026'),
        '2026-04-15 10:00:00', NULL, true, 4, '05ad310e-4cff-48fc-84e7-90fdd8cb56a8', 0);
INSERT INTO good_receipt_items (good_receipt_id, product_id, expected_quantity, received_quantity, location_id)
SELECT id, 1962, 200, 200, 41862 FROM good_receipts WHERE receipt_number = 'RC-DEMO-0002/2026';
INSERT INTO good_receipt_items (good_receipt_id, product_id, expected_quantity, received_quantity, location_id)
SELECT id, 219703, 50, 50, 41862 FROM good_receipts WHERE receipt_number = 'RC-DEMO-0002/2026';

-- RC-DEMO-0003/2026 ← OC-DEMO-0003
INSERT INTO good_receipts (receipt_number, purchase_order_id, received_at, notes, closed, destination_warehouse_id, received_by_id, version)
VALUES ('RC-DEMO-0003/2026',
        (SELECT id FROM purchase_orders WHERE order_number = 'OC-DEMO-0003/2026'),
        '2026-05-06 15:00:00', NULL, true, 3, 'e6e0728c-ea74-4abf-9d04-abcf3594ad9e', 0);
INSERT INTO good_receipt_items (good_receipt_id, product_id, expected_quantity, received_quantity, location_id)
SELECT id, 22142, 400, 400, 481 FROM good_receipts WHERE receipt_number = 'RC-DEMO-0003/2026';
INSERT INTO good_receipt_items (good_receipt_id, product_id, expected_quantity, received_quantity, location_id)
SELECT id, 393957, 300, 300, 481 FROM good_receipts WHERE receipt_number = 'RC-DEMO-0003/2026';

-- RC-DEMO-0004/2026 ← OC-DEMO-0004
INSERT INTO good_receipts (receipt_number, purchase_order_id, received_at, notes, closed, destination_warehouse_id, received_by_id, version)
VALUES ('RC-DEMO-0004/2026',
        (SELECT id FROM purchase_orders WHERE order_number = 'OC-DEMO-0004/2026'),
        '2026-05-19 11:00:00', 'Verificado por control de calidad', true, 3, '74c9d767-f359-45fa-90e5-8b30de957776', 0);
INSERT INTO good_receipt_items (good_receipt_id, product_id, expected_quantity, received_quantity, location_id)
SELECT id, 373, 150, 150, 481 FROM good_receipts WHERE receipt_number = 'RC-DEMO-0004/2026';
INSERT INTO good_receipt_items (good_receipt_id, product_id, expected_quantity, received_quantity, location_id)
SELECT id, 928, 80, 80, 481 FROM good_receipts WHERE receipt_number = 'RC-DEMO-0004/2026';
INSERT INTO good_receipt_items (good_receipt_id, product_id, expected_quantity, received_quantity, location_id)
SELECT id, 930, 60, 60, 481 FROM good_receipts WHERE receipt_number = 'RC-DEMO-0004/2026';

-- RC-DEMO-0005/2026 ← OC-DEMO-0005 (parcial, abierta)
INSERT INTO good_receipts (receipt_number, purchase_order_id, received_at, notes, closed, destination_warehouse_id, received_by_id, version)
VALUES ('RC-DEMO-0005/2026',
        (SELECT id FROM purchase_orders WHERE order_number = 'OC-DEMO-0005/2026'),
        '2026-06-08 09:00:00', 'Primera entrega parcial', false, 3, 'e6e0728c-ea74-4abf-9d04-abcf3594ad9e', 0);
INSERT INTO good_receipt_items (good_receipt_id, product_id, expected_quantity, received_quantity, location_id)
SELECT id, 219707, 90, 60, 481 FROM good_receipts WHERE receipt_number = 'RC-DEMO-0005/2026';
INSERT INTO good_receipt_items (good_receipt_id, product_id, expected_quantity, received_quantity, location_id)
SELECT id, 219708, 25, 10, 481 FROM good_receipts WHERE receipt_number = 'RC-DEMO-0005/2026';

-- RC-DEMO-0006/2026 ← OC-DEMO-0006
INSERT INTO good_receipts (receipt_number, purchase_order_id, received_at, notes, closed, destination_warehouse_id, received_by_id, version)
VALUES ('RC-DEMO-0006/2026',
        (SELECT id FROM purchase_orders WHERE order_number = 'OC-DEMO-0006/2026'),
        '2026-06-15 16:00:00', NULL, true, 7, 'f93cd1a6-b098-4a0d-a88e-5e416c8b1bf9', 0);
INSERT INTO good_receipt_items (good_receipt_id, product_id, expected_quantity, received_quantity, location_id)
SELECT id, 219711, 100, 100, 41863 FROM good_receipts WHERE receipt_number = 'RC-DEMO-0006/2026';
INSERT INTO good_receipt_items (good_receipt_id, product_id, expected_quantity, received_quantity, location_id)
SELECT id, 219712, 60, 60, 41863 FROM good_receipts WHERE receipt_number = 'RC-DEMO-0006/2026';
INSERT INTO good_receipt_items (good_receipt_id, product_id, expected_quantity, received_quantity, location_id)
SELECT id, 219713, 150, 150, 41863 FROM good_receipts WHERE receipt_number = 'RC-DEMO-0006/2026';
INSERT INTO good_receipt_items (good_receipt_id, product_id, expected_quantity, received_quantity, location_id)
SELECT id, 219714, 80, 80, 41863 FROM good_receipts WHERE receipt_number = 'RC-DEMO-0006/2026';

-- RC-DEMO-0007/2026 ← OC-DEMO-0009
INSERT INTO good_receipts (receipt_number, purchase_order_id, received_at, notes, closed, destination_warehouse_id, received_by_id, version)
VALUES ('RC-DEMO-0007/2026',
        (SELECT id FROM purchase_orders WHERE order_number = 'OC-DEMO-0009/2026'),
        '2026-07-25 13:00:00', NULL, true, 5, '57ff9479-46bf-454c-90f4-3ea5c2eae099', 0);
INSERT INTO good_receipt_items (good_receipt_id, product_id, expected_quantity, received_quantity, location_id)
SELECT id, 48, 150, 150, 41856 FROM good_receipts WHERE receipt_number = 'RC-DEMO-0007/2026';
INSERT INTO good_receipt_items (good_receipt_id, product_id, expected_quantity, received_quantity, location_id)
SELECT id, 43, 120, 120, 41856 FROM good_receipts WHERE receipt_number = 'RC-DEMO-0007/2026';

-- RC-DEMO-0008/2026 ← OC-DEMO-0005 (entrega final, cierra la orden)
INSERT INTO good_receipts (receipt_number, purchase_order_id, received_at, notes, closed, destination_warehouse_id, received_by_id, version)
VALUES ('RC-DEMO-0008/2026',
        (SELECT id FROM purchase_orders WHERE order_number = 'OC-DEMO-0005/2026'),
        '2026-06-20 09:00:00', 'Entrega final', true, 3, 'e6e0728c-ea74-4abf-9d04-abcf3594ad9e', 0);
INSERT INTO good_receipt_items (good_receipt_id, product_id, expected_quantity, received_quantity, location_id)
SELECT id, 219707, 90, 30, 481 FROM good_receipts WHERE receipt_number = 'RC-DEMO-0008/2026';
INSERT INTO good_receipt_items (good_receipt_id, product_id, expected_quantity, received_quantity, location_id)
SELECT id, 219708, 25, 15, 481 FROM good_receipts WHERE receipt_number = 'RC-DEMO-0008/2026';

-- RC-DEMO-0009/2026 ← OC-DEMO-0014
INSERT INTO good_receipts (receipt_number, purchase_order_id, received_at, notes, closed, destination_warehouse_id, received_by_id, version)
VALUES ('RC-DEMO-0009/2026',
        (SELECT id FROM purchase_orders WHERE order_number = 'OC-DEMO-0014/2026'),
        '2026-09-03 12:00:00', NULL, true, 3, 'e6e0728c-ea74-4abf-9d04-abcf3594ad9e', 0);
INSERT INTO good_receipt_items (good_receipt_id, product_id, expected_quantity, received_quantity, location_id)
SELECT id, 219707, 30, 30, 481 FROM good_receipts WHERE receipt_number = 'RC-DEMO-0009/2026';
INSERT INTO good_receipt_items (good_receipt_id, product_id, expected_quantity, received_quantity, location_id)
SELECT id, 219708, 15, 15, 481 FROM good_receipts WHERE receipt_number = 'RC-DEMO-0009/2026';
INSERT INTO good_receipt_items (good_receipt_id, product_id, expected_quantity, received_quantity, location_id)
SELECT id, 41, 120, 120, 481 FROM good_receipts WHERE receipt_number = 'RC-DEMO-0009/2026';

-- ════════════════════════════════════════════════════════════════════
-- 4. DESPACHOS (Dispatch Notes)
-- ════════════════════════════════════════════════════════════════════

-- DS-DEMO-0001/2026
INSERT INTO dispatch_notes (dispatch_number, warehouse_id, version, withdrawn_by_id, notes, created_at, created_by_id, cost_center_id)
VALUES ('DS-DEMO-0001/2026', 3, 0, 5481, 'DESPACHO DE ACEITE LUBRICANTE PARA TALLER CENTRAL', '2026-04-10 09:00:00', 'e6e0728c-ea74-4abf-9d04-abcf3594ad9e', 404);
INSERT INTO dispatch_note_items (dispatch_note_id, product_id, quantity)
SELECT id, 1802, 10 FROM dispatch_notes WHERE dispatch_number = 'DS-DEMO-0001/2026';

-- DS-DEMO-0002/2026
INSERT INTO dispatch_notes (dispatch_number, warehouse_id, version, withdrawn_by_id, notes, created_at, created_by_id, cost_center_id)
VALUES ('DS-DEMO-0002/2026', 3, 0, 6038, 'ENTREGA DE GRAPAS PARA AREA DE EMBALAJE', '2026-05-08 10:00:00', 'e6e0728c-ea74-4abf-9d04-abcf3594ad9e', 406);
INSERT INTO dispatch_note_items (dispatch_note_id, product_id, quantity)
SELECT id, 22142, 50 FROM dispatch_notes WHERE dispatch_number = 'DS-DEMO-0002/2026';
INSERT INTO dispatch_note_items (dispatch_note_id, product_id, quantity)
SELECT id, 393957, 30 FROM dispatch_notes WHERE dispatch_number = 'DS-DEMO-0002/2026';

-- DS-DEMO-0003/2026
INSERT INTO dispatch_notes (dispatch_number, warehouse_id, version, withdrawn_by_id, notes, created_at, created_by_id, cost_center_id)
VALUES ('DS-DEMO-0003/2026', 4, 0, 9971, 'SALIDA DE LIMPIADOR GRANULADO A PLANTA', '2026-04-18 09:00:00', '05ad310e-4cff-48fc-84e7-90fdd8cb56a8', 293);
INSERT INTO dispatch_note_items (dispatch_note_id, product_id, quantity)
SELECT id, 1962, 40 FROM dispatch_notes WHERE dispatch_number = 'DS-DEMO-0003/2026';

-- DS-DEMO-0004/2026
INSERT INTO dispatch_notes (dispatch_number, warehouse_id, version, withdrawn_by_id, notes, created_at, created_by_id, cost_center_id)
VALUES ('DS-DEMO-0004/2026', 3, 0, 5481, 'DESPACHO DE ACIDOS PARA LABORATORIO', '2026-05-22 09:00:00', '74c9d767-f359-45fa-90e5-8b30de957776', 5);
INSERT INTO dispatch_note_items (dispatch_note_id, product_id, quantity)
SELECT id, 373, 20 FROM dispatch_notes WHERE dispatch_number = 'DS-DEMO-0004/2026';
INSERT INTO dispatch_note_items (dispatch_note_id, product_id, quantity)
SELECT id, 928, 10 FROM dispatch_notes WHERE dispatch_number = 'DS-DEMO-0004/2026';

-- DS-DEMO-0005/2026
INSERT INTO dispatch_notes (dispatch_number, warehouse_id, version, withdrawn_by_id, notes, created_at, created_by_id, cost_center_id)
VALUES ('DS-DEMO-0005/2026', 3, 0, 6038, 'ENTREGA PINTURA MARFIL PARA EDIFICACIONES', '2026-06-12 09:00:00', 'e6e0728c-ea74-4abf-9d04-abcf3594ad9e', 422);
INSERT INTO dispatch_note_items (dispatch_note_id, product_id, quantity)
SELECT id, 219707, 15 FROM dispatch_notes WHERE dispatch_number = 'DS-DEMO-0005/2026';
INSERT INTO dispatch_note_items (dispatch_note_id, product_id, quantity)
SELECT id, 219708, 8 FROM dispatch_notes WHERE dispatch_number = 'DS-DEMO-0005/2026';

-- DS-DEMO-0006/2026
INSERT INTO dispatch_notes (dispatch_number, warehouse_id, version, withdrawn_by_id, notes, created_at, created_by_id, cost_center_id)
VALUES ('DS-DEMO-0006/2026', 7, 0, 9971, 'SALIDA MATERIALES ELECTRICOS PARA PARADA', '2026-06-18 09:00:00', 'f93cd1a6-b098-4a0d-a88e-5e416c8b1bf9', 406);
INSERT INTO dispatch_note_items (dispatch_note_id, product_id, quantity)
SELECT id, 219711, 30 FROM dispatch_notes WHERE dispatch_number = 'DS-DEMO-0006/2026';
INSERT INTO dispatch_note_items (dispatch_note_id, product_id, quantity)
SELECT id, 219713, 50 FROM dispatch_notes WHERE dispatch_number = 'DS-DEMO-0006/2026';

-- DS-DEMO-0007/2026
INSERT INTO dispatch_notes (dispatch_number, warehouse_id, version, withdrawn_by_id, notes, created_at, created_by_id, cost_center_id)
VALUES ('DS-DEMO-0007/2026', 5, 0, 5481, 'DESPACHO DISCOS DE CORTE A OBRA', '2026-07-27 09:00:00', '57ff9479-46bf-454c-90f4-3ea5c2eae099', 55);
INSERT INTO dispatch_note_items (dispatch_note_id, product_id, quantity)
SELECT id, 48, 20 FROM dispatch_notes WHERE dispatch_number = 'DS-DEMO-0007/2026';

-- DS-DEMO-0008/2026
INSERT INTO dispatch_notes (dispatch_number, warehouse_id, version, withdrawn_by_id, notes, created_at, created_by_id, cost_center_id)
VALUES ('DS-DEMO-0008/2026', 3, 0, 6038, 'ENTREGA SELLADOR ANTIALCALINO', '2026-06-22 09:00:00', 'e6e0728c-ea74-4abf-9d04-abcf3594ad9e', 422);
INSERT INTO dispatch_note_items (dispatch_note_id, product_id, quantity)
SELECT id, 219708, 5 FROM dispatch_notes WHERE dispatch_number = 'DS-DEMO-0008/2026';

-- DS-DEMO-0009/2026
INSERT INTO dispatch_notes (dispatch_number, warehouse_id, version, withdrawn_by_id, notes, created_at, created_by_id, cost_center_id)
VALUES ('DS-DEMO-0009/2026', 3, 0, 5481, 'SALIDA HERRAMIENTAS PARA MANTENIMIENTO', '2026-08-03 09:00:00', '05ad310e-4cff-48fc-84e7-90fdd8cb56a8', 293);
INSERT INTO dispatch_note_items (dispatch_note_id, product_id, quantity)
SELECT id, 9, 5 FROM dispatch_notes WHERE dispatch_number = 'DS-DEMO-0009/2026';
INSERT INTO dispatch_note_items (dispatch_note_id, product_id, quantity)
SELECT id, 41, 30 FROM dispatch_notes WHERE dispatch_number = 'DS-DEMO-0009/2026';

-- DS-DEMO-0010/2026
INSERT INTO dispatch_notes (dispatch_number, warehouse_id, version, withdrawn_by_id, notes, created_at, created_by_id, cost_center_id)
VALUES ('DS-DEMO-0010/2026', 4, 0, 9971, 'DESPACHO ESPATULAS A CUADRILLA', '2026-08-12 09:00:00', '05ad310e-4cff-48fc-84e7-90fdd8cb56a8', 293);
INSERT INTO dispatch_note_items (dispatch_note_id, product_id, quantity)
SELECT id, 219703, 10 FROM dispatch_notes WHERE dispatch_number = 'DS-DEMO-0010/2026';

-- DS-DEMO-0011/2026
INSERT INTO dispatch_notes (dispatch_number, warehouse_id, version, withdrawn_by_id, notes, created_at, created_by_id, cost_center_id)
VALUES ('DS-DEMO-0011/2026', 3, 0, 6038, 'ENTREGA EQUIPO MEDICO A AMBULATORIO', '2026-09-04 09:00:00', '6c4f539a-6660-44fd-8aa6-02e12cbe2334', 5);
INSERT INTO dispatch_note_items (dispatch_note_id, product_id, quantity)
SELECT id, 219701, 1 FROM dispatch_notes WHERE dispatch_number = 'DS-DEMO-0011/2026';

-- DS-DEMO-0012/2026
INSERT INTO dispatch_notes (dispatch_number, warehouse_id, version, withdrawn_by_id, notes, created_at, created_by_id, cost_center_id)
VALUES ('DS-DEMO-0012/2026', 3, 0, 5481, 'SALIDA GRAPAS NRO 3 PARA LOGISTICA', '2026-09-06 09:00:00', 'e6e0728c-ea74-4abf-9d04-abcf3594ad9e', 406);
INSERT INTO dispatch_note_items (dispatch_note_id, product_id, quantity)
SELECT id, 393957, 20 FROM dispatch_notes WHERE dispatch_number = 'DS-DEMO-0012/2026';

-- ════════════════════════════════════════════════════════════════════
-- 5. MOVIMIENTOS DE ALMACÉN
-- ════════════════════════════════════════════════════════════════════

-- INPUT: uno por cada ítem recibido en las recepciones DEMO
INSERT INTO inventory_movements (product_id, to_warehouse_id, quantity, type, reason, entry_unit_price, created_by_id, created_at)
SELECT gi.product_id, gr.destination_warehouse_id, gi.received_quantity, 'INPUT',
       'Goods receipt - ' || gr.receipt_number, NULL, gr.received_by_id, gr.received_at
FROM good_receipt_items gi
JOIN good_receipts gr ON gr.id = gi.good_receipt_id
WHERE gr.receipt_number LIKE 'RC-DEMO-%';

-- OUTPUT: uno por cada ítem despachado en los despachos DEMO
INSERT INTO inventory_movements (product_id, from_warehouse_id, quantity, type, reason, created_by_id, created_at)
SELECT di.product_id, dn.warehouse_id, di.quantity, 'OUTPUT',
       'Dispatch: ' || dn.dispatch_number, dn.created_by_id, dn.created_at
FROM dispatch_note_items di
JOIN dispatch_notes dn ON dn.id = di.dispatch_note_id
WHERE dn.dispatch_number LIKE 'DS-DEMO-%';

-- TRANSFER y ADJUSTMENT adicionales para variedad
INSERT INTO inventory_movements (product_id, from_warehouse_id, to_warehouse_id, quantity, type, reason, created_by_id, created_at)
VALUES
  (22142, 3, 4, 100, 'TRANSFER', 'Seed transferencia de grapas a Ciudad Piar', 'e6e0728c-ea74-4abf-9d04-abcf3594ad9e', '2026-05-10 09:00:00'),
  (41,   3, 5,  50, 'TRANSFER', 'Seed transferencia de discos a Torre Bell',  '57ff9479-46bf-454c-90f4-3ea5c2eae099', '2026-07-28 09:00:00'),
  (1802, 3, 7,  15, 'TRANSFER', 'Seed transferencia de aceite a Clover',      'f93cd1a6-b098-4a0d-a88e-5e416c8b1bf9', '2026-08-05 09:00:00'),
  (1962, 3, NULL, 5, 'ADJUSTMENT', 'Seed ajuste por merma en limpiador',        '05ad310e-4cff-48fc-84e7-90fdd8cb56a8', '2026-06-25 09:00:00'),
  (219703, 3, NULL, 2, 'ADJUSTMENT', 'Seed ajuste por inventario fisico',        '74c9d767-f359-45fa-90e5-8b30de957776', '2026-08-15 09:00:00'),
  (219707, 3, NULL, 3, 'ADJUSTMENT', 'Seed ajuste por diferencia de conteo',     'e6e0728c-ea74-4abf-9d04-abcf3594ad9e', '2026-09-05 09:00:00');

COMMIT;

-- ── Resumen ──────────────────────────────────────────────────────────
SELECT 'requisitions' AS tabla, count(*) AS filas FROM requisitions WHERE requisition_number LIKE 'RQ-DEMO-%'
UNION ALL SELECT 'purchase_orders', count(*) FROM purchase_orders WHERE order_number LIKE 'OC-DEMO-%'
UNION ALL SELECT 'good_receipts', count(*) FROM good_receipts WHERE receipt_number LIKE 'RC-DEMO-%'
UNION ALL SELECT 'dispatch_notes', count(*) FROM dispatch_notes WHERE dispatch_number LIKE 'DS-DEMO-%'
UNION ALL SELECT 'inventory_movements', count(*) FROM inventory_movements WHERE reason LIKE 'Goods receipt - RC-DEMO-%' OR reason LIKE 'Dispatch: DS-DEMO-%' OR reason LIKE 'Seed %';
