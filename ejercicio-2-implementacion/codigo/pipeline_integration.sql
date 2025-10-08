-- #############################################################################
-- ## Script: pipeline_integration.sql
-- ## Propósito: Demostrar la integración de validaciones de calidad de datos
-- ##            en un pipeline de carga para el Data Warehouse (Redshift).
-- ## Patrón: "Garita de Calidad" (Gated Check) usando una tabla de staging
-- ##         y un procedimiento almacenado.
-- #############################################################################


-- --- PASO 1: Asegurarse de que las tablas de soporte existan ---

-- Tabla de Staging: Donde Glue deposita los datos transformados para validación.
-- Es una copia exacta de la tabla de producción.
CREATE TABLE IF NOT EXISTS staging.fact_salesmetrics (
    fecha_reporte DATE,
    tribu_id INTEGER,
    cumplimiento_100 DECIMAL(5,2),
    meta_clientes_nuevos INTEGER,
    clientes_nuevos_reales INTEGER,
    par0 DECIMAL(18,2),
    par7 DECIMAL(18,2),
    ptyf DECIMAL(5,2)
);

-- Tabla de Log de Errores: Donde se registran los fallos de calidad para análisis.
CREATE TABLE IF NOT EXISTS governance.dq_error_log (
    log_id BIGINT IDENTITY(1,1),
    schema_name VARCHAR(100),
    table_name VARCHAR(100),
    check_name VARCHAR(255),
    error_count INTEGER,
    error_timestamp TIMESTAMP
);


-- --- PASO 2: Procedimiento Almacenado de Validación y Promoción ---

CREATE OR REPLACE PROCEDURE sp_promote_fact_salesmetrics()
AS $$
DECLARE
    -- Variables para contar los errores encontrados en cada validación
    v_null_errors INT;
    v_referential_errors INT;
    v_range_errors INT;
    v_total_errors INT;
BEGIN

    -- Iniciar una transacción. O todo se completa, o nada lo hace.
    BEGIN;

    RAISE INFO '--- INICIO: Proceso de Validación y Promoción para fact_salesmetrics ---';

    -- ============== SECCIÓN DE VALIDACIONES DE CALIDAD ==============
    -- Se ejecutan una serie de chequeos contra la tabla de staging.

    -- 1. [Completitud] Chequeo de nulos en columnas clave
    SELECT COUNT(*) INTO v_null_errors
    FROM staging.fact_salesmetrics
    WHERE tribu_id IS NULL OR fecha_reporte IS NULL;

    -- 2. [Validez] Chequeo de integridad referencial contra la tabla de dimensiones
    SELECT COUNT(*) INTO v_referential_errors
    FROM staging.fact_salesmetrics s
    LEFT JOIN curated_data.dim_tribus d ON s.tribu_id = d.tribu_id
    WHERE d.tribu_id IS NULL; -- Si el join falla, el ID de la tribu no existe

    -- 3. [Exactitud] Chequeo de valores fuera de rango
    SELECT COUNT(*) INTO v_range_errors
    FROM staging.fact_salesmetrics
    WHERE cumplimiento_100 < 0 OR cumplimiento_100 > 100;

    -- Sumar todos los errores encontrados
    v_total_errors := v_null_errors + v_referential_errors + v_range_errors;

    RAISE INFO 'Errores de Nulos: %, Errores Referenciales: %, Errores de Rango: %', v_null_errors, v_referential_errors, v_range_errors;


    -- ============== SECCIÓN DE DECISIÓN Y PROMOCIÓN ==============
    -- Si se encontraron errores, se aborta el proceso. Si no, se promueven los datos.

    IF v_total_errors > 0 THEN
        -- Si hay errores, registrar la falla y revertir la transacción
        RAISE WARNING 'SE ENCONTRARON % ERRORES DE CALIDAD. Abortando la carga.', v_total_errors;

        INSERT INTO governance.dq_error_log (schema_name, table_name, check_name, error_count, error_timestamp)
        VALUES ('staging', 'fact_salesmetrics', 'Chequeo de Nulos', v_null_errors, GETDATE()),
               ('staging', 'fact_salesmetrics', 'Chequeo Referencial', v_referential_errors, GETDATE()),
               ('staging', 'fact_salesmetrics', 'Chequeo de Rangos', v_range_errors, GETDATE());

        -- Revertir cualquier cambio y terminar
        ROLLBACK;
        RAISE INFO '--- FIN: Proceso abortado. ROLLBACK ejecutado. ---';

    ELSE
        -- Si no hay errores, proceder con la carga a la tabla de producción
        RAISE INFO 'No se encontraron errores de calidad. Procediendo a cargar los datos.';

        -- Borrar los datos del día correspondiente en la tabla de producción para evitar duplicados (operación idempotente)
        DELETE FROM curated_data.fact_salesmetrics
        WHERE fecha_reporte IN (SELECT DISTINCT fecha_reporte FROM staging.fact_salesmetrics);

        -- Insertar los datos limpios desde staging a la tabla de producción
        INSERT INTO curated_data.fact_salesmetrics (
            fecha_reporte,
            tribu_id,
            cumplimiento_100,
            meta_clientes_nuevos,
            clientes_nuevos_reales,
            par0,
            par7,
            ptyf
        )
        SELECT
            fecha_reporte,
            tribu_id,
            cumplimiento_100,
            meta_clientes_nuevos,
            clientes_nuevos_reales,
            par0,
            par7,
            ptyf
        FROM staging.fact_salesmetrics;

        -- Limpiar la tabla de staging para la próxima ejecución
        TRUNCATE TABLE staging.fact_salesmetrics;

        -- Confirmar todos los cambios
        COMMIT;
        RAISE INFO '--- FIN: Proceso completado exitosamente. COMMIT ejecutado. ---';

    END IF;

END;
$$ LANGUAGE plpgsql;


-- --- PASO 3: Ejecución desde el Pipeline ---
-- El orquestador (ej. AWS Step Functions o el mismo job de Glue al final)
-- ejecutaría la siguiente llamada después de cargar los datos en la tabla de staging.

-- CALL sp_promote_fact_salesmetrics();