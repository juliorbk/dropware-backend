# Visco Orinoco (visco-sg) — Diagramas de Casos de Uso

Diagramas por actor (rol). Los seis roles del sistema son: `SUPERADMIN`, `ADMIN`, `MANAGER`, `PROCUREMENT`, `WAREHOUSEMAN` y `USER`.

## Casos de Uso — Administración (SUPERADMIN / ADMIN)

```mermaid
flowchart LR
    subgraph SYS["Sistema visco-sg"]
        UC1([Gestionar usuarios]) 
        UC2([Crear invitaciones])
        UC3([Activar / desactivar usuarios])
        UC4([Asignar roles y centros de costo])
        UC5([Gestionar estructura organizacional])
        UC6([Gestionar reportes programados])
    end
    A[👤 SUPERADMIN / ADMIN] --> UC1
    A --> UC2
    A --> UC3
    A --> UC4
    A --> UC5
    A --> UC6
```

## Casos de Uso — Compras (PROCUREMENT)

```mermaid
flowchart LR
    subgraph SYS["Sistema visco-sg"]
        UC1([Gestionar proveedores])
        UC2([Gestionar categorías de proveedor])
        UC3([Gestionar productos y categorías])
        UC4([Crear requisición])
        UC5([Crear orden de compra])
        UC6([Enviar OC al proveedor])
        UC7([Registrar factura y 3-way matching])
        UC8([Marcar factura pagada])
    end
    A[👤 PROCUREMENT] --> UC1
    A --> UC2
    A --> UC3
    A --> UC4
    A --> UC5
    A --> UC6
    A --> UC7
    A --> UC8
```

## Casos de Uso — Almacén (WAREHOUSEMAN)

```mermaid
flowchart LR
    subgraph SYS["Sistema visco-sg"]
        UC1([Gestionar almacenes])
        UC2([Gestionar ubicaciones])
        UC3([Recibir mercancía contra OC])
        UC4([Transferir stock entre almacenes])
        UC5([Ajustar stock])
        UC6([Registrar despachos])
        UC7([Consultar kardex de movimientos])
    end
    A[👤 WAREHOUSEMAN] --> UC1
    A --> UC2
    A --> UC3
    A --> UC4
    A --> UC5
    A --> UC6
    A --> UC7
```

## Casos de Uso — Gerencia (MANAGER)

```mermaid
flowchart LR
    subgraph SYS["Sistema visco-sg"]
        UC1([Aprobar / rechazar requisiciones])
        UC2([Aprobar / rechazar órdenes de compra])
        UC3([Consultar dashboard de KPIs])
        UC4([Consultar gasto mensual])
        UC5([Consultar inventario crítico])
    end
    A[👤 MANAGER] --> UC1
    A --> UC2
    A --> UC3
    A --> UC4
    A --> UC5
```

## Casos de Uso — Usuario básico (USER)

```mermaid
flowchart LR
    subgraph SYS["Sistema visco-sg"]
        UC1([Registrarse por invitación])
        UC2([Iniciar / cerrar sesión])
        UC3([Recuperar contraseña])
        UC4([Consultar su perfil])
    end
    A[👤 USER] --> UC1
    A --> UC2
    A --> UC3
    A --> UC4
```

## Casos de Uso — Actor externo (Proveedor)

```mermaid
flowchart LR
    subgraph SYS["Sistema visco-sg"]
        UC1([Recibir notificación de OC por email])
        UC2([Recibir reportes por email])
    end
    A[🏭 Proveedor] --> UC1
    A --> UC2
```

## Relación actores → roles

| Actor | Rol del sistema | Módulos |
|-------|-----------------|---------|
| Administrador | `SUPERADMIN` / `ADMIN` | Usuarios, invitaciones, organización, reportes |
| Compras | `PROCUREMENT` | Proveedores, productos, requisiciones, OC, facturas |
| Almacenista | `WAREHOUSEMAN` | Almacenes, ubicaciones, recepciones, transferencias, despachos |
| Gerente | `MANAGER` | Aprobaciones, dashboard, gastos |
| Usuario | `USER` | Autenticación y perfil |
| Proveedor | Externo (fuera del sistema) | Recibe notificaciones por email |
