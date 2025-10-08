# 1. Flujo de Trabajo (Workflow)
Este documento define un proceso formal y auditable para gestionar el ciclo de vida del acceso a los datos. El objetivo es que el proceso sea claro, eficiente y seguro.
El proceso sigue un flujo de aprobación basado en la clasificación del dato solicitado.

1. Solicitud
   Usuario llena un formulario
   (Jira Service Desk / MS Forms)
      |
      V
2. Aprobación Nivel 1 (Data Steward)
   - Revisa la justificación de negocio.
   - Si el dato es Confidencial o inferior, aprueba.
   - Si el dato es Restringido, escala al Data Owner.
      |
      V
3. Aprobación Nivel 2 (Data Owner - Solo para datos Restringidos)
   - Realiza la aprobación final para datos sensibles.
      |
      V
4. Ejecución Técnica
   - Se crea un ticket para el equipo de Data Engineering.
   - Se ejecuta el comando GRANT en Redshift.
   - Se cierra el ticket.
      |
      V
5. Notificación
   - El usuario es notificado de que su acceso ha sido concedido.

# 2. Componentes del Proceso
Formulario de Solicitud de Acceso
El formulario será la única puerta de entrada para solicitar acceso. Requerirá la siguiente información:

* Solicitante y Rol: (Autocompletado con su sesión)

* Justificación de Negocio: (¿Para qué necesitas estos datos? ¿Qué pregunta de negocio vas a responder?)

* Datos Requeridos: (Nombres de las tablas, vistas o schemas)

* Nivel de Acceso: (READ-ONLY)

* Duración del Acceso: (Indefinido, Temporal [especificar fecha de fin])

* Aprobador Sugerido (Data Steward): (El usuario sugiere quién es el experto en esos datos)

## Flujo de Aprobación
* Datos Confidenciales o Internos: Requieren solo la aprobación del Data Steward del dominio.

* Datos Restringidos: Requieren la aprobación del Data Steward Y la aprobación final del Data Owner.

* Revisión Periódica de Accesos (Recertificación)

El acceso a datos no puede ser para siempre sin revisión. Implementaremos un proceso de recertificación trimestral:

* Generación de Reporte: Un script automatizado se ejecutará cada trimestre para generar un reporte de "quién tiene acceso a qué" para los datos Confidenciales y Restringidos.

* Identificación de Inactivos: El script cruzará esta información con los logs de auditoría de Redshift para marcar a los usuarios que no han accedido a un dato en los últimos 90 días.

* Envío a Data Owners: El reporte se envía a los Data Owners correspondientes.

* Certificación: El Data Owner debe certificar si cada acceso sigue siendo necesario. Los accesos no certificados o los de usuarios inactivos se revocan automáticamente.

## Offboarding

Este es el proceso más crítico.

* Integración con HR: El proceso de baja de un empleado en el sistema de RRHH debe disparar un evento automático (vía webhook o API).

* Automatización de Revocación: Este evento activará un script (ej. una función Lambda) que se conectará a Redshift y ejecutará un REVOKE de todos los roles y permisos del usuario y lo deshabilitará. El acceso debe ser revocado en cuestión de minutos, no de días.


