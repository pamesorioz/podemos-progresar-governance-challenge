# dq_validations.py
# Este script usa Great Expectations para definir una suite de validaciones
# para la tabla fact_salesmetrics.

import great_expectations as gx
from great_expectations.core.batch import BatchRequest
from great_expectations.core.yaml_handler import YAMLHandler

yaml = YAMLHandler()

# --- 1. OBTENER EL DATACONTEXT ---
# El DataContext es el punto de entrada principal para la API de Great Expectations.
# Se asume que está configurado a través de great_expectations.yml
context = gx.get_context()

# --- 2. DEFINIR LA SUITE Y EL BATCH DE DATOS ---
expectation_suite_name = "fact_salesmetrics.warning"
datasource_name = "redshift_prod" # Nombre del Datasource configurado en el YML
table_name = "curated_data.fact_salesmetrics"

# Crear la suite de expectativas si no existe
context.add_or_update_expectation_suite(expectation_suite_name=expectation_suite_name)

# Crear una solicitud para un batch de datos (en este caso, toda la tabla)
batch_request = BatchRequest(
    datasource_name=datasource_name,
    data_connector_name="default_inferred_data_connector_name",
    data_asset_name=table_name,
)

# --- 3. OBTENER UN VALIDADOR ---
# El validador es el objeto que usamos para crear y editar las expectativas.
validator = context.get_validator(
    batch_request=batch_request,
    expectation_suite_name=expectation_suite_name,
)

print(f"--- Definiendo validaciones para la suite '{expectation_suite_name}' ---")

# --- 4. AÑADIR LAS EXPECTATIVAS ---

# Completitud
validator.expect_column_to_not_be_null("sales_metric_id")
validator.expect_column_to_not_be_null("fecha_reporte")
validator.expect_column_to_not_be_null("tribu_id")

# Exactitud
validator.expect_column_values_to_be_between(
    "cumplimiento_100", min_value=0, max_value=100, mostly=0.99
)
validator.expect_column_min_to_be_between("par0", min_value=0)

# Validez
validator.expect_column_values_to_be_of_type("tribu_id", "INTEGER")
validator.expect_column_values_to_be_in_set(
    "tribu_id",
    value_set=list(range(1, 30)), # Asumiendo 29 tribus con IDs del 1 al 29
    meta={"notes": "Valida que el ID de la tribu sea uno de los conocidos."}
)

# Consistencia
validator.expect_compound_columns_to_be_unique(["fecha_reporte", "tribu_id"])

# Oportunidad (Freshness)
from datetime import datetime, timedelta
yesterday_str = (datetime.today() - timedelta(days=1)).strftime('%Y-%m-%d')
validator.expect_column_max_to_be_on_or_before(
    "fecha_reporte",
    yesterday_str
)

# --- 5. GUARDAR LA SUITE DE EXPECTATIVAS ---
validator.save_expectation_suite(discard_failed_expectations=False)

print("--- Suite de validaciones guardada exitosamente. ---")

# --- OPCIONAL: EJECUTAR UN CHECKPOINT PARA PROBAR ---
# En un pipeline real, esto se ejecutaría desde el job de Glue.
# checkpoint_name = "fact_salesmetrics_checkpoint"
# results = context.run_checkpoint(checkpoint_name=checkpoint_name)
# print(f"Resultado del Checkpoint: {'Éxito' if results['success'] else 'Fallo'}")