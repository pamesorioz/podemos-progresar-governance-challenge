# 1. Framework de Calidad para Microfinanzas
Implementaremos un framework basado en 5 dimensiones de calidad, con reglas específicas para fact_salesmetrics:
| Dimensión        | Pregunta de Negocio                      | Regla Específica para `fact_salesmetrics`                                                                                                                                                                     |
| ---------------- | ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Completitud**  | ¿Tenemos todos los datos que deberíamos? | 1\. El # de filas para una `fecha_reporte` debe ser 29 (una por tribu). 2. Las columnas `tribu_id` y `fecha_reporte` no pueden ser nulas.                                                                     |
| **Exactitud**    | ¿Son los valores correctos y precisos?   | 1\. `cumplimiento_100` debe estar entre 0 y 100. 2. Los montos de cartera (`par0`, `par7`) deben ser mayores o iguales a 0.                                                                                   |
| **Consistencia** | ¿Tienen sentido los datos en conjunto?   | 1\. `clientes_nuevos_reales` no debería exceder `meta_clientes_nuevos` en más de un 20% (para detectar errores de tipeo). 2. La suma de `par0` y `par7` debe cuadrar con un total de cartera de otro sistema. |
| **Oportunidad**  | ¿Llegaron los datos a tiempo?            | El valor máximo de `fecha_carga_dw` para los datos de ayer debe ser menor a las 6:00 AM de hoy.                                                                                                               |
| **Validez**      | ¿Se ajustan los datos a nuestras reglas? | 1\. Todos los `tribu_id` deben existir en la tabla `dim_tribus` (integridad referencial). 2. `fecha_reporte` debe ser una fecha válida y no puede ser futura.                                                 |

# 2. Integración en el Pipeline y Manejo de Fallas

El Patrón "Garita de Calidad" (Gated Check)
Las validaciones de Great Expectations se ejecutarán como una "garita de peaje" al final de nuestro job de Glue.

Transformación: El job de Glue lee los datos crudos, los transforma y escribe el resultado en una ubicación temporal en S3 (ej. s3://.../staging/fact_salesmetrics/).

Validación: Great Expectations se ejecuta sobre los datos en esta ubicación temporal.

* Decisión:

Si las validaciones pasan: Los datos se mueven de la ubicación temporal a la ubicación final (s3://.../curated/) y se carga Redshift.

* Si las validaciones fallan:

Error Crítico (ej. tribu_id inválido): El pipeline se detiene por completo. Los datos no se mueven. Se envía una alerta de alta prioridad al Data Steward y al Data Engineer de guardia vía Slack/PagerDuty.

Advertencia (ej. una tribu no reportó): El pipeline continúa, pero se registra la advertencia. Se envía una alerta de baja prioridad al Data Steward.

Visualización del Estado
Great Expectations genera un sitio HTML estático llamado "Data Docs" con los resultados detallados de cada validación. Este sitio se desplegará en un S3 bucket con acceso web y será nuestro dashboard público de calidad de datos.

# 3. Casos Edge del Mundo Real

* Caso A: Falla de internet en Tribu_0015, reporte semanal obligatorio.

Decisión: [✅] Publicas con nota explicativa y datos parciales.

Justificación: La puntualidad de un reporte regulatorio o para el CEO a menudo supera la necesidad de completitud perfecta. Bloquear la publicación por un 3% de los datos faltantes (1 de 29 tribus) causa más daño que bien. La transparencia es la clave para construir confianza.

Proceso Establecido:

La regla de "Completitud" (verificar 29 tribus) fallará, pero estará configurada con un nivel de severidad de "Advertencia" (Warning), no de "Fallo" (Failure).

Esto permite que el pipeline termine, pero dispara una alerta al Data Steward de la Tribu_0015 y al equipo de BI.

El dashboard de Power BI tendrá una nota automática en la parte superior: "Aviso: Datos para la Tribu_0015 no disponibles para el día X debido a una falla de origen. Las métricas totales no incluyen esta región."

* Caso B: Cambio de regla de negocio histórica para el cálculo de par7.

Manejo Técnico (¿Recalcular?): NUNCA se deben sobreescribir los datos históricos con la nueva regla. Hacerlo sería reescribir la historia y destruir la capacidad de hacer análisis comparativos válidos (ej. "año contra año"). La solución correcta es implementar Versionado de Dimensiones Lentas (SCD Tipo 2).

## Implementación:

A la tabla de dimensión o de reglas de negocio donde se define el cálculo, se le añaden tres columnas: version, fecha_inicio_validez, fecha_fin_validez.

Cuando la regla cambia, la fila vieja se "cierra" (se le pone una fecha_fin_validez = now() - 1 day) y se inserta una fila nueva con la nueva regla, una nueva versión y la nueva fecha_inicio_validez (now()).

El ETL se modifica para que al hacer el join, una la transacción con la versión de la regla que estaba vigente en la fecha_reporte de la transacción.

``
DDL para modificar la tabla de reglas
ALTER TABLE dim_reglas_negocio ADD COLUMN version INT;
ALTER TABLE dim_reglas_negocio ADD COLUMN fecha_inicio_validez DATE;
ALTER TABLE dim_reglas_negocio ADD COLUMN fecha_fin_validez DATE;
```
-- El join en el ETL ahora se ve así:

``
FROM fact_salesmetrics f
JOIN dim_reglas_negocio r ON f.regla_id = r.regla_id
AND f.fecha_reporte BETWEEN r.fecha_inicio_validez AND r.fecha_fin_validez
```

# Manejo de Governance:

¿Quién decide? El Data Owner del dominio de Riesgo aprueba el cambio.

¿Cómo se comunica? El Data Steward es responsable de documentar el cambio en la ficha del dataset en el Catálogo de Datos, incluyendo la fecha de efectividad y la razón del cambio. Se envía un comunicado a los usuarios principales.
