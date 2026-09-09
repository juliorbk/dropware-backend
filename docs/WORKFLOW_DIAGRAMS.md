# Visco Orinoco (visco-sg) — Diagramas de Flujo de Trabajo (Workflows)

## Ciclo de vida — Requisición de Compra

```mermaid
stateDiagram-v2
    [*] --> DRAFT
    DRAFT --> PENDING : "submit (enviar)"
    PENDING --> AWAITING_APPROVAL : "pasa a revisión"
    AWAITING_APPROVAL --> APPROVED : "approve (aprobar)"
    AWAITING_APPROVAL --> REJECTED : "reject (rechazar)"
    PENDING --> CANCELLED : "cancelar"
    DRAFT --> CANCELLED : "cancelar"
    APPROVED --> CONVERTED : "convert → OC"
    APPROVED --> PARTIALLY_CONVERTED : "convert parcial"
    CONVERTED --> [*]
    PARTIALLY_CONVERTED --> [*]
    REJECTED --> [*]
    CANCELLED --> [*]
```

## Ciclo de vida — Orden de Compra

```mermaid
stateDiagram-v2
    [*] --> PENDING
    PENDING --> AWAITING_APPROVAL : "submit for approval"
    AWAITING_APPROVAL --> APPROVED : "approve"
    AWAITING_APPROVAL --> REJECTED : "reject"
    PENDING --> CANCELLED : "cancel"
    APPROVED --> IN_TRANSIT : "send to supplier"
    IN_TRANSIT --> HELD_AT_CUSTOMS : "retenida en aduana"
    HELD_AT_CUSTOMS --> IN_TRANSIT : "liberada"
    IN_TRANSIT --> DELIVERED : "entregada (total)"
    IN_TRANSIT --> PARTIALLY_DELIVERED : "entrega parcial"
    PARTIALLY_DELIVERED --> DELIVERED : "completa entrega"
    DELIVERED --> WAITING_PAYMENT : "factura pendiente"
    WAITING_PAYMENT --> COMPLETED : "pagada"
    DELIVERED --> COMPLETED : "cerrada"
    REJECTED --> [*]
    CANCELLED --> [*]
    COMPLETED --> [*]
```

## Ciclo de vida — Factura (3-way matching)

```mermaid
stateDiagram-v2
    [*] --> PENDING
    PENDING --> MATCHED : "cantidad y precio coinciden"
    PENDING --> PARTIALLY_MATCHED : "coincide parcialmente"
    PENDING --> UNMATCHED : "no coincide"
    MATCHED --> PAID : "marcar pagada"
    PARTIALLY_MATCHED --> PAID : "marcar pagada"
    UNMATCHED --> PAID : "marcar pagada"
    PENDING --> CANCELLED : "cancelar"
    MATCHED --> CANCELLED : "cancelar"
    PAID --> [*]
    CANCELLED --> [*]
```

## Tipos de movimiento de inventario

```mermaid
flowchart LR
    S((Inicio)) --> M{¿Tipo de<br/>movimiento?}

    M -->|"INPUT (recepción)"| A[Entrada de stock<br/>+ movimiento en kardex]
    M -->|"OUTPUT (salida)"| B[Salida de stock<br/>+ movimiento en kardex]
    M -->|"TRANSFER (transferencia)"| C[Restar origen<br/>Sumar destino]
    M -->|"ADJUSTMENT (ajuste)"| D[Corregir stock<br/>por conteo físico]
    M -->|"DISPATCH (despacho)"| E[Descontar stock<br/>asociado a nota de despacho]

    A --> F([Fin])
    B --> F
    C --> F
    D --> F
    E --> F
```

## Flujo integral Procure-to-Pay

```mermaid
flowchart TD
    A([👤 Solicitante crea requisición]) --> B{¿Aprobada?}
    B -->|No / Rechazada| Z([Fin])
    B -->|Sí| C[Convertir a Orden de Compra]
    C --> D[Enviar OC al proveedor]
    D --> E[OC en tránsito]
    E --> F[👤 Almacenista recibe mercancía<br/>Good Receipt contra OC]
    F --> G[Actualizar stock y kardex]
    G --> H[👤 Compras registra factura]
    H --> I{3-way matching<br/>OC vs recepción vs factura}
    I -->|Coincide| J[Marcar factura pagada]
    I -->|No coincide| K[Registrar discrepancia<br/>y resolver]
    K --> I
    J --> L([✅ Proceso completado])
```
