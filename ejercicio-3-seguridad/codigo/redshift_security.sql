-- #############################################################################
-- ## Script de Implementación de Seguridad en Redshift (RBAC)
-- #############################################################################

-- 1. CREACIÓN DE SCHEMAS POR SENSIBILIDAD
CREATE SCHEMA IF NOT EXISTS restricted_pii;
CREATE SCHEMA IF NOT EXISTS curated_data;

-- 2. CREACIÓN DE ROLES FUNCIONALES
CREATE ROLE analista_tribu;
CREATE ROLE data_scientist;
CREATE ROLE cfo;
CREATE ROLE auditor_interno;
-- Rol para el regulador, con permisos muy específicos
CREATE ROLE regulador_cnbv;

-- 3. CREACIÓN DE VISTAS SEGURAS Y CON ENMASCARAMIENTO
-- Los usuarios no accederán a 'restricted_pii.dim_clientes', sino a esta vista.
CREATE OR REPLACE VIEW curated_data.vw_clientes AS
SELECT
    cliente_id,
    -- El auditor ve el nombre, el DS lo ve anonimizado, el resto no lo ve.
    CASE
        WHEN current_user_in('auditor_interno') THEN nombre_cliente
        WHEN current_user_in('data_scientist') THEN 'cliente_' || cliente_id::varchar
        ELSE 'REDACTED'
    END AS nombre_cliente_masked,
    -- Enmascaramiento del teléfono
    CASE
        WHEN current_user_in('auditor_interno') THEN telefono
        ELSE '******' || SUBSTRING(telefono, 7, 4)
    END AS telefono_masked,
    estado,
    monto_credito_aprobado
FROM restricted_pii.dim_clientes;

-- 4. ASIGNACIÓN DE PERMISOS A LOS ROLES
-- Conceder USAGE en los schemas
GRANT USAGE ON SCHEMA curated_data TO ROLE analista_tribu, ROLE data_scientist, ROLE cfo, ROLE auditor_interno;
-- Un analista de tribu solo puede ver métricas y la vista de clientes enmascarada
GRANT SELECT ON curated_data.fact_salesmetrics TO ROLE analista_tribu;
GRANT SELECT ON curated_data.vw_clientes TO ROLE analista_tribu;

-- Un data scientist tiene acceso más amplio a datos enmascarados
GRANT SELECT ON ALL TABLES IN SCHEMA curated_data TO ROLE data_scientist;

-- El auditor puede ver las tablas base con PII para trazar datos
GRANT USAGE ON SCHEMA restricted_pii TO ROLE auditor_interno;
GRANT SELECT ON ALL TABLES IN SCHEMA restricted_pii TO ROLE auditor_interno;

-- 5. EJEMPLO DE ASIGNACIÓN DE USUARIO A ROL
-- CREATE USER juan_perez PASSWORD '...';
-- GRANT ROLE analista_tribu TO juan_perez;