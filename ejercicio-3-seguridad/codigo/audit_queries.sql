-- #############################################################################
-- ## Queries de Auditoría para Trazabilidad de Accesos en Redshift
-- #############################################################################

-- Query 1: ¿Quién accedió a la tabla dim_clientes (directamente o vía la vista) esta semana?
SELECT DISTINCT
    s.user_name,
    q.query_text,
    s.start_time
FROM SVL_QUERY_SUMMARY s
JOIN STL_QUERYTEXT q ON s.query = q.query
WHERE (s.query_text ILIKE '%dim_clientes%' OR s.query_text ILIKE '%vw_clientes%')
  AND s.start_time >= GETDATE() - interval '7 days'
ORDER BY s.start_time DESC;

-- Query 2: ¿Qué usuarios ejecutaron queries con campos PII como 'telefono'?
SELECT
    u.usename AS user_name,
    qt.text AS query_text,
    q.starttime
FROM stl_query q
JOIN stl_querytext qt ON q.query = qt.query
JOIN pg_user u ON q.userid = u.usesysid
WHERE qt.text ILIKE '%telefono%'
  AND q.starttime >= GETDATE() - interval '30 days'
  -- Excluimos usuarios de servicio
  AND u.usename NOT LIKE '%svc%'
ORDER BY q.starttime DESC;

-- Query 3: Detectar accesos anómalos (ej: un usuario que de repente consulta 100x más datos de lo normal)
WITH query_stats AS (
    SELECT
        userid,
        query,
        SUM(rows) as total_rows_scanned
    FROM svl_query_metrics
    WHERE start_time >= GETDATE() - interval '30 days'
    GROUP BY 1, 2
),
user_daily_stats AS (
    SELECT
        userid,
        TRUNC(start_time) as query_date,
        SUM(total_rows_scanned) as daily_rows_scanned
    FROM query_stats qs
    JOIN stl_query q on qs.query = q.query
    GROUP BY 1, 2
),
user_avg_stats AS (
    SELECT
        userid,
        AVG(daily_rows_scanned) as avg_daily_scan,
        STDDEV(daily_rows_scanned) as stddev_daily_scan
    FROM user_daily_stats
    GROUP BY 1
)
SELECT
    u.usename,
    uds.query_date,
    uds.daily_rows_scanned,
    uas.avg_daily_scan
FROM user_daily_stats uds
JOIN user_avg_stats uas ON uds.userid = uas.userid
JOIN pg_user u ON uds.userid = u.usesysid
-- Una anomalía es escanear 3 desviaciones estándar por encima del promedio
WHERE uds.daily_rows_scanned > uas.avg_daily_scan + (3 * uas.stddev_daily_scan)
ORDER BY uds.daily_rows_scanned DESC;