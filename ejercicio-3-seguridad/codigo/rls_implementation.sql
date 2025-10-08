-- #############################################################################
-- ## Script de Implementación de Seguridad a Nivel de Fila (RLS)
-- #############################################################################

-- 1. TABLA DE MAPEO DE USUARIOS
-- Esta tabla vincula un usuario de la base de datos con su tribu.
-- Debe ser mantenida por el equipo de datos.
CREATE TABLE IF NOT EXISTS governance.user_tribu_mapping (
    db_user_name VARCHAR(100) PRIMARY KEY,
    tribu_id INTEGER
);
-- INSERT INTO governance.user_tribu_mapping VALUES ('juan_perez', 1); -- Ejemplo para Tribu Puebla

-- 2. FUNCIÓN DE SEGURIDAD
-- Devuelve el ID de la tribu del usuario que ejecuta la consulta.
CREATE OR REPLACE FUNCTION get_current_user_tribu() RETURNS INTEGER STABLE AS $$
DECLARE
    user_tribu_id INTEGER;
BEGIN
    SELECT tribu_id INTO user_tribu_id
    FROM governance.user_tribu_mapping
    WHERE db_user_name = current_user;
    RETURN user_tribu_id;
END;
$$ LANGUAGE plpgsql;

-- 3. POLÍTICA DE SEGURIDAD
-- Define la regla: la columna 'tribu_id' de la tabla debe ser igual
-- al resultado de la función de seguridad.
CREATE RLS POLICY tribu_filter_policy
WITH (tribu_id INTEGER) -- Columna en la tabla a filtrar
USING (tribu_id = get_current_user_tribu() OR current_user_in('cfo', 'auditor_interno')); -- Los roles de alto nivel pueden ver todo

-- 4. ADJUNTAR LA POLÍTICA A LAS TABLAS Y ROLES
-- La política se activa solo para el rol 'analista_tribu'.
ALTER TABLE curated_data.fact_salesmetrics ATTACH RLS POLICY tribu_filter_policy TO ROLE analista_tribu;
-- También se puede aplicar a otras tablas de hechos.
-- ALTER TABLE curated_data.fact_payments ATTACH RLS POLICY tribu_filter_policy TO ROLE analista_tribu;