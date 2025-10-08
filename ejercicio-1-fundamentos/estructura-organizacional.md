# 1. Modelo Organizacional: Híbrido / Federado

Este documento describe la propuesta de modelo organizacional, los roles, las responsabilidades y los procesos de decisión para la función de Gobierno de Datos en Podemos Progresar.

La filosofía de esta estructura es: centralizar los estándares y las herramientas, pero descentralizar la ejecución y el conocimiento del negocio.

Adoptaremos un modelo Híbrido. Esto significa que tendremos:

Un Equipo Central de Gobierno de Datos (DGO - Data Governance Office) pequeño y técnico, que establece las reglas del juego, provee las herramientas (catálogo, calidad de datos) y audita el cumplimiento.

Una red de Data Stewards distribuidos dentro de las tribus y áreas de negocio, quienes son los verdaderos expertos en los datos y responsables de su calidad en el día a día.

¿Por qué este modelo?

* Escalabilidad: Un equipo central nunca podría entender el contexto de las 29 tribus. Este modelo escala el gobierno a través de la propia organización.

* Agilidad: Evita que el equipo central se convierta en un cuello de botella para cada solicitud o cambio. Las decisiones se toman más cerca de donde se genera y utiliza el dato.

* Alineación con Data Mesh: Este modelo es la base organizacional para una arquitectura Data Mesh, donde cada tribu (dominio) es responsable de sus "productos de datos".

* Nuestro Equipo (DGO)
Dadas las restricciones presupuestarias y la necesidad de ser ágiles, el DGO inicial estará compuesto por:

1x Data Governance Lead (Yo): Responsable de la estrategia, la evangelización, la gestión del roadmap y la coordinación con los Data Owners.

1x Data Quality Engineer: Un rol técnico y práctico. Será responsable de implementar el framework de calidad de datos (ej. Great Expectations), construir los dashboards de monitoreo y ayudar a los ingenieros a instrumentar sus pipelines.

# 2. Roles y Responsabilidades Clave

| Rol                      | ¿Quién es?                                                                                                                              | Responsabilidades Clave                                                                                                                                                                                               |
| :----------------------- | :-------------------------------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Data Owner** | Líder ejecutivo (ej. CFO, Director de Riesgos).                                                                                         | - **Rinde cuentas** por un dominio de datos.<br>- Aprueba políticas de acceso y uso.<br>- Asigna recursos y prioriza iniciativas.<br>- Es el **punto final de escalamiento**.                                               |
| **Data Steward** | Experto en la materia dentro de una tribu o área. **No es un puesto nuevo**, es una responsabilidad asignada.                             | - **Define** métricas y reglas de negocio.<br>- **Documenta** los datos de su área en el catálogo.<br>- Es el **primer punto de contacto** para preguntas.<br>- Monitorea la calidad de los datos de su área.              |
| **Data Governance Office (DGO)** | Mi equipo y yo.                                                                                                                         | - **Define** los estándares, políticas y herramientas.<br>- **Gestiona** el catálogo y el framework de calidad.<br>- **Capacita y apoya** a los Data Stewards.<br>- **Monitorea y reporta** sobre la salud de los datos. |
| **Data Engineer** | Miembro del equipo técnico de datos.                                                                                                    | - **Implementa** los controles de calidad y linaje en los pipelines.<br>- **Asegura** que los nuevos "productos de datos" cumplan con los estándares de gobierno.                                                          |


# 3. Estructura y Flujo de Interacción
El DGO no es un "policía de datos", sino un "habilitador". Nuestra interacción con los ingenieros de datos se integrará en su flujo de trabajo existente (CI/CD, Pull Requests).

¿Cómo interactuamos?

Definición: El DGO provee plantillas y librerías para que los ingenieros implementen calidad y linaje fácilmente.

Desarrollo: Los requisitos de gobierno (ej. "documentar en el catálogo") son parte de la "Definition of Done" de las tareas de ingeniería.

Revisión: La revisión de un Pull Request incluirá una validación de gobierno.

Diagrama de Estructura Organizacional
A continuación se muestra un diagrama simplificado de las relaciones. La línea punteada representa una relación de guía y soporte, no de reporte directo.

- **CTO**
    - **Equipo Central de Datos**
        - **Equipo de Data Engineering**
        - **Data Governance Office (DGO)**
            - *Relación de guía y soporte con:*
                - **Data Stewards** (ubicados dentro de cada Tribu y Unidad de Negocio)

# 4. Matriz de Decisiones (RACI)
Para ilustrar cómo funciona este modelo en la práctica, usemos un caso real:

Decisión Clave: "¿Quién decide si agregamos un nuevo campo a la tabla fact_salesmetrics?"

| Rol                               | R     | A     | C     | I     |
| :-------------------------------- | :---: | :---: | :---: | :---: |
| **Data Owner** (Ventas)           |       | ✅    |       |       |
| **Data Steward** (Tribu)          |       |       | ✅    |       |
| **Data Engineer** | ✅    |       |       |       |
| **BI Analysts** (Usuarios)        |       |       | ✅    |       |
| **Data Governance Office (DGO)** |       |       |       | ✅    |
| **CTO** |       |       |       | ✅    |

Justificación:

R (Responsible): El Data Engineer ejecuta el trabajo técnico.

A (Accountable): El Data Owner de Ventas tiene la autoridad final y es responsable del resultado.

C (Consulted): Se consulta a los Data Stewards y Analistas de BI por su conocimiento práctico y para entender el impacto.

I (Informed): El DGO y el CTO son informados para mantener la visibilidad y asegurar la consistencia.
