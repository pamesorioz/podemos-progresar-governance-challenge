# Roadmap de Gobierno de Datos (Primeros 6 Meses)

Este roadmap describe el plan de implementación de la función de Gobierno de Datos, priorizando la entrega de valor temprano y la construcción de una base sólida para el futuro. El plan está diseñado para ser pragmático, adaptarse a nuestra cultura ágil y operar dentro de las restricciones presupuestarias y de equipo.

Este roadmap describe el plan de implementación de la función de Gobierno de Datos, priorizando la entrega de valor temprano y la construcción de una base sólida para el futuro. El plan está diseñado para ser pragmático, adaptarse a nuestra cultura ágil y operar dentro de las restricciones presupuestarias y de equipo.

Cronograma Visual:
| Fase             | Meses 1-2: Fundamentos                 | Meses 3-4: Piloto de Alto Impacto     | Meses 5-6: Escalamiento y Blueprint      |
| :--------------- | :------------------------------------- | :------------------------------------ | :--------------------------------------- |
| **Foco Principal** | Visibilidad y Confianza Inicial        | Resolver un Dolor de Negocio Real     | Crear el Modelo para Crecer              |
| **Entregables Clave** | <ul><li>Catálogo de Activos Críticos</li><li>Framework de Calidad (DQ) v1</li><li>Nombramiento de Stewards</li></ul> | <ul><li>Dominio de Riesgo "Certificado"</li><li>Catálogo completo del Dominio</li><li>Dashboard de DQ v2</li></ul> | <ul><li>Blueprint de expansión</li><li>Inicio de Gobierno en Dominio Ventas</li><li>KPIs de éxito definidos</li></ul> |

## Mes 1-2: Fundamentos - Visibilidad y Confianza Inicial

El objetivo de esta fase es sentar las bases técnicas y organizacionales, y demostrar valor inmediato al CTO y CFO.

* ¿Qué implementamos primero y por qué?

Catálogo de Datos para Activos Críticos: 
Prioridad #1. No podemos gobernar lo que no vemos. Empezaremos catalogando todos los activos que se están migrando a Redshift como parte del "Proyecto Torbellino".

Framework de Calidad de Datos: Lo implementaremos directamente en los nuevos pipelines de Glue. Esto nos permite construir confianza en Redshift desde el día uno y demostrar que es más fiable que el sistema anterior.

Nombramiento de Data Owners y Stewards: Formalizaremos los roles (definidos en la estructura-organizacional.md) para el dominio que usaremos en el piloto (Riesgo Crediticio).

* Selección de Herramientas (Costo vs. Beneficio):

Catálogo de Datos: AWS Glue Data Catalog

Costo: Muy bajo (modelo pago por uso, ~$1 por cada millón de objetos almacenados). Se ajusta perfectamente a nuestro presupuesto de <$50K.

Beneficio: Es nativo de AWS, se integra sin fricción con nuestro stack (S3, Glue, Redshift), permite automatizar el descubrimiento con Crawlers y es suficiente para nuestras necesidades actuales sin la complejidad de una herramienta enterprise.

Calidad de Datos: Great Expectations (Open Source)

Costo: $0 en licencia. El costo es el tiempo de implementación de nuestro Ingeniero de Calidad de Datos.

Beneficio: Es el estándar de facto en la industria para "data testing". Se integra como código Python en nuestros pipelines de Glue, es potente, flexible y genera automáticamente "Data Docs" (reportes HTML) que sirven como dashboards de calidad.

* ¿Cómo demostramos valor temprano?
Al final del mes 2, presentaremos al CTO/CFO un "Paquete de Confianza Inicial":

Un dashboard de calidad de datos vivo que muestre la salud diaria de la tabla fact_salesmetrics en Redshift.

Un mini-catálogo funcional y con buscador (usando la UI de AWS o una página simple de Confluence) con las 15 tablas más críticas documentadas.

Métricas claras: "Detectamos y prevenimos X errores de datos antes de que llegaran a los reportes".

## Mes 3-4: Casos de Uso Piloto - Resolver un Dolor de Negocio Real
Ahora que tenemos las herramientas, las aplicamos a un área de negocio con un problema tangible.

