# Dataset: fact_salesmetrics

## Metadata Técnica
- **Data Owner (Dueño que aprueba cambios):** Director de Operaciones de Crédito
- **Data Steward (Contacto técnico/funcional):** Analista Senior de BI
- **Ubicación:** Redshift, Schema `curated_data`
- **Tabla Física:** `fact_salesmetrics`, `DISTSTYLE KEY DISTKEY (tribu_id) SORTKEY (fecha_reporte)`
- **Schema (Estructura):**
  | Campo | Tipo | Nulo | Descripción | Ejemplo |
  | :--- | :--- | :---: | :--- | :--- |
  | `sales_metric_id` | `BIGINT IDENTITY` | No | Clave primaria subrogada de la tabla de hechos | 1002345 |
  | `fecha_reporte` | `DATE` | No | Fecha a la que corresponde la métrica (Sort Key) | 2025-10-06 |
  | `tribu_id` | `INTEGER` | No | FK a `dim_tribus`. Identificador de la tribu (Dist Key) | 15 |
  | `cumplimiento_100` | `DECIMAL(5,2)` | Sí | % de coordinadores que cumplieron el 100% de su meta de colocación | 87.50 |
  | `meta_clientes_nuevos` | `INTEGER` | Sí | # de clientes nuevos que era la meta de la tribu para esa semana | 250 |
  | `clientes_nuevos_reales`| `INTEGER` | Sí | # de clientes nuevos reales conseguidos en esa semana | 245 |
  | `par0` | `DECIMAL(18,2)` | Sí | Monto de cartera en riesgo con 0 días de atraso (cartera vigente) | 150000.00 |
  | `par7` | `DECIMAL(18,2)` | Sí | Monto de cartera en riesgo con 1-7 días de atraso | 12500.50 |
  | `ptyf` | `DECIMAL(5,2)` | Sí | % de "pago total y a tiempo". Mide la calidad del pago. | 92.10 |
  | `fecha_carga_dw` | `TIMESTAMP` | No | Fecha y hora de cuando se cargó el registro en el Data Warehouse | 2025-10-07 04:30:00 |
- **Volumen:** ~2M de registros nuevos por semana. Crecimiento estimado del 5% mensual.
- **Particionamiento:** La tabla subyacente en S3 está particionada por `fecha_reporte`. En Redshift, se usa como `SORTKEY` para optimizar consultas.
- **Refresh (Actualización):** Se actualiza diariamente. El proceso ETL corre de 2:00 AM a 4:30 AM.

## Metadata de Negocio
- **Propósito:** Consolidar las métricas de rendimiento operativo y de riesgo de cartera más importantes para cada tribu, permitiendo el análisis comparativo y el seguimiento de objetivos. **Es la fuente de verdad para el performance operativo de las tribus.**
- **Usuarios Principales:** Analistas de BI, Líderes de Tribu, Directores Regionales, CFO, Auditores.
- **Métricas Clave Derivadas:**
    - `% de Cumplimiento` = (`clientes_nuevos_reales` / `meta_clientes_nuevos`) * 100
    - `Índice de Cartera Vencida` = (`par7` / `par0`) * 100
- **SLAs (Acuerdos de Nivel de Servicio):**
  - **Disponibilidad:** Debe estar disponible de 6 AM a 10 PM, de Lunes a Sábado.
  - **Frescura (Freshness):** Los datos del día anterior (D-1) deben estar disponibles antes de las 6:00 AM CST.

## Lineage (De dónde viene)
- **Upstream (Fuentes):**
  - `s3://.../raw/mysql_sucursal_pagos`
  - `s3://.../raw/mysql_sucursal_colocacion`
  - `redshift.curated_data.dim_tribus`
- **Transformaciones:** El job de Glue `ETL-DailySalesMetrics-v1.py` realiza las siguientes acciones:
  - Filtra transacciones del día anterior.
  - Agrega los pagos y colocaciones a nivel de tribu y día.
  - Realiza joins con `dim_tribus` para obtener la geografía y el nombre del líder.
  - Calcula las métricas `cumplimiento_100` y `ptyf` según la lógica de negocio documentada en Confluence.
- **Downstream (Quién depende de esta tabla):**
  - Dashboard de Power BI: "Dashboard de Performance Operativo Semanal".
  - Reporte regulatorio: "Reporte CNBV-04B: Cartera de Riesgo".
  - Modelo de Machine Learning: "Predicción de default de clientes".

## Calidad
- **Validaciones Activas:**
  - `tribu_id` debe existir en `dim_tribus`.
  - `cumplimiento_100` y `ptyf` deben estar entre 0 y 100.
  - No debe haber nulos en `fecha_reporte` y `tribu_id`.
  - El # de tribus reportadas cada día debe ser 29.
  - La `fecha_reporte` no puede ser una fecha futura.
- **Problemas Conocidos:**
  - La métrica `ptyf` puede tener una ligera variación con el sistema legacy debido a un redondeo diferente. Documentado en JIRA-DATA-101.
- **Contacto para Problemas:** #canal-slack-calidad-datos