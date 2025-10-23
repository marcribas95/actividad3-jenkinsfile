# 🚀 Proyecto Actividad 3 - Jenkins Pipeline

## ✅ Archivos Creados

Se han creado exitosamente los siguientes archivos:

### 1. 📄 `Makefile` (en la raíz del proyecto)
**Ubicación:** `/home/marc/Escritorio/MasterDevOps/Entornos Integracion y Entrega Continua/actividad3-jenkinsfile/Makefile`

**Descripción:** 
Makefile que replica la funcionalidad del script `run_tests.sh` con comandos más simples y mantenibles.

**Características principales:**
- ✓ Configuración automática del entorno virtual
- ✓ Instalación de dependencias
- ✓ Ejecución de tests unitarios
- ✓ Ejecución de tests de API
- ✓ Ejecución de tests E2E con Docker
- ✓ Generación de reportes XML (JUnit format)
- ✓ Logs detallados de cada ejecución
- ✓ Colores en la consola para mejor visualización

**Comandos principales:**
```bash
make help        # Muestra ayuda
make setup       # Configura el entorno
make test        # Ejecuta todas las pruebas
make test-unit   # Solo pruebas unitarias
make test-api    # Solo pruebas de API
make test-e2e    # Solo pruebas E2E
make clean       # Limpia archivos temporales
```

### 2. 📄 `jenkins/Jenkinsfile`
**Ubicación:** `/home/marc/Escritorio/MasterDevOps/Entornos Integracion y Entrega Continua/actividad3-jenkinsfile/jenkins/Jenkinsfile`

**Descripción:** 
Pipeline declarativo de Jenkins que automatiza todo el proceso de CI/CD.

**Características principales:**
- ✓ Descarga código desde GitHub (https://github.com/marcribas95/actividad3-jenkinsfile.git)
- ✓ Configuración automática del entorno
- ✓ Ejecución secuencial de todos los tests usando el Makefile
- ✓ Publicación de reportes JUnit
- ✓ Archivado de artefactos (reportes y logs)
- ✓ Mensajes informativos con emojis
- ✓ Manejo de errores y limpieza automática

**Stages del pipeline:**
1. 🔍 **Checkout** - Descarga el código del repositorio
2. 🔧 **Setup** - Configura el entorno (ejecuta `make setup`)
3. 🧪 **Test Unitarios** - Ejecuta `make test-unit`
4. 🌐 **Test API** - Ejecuta `make test-api`
5. 🚀 **Test E2E** - Ejecuta `make test-e2e`
6. 📊 **Análisis de Resultados** - Publica reportes JUnit

### 3. 📄 `jenkins/README.md`
**Ubicación:** `/home/marc/Escritorio/MasterDevOps/Entornos Integracion y Entrega Continua/actividad3-jenkinsfile/jenkins/README.md`

**Descripción:** 
Documentación completa sobre cómo usar el Jenkinsfile y el Makefile.

**Contenido:**
- ✓ Descripción del proyecto
- ✓ Instrucciones de uso del Makefile
- ✓ Configuración paso a paso en Jenkins
- ✓ Explicación de cada stage del pipeline
- ✓ Lista de artefactos generados
- ✓ Troubleshooting común
- ✓ Variables de entorno configurables
- ✓ Configuración de seguridad para repos privados

## 🎯 Diferencias entre run_tests.sh y Makefile

| Aspecto | run_tests.sh | Makefile |
|---------|-------------|----------|
| **Sintaxis** | Bash script | Make targets |
| **Modularidad** | Funciones bash | Targets independientes |
| **Reutilización** | Ejecuta todo de una vez | Puedes ejecutar partes específicas |
| **Integración CI** | Requiere bash | Estándar en CI/CD |
| **Mantenibilidad** | Script largo | Targets bien definidos |
| **Paralelización** | Secuencial | Puede paralelizar con `-j` |

## 🔄 Flujo de Trabajo Completo

### Local (Manual)
```bash
# 1. Clonar el repositorio
git clone https://github.com/marcribas95/actividad3-jenkinsfile.git
cd actividad3-jenkinsfile

# 2. Configurar el entorno
make setup

# 3. Ejecutar todas las pruebas
make test

# O ejecutar pruebas específicas
make test-unit
make test-api
make test-e2e
```

### Jenkins (Automatizado)
1. Crear un nuevo Pipeline en Jenkins
2. Configurar el repositorio Git:
   - URL: `https://github.com/marcribas95/actividad3-jenkinsfile.git`
   - Branch: `main`
   - Script Path: `jenkins/Jenkinsfile`
3. Ejecutar el build
4. Ver resultados en la interfaz de Jenkins

## 📊 Reportes Generados

Cada ejecución genera archivos con timestamp único:

### Reportes XML (JUnit format)
- `tests-reports/test-results-unit-{timestamp}.xml`
- `tests-reports/test-results-api-{timestamp}.xml`
- `tests-reports/test-results-e2e-{timestamp}.xml`

### Logs detallados
- `tests-reports/unit-output-{timestamp}.log`
- `tests-reports/api-output-{timestamp}.log`
- `tests-reports/e2e-output-{timestamp}.log`

## 🛠️ Requisitos del Sistema

### Para ejecución local con Makefile:
- Python 3.x
- Make
- Docker y Docker Compose
- Git

### Para Jenkins:
- Jenkins 2.x o superior
- Plugins: Git, Pipeline, JUnit, Docker Pipeline
- Agente con Python, Make, Docker y Git instalados

## ✨ Ventajas de esta Implementación

1. **Modularidad**: El Makefile permite ejecutar stages individuales
2. **Reutilización**: Mismo Makefile para local y CI/CD
3. **Mantenibilidad**: Código organizado y fácil de entender
4. **Escalabilidad**: Fácil agregar nuevos tipos de tests
5. **Estándar**: Makefile es un estándar en la industria
6. **Trazabilidad**: Reportes XML compatibles con Jenkins
7. **Debugging**: Logs detallados de cada ejecución

## 🎓 Próximos Pasos

1. **Probar localmente:**
   ```bash
   make setup
   make test
   ```

2. **Configurar en Jenkins:**
   - Seguir las instrucciones en `jenkins/README.md`

3. **Verificar reportes:**
   - Revisar archivos generados en `tests-reports/`

4. **Personalizar según necesidades:**
   - Modificar variables en el Jenkinsfile
   - Ajustar tiempos de espera en Makefile
   - Agregar nuevos stages si es necesario

## 📚 Documentación Adicional

- **Makefile syntax**: https://www.gnu.org/software/make/manual/
- **Jenkins Pipeline**: https://www.jenkins.io/doc/book/pipeline/
- **JUnit XML format**: https://llg.cubic.org/docs/junit/

## 🎉 ¡Todo Listo!

Tu proyecto ahora tiene:
- ✅ Un Makefile profesional
- ✅ Un Jenkinsfile completo
- ✅ Documentación detallada
- ✅ Listo para CI/CD

¡Puedes empezar a usar el pipeline inmediatamente!

---

**Última actualización:** Octubre 2025  
**Versión:** 1.0
