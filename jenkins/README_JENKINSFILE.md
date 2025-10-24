# Jenkinsfile - Guía de Uso

## Características Implementadas ✅

Este Jenkinsfile cumple con todos los requisitos solicitados:

### 1. ✅ Etapas de Pruebas
- **Test Unitarios** (`🧪 Test Unitarios`): Ejecuta pruebas unitarias de `calc_test.py` y `util_test.py`
- **Test API** (`🌐 Test API`): Ejecuta pruebas de API REST
- **Test E2E** (`🚀 Test E2E`): Ejecuta pruebas End-to-End con Cypress

### 2. ✅ Archivado de Archivos XML
Los archivos XML de las pruebas se archivan automáticamente en el bloque `post > always`:
```groovy
archiveArtifacts(
    artifacts: 'tests-reports/*.xml, tests-reports/*.log',
    allowEmptyArchive: true,
    fingerprint: true
)
```

### 3. ✅ Presentación de Informes
Cada stage de pruebas publica sus propios resultados de forma independiente:
- **Test Unitarios**: `test-results-unit-*.xml`
- **Test API**: `test-results-api-*.xml`
- **Test E2E**: `test-results-e2e-*.xml`

Esto permite ver los resultados separados por tipo de prueba en Jenkins.

### 4. ✅ Envío de Correo en Caso de Fallo
En el bloque `post > failure`, se incluye el código para enviar un correo electrónico que contiene:
- **Nombre del trabajo**: `${env.JOB_NAME}`
- **Número de ejecución**: `${env.BUILD_NUMBER}`
- **URL del build**: `${env.BUILD_URL}`

El código del correo está **comentado** para evitar errores de configuración SMTP. Para probarlo sin enviar realmente el correo, se usa un `echo` que muestra la información que se incluiría.

## Cómo Usar Este Jenkinsfile

### Opción 1: Editar el Pipeline Directamente en Jenkins (Recomendado para la actividad)

1. **Crear un nuevo trabajo en Jenkins**:
   - Ir a Jenkins → "Nueva Tarea"
   - Nombre: `calculadora`
   - Tipo: "Pipeline"
   - Hacer clic en "OK"

2. **Configurar el Pipeline**:
   - En la sección "Pipeline", seleccionar "Pipeline script"
   - Copiar y pegar el contenido completo del archivo `Jenkinsfile`
   - Hacer clic en "Guardar"

3. **Ejecutar el Pipeline**:
   - Hacer clic en "Construir Ahora"
   - Ver los resultados en "Console Output"

### Opción 2: Usar el Jenkinsfile desde el Repositorio

1. **Crear un nuevo trabajo en Jenkins**:
   - Ir a Jenkins → "Nueva Tarea"
   - Nombre: `calculadora-from-scm`
   - Tipo: "Pipeline"
   - Hacer clic en "OK"

2. **Configurar el Pipeline desde SCM**:
   - En la sección "Pipeline", seleccionar "Pipeline script from SCM"
   - SCM: "Git"
   - Repository URL: `https://github.com/marcribas95/actividad3-jenkinsfile.git`
   - Branch: `*/main`
   - Script Path: `jenkins/Jenkinsfile`
   - Hacer clic en "Guardar"

3. **Ejecutar el Pipeline**:
   - Hacer clic en "Construir Ahora"

## Variables Globales Disponibles

El Jenkinsfile utiliza las siguientes variables globales de Jenkins:

- `${env.JOB_NAME}`: Nombre del trabajo en Jenkins
- `${env.BUILD_NUMBER}`: Número de la ejecución actual
- `${env.BUILD_URL}`: URL completa del build actual
- `${WORKSPACE}`: Directorio de trabajo del job

## Herramientas Útiles en Jenkins

### 1. Pipeline Syntax (Generador de Snippets)
Para generar código de Pipeline:
1. En el job, ir a la izquierda "Pipeline Syntax"
2. Seleccionar el tipo de step que necesitas (ej: `emailext`)
3. Rellenar los campos necesarios
4. Hacer clic en "Generate Pipeline Script"

### 2. Declarative Directive Generator
Para generar directivas declarativas del Pipeline:
1. En "Pipeline Syntax", ir a la pestaña "Declarative Directive Generator"
2. Seleccionar la directiva (ej: `post`, `agent`, `options`)
3. Rellenar los campos
4. Generar el código

## Verificación de Funcionalidades

### ✅ Probar que el correo se enviaría (sin configurar SMTP)

En el log de ejecución, cuando el build falle, deberías ver:

```
📧 INFORMACIÓN DEL CORREO:
   Trabajo: calculadora
   Número de ejecución: 15
   URL: http://localhost:8080/job/calculadora/15/
```

Esto confirma que:
- El nombre del trabajo se captura correctamente
- El número de ejecución se obtiene correctamente
- La URL del build está disponible

### ✅ Verificar Informes por Separado

En Jenkins, después de ejecutar el build:
1. Ir a "Test Result"
2. Verás los resultados agrupados por archivo XML:
   - `test-results-unit-TIMESTAMP.xml`
   - `test-results-api-TIMESTAMP.xml`
   - `test-results-e2e-TIMESTAMP.xml`

### ✅ Verificar Archivado de Artefactos

En Jenkins, después de ejecutar el build:
1. Ir a "Build Artifacts"
2. Verás todos los archivos `.xml` y `.log` archivados
3. Puedes descargarlos para revisión

## Notas Importantes

1. **Correo Electrónico**: El código para enviar correos está comentado. Para habilitarlo:
   - Descomentar el bloque `emailext` en el `post > failure`
   - Configurar el servidor SMTP en Jenkins (Administrar Jenkins → Configurar el Sistema → E-mail Notification)
   - Cambiar `admin@example.com` por un correo real

2. **Plugin Necesario**: Para el envío de correos, necesitas el plugin "Email Extension Plugin" instalado en Jenkins.

3. **Resultados Separados**: Cada tipo de prueba publica sus resultados de forma independiente, lo que permite un análisis más granular en Jenkins.

## Estructura del Pipeline

```
Pipeline
├── Stage: Checkout (Descargar código)
├── Stage: Setup (Configurar entorno)
├── Stage: Test Unitarios (+ publicar resultados)
├── Stage: Test API (+ publicar resultados)
├── Stage: Test E2E (+ publicar resultados)
└── Post Actions
    ├── always: Limpieza y archivado
    ├── success: Mensaje de éxito
    ├── failure: Mensaje de fallo + envío de correo
    └── unstable: Mensaje de inestabilidad
```

## Contacto y Soporte

Si tienes dudas sobre la configuración o ejecución del Jenkinsfile, revisa:
- La documentación oficial de Jenkins: https://www.jenkins.io/doc/
- Pipeline Syntax Generator en tu instancia de Jenkins
- Los logs de ejecución en "Console Output"
