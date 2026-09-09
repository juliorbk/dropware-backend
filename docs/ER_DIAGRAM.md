# Visco Orinoco (visco-sg) — Modelo Entidad-Relación (ER)

Diagrama del esquema relacional persistido en PostgreSQL (28 entidades JPA). Las entidades `REPORT` y `SCHEDULED_REPORT` referencian almacenes/categorías por `id` sin FK real, por lo que aparecen aisladas.

```mermaid
erDiagram
    GENERAL_MANAGEMENT ||--o{ MANAGEMENT : "agrupa"
    MANAGEMENT ||--o{ COST_CENTER : "agrupa"
    COST_CENTER ||--o{ USER : "asigna"
    COST_CENTER ||--o{ EMPLOYEE : "asigna"
    COST_CENTER ||--o{ REQUISITION : "solicita para"
    COST_CENTER ||--o{ DISPATCH_NOTE : "consume"

    SUPPLIER_CATEGORY ||--o{ SUPPLIER : "clasifica"
    SUPPLIER ||--o{ LEGAL_REPRESENTATIVE : "tiene"
    SUPPLIER ||--o{ PRODUCT : "suministra"
    SUPPLIER ||--o{ PURCHASE_ORDER : "recibe"
    SUPPLIER ||--o{ INVOICE : "emite"

    CATEGORY ||--o{ PRODUCT : "categoriza"

    WAREHOUSE ||--o{ LOCATION : "tiene"
    WAREHOUSE ||--o{ STOCK_LEVEL : "almacena"
    PRODUCT ||--o{ STOCK_LEVEL : "niveles por almacen"
    WAREHOUSE ||--o{ PURCHASE_ORDER : "destino de"
    WAREHOUSE ||--o{ DISPATCH_NOTE : "despacha desde"

    USER ||--o{ PURCHASE_ORDER : "crea/aprueba"
    USER ||--o{ REQUISITION : "solicita/aprueba"
    USER ||--o{ INVENTORY_MOVEMENT : "registra"
    USER ||--o{ GOOD_RECEIPT : "recibe"
    USER ||--o{ DISPATCH_NOTE : "crea"
    USER ||--o{ PASSWORD_RESET_TOKEN : "solicita"
    USER ||--o{ INVITE_TOKEN : "genera"

    REQUISITION ||--o{ PURCHASE_ORDER : "se convierte en"
    REQUISITION ||--o{ REQUISITION_ITEM : "contiene"
    REQUISITION_ITEM }o--|| PRODUCT : "referencia"

    PURCHASE_ORDER ||--o{ PURCHASE_ORDER_ITEM : "contiene"
    PURCHASE_ORDER_ITEM }o--|| PRODUCT : "referencia"
    PURCHASE_ORDER ||--o{ GOOD_RECEIPT : "recepcionado via"
    PURCHASE_ORDER ||--o{ INVOICE : "facturado via"

    GOOD_RECEIPT ||--o{ GOOD_RECEIPT_ITEM : "contiene"
    GOOD_RECEIPT_ITEM }o--|| PRODUCT : "referencia"
    GOOD_RECEIPT_ITEM }o--|| LOCATION : "ubicado en"

    INVOICE ||--o{ INVOICE_ITEM : "contiene"
    INVOICE_ITEM }o--|| PRODUCT : "referencia"

    DISPATCH_NOTE ||--o{ DISPATCH_NOTE_ITEM : "contiene"
    DISPATCH_NOTE_ITEM }o--|| PRODUCT : "referencia"
    EMPLOYEE ||--o{ DISPATCH_NOTE : "retira"

    PRODUCT ||--o{ INVENTORY_MOVEMENT : "movido"
    WAREHOUSE ||--o{ INVENTORY_MOVEMENT : "origen/destino"

    GENERAL_MANAGEMENT {
        bigint id PK
        string code UK
        string description
    }
    MANAGEMENT {
        bigint id PK
        string code UK
        string description
        bigint general_management_id FK
    }
    COST_CENTER {
        bigint id PK
        string code UK
        string full_description
        string division_description
        bigint management_id FK
        bool is_active
    }
    EMPLOYEE {
        bigint id PK
        string full_name
        string document_number UK
        string shirt_size
        string pants_size
        string shoes_size
        string gender
        bigint cost_center_id FK
        bool is_active
    }
    USER {
        uuid id PK
        string name
        string email UK
        string password
        string role
        uuid cost_center_id FK
        bool is_active
        string profile_picture_url
    }
    SUPPLIER_CATEGORY {
        bigint id PK
        string name UK
        string description
        bool is_active
    }
    SUPPLIER {
        bigint id PK
        string name UK
        string address
        string email UK
        string tax_id
        string description
        string currency
        bigint category_id FK
        bool is_active
    }
    LEGAL_REPRESENTATIVE {
        bigint id PK
        string full_name
        bigint supplier_id FK
    }
    CATEGORY {
        bigint id PK
        string name
        bigint parent_id FK
    }
    PRODUCT {
        bigint id PK
        string internal_code UK
        string sku UK
        string name
        string sap_code
        string uom
        decimal reorder_point
        decimal max_stock
        bigint supplier_id FK
        bigint category_id FK
        bool is_active
    }
    WAREHOUSE {
        bigint id PK
        string name UK
        string physical_address
        string description
        string sap_center_code
        uuid responsible_user_id FK
        bool is_active
    }
    LOCATION {
        bigint id PK
        string code
        bigint warehouse_id FK
        string zone
        string aisle
        string rack
        string level
        int position_x
        int position_y
    }
    STOCK_LEVEL {
        bigint id PK
        bigint product_id FK
        bigint warehouse_id FK
        decimal current_stock
        decimal pending_stock
    }
    REQUISITION {
        bigint id PK
        string requisition_number UK
        string description
        string status
        uuid requested_by_id FK
        bigint cost_center_id FK
        uuid approved_by_id FK
        string rejection_reason
    }
    REQUISITION_ITEM {
        bigint id PK
        bigint requisition_id FK
        bigint product_id FK
        decimal quantity
        string notes
    }
    PURCHASE_ORDER {
        bigint id PK
        string order_number UK
        string description
        string status
        string payment_method
        string type
        bigint supplier_id FK
        uuid created_by_id FK
        uuid approved_by_id FK
        uuid rejected_by_id FK
        bigint requisition_id FK
        bigint destination_warehouse_id FK
        string incoterm
        int lead_time
    }
    PURCHASE_ORDER_ITEM {
        bigint id PK
        bigint purchase_order_id FK
        bigint product_id FK
        decimal quantity
        decimal unit_price
    }
    GOOD_RECEIPT {
        bigint id PK
        string receipt_number UK
        bigint purchase_order_id FK
        uuid received_by_id FK
        bigint destination_warehouse_id FK
        datetime received_at
        bool closed
    }
    GOOD_RECEIPT_ITEM {
        bigint id PK
        bigint good_receipt_id FK
        bigint product_id FK
        bigint location_id FK
        decimal expected_quantity
        decimal received_quantity
    }
    INVOICE {
        bigint id PK
        string invoice_number UK
        bigint purchase_order_id FK
        bigint supplier_id FK
        date invoice_date
        date due_date
        decimal total_amount
        decimal tax_amount
        string status
        date payment_date
    }
    INVOICE_ITEM {
        bigint id PK
        bigint invoice_id FK
        bigint product_id FK
        decimal quantity
        decimal unit_price
        decimal line_total
        bool quantity_match
        bool price_match
    }
    DISPATCH_NOTE {
        bigint id PK
        string dispatch_number UK
        bigint warehouse_id FK
        bigint withdrawn_by_id FK
        bigint cost_center_id FK
        uuid created_by_id FK
    }
    DISPATCH_NOTE_ITEM {
        bigint id PK
        bigint dispatch_note_id FK
        bigint product_id FK
        decimal quantity
    }
    INVENTORY_MOVEMENT {
        bigint id PK
        bigint product_id FK
        bigint from_warehouse_id FK
        bigint to_warehouse_id FK
        uuid created_by_id FK
        decimal quantity
        string type
        string reason
    }
    INVITE_TOKEN {
        uuid id PK
        string token UK
        string email
        string intended_role
        bigint cost_center_id
        uuid created_by_id
        datetime expires_at
    }
    PASSWORD_RESET_TOKEN {
        uuid id PK
        string token UK
        uuid user_id
        datetime expires_at
        datetime used_at
    }
    REPORT {
        bigint id PK
        string name
        string type
        string status
        string format
        bigint warehouse_id
        bigint category_id
        string file_path
    }
    SCHEDULED_REPORT {
        bigint id PK
        string name
        string report_type
        string frequency
        string recipient_emails
        string format
        time schedule_time
        bool enabled
    }
```
