# 1. Clasificación de Datos
Este documento detalla la estrategia para proteger los activos de datos de Podemos Progresar. Nuestro enfoque se basa en tres principios clave:

* Principio de Menor Privilegio (Least Privilege): Los usuarios solo tendrán acceso a los datos estrictamente necesarios para realizar su trabajo. El acceso por defecto es "denegado".

* Defensa en Profundidad (Defense in Depth): Implementaremos múltiples capas de seguridad (red, infraestructura, base de datos, BI) para que la falla de un solo control no comprometa todo el sistema.

* Privacidad por Diseño (Privacy by Design): La protección de datos personales (PII) no será una ocurrencia tardía, sino un requisito fundamental integrado en el diseño de nuestras tablas y vistas.


El primer paso para proteger nuestros datos es entender su nivel de sensibilidad. Proponemos un framework de clasificación de 4 niveles:
| Nivel            | Descripción                                                                                                                                          | Ejemplos en Podemos Progresar                                                        |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| **Público**      | Información que puede ser compartida libremente con el exterior.                                                                                     | Ubicaciones de sucursales, descripciones de productos de crédito.                    |
| **Interno**      | Información de negocio de bajo riesgo, accesible para todos los empleados.                                                                           | Organigrama, políticas internas, métricas agregadas no sensibles.                    |
| **Confidencial** | Información de negocio sensible cuyo acceso debe estar restringido a roles específicos. Su divulgación no autorizada podría causar un daño moderado. | `fact_salesmetrics` (métricas de negocio), planes estratégicos.                      |
| **Restringido**  | Datos altamente sensibles, incluyendo PII y datos financieros, protegidos por ley (LFPDPPP). Su divulgación podría causar un daño grave.             | `fact_payments` (transacciones), `dim_clientes` (PII), `dim_colaboradores_ce` (PII). |

* Matriz de Clasificación de Activos de Datos:

| Dataset                | Campo Específico             | Clasificación    | Razón                                                           |
| ---------------------- | ---------------------------- | ---------------- | --------------------------------------------------------------- |
| `fact_salesmetrics`    | (Todos)                      | **Confidencial** | Revela el rendimiento interno y la estrategia de las tribus.    |
| `fact_payments`        | (Todos)                      | **Restringido**  | Contiene información financiera detallada de las transacciones. |
| `dim_colaboradores_ce` | `nombre_completo`, `rfc`     | **Restringido**  | Datos Personales de Identificación (PII) de empleados.          |
| `dim_clientes`         | `nombre_cliente`, `telefono` | **Restringido**  | PII de clientes, protegido por la LFPDPPP.                      |
| `dim_clientes`         | `monto_credito_aprobado`     | **Restringido**  | Información financiera sensible del cliente.                    |

# 2. Diseño de Acceso en Redshift (Estrategia)
Nuestra estrategia de control de acceso en Redshift será multicapa, combinando varios mecanismos nativos para lograr una seguridad granular.

Control de Acceso Basado en Roles (RBAC): Nunca asignaremos permisos directamente a usuarios. Crearemos roles funcionales (analista_tribu, data_scientist, auditor_interno) y asignaremos usuarios a estos roles. Esto simplifica drásticamente la gestión y la auditoría.

* Segregación por Schemas: Usaremos schemas para separar los datos por nivel de sensibilidad.

* curated_data: Contendrá datos de negocio limpios y transformados, como fact_salesmetrics. Será el schema principal para la mayoría de los analistas.

* restricted_pii: Contendrá las tablas base con datos PII y financieros sensibles, como dim_clientes. El acceso a este schema será extremadamente limitado.

* Vistas de Acceso Seguro: La mayoría de los usuarios no accederán directamente a las tablas en restricted_pii. En su lugar, accederán a vistas creadas en el schema curated_data que exponen solo los datos necesarios y aplican enmascaramiento dinámico.

* Seguridad a Nivel de Fila (RLS - Row-Level Security): Para el rol analista_tribu, implementaremos políticas de RLS en las tablas de hechos para asegurar que un analista de la "Tribu Puebla" solo pueda ver las filas correspondientes a su tribu.

* Seguridad a Nivel de Columna (CLS - Column-Level Security): Usaremos CASE statements dentro de las vistas para implementar enmascaramiento dinámico. Por ejemplo, un data_scientist verá un número de teléfono como ******1234, mientras que un auditor_interno verá el número completo.

# 3. Integración con Capa de BI (QuickSight y Amazon Q)
La seguridad se aplicará en la capa más baja (Redshift), lo que significa que las herramientas de BI heredarán automáticamente estos controles.

Arquitectura de Seguridad End-to-End:

* Autenticación: Los usuarios inician sesión en AWS y asumen un Rol de IAM.

* Federación: Este Rol de IAM está mapeado a un grupo de usuarios en Redshift.

* Autorización: El grupo de usuarios de Redshift tiene asignado un rol (analista_tribu, etc.).

* Ejecución: Cuando el usuario ejecuta una consulta desde QuickSight o Amazon Q, Redshift la evalúa bajo el contexto de su rol asignado, aplicando RLS y el enmascaramiento de las vistas.

¿Cómo se evita el bypass? Al no conceder acceso a las tablas base con PII, es imposible que un usuario "inteligente" en QuickSight pueda escribir una consulta personalizada para ver los datos sin máscara. La seguridad está en la base de datos, no en la herramienta de BI.

* Amazon Q: Respetará al 100% los permisos de Redshift. Si un analista de tribu pregunta "Dame el teléfono de Juan Pérez", la consulta subyacente fallará o devolverá un valor enmascarado porque su rol no tiene permiso para ver esa columna en claro.

# 4. Experiencia Pasada
¿Controles demasiado restrictivos?

"En el proyecto actual en el que me encuentro, implementamos una política de acceso muy estricta que, sin querer, bloqueó al equipo de marketing de analizar el comportamiento de los clientes por región. El proceso de solicitud era lento y frenaba el negocio. La lección fue que la seguridad debe ser un diálogo, no un decreto. La solución fue crear un rol específico marketing_analytics que accedía a una vista agregada y anonimizada de los datos del cliente, dándoles la información que necesitaban sin exponer PII. El balance es clave."

¿Respuesta a auditorías?

"Tuve que responder a una auditoría de privacidad de datos. Tener implementado un sistema de RBAC, logs de auditoría centralizados y un proceso de solicitud de acceso documentado fue lo que nos salvó. La lección más grande fue: si no está registrado, no sucedió. Un auditor no se fía de las palabras; quiere ver los logs que demuestren quién accedió a qué dato y cuándo. Por eso la estrategia de logging es tan importante como la de control de acceso."


