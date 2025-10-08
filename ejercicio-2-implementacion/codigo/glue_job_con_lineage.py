# glue_job_con_lineage.py
# Este es un script conceptual de un job de AWS Glue (PySpark) que demuestra
# cómo se integrarían la calidad de datos y el linaje.

import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import great_expectations as gx
import boto3

# --- Bloque de Funciones de Gobierno ---
def log_lineage(glue_job_run_id, source_list, target_entity, transformation_notes, status):
    """
    Escribe una entrada en una tabla de linaje en Redshift.
    En un escenario real, esto usaría el Redshift Data API o un conector.
    """
    print(f"[LINAJE] RunID: {glue_job_run_id} | Fuentes: {source_list} | Destino: {target_entity} | Estado: {status} | Notas: {transformation_notes}")
    # redshift_client = boto3.client('redshift-data')
    # redshift_client.execute_statement(...)

def run_quality_checks(validator, expectation_suite_name):
    """
    Ejecuta una suite de validaciones de Great Expectations y devuelve el resultado.
    """
    print(f"--- Ejecutando suite de calidad: {expectation_suite_name} ---")
    results = validator.validate()
    print(f"--- Resultado de validación: {'Éxito' if results['success'] else 'Fallo'} ---")
    # Lógica para guardar el resultado en S3
    return results

# --- Inicialización del Job ---
args = getResolvedOptions(sys.argv, ["JOB_NAME", "JOB_RUN_ID", "TempDir"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

JOB_RUN_ID = args["JOB_RUN_ID"]
S3_STAGING_PATH = "s3://podemos-progresar-data/staging/fact_salesmetrics/"
S3_CURATED_PATH = "s3://podemos-progresar-data/curated/fact_salesmetrics/"
REDSHIFT_TABLE = "curated_data.fact_salesmetrics"

try:
    # --- 1. LEER DATOS FUENTE ---
    source_tables = ["s3://.../raw/pagos", "s3://.../raw/colocacion"]
    log_lineage(JOB_RUN_ID, source_tables, S3_STAGING_PATH, "Inicio de transformación", "EN_PROGRESO")
    
    pagos_dyf = glueContext.create_dynamic_frame.from_catalog(database="raw_db", table_name="pagos")
    colocacion_dyf = glueContext.create_dynamic_frame.from_catalog(database="raw_db", table_name="colocacion")

    # --- 2. APLICAR TRANSFORMACIONES ---
    # (Aquí iría la lógica de negocio: joins, agregaciones, cálculos, etc.)
    # transformed_dyf = ... # Lógica de transformación compleja

    # --- 3. ESCRIBIR A STAGING ---
    # glueContext.write_dynamic_frame.from_options(
    #     frame=transformed_dyf,
    #     connection_type="s3",
    #     connection_options={"path": S3_STAGING_PATH},
    #     format="parquet"
    # )
    log_lineage(JOB_RUN_ID, source_tables, S3_STAGING_PATH, "Escritura a staging completada", "EN_PROGRESO")

    # --- 4. VALIDACIÓN DE CALIDAD (LA GARITA) ---
    gx_context = gx.get_context(context_root_dir="./great_expectations") # Se asume que el proyecto de GX está desplegado con el job
    
    # Esta parte es conceptual y puede variar según la implementación exacta de GX en Glue
    # validator = gx_context.get_validator(...)
    
    # validation_result = run_quality_checks(validator, "fact_salesmetrics.warning")

    # if not validation_result["success"]:
    #     log_lineage(JOB_RUN_ID, [S3_STAGING_PATH], "N/A", "Validaciones de calidad fallaron críticamente", "FALLIDO")
    #     raise Exception("Las validaciones de calidad de datos fallaron. Abortando el pipeline.")

    # --- 5. PROMOVER A CURATED Y CARGAR A REDSHIFT ---
    # Si las validaciones pasan, se mueven los datos de staging a curated
    # Y se cargan en Redshift
    
    # glueContext.write_dynamic_frame.from_jdbc_conf(
    #     frame=transformed_dyf,
    #     catalog_connection="redshift_prod_connection",
    #     connection_options={"dbtable": REDSHIFT_TABLE, "database": "proddb"},
    #     redshift_tmp_dir=args["TempDir"]
    # )
    log_lineage(JOB_RUN_ID, [S3_STAGING_PATH], REDSHIFT_TABLE, "Carga a Redshift completada", "EXITOSO")

except Exception as e:
    # Loggear el error final
    log_lineage(JOB_RUN_ID, "N/A", "N/A", f"El job falló con el error: {str(e)}", "FALLIDO")
    raise e

job.commit()