Área de datos elegida para el piloto: Riesgo Crediticio (Métricas como par0, par7, ptyf).

* ¿Por qué esta área?

Alto Impacto: Es el corazón de una microfinanciera. La calidad y consistencia de estos datos tienen un impacto directo en la rentabilidad y el cumplimiento regulatorio.

Dolor Existente: Es muy probable que estas métricas sean calculadas de formas inconsistentes entre tribus y requieran ajustes manuales.

Champions Claros: El CFO y el Director de Riesgos son los Data Owners naturales de este dominio, lo que nos asegura su apoyo.

Entregables Concretos:

"Dominio de Riesgo Certificado": Un conjunto de 10-15 tablas y vistas en Redshift declaradas como la única fuente de verdad para el cálculo de riesgo.

Catálogo Completo del Dominio: Todas las tablas, columnas y métricas del dominio de riesgo estarán 100% documentadas por sus Data Stewards, con definiciones claras y linaje a nivel de tabla.

Dashboard Público de Calidad de Datos de Riesgo: Un reporte de "Data Docs" (Great Expectations) actualizado diariamente y accesible para todos, mostrando la salud de las métricas de riesgo.

## Mes 5-6: Escalamiento - Crear el Blueprint para Crecer
Tomamos las lecciones aprendidas del piloto y creamos un modelo repetible para expandir el gobierno al resto de la organización.

* ¿Cómo expandimos a otras áreas?

Crearemos un "Blueprint de Gobierno de Dominio": un checklist y un conjunto de plantillas basado en el éxito del piloto de Riesgo.

Iniciaremos el gobierno del siguiente dominio más crítico: Operaciones de Venta (datos de fact_salesmetrics, cumplimiento_100, etc.), aplicando el mismo blueprint.

* ¿Qué automatizamos vs. qué requiere intervención manual?

Automatizado: La ejecución de las pruebas de calidad, la generación de los reportes de calidad, la extracción de metadatos técnicos con Glue Crawlers.

Manual: La definición de reglas de negocio (requiere un experto), la investigación de la causa raíz de un error de calidad, y la documentación del contexto de negocio en el catálogo.

* ¿Cómo medimos el éxito? (KPIs de Gobierno de Datos)

Cobertura del Catálogo: % de Activos de Datos Críticos documentados (Objetivo: 50% al final de esta fase).

Puntaje de Calidad de Datos (Data Quality Score): Un índice ponderado de la calidad de los Elementos de Datos Críticos (CDEs). El objetivo es mostrar una tendencia positiva mes a mes.

Reducción de Incidentes: Disminución en el # de tickets de soporte relacionados con "datos incorrectos" (Objetivo: 25% de reducción).

Confianza del Usuario: Encuesta semestral (tipo NPS) a analistas y líderes de tribu sobre su nivel de confianza en los datos.

Qué NO Haremos (y por qué es importante)
Hacer gobierno de datos de forma pragmática también significa decidir qué "buenas prácticas" ignorar deliberadamente al principio.

* NO implementaremos un comité de gobierno formal con reuniones semanales.

Justificación: Nuestra cultura es ágil y somos un equipo pequeño. Un comité burocrático nos frenaría. En su lugar, operaremos con "grupos de trabajo" por dominio que se activarán para tomar decisiones específicas cuando sea necesario.

* NO catalogaremos el 100% de los datos.

Justificación: Seguiremos el principio de Pareto (80/20). El esfuerzo de catalogar todo es masivo y el retorno es decreciente. Nos enfocaremos obsesivamente en los activos críticos que alimentan las decisiones clave y los reportes regulatorios.

* NO implementaremos linaje de datos a nivel de columna para todos los procesos.

Justificación: Es una de las tareas más complejas y costosas del gobierno de datos. Implementaremos linaje a nivel de tabla para todos los activos críticos (fácil de obtener con las herramientas de AWS) y reservaremos el linaje a nivel de columna únicamente para las métricas que se reportan a la CNBV y al dashboard del CEO, donde la auditabilidad es máxima y el esfuerzo se justifica.