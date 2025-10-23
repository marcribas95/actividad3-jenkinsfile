# Jenkins Pipeline - Documentación

## 📋 Descripción

Este proyecto contiene un **Jenkinsfile** completo que automatiza el proceso de CI/CD para una aplicación de calculadora con pruebas unitarias, de API y End-to-End (E2E).

## 🏗️ Estructura del Proyecto

```
.
├── Jenkinsfile           # Pipeline de Jenkins
├── Makefile             # Comandos automatizados
├── run_tests.sh         # Script original de pruebas
├── docker-compose.yml   # Configuración de servicios Docker
├── requirements.txt     # Dependencias de Python
├── app/                 # Código fuente de la aplicación
├── tests/               # Pruebas unitarias, API y E2E
└── tests-reports/       # Reportes XML y logs generados
```

## 🚀 Uso del Makefile

El **Makefile** replica la funcionalidad del script `run_tests.sh` y proporciona los siguientes comandos:

### Comandos Disponibles

```bash
# Ver todos los comandos disponibles
make help

# Configurar entorno (crear venv e instalar dependencias)
make setup

# Ejecutar TODAS las pruebas
make test

# Ejecutar solo pruebas unitarias
make test-unit

# Ejecutar solo pruebas de API
make test-api

# Ejecutar solo pruebas E2E
make test-e2e

# Iniciar servicios Docker
make docker-up

# Detener servicios Docker
make docker-down

# Limpiar archivos temporales
make clean
```

### Ejemplo de Uso Manual

```bash
# 1. Configurar el entorno
make setup

# 2. Ejecutar todas las pruebas
make test

# O ejecutar pruebas específicas
make test-unit
make test-api
make test-e2e
```

## 🔧 Configuración de Jenkins

### Prerrequisitos en Jenkins

1. **Plugins necesarios:**
   - Git plugin
   - Pipeline plugin
   - JUnit plugin
   - Docker Pipeline plugin (si se usa agente Docker)

2. **Herramientas necesarias en el agente Jenkins:**
   - Python 3.x
   - Make
   - Docker y Docker Compose
   - Git

### Crear el Job en Jenkins

1. **Crear un nuevo Pipeline:**
   - En Jenkins, click en "Nueva Tarea" / "New Item"
   - Nombre: `calculadora-tests-pipeline`
   - Tipo: "Pipeline"

2. **Configurar el Pipeline:**
   - En la sección "Pipeline":
     - Definition: "Pipeline script from SCM"
     - SCM: Git
     - Repository URL: `https://github.com/marcribas95/actividad3-jenkinsfile.git`
     - Branch: `*/main`
     - Script Path: `jenkins/Jenkinsfile`

3. **Guardar y Ejecutar:**
   - Click en "Guardar"
   - Click en "Construir Ahora" / "Build Now"

## 📊 Stages del Pipeline

El Jenkinsfile contiene los siguientes stages:

### 1. 🔍 Checkout
- Descarga el código del repositorio Git
- Branch: `main`
- URL: `https://github.com/marcribas95/actividad3-jenkinsfile.git`

### 2. 🔧 Setup
- Crea el entorno virtual de Python
- Instala las dependencias desde `requirements.txt`
- Crea el directorio de reportes

### 3. 🧪 Test Unitarios
- Ejecuta pruebas unitarias de `calc_test.py` y `util_test.py`
- Genera reporte XML en formato JUnit
- Guarda logs de ejecución

### 4. 🌐 Test API
- Ejecuta pruebas de API REST desde `api_test_local.py`
- Genera reporte XML en formato JUnit
- Guarda logs de ejecución

### 5. 🚀 Test E2E
- Inicia servicios Docker (calc-api, calc-web)
- Ejecuta pruebas E2E con Cypress
- Genera reporte XML
- Detiene servicios Docker

### 6. 📊 Análisis de Resultados
- Publica reportes de pruebas en Jenkins
- Muestra estadísticas de tests pasados/fallidos
- Genera gráficos de tendencias

## 📦 Artefactos Generados

Cada ejecución del pipeline genera los siguientes artefactos:

### Reportes XML (formato JUnit)
- `test-results-unit-{timestamp}.xml`
- `test-results-api-{timestamp}.xml`
- `test-results-e2e-{timestamp}.xml`

### Logs de Ejecución
- `unit-output-{timestamp}.log`
- `api-output-{timestamp}.log`
- `e2e-output-{timestamp}.log`

Todos los artefactos están disponibles en Jenkins bajo "Artifacts" después de cada build.

## 🔄 Post-Actions

El pipeline incluye acciones post-ejecución:

- **Always (Siempre):**
  - Detiene servicios Docker
  - Archiva reportes y logs

- **Success (Éxito):**
  - Muestra mensaje de éxito
  - Todas las pruebas pasaron ✓

- **Failure (Fallo):**
  - Muestra mensaje de error
  - Algunas pruebas fallaron ✗

- **Unstable (Inestable):**
  - Muestra advertencia
  - Build inestable ⚠

## 🐛 Troubleshooting

### Problema: Error de permisos con Docker
**Solución:** Asegurar que el usuario Jenkins tiene permisos para ejecutar Docker:
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Problema: No se encuentra Python o Make
**Solución:** Instalar herramientas necesarias en el agente Jenkins:
```bash
sudo apt-get update
sudo apt-get install -y python3 python3-venv make
```

### Problema: Tests E2E fallan por timeout
**Solución:** Aumentar el tiempo de espera en `Makefile`:
```makefile
# En la línea de docker-up
@sleep 15  # Aumentar de 10 a 15 segundos
```

## 📝 Variables de Entorno

El pipeline utiliza las siguientes variables configurables:

```groovy
GIT_REPO = 'https://github.com/marcribas95/actividad3-jenkinsfile.git'
GIT_BRANCH = 'main'
PROJECT_DIR = "${WORKSPACE}"
REPORTS_DIR = "${WORKSPACE}/tests-reports"
```

Puedes modificar estas variables en el Jenkinsfile según tus necesidades.

## 🔐 Seguridad

Si el repositorio es privado, configura credenciales en Jenkins:

1. Jenkins → Credentials → System → Global credentials
2. Agregar credenciales (Username/Password o SSH Key)
3. Modificar el Jenkinsfile para usar las credenciales:

```groovy
checkout([
    $class: 'GitSCM',
    branches: [[name: "*/${GIT_BRANCH}"]],
    userRemoteConfigs: [[
        url: "${GIT_REPO}",
        credentialsId: 'github-credentials-id'
    ]]
])
```

## 📈 Mejoras Futuras

Posibles extensiones del pipeline:

- [ ] Agregar stage de análisis de código estático (SonarQube, Pylint)
- [ ] Agregar stage de cobertura de código
- [ ] Implementar notificaciones (Slack, Email)
- [ ] Agregar stage de deployment
- [ ] Configurar triggers automáticos (Webhooks)
- [ ] Agregar pruebas de performance

## 📞 Soporte

Para problemas o sugerencias, crear un issue en el repositorio:
https://github.com/marcribas95/actividad3-jenkinsfile/issues

---

**Autor:** Marc Ribas  
**Fecha:** Octubre 2025  
**Versión:** 1.0
