# Manual del Programador — Visco Orinoco Backend (`visco-sg`)

Sistema de gestión empresarial para control de inventario, órdenes de compra, proveedores y facturación.
Backend monolítico REST construido con **Spring Boot** y desplegado en **Railway**.

Este manual está orientado a desarrolladores que van a **mantener, extender o depurar** el código.
Para documentación funcional y del modelo de datos consulta:

- `README.md` — descripción general, setup y despliegue.
- `docs/modelo_bd.md` — modelo relacional (sin el módulo de compras).
- `C4_DIAGRAMS.md` — diagramas C4 (contexto, contenedores, componentes, entidades).
- `PROMPT_MANUAL_USUARIO.md` — manual de usuario.

---

## Tabla de contenidos

1. [Stack tecnológico](#1-stack-tecnológico)
2. [Arquitectura de capas](#2-arquitectura-de-capas)
3. [Estructura del código](#3-estructura-del-código)
4. [Setup local](#4-setup-local)
5. [Configuración y variables de entorno](#5-configuración-y-variables-de-entorno)
6. [Seguridad](#6-seguridad)
7. [Flujos de negocio](#7-flujos-de-negocio)
8. [Base de datos y migraciones Flyway](#8-base-de-datos-y-migraciones-flyway)
9. [Módulo de reportes](#9-módulo-de-reportes)
10. [Observabilidad y monitoreo](#10-observabilidad-y-monitoreo)
11. [Despliegue](#11-despliegue)
12. [Testing](#12-testing)
13. [Convenciones y guía práctica](#13-convenciones-y-guía-práctica)
14. [Troubleshooting](#14-troubleshooting)

---

## 1. Stack tecnológico

| Tecnología | Versión | Uso |
|---|---|---|
| Java | 21 | Lenguaje |
| Spring Boot | 4.0.6 (parent) | Framework |
| Spring Security | vía Boot 4 | AuthN/AuthZ, roles jerárquicos |
| Spring Data JPA + Hibernate | vía Boot 4 | Persistencia, optimistic locking |
| PostgreSQL | 15+ (prod: 16) | Base de datos |
| Flyway | vía Boot 4 | Migraciones (`db/migration`, V1–V21) |
| JWT (jjwt) | 0.12.6 | Tokens HMAC-SHA256 |
| Bucket4j | 8.10.1 | Rate limiting token-bucket por IP |
| Caffeine | vía Boot 4 | Cache KPIs del dashboard |
| Apache POI | 5.2.5 | Reportes Excel |
| iText 8 + JFreeChart | 8.0.3 / 1.5.3 | Reportes PDF |
| Commons CSV | 1.10.0 | Importación masiva de productos |
| Resend (resend-java) | 3.0.0 | Emails transaccionales |
| Cloudinary | 2.0.0 | Fotos de perfil |
| Micrometer + Prometheus + OTLP | vía Boot 4 | Métricas |
| Loki4j + Logstash | 1.5.1 / 8.0 | Logs estructurados |
| Lombok | vía Boot 4 | Reducción de boilerplate |
| SpringDoc OpenAPI | 3.0.2 | Swagger UI |
| Maven | 3.9+ (`mvnw`) | Build |

> **Importante:** el `pom.xml` usa `spring-boot-starter-parent` **4.0.6**. Esto significa APIs de Spring 6.x / Boot 4
> (e.g. `DaoAuthenticationProvider(CustomUserDetailsService)` por constructor, `spring-boot-starter-restclient`).
> No "bajes" librerías a versiones de Boot 3 sin verificar compatibilidad (ver httpclient 4.5.14, comentado en git log).

---

## 2. Arquitectura de capas

Patrón **Controller → Service → Repository** en un monolito. No hay capa de dominio compleja (DDD); los `Service` contienen la lógica de negocio.

```
Cliente (Next.js / SPA)
   │  HTTPS + cookie HttpOnly (JWT)
   ▼
[RateLimitFilter] ──► [JwtAuthFilter] ──► [SecurityConfig FilterChain]
                                              │
                                              ▼
                        ┌──────────────────────────────┐
                        │  Controllers (REST)          │
                        └──────────────┬───────────────┘
                                       ▼
                        ┌──────────────────────────────┐
                        │  Services (lógica de negocio)│
                        └──────────────┬───────────────┘
                                       ▼
                        ┌──────────────────────────────┐
                        │  Repositories (Spring Data)  │
                        └──────────────┬───────────────┘
                                       ▼
                              PostgreSQL (Flyway)
```

**Orden de filtros:** `RateLimitFilter` corre antes que el filtro de autenticación; `JwtAuthFilter` se registra
con `addFilterBefore(..., UsernamePasswordAuthenticationFilter.class)`. Ver `SecurityConfig.java:237`.

**Patrones transversales:**

- **Soft delete:** `@SQLDelete` en `Supplier`, `Product`, `Location`, `Employee`, `CostCenter`, `Warehouse`.
- **Optimistic locking:** `@Version` en `Product`, `StockLevel`, `PurchaseOrder`, `Requisition`, `Invoice`, `GoodReceipt`, `DispatchNote`, `Report`. Ante conflicto, `GlobalExceptionHandler` devuelve **409**.
- **Async:** `@EnableAsync` + `@Async` en `EmailService`, con `TaskExecutor` dedicado `emailExecutor` (`SystemApplication.java:50`).
- **Scheduling:** `@EnableScheduling` — reporte semanal (Lunes 8:00 AM, `WeeklyReportService`) y verificación horaria de reportes programados (`ScheduledReportService`).
- **Caché:** `@EnableCaching` + Caffeine (`maximumSize=500, expireAfterWrite=5m`) para KPIs del dashboard.
- **Auth stateless:** sin sesiones HTTP, JWT en cookie `visco_auth_token`.

---

## 3. Estructura del código

```
src/main/java/com/visco/backend/
├── SystemApplication.java          # Entry point: @EnableCaching/Scheduling/Async + emailExecutor
├── config/
│   ├── SecurityConfig.java         # FilterChain, roles, CORS, BCrypt, auth entry points
│   ├── JwtAuthFilter.java          # Extrae JWT (header o cookie), valida y setea SecurityContext
│   ├── RateLimitFilter.java        # Bucket4j token-bucket por IP y ruta
│   ├── CustomUserDetailsService.java
│   ├── UserPrincipal.java          # UserDetails cargado desde BD
│   ├── CloudinaryConfig.java
│   ├── JpaAuditingConfig.java      # Auditoría createdAt/updatedAt
│   ├── MonitoringConfig.java       # Métricas OTLP → Grafana Cloud
│   └── OpenApiConfig.java          # Swagger (gated por app.openapi.enabled)
├── controllers/                    # 19 REST controllers
├── services/                       # 25 servicios de negocio
├── models/
│   ├── entities/                   # Entidades JPA + enums de dominio
│   └── dtos/                       # 73 DTOs request/response
├── repositories/                   # Spring Data JPA
├── exception/
│   └── GlobalExceptionHandler.java # @RestControllerAdvice
├── reports/                        # Módulo de reportes (sub-paquetes propios)
│   ├── controllers/ ReportController.java
│   ├── services/   ReportService, ReportGeneratorService, ExcelExportService,
│   │               PdfExportService, ScheduledReportService
│   ├── models/     entities (Report, ScheduledReport), enums, dtos
│   ├── repositories/
│   └── utils/
└── scripts/
    └── backup.sh                   # Backup/rotación de PostgreSQL

src/main/resources/
├── application.properties          # Config base (todo por variables de entorno)
├── application-local.properties    # Perfil "local" (NO subir a Git)
├── logback-spring.xml              # JSON a stdout + appender Loki (profile "loki")
└── db/migration/                   # Migraciones Flyway V1..V21
```

**Módulo `reports/`** es un paquete autocontenido (controllers/services/entities propios), integrado al
mismo contexto Spring. Es la única excepción al árbol plano del resto.

---

## 4. Setup local

### Prerrequisitos

- Java 21 (Temurin/Adoptium recomendado).
- Docker + Docker Compose (para Postgres local).
- Maven 3.9+ (o usa `./mvnw`).

### Pasos

1. **Levantar Postgres de desarrollo** (esquema vacío, puerto **5434** para no chocar con un Postgres local):

```bash
# Copia .env con DB_USERNAME y DB_PASSWORD (ver abajo)
docker compose -f docker-compose.dev.yml up -d
```

2. **Configurar entorno local.** El perfil `local` (`application-local.properties`) define la URL
`jdbc:postgresql://localhost:5434/visco_db` y usa `ddl-auto=update` + `show-sql=true`. Crea un `.env`
en la raíz con al menos:

```dotenv
DB_USERNAME=visco_admin
DB_PASSWORD=tu_password
DB_URL_LOCAL=jdbc:postgresql://localhost:5434/visco_db
JWT_SECRET=<base64 de al menos 32 bytes>
JWT_EXPIRATION_MS=86400000
JWT_COOKIE_SECURE=false        # false en local (HTTP)
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173
RESEND_API_KEY=                # vacío en local si no pruebas emails
APP_EMAIL_ENABLED=false
CLOUDINARY_URL=
```

   El arranque carga `.env` vía `dotenv-java`. Los `@Value` de la app leen estos nombres.

3. **Ejecutar:**

```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=local
```

   En el primer arranque Flyway crea el esquema (V1–V21) y Hibernate completa columnas con `ddl-auto=update`.

4. **Verificar:** `http://localhost:8080/health` → `{"status":"ok"}`. Swagger disponible en
`http://localhost:8080/swagger-ui.html` (solo si `app.openapi.enabled=true`, ver sección 5).

> **Ojo con la rama.** El repo tiene ramas `main`, `dev` y `local`. Trabaja sobre `dev` y mergea a `main`
> cuando estés listo (Railway despliega `main` automáticamente).

---

## 5. Configuración y variables de entorno

Todo está centralizado en `application.properties` con placeholders `${VAR:default}`. En producción
(Railway) cada variable se define en el panel del servicio.

### Conexión y JPA

| Variable | Default | Descripción |
|---|---|---|
| `DB_URL` | — (requerido) | JDBC URL, ej. `jdbc:postgresql://host:5432/railway` |
| `DB_USERNAME` / `DB_PASSWORD` | — | Credenciales Postgres |
| `JPA_DDL_AUTO` | `validate` | Flyway gestiona el esquema; NUNCA `update` en prod |

### JWT / cookies

| Variable | Default | Descripción |
|---|---|---|
| `JWT_SECRET` | — | Base64 ≥ 32 bytes, firma HMAC-SHA256 |
| `JWT_EXPIRATION_MS` | `86400000` | 24 h |
| `JWT_COOKIE_NAME` | `visco_auth_token` | Nombre de la cookie |
| `JWT_COOKIE_SECURE` | `true` | `true` en prod (HTTPS); `false` en local |

### CORS / servidor

| Variable | Default |
|---|---|
| `CORS_ALLOWED_ORIGINS` | `http://localhost:3000,http://localhost:5173,https://viscoorinocosia.vercel.app` |
| `PORT` | `8080` (Railway lo inyecta) |

### Emails / servicios externos

| Variable | Default | Descripción |
|---|---|---|
| `RESEND_API_KEY` | vacío | Transporte de email primario |
| `APP_EMAIL_ENABLED` | `false` | Interruptor general de envío |
| `APP_MAIL_FROM` | `Visco Orinoco <noreply@viscorinoco.com>` | Remitente |
| `PASSWORD_RESET_BASE_URL` | `https://viscoorinocosia.vercel.app` | Base del link de reset |
| `PASSWORD_RESET_VALIDITY_HOURS` | `2` | Validez del token de reset |
| `INVITE_DEFAULT_VALIDITY_HOURS` | `72` | Validez de tokens de invitación |
| `CLOUDINARY_URL` | vacío | Uploads de foto de perfil |
| `REPORT_RECIPIENTS` | vacío | Emails (separados por coma) del reporte semanal |

### Reportes y límites

| Variable | Default | Descripción |
|---|---|---|
| `REPORTS_STORAGE_PATH` | `/var/app/reports` | Directorio de archivos generados |
| `REPORTS_MAX_FILE_SIZE` | `104857600` | Bytes máx. por archivo |
| `REPORTS_CLEANUP_DAYS` | `30` | Días de retención |
| `REPORTS_MAX_RECORDS` | `2000` | **Tope de filas por exportación** (evita OOM) |
| `INVITE_LIST_MAX_RECORDS` | `1000` | Tope de la lista de invites |
| `spring.data.web.pageable.max-page-size` | `2000` | Tope global de `?size=` en paginación |

> **Anti-OOM:** `REPORTS_MAX_RECORDS` y `max-page-size` son protecciones intencionales. No los subas sin
> presupuestar memoria (instancias de 512 MB).

### Rate limiting

Todos configurables: `rate-limit.<grupo>.capacity` y `rate-limit.<grupo>.minutes`. Grupos: `login`,
`register`, `password-reset`, `admin`, `inventory`, `procurement`, `users`, `suppliers`, `warehouses`,
`dashboard`, `invoices`, `requisitions`, `cost-centers`, `employees`, `reports`.
Además `rate-limit.trust-forwarded-for` (default `false`) controla si se confía en `X-Forwarded-For`.

### Observabilidad

| Variable | Default | Descripción |
|---|---|---|
| `OTLP_ENABLED` | `false` | Exporta métricas OTLP → Grafana Cloud |
| `OTLP_URL` | gateway `us-west-0` de Grafana | Endpoint OTLP |
| `OTLP_STEP` | `60s` | Intervalo de scrape |
| `LOKI_URL` | `logs-prod-021.grafana.net` | Push Loki (solo profile `loki`) |

### OpenAPI / Swagger

`app.openapi.enabled` (default **false**) — en `SecurityConfig.java:49` las rutas `/swagger-ui/**` y
`/v3/api-docs/**` están **gated** por este flag. Para habilitar Swagger en un entorno: `OPENAPI_ENABLED=true`.

---

## 6. Seguridad

### 6.1 Autenticación JWT (cookie HttpOnly)

1. `POST /api/auth/login` valida credenciales y responde con `Set-Cookie: visco_auth_token=<jwt>`.
2. El token **nunca** viaja en el body; `CookieService` construye la cookie con flags `HttpOnly`, `Secure`
   (según `JWT_COOKIE_SECURE`) y `SameSite`.
3. En cada request, `JwtAuthFilter`:
   - Omite rutas públicas (`PUBLIC_PATHS`, `JwtAuthFilter.java:36`).
   - Extrae el JWT del header `Authorization: Bearer ...` **o** de la cookie.
   - Valida con `JwtService`, carga `UserPrincipal` desde BD (verifica que el usuario **exista y esté activo**).
   - Ante token expirado/inválido o usuario inexistente devuelve **401** con mensaje JSON.
4. **Logout** borra la cookie (`/api/auth/logout`).

### 6.2 Jerarquía de roles

`RoleHierarchy` (`SecurityConfig.java:93`):

```
ROLE_SUPERADMIN > ROLE_ADMIN
ROLE_ADMIN > ROLE_MANAGER
ROLE_ADMIN > ROLE_PROCUREMENT
ROLE_ADMIN > ROLE_WAREHOUSEMAN
ROLE_MANAGER > ROLE_USER
ROLE_PROCUREMENT > ROLE_USER
ROLE_WAREHOUSEMAN > ROLE_USER
```

Reglas por grupo de rutas (ver `SecurityConfig.java:145-230`):

| Ruta | Regla |
|---|---|
| `/api/auth/register|login|forgot-password|reset-password`, `/health` | `permitAll` |
| `/api/auth/me`, `/api/auth/logout` | autenticado |
| `/api/users/**` | `ADMIN` |
| `DELETE /api/users/**`, `GET /api/users/*/references` | `SUPERADMIN` |
| `/api/cost-centers/**`, `/api/management/**`, `/api/general-management/**` | autenticado |
| GET `/api/employees, suppliers, supplier-categories, procurement, requisitions, warehouse, invoices, inventory, reports, dashboard` | autenticado (listas de solo lectura) |
| Escritura `/api/suppliers, supplier-categories, procurement, requisitions` | `ADMIN, MANAGER, PROCUREMENT` |
| `/api/warehouse/**` | `ADMIN, MANAGER, PROCUREMENT, WAREHOUSEMAN` |
| `/api/invoices/**` | `ADMIN, MANAGER, PROCUREMENT` |
| `/api/inventory/**` | `ADMIN, MANAGER, WAREHOUSEMAN` |
| `/api/reports/**` | `ADMIN, MANAGER, PROCUREMENT` |
| `/api/admin/**`, `/api/migration/**` | `ADMIN` |
| `/api/invites/**` | `ADMIN`; `/api/invites/by-token/**` | `permitAll` |
| `/actuator/prometheus`, `/actuator/health*` | `permitAll` |
| `/actuator/**` (resto) | `SUPERADMIN` |
| `/swagger-ui/**`, `/v3/api-docs/**` | gate por `app.openapi.enabled` |

Además hay `@PreAuthorize` a nivel de método (ej. `hasRole('MANAGER')` en aprobar/rechazar OCs).

### 6.3 Rate limiting (Bucket4j)

`RateLimitFilter` implementa token-bucket **por (IP + ruta)** con límites configurables (ver 5). Detalles clave:

- Buckets en Caffeine: `expireAfterAccess=10min`, `maximumSize=50_000` (protección anti-DoS).
- Solo se confía en `X-Forwarded-For` con `rate-limit.trust-forwarded-for=true` (evita IP spoofing).
- Respuesta **429** con mensaje en español.

### 6.4 CORS

Orígenes desde `CORS_ALLOWED_ORIGINS`, con `allowCredentials=true` (necesario para cookies).
Headers expuestos: `Set-Cookie`.

---

## 7. Flujos de negocio

### 7.1 Estructura organizacional

`GeneralManagement` → `Management` → `CostCenter` → `User` / `Employee`.
Controladores: `/api/general-management`, `/api/management`, `/api/cost-centers`, `/api/employees`.

### 7.2 Catálogo

- **Categorías** (`/api/inventory/categories`): jerárquicas (padre-hijo).
- **Productos** (`/api/inventory`): `internal_code` y `sap_code` únicos, `sku`, `uom`, `reorder_point`,
  `max_stock`. Soft-delete. Importación masiva por **CSV** (Commons CSV).
- **Proveedores** (`/api/suppliers`): soft-delete (`deleted_at`), representantes legales N:M
  (`supplier_representatives`), múltiples teléfonos, categoría, moneda, `tax_id`. Métricas de desempeño
  mensual en `/api/suppliers/performance`.

### 7.3 Almacenes e inventario (`/api/warehouse`)

- `Warehouse` → `Location` (ubicaciones físicas), `StockLevel` por (producto, almacén, ubicación).
- **Movimientos** (`inventory_movements`): bitácora tipo `INPUT | OUTPUT | TRANSFER | ADJUSTMENT | DISPATCH`.
- **Recepciones:** `POST /api/warehouse/orders/{id}/receive` — good receipt contra una OC, genera
  `GoodReceipt`/`GoodReceiptItem`, actualiza stock y crea movimientos INPUT.
- **Transferencias:** `POST /api/warehouse/stock/transfer` (origen → destino, tipo TRANSFER).
- **Ajustes:** `POST /api/warehouse/stock/adjust` (tipo ADJUSTMENT).
- **Despachos:** `POST /api/warehouse/dispatch` — `DispatchNote`/`DispatchNoteItem` (salida a empleado/centro de costo, tipo DISPATCH).
- **Consultas:** stock-breakdown por producto, stock-summary, on-stock, movements (con export).

### 7.4 Requisiciones (`/api/requisitions`)

Ciclo: `DRAFT → PENDING → AWAITING_APPROVAL → APPROVED | REJECTED | CANCELLED → CONVERTED | PARTIALLY_CONVERTED`.

- `POST /` crea en `DRAFT`.
- `PATCH /{id}/submit` → `PENDING`.
- `PATCH /{id}/approve` / `reject` / `cancel` (aprobación por `MANAGER`).
- `PATCH /{id}/convert` → convierte la requisición aprobada en **OC** (estado `CONVERTED`).

### 7.5 Órdenes de compra (`/api/procurement/orders`)

Ciclo: `PENDING → AWAITING_APPROVAL → APPROVED | REJECTED | CANCELLED → IN_TRANSIT → DELIVERED → PARTIALLY_DELIVERED | COMPLETED | WAITING_PAYMENT | HELD_AT_CUSTOMS`.

- `POST /orders` crea la OC (con items y proveedor).
- `PATCH /orders/{id}/submit-for-approval` → `AWAITING_APPROVAL`.
- `PATCH /orders/{id}/approve` (`@PreAuthorize("hasRole('MANAGER')")`) → `APPROVED`, registra aprobador.
- `PATCH /orders/{id}/reject` → `REJECTED` con motivo.
- `PATCH /orders/{id}/send-to-supplier` → `IN_TRANSIT`.
- `PATCH /orders/{id}/cancel` → `CANCELLED` con motivo.
- `GET /orders/by-product/{productId}` → resumen de OCs que contienen un producto.

### 7.6 Recepción y Facturación

- **Recepción** (`/api/warehouse/orders/{id}/receive`) incrementa stock y puede marcar la OC como entregada.
- **Facturas** (`/api/invoices`): ciclo `PENDING → MATCHED | PARTIALLY_MATCHED | UNMATCHED → PAID | OVERDUE | CANCELLED`.
  - **3-way matching** (`InvoiceService`): compara cantidad **ordenada** (OC) vs **recibida** (GoodReceipt)
    vs **facturada** (Invoice), y precio unitario.
  - `PATCH /{id}/pay` → `PAID`. `PATCH /{id}/cancel` → `CANCELLED`.

### 7.7 Dashboard (`/api/dashboard`)

KPIs cacheados (Caffeine, 5 min): `kpis`, `recent-orders`, `spending`, `critical-inventory`.
`StatsService` calcula total de OCs, unidades en inventario, gasto mensual, fulfillment rate y stock crítico/sobrestock.

### 7.8 Usuarios, invitaciones y contraseña

- `AuthController`: `register` (JSON o multipart con foto), `login`, `logout`, `me`, `forgot-password`, `reset-password`.
- `InviteTokenController` (`/api/invites`): tokens de invitación de un solo uso (`InviteTokenService`), registro con token.
- `AdminController` (`/api/admin`): gestión de usuarios, conteo de referencias, reporte manual
  (`POST /api/admin/reports/send`), migraciones (`/api/migration/**`).

---

## 8. Base de datos y migraciones Flyway

- Migraciones en `src/main/resources/db/migration/` con nomenclatura `V<n>__<desc>.sql` (V1…V21).
- En producción `JPA_DDL_AUTO=validate`; **toda** evolución de esquema debe ser una migración nueva (V22, V23…).
- En local (`profile=local`) `ddl-auto=update` puede crear columnas faltantes, pero **no** es la vía para schema changes reproducibles.

Convenciones de migración observables en el repo:
- Índices explícitos con nombres descriptivos (`idx_*`), ver `V4__missing_fk_indexes.sql`, `V9/V10/V12__*_indexes`.
- Uso de `unaccent` para búsquedas (`V10__unaccent_search_indexes.sql`) — requiere la extensión en prod.
- Re-sincronización de secuencias para `IDENTITY` (`V16`, `V17`, `V20`) tras importar datos.
- `V11` **elimina** `exit_unit_price`; `V13` agrega `location_id` a good_receipt_item.

Entidades clave con `@Version` (optimistic locking): `Product`, `StockLevel`, `PurchaseOrder`,
`Requisition`, `Invoice`, `GoodReceipt`, `DispatchNote`, `Report`. Si editas una de estas, respeta el campo
`version` en updates (los 409 se generan automáticamente en `GlobalExceptionHandler`).

> `docs/modelo_bd.md` documenta el esquema **sin** el módulo de compras. Para tablas de compras
> (requisitions, purchase_orders, good_receipts, invoices) revisa los `@Table` en `models/entities/`.

---

## 9. Módulo de reportes

Ubicado en `com.visco.backend.reports` (sub-árbol propio), expuesto en `/api/reports`.

- **Tipos** (`ReportType`): `STOCK_INVENTORY`, `STOCK_MOVEMENTS`, `CRITICAL_ALERTS`, `WAREHOUSE_ANALYSIS`, `DAILY_RECEIPTS`.
- **Formatos** (`ReportFormat`): `PDF`, `EXCEL`, `JSON` (con MIME types).
- **Estados** (`ReportStatus`): `PENDING → PROCESSING → COMPLETED | FAILED`.
- **Frecuencias** (`ReportFrequency`): `DAILY`, `WEEKLY`, `MONTHLY` para reportes programados.

Endpoints principales (`ReportController`):

```
GET    /api/reports
GET    /api/reports/{id}
POST   /api/reports/generate
GET    /api/reports/{id}/download
DELETE /api/reports/{id}
GET    /api/reports/templates
GET    /api/reports/analytics
GET    /api/reports/scheduled
POST   /api/reports/scheduled
PUT    /api/reports/scheduled/{id}
DELETE /api/reports/scheduled/{id}
POST   /api/reports/scheduled/{id}/execute
```

- **Generación:** `ReportGeneratorService` orquesta la consulta de datos y delega en `ExcelExportService`
  (Apache POI) o `PdfExportService` (iText 8 + JFreeChart para gráficos).
- **Almacenamiento:** `ReportAttachmentStorage` persiste archivos en `REPORTS_STORAGE_PATH`.
- **Programados:** `ScheduledReportService` verifica cada hora los reportes programados cuya hora de
  ejecución llegó; `WeeklyReportService` corre el reporte semanal (Lunes 8:00 AM) a los `REPORT_RECIPIENTS`.
- `REPORTS_MAX_RECORDS` (default 2000) limita filas por exportación para evitar OOM.

---

## 10. Observabilidad y monitoreo

### Actuator (expuesto)

- `GET /actuator/health` (+`/health/liveness`, `/health/readiness`) — **público** (healthcheck de Railway).
- `GET /actuator/prometheus` — **público**, scrape de Prometheus.
- Resto de `/actuator/**` (env, heapdump, threaddump, metrics) — solo `SUPERADMIN`.
- Percentiles de latencia HTTP configurados: p50, p90, p95, p99 con SLOs 50ms–5s (`application.properties:145`).

### Logs

- `logback-spring.xml`: logs **JSON estructurados** a stdout (capturados por Railway) vía Logstash encoder.
- Appender **Loki** opcional, activado solo con `--spring.profiles.active=loki` + `LOKI_URL` (envío directo a Grafana Cloud Loki).
- `MemoryMonitorService` monitorea heap/metaspace (útil para diagnosticar OOM en 512 MB).

### Métricas OTLP → Grafana Cloud

`MonitoringConfig` + `micrometer-registry-otlp`: cuando `OTLP_ENABLED=true`, la app empuja métricas al
gateway OTLP de Grafana Cloud sin Alloy. `Dockerfile.alloy`/`config.alloy` son alternativas previas
(agente Alloy sidecar) — en desuso desde que el export es directo.

---

## 11. Despliegue

### Docker

- `Dockerfile` multi-stage: build con `maven:3.9.6-eclipse-temurin-21` → runtime `eclipse-temurin:21-jre-alpine`.
- Usuario **no-root** (`visco`), `EXPOSE 8080`, entrypoint `/app/start.sh`.
- `start.sh` fija flags JVM conservadores para instancias de 512 MB:

```sh
unset JAVA_TOOL_OPTIONS        # evita flags conflictivos inyectados por la plataforma
exec java -XX:+UseG1GC -Xmx256m -Xms128m -Xss512k -XX:MaxMetaspaceSize=160m \
  -XX:+ExitOnOutOfMemoryError -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/tmp \
  -Djava.security.egd=file:/dev/./urandom -jar app.jar
```

### Railway

- `railway.json`: builder `DOCKERFILE`, start command `/app/start.sh`,
  healthcheck `GET /actuator/health`, restart policy `ON_FAILURE` (10 reintentos).
- Postgres gestionado por Railway; definir `DB_URL` en formato **JDBC** (convierte `postgres://` → `jdbc:postgresql://`).
- Deploy automático por push a `main`.

### Backups

`src/main/java/com/visco/backend/scripts/backup.sh` — `pg_dump` comprimido + rotación por días
(`RETENTION_DAYS`). Variables: `DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD, BACKUP_DIR, RETENTION_DAYS`.

---

## 12. Testing

- Dependencias de test en `pom.xml`: `spring-boot-starter-test`, `security-test`, `restclient-test`,
  `webmvc-test`, `jdbc-test` + **H2** (`com.h2database`) + `spring-boot-starter-jdbc-test`.
- Config de test: `src/test/resources/application-test.properties` (H2 en memoria).
- Ejecutar: `./mvnw test`.
- **No hay tests unitarios todavía** (`src/test/java` está vacío). Prioridad recomendada: servicios de
  flujos críticos (`ProcurementService`, `InvoiceService` 3-way matching, `WarehouseService` transferencias).

---

## 13. Convenciones y guía práctica

### Cómo agregar un endpoint nuevo

1. **Controller** en `controllers/` con `@RestController`, `@RequestMapping`, `@RequiredArgsConstructor`,
   `@Tag` de springdoc y `@Operation` en cada método.
2. **Service** con la lógica; si hay reglas de negocio inválidas lanza `IllegalArgumentException` (400)
   o `IllegalStateException` (409) — el `GlobalExceptionHandler` los traduce automáticamente.
3. **Repository** Spring Data; usa `@Query` cuando necesites joins/agregaciones.
4. **DTOs** en `models/dtos/` (records preferidos para request/response).
5. **Seguridad:** regla en `SecurityConfig` para el grupo de rutas **y** entrada en `RateLimitedRoute`
   de `RateLimitFilter` si la ruta necesita límite.
6. **Migración Flyway** nueva (`V22__...sql`) si cambia el esquema.

### Cómo agregar una entidad nueva

1. Entidad JPA en `models/entities/` (con `@Entity`, `@Table`, `@Getter/@Setter/@Builder` de Lombok).
2. Enum de dominio si aplica (mismo paquete, `@Enumerated(EnumType.STRING)`).
3. Migración Flyway.
4. Repositorio + DTOs + Service + Controller.

### Reglas de oro

- **Nunca** subas `application-local.properties`, `.env` o `backup*.sql` (están en `.gitignore`).
- Respetá el **optimistic locking**: lee la entidad, mutala y guarda; no sobrescribas `version` manualmente.
- **Siempre** pagina listas con `Pageable`; no hagas `findAll()` sin paginar (histórico de OOM en prod).
- Respeta `REPORTS_MAX_RECORDS` en exportaciones y `max-page-size` en queries.
- Mensajes de error de negocio en **español** (los usuarios finales los ven).
- Logs con Lombok `@Slf4j`; el formato JSON de producción los estructura automáticamente.
- Cambios de esquema → migración, no `ddl-auto=update` en prod.
- Java 21, usa records para DTOs, `switch` expressions y text blocks cuando aplique (estilo ya presente).
- No hay linter/formateador configurado; mantén la indentación de 2 espacios del código existente.

---

## 14. Troubleshooting

| Síntoma | Causa probable | Solución |
|---|---|---|
| 401 `Token expirado` | JWT vencido | Re-login; el front renueva token |
| 401 `Cuenta inactiva o bloqueada` | Usuario `is_active=false` | Reactivar en `/api/admin` o BD |
| 401 `User no longer exists` | JWT de un usuario hard-deleted | Re-login |
| 409 `Optimistic lock` | Update concurrente | Refresh y reintentar (mensaje lo indica) |
| 409 `Data integrity` | Duplicado de unique (code, sap_code, email…) | Corregir el valor duplicado |
| 429 `Demasiadas solicitudes` | Rate limit por IP | Esperar ventana; subir `rate-limit.*` si es legítimo |
| OOM al listar/exportar | `?size=` grande o export sin tope | Usar paginación; no subir `REPORTS_MAX_RECORDS` |
| Swagger 403/404 | `app.openapi.enabled=false` | `OPENAPI_ENABLED=true` (nunca en prod salvo que se necesite) |
| No envía emails | `APP_EMAIL_ENABLED=false` o `RESEND_API_KEY` inválida | Habilitar flag y verificar dominio en Resend |
| DB_URL falla en Railway | Formato libpq (`postgres://`) no JDBC | Definir `DB_URL=jdbc:postgresql://...` |
| App muere con OOM | Heap 256m insuficiente para la carga | Revisar `start.sh`; paginar queries; subir plan |
| Fechas/index unaccent fallan | Extensión `unaccent` ausente en Postgres | Crear extensión antes de migrar (`CREATE EXTENSION unaccent`) |

---

## Referencias rápidas

- Swagger local: `http://localhost:8080/swagger-ui.html` (con `OPENAPI_ENABLED=true`).
- Health: `/health` y `/actuator/health`.
- OpenAPI JSON: `/v3/api-docs`.
- Métricas: `/actuator/prometheus`.
- Rama de deploy: `main` (Railway). Desarrollo: `dev`.
- Diagramas C4: `C4_DIAGRAMS.md`. Modelo de BD: `docs/modelo_bd.md`.