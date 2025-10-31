# ==============================================================================
# MAKEFILE PARA GESTIÓN DE PRUEBAS Y DESPLIEGUE
# ==============================================================================
# Este Makefile automatiza el proceso de construcción, pruebas y limpieza
# de una aplicación Flask con API de calculadora.
# Incluye pruebas unitarias, de API REST y End-to-End (E2E) con Cypress.
# ==============================================================================

.PHONY: all build test-unit test-api test-e2e test-all clean setup-dirs setup docker-down

# ==============================================================================
# VARIABLES DE CONFIGURACIÓN
# ==============================================================================

# Genera un timestamp único para identificar cada ejecución de pruebas
# Formato: YYYYMMDD_HHMMSS (ej: 20251029_143025)
TIMESTAMP := $(shell date +"%Y%m%d_%H%M%S")

# Directorio donde se almacenarán todos los reportes de pruebas
REPORTS_DIR := tests-reports

# Rutas de los archivos de reporte XML (formato JUnit) para cada tipo de prueba
UNIT_REPORT := $(REPORTS_DIR)/test-results-unit-$(TIMESTAMP).xml
API_REPORT := $(REPORTS_DIR)/test-results-api-$(TIMESTAMP).xml
E2E_REPORT := $(REPORTS_DIR)/test-results-e2e-$(TIMESTAMP).xml

# Rutas de los archivos de log con la salida completa de cada ejecución
UNIT_LOG := $(REPORTS_DIR)/unit-output-$(TIMESTAMP).log
API_LOG := $(REPORTS_DIR)/api-output-$(TIMESTAMP).log
E2E_LOG := $(REPORTS_DIR)/e2e-output-$(TIMESTAMP).log

# ==============================================================================
# CÓDIGOS DE COLOR PARA MEJORAR LA LEGIBILIDAD DEL OUTPUT EN TERMINAL
# ==============================================================================
RED := \033[0;31m      # Rojo para errores y fallos
GREEN := \033[0;32m    # Verde para éxitos y completados
YELLOW := \033[1;33m   # Amarillo para advertencias y procesos en curso
BLUE := \033[0;34m     # Azul para información y títulos
NC := \033[0m          # Sin color (reset)

# ==============================================================================
# TARGET: setup-dirs
# ==============================================================================
# DESCRIPCIÓN:
#   Crea la estructura de directorios necesaria para almacenar reportes de pruebas.
#   Este target es un prerequisito para todas las tareas de testing.
#
# ACCIÓN:
#   - Crea el directorio tests-reports/ si no existe
#   - Utiliza -p para crear directorios padre si son necesarios
# ==============================================================================
setup-dirs:
	@echo "$(BLUE)→$(NC) Configurando directorios..."
	@mkdir -p $(REPORTS_DIR)
	@echo "$(GREEN)✓$(NC) Directorio de reportes creado"

# ==============================================================================
# TARGET: setup
# ==============================================================================
# DESCRIPCIÓN:
#   Prepara el entorno completo para la ejecución de pruebas.
#   Este target es llamado desde el Jenkinsfile para inicializar el pipeline.
#
# DEPENDENCIAS:
#   - setup-dirs: Asegura que existan los directorios necesarios
#   - build: Construye las imágenes Docker antes de cualquier prueba
#
# ORDEN DE EJECUCIÓN:
#   1. Ejecuta setup-dirs
#   2. Ejecuta build
#   3. Confirma configuración exitosa
# ==============================================================================
setup: setup-dirs build
	@echo "$(BLUE)→$(NC) Configurando entorno completo..."
	@echo "$(GREEN)✓$(NC) Entorno configurado exitosamente"

# ==============================================================================
# TARGET: build
# ==============================================================================
# DESCRIPCIÓN:
#   Construye las imágenes Docker necesarias para la aplicación.
#   Utiliza docker-compose para orquestar la construcción de múltiples servicios.
#
# SERVICIOS CONSTRUIDOS:
#   - calc-api: Contenedor con la API Flask de calculadora
#   - calc-web: Contenedor con el frontend web (Nginx + HTML)
#
# NOTA:
#   Las imágenes se construyen según las especificaciones del docker-compose.yml
#   y los Dockerfiles correspondientes.
# ==============================================================================
build:
	@echo "$(BLUE)→$(NC) Construyendo imágenes Docker..."
	@docker compose build calc-api calc-web
	@echo "$(GREEN)✓$(NC) Imágenes construidas exitosamente"

# ==============================================================================
# TARGET: test-unit
# ==============================================================================
# DESCRIPCIÓN:
#   Ejecuta las pruebas unitarias de las funciones básicas de la aplicación.
#   Las pruebas unitarias verifican el comportamiento individual de cada función
#   sin dependencias externas.
#
# ARCHIVOS DE PRUEBA:
#   - tests/unit/calc_test.py: Pruebas de operaciones matemáticas (suma, resta, etc.)
#   - tests/unit/util_test.py: Pruebas de funciones utilitarias
#
# HERRAMIENTAS:
#   - pytest: Framework de testing para Python
#   - docker compose run: Ejecuta pytest dentro del contenedor calc-api
#
# OPCIONES DE PYTEST:
#   -v: Modo verbose (muestra cada test individualmente)
#   --tb=short: Formato corto de traceback en caso de errores
#   --junit-xml: Genera reporte en formato JUnit XML para integración con Jenkins
#
# SALIDA:
#   - Reporte XML: tests-reports/test-results-unit-TIMESTAMP.xml
#   - Log completo: tests-reports/unit-output-TIMESTAMP.log
#
# NOTA:
#   El '|| true' al final evita que Make se detenga si hay pruebas fallidas,
#   permitiendo que el pipeline continúe y genere reportes completos.
# ==============================================================================
test-unit: setup-dirs
	@echo "\n$(BLUE)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC) EJECUTANDO PRUEBAS UNITARIAS"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════╝$(NC)\n"
	@echo "$(YELLOW)→$(NC) Ejecutando pruebas unitarias de calc_test.py y util_test.py..."
	@docker compose run --rm calc-api pytest \
		/app/tests/unit \
		-v \
		--tb=short \
		--junit-xml=/app/$(UNIT_REPORT) 2>&1 | tee $(UNIT_LOG) || true
	@if [ -f $(UNIT_REPORT) ]; then \
		echo "$(GREEN)✓$(NC) Pruebas unitarias completadas"; \
		echo "$(BLUE)ℹ$(NC) Reporte: $(UNIT_REPORT)"; \
	else \
		echo "$(RED)✗$(NC) Error al generar reporte"; \
	fi

# ==============================================================================
# TARGET: test-api
# ==============================================================================
# DESCRIPCIÓN:
#   Ejecuta las pruebas de integración de la API REST.
#   Estas pruebas verifican que los endpoints HTTP respondan correctamente
#   y que la API cumpla con su contrato.
#
# ARCHIVOS DE PRUEBA:
#   - tests/rest/api_test_local.py: Pruebas de endpoints REST
#     * GET /calc/add/{x}/{y}: Suma de dos números
#     * GET /calc/subtract/{x}/{y}: Resta de dos números
#     * GET /calc/multiply/{x}/{y}: Multiplicación
#     * GET /calc/divide/{x}/{y}: División
#     * Y otros endpoints de la API
#
# REQUISITOS:
#   - El servicio calc-api debe estar disponible en la red Docker
#   - Los tests hacen peticiones HTTP reales a la API
#
# HERRAMIENTAS:
#   - pytest: Framework de testing
#   - requests: Librería para hacer peticiones HTTP
#
# SALIDA:
#   - Reporte XML: tests-reports/test-results-api-TIMESTAMP.xml
#   - Log completo: tests-reports/api-output-TIMESTAMP.log
# ==============================================================================
test-api: setup-dirs
	@echo "\n$(BLUE)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC) EJECUTANDO PRUEBAS DE API"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════╝$(NC)\n"
	@echo "$(YELLOW)→$(NC) Ejecutando pruebas de API..."
	@docker compose run --rm calc-api pytest \
		/app/tests/rest/api_test_local.py \
		-v \
		--tb=short \
		--junit-xml=/app/$(API_REPORT) 2>&1 | tee $(API_LOG) || true
	@if [ -f $(API_REPORT) ]; then \
		echo "$(GREEN)✓$(NC) Pruebas de API completadas"; \
		echo "$(BLUE)ℹ$(NC) Reporte: $(API_REPORT)"; \
	else \
		echo "$(RED)✗$(NC) Error al generar reporte"; \
	fi

# ==============================================================================
# TARGET: test-e2e
# ==============================================================================
# DESCRIPCIÓN:
#   Ejecuta las pruebas End-to-End (E2E) que simulan el comportamiento completo
#   de un usuario real interactuando con la aplicación web.
#   
# FLUJO DE EJECUCIÓN:
#   1. LIMPIEZA: Elimina contenedores previos para evitar conflictos
#   2. INICIO: Levanta los servicios calc-api (backend) y calc-web (frontend)
#   3. ESPERA: Pausa de 10 segundos para que los servicios se inicialicen
#   4. PRUEBAS: Ejecuta Cypress que abre un navegador y prueba la interfaz web
#   5. VALIDACIÓN: Analiza el reporte XML para detectar fallos
#   6. LIMPIEZA: Detiene y elimina todos los contenedores
#
# SERVICIOS INVOLUCRADOS:
#   - calc-api: API Flask que procesa las operaciones matemáticas
#   - calc-web: Frontend Nginx que sirve la interfaz HTML
#   - cypress-e2e: Contenedor Cypress que ejecuta las pruebas del navegador
#
# ARCHIVOS DE PRUEBA:
#   - tests/e2e/cypress/integration/calc.spec.js: Pruebas Cypress
#     * Verifica que la interfaz web cargue correctamente
#     * Simula interacciones del usuario (clicks, inputs)
#     * Valida que los resultados se muestren correctamente
#
# VALIDACIÓN DE RESULTADOS:
#   - Copia el reporte XML de Cypress al directorio de reportes
#   - Extrae el número de fallos del XML con grep
#   - Si hay fallos (failures > 0), termina con código de error
#   - Si Cypress retorna código de salida != 0, propaga el error
#
# SALIDA:
#   - Reporte XML: tests-reports/test-results-e2e-TIMESTAMP.xml
#   - Log completo: tests-reports/e2e-output-TIMESTAMP.log
#   - Screenshots: tests/e2e/cypress/screenshots/ (solo en caso de fallos)
#
# TIEMPO DE ESPERA:
#   El sleep de 10 segundos asegura que:
#   - Flask esté completamente iniciado
#   - Nginx haya cargado los archivos estáticos
#   - La red Docker esté estable
# ==============================================================================
test-e2e: setup-dirs
	@echo "\n$(BLUE)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC) EJECUTANDO PRUEBAS E2E (End-to-End)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════╝$(NC)\n"
	@echo "$(YELLOW)→$(NC) Limpiando contenedores previos..."
	@docker compose rm -f calc-api calc-web cypress-e2e 2>/dev/null || true
	@echo "$(YELLOW)→$(NC) Iniciando servicios necesarios con docker-compose..."
	@docker compose up -d calc-api calc-web
	@echo "$(GREEN)✓$(NC) Servicios iniciados correctamente"
	@echo "$(YELLOW)→$(NC) Esperando 10 segundos para que los servicios se inicialicen..."
	@sleep 10
	@echo "$(YELLOW)→$(NC) Ejecutando pruebas e2e con Cypress..."
	@docker compose run --rm cypress-e2e 2>&1 | tee $(E2E_LOG); \
	CYPRESS_EXIT=$$?; \
	echo "$(YELLOW)→$(NC) Deteniendo servicios de docker-compose..."; \
	docker compose stop calc-api calc-web; \
	docker compose rm -f calc-api calc-web cypress-e2e; \
	if [ -f tests/e2e/results/cypress_result.xml ]; then \
		cp tests/e2e/results/cypress_result.xml $(E2E_REPORT); \
		echo "$(GREEN)✓$(NC) Reporte e2e copiado a: $(E2E_REPORT)"; \
		FAILURES=$$(grep -oP 'failures="\K[0-9]+' $(E2E_REPORT) | head -1); \
		if [ "$$FAILURES" != "" ] && [ $$FAILURES -gt 0 ]; then \
			echo "$(RED)✗$(NC) Se detectaron $$FAILURES pruebas E2E fallidas"; \
			exit 1; \
		fi; \
	else \
		echo "$(RED)✗$(NC) No se encontró el reporte XML de Cypress"; \
		exit 1; \
	fi; \
	if [ $$CYPRESS_EXIT -ne 0 ]; then \
		echo "$(RED)✗$(NC) Cypress terminó con código de salida: $$CYPRESS_EXIT"; \
		exit $$CYPRESS_EXIT; \
	fi; \
	echo "$(GREEN)✓$(NC) Todas las pruebas E2E pasaron correctamente"
		exit 1; \
	fi; \
	if [ $$CYPRESS_EXIT -ne 0 ]; then \
		echo "$(RED)✗$(NC) Cypress terminó con código de salida: $$CYPRESS_EXIT"; \
		exit $$CYPRESS_EXIT; \
	fi; \
	echo "$(GREEN)✓$(NC) Todas las pruebas E2E pasaron correctamente"

# ==============================================================================
# TARGET: test-all
# ==============================================================================
# DESCRIPCIÓN:
#   Ejecuta secuencialmente todas las pruebas del proyecto y muestra un resumen
#   final con las ubicaciones de todos los reportes y logs generados.
#
# ORDEN DE EJECUCIÓN:
#   1. test-unit: Pruebas unitarias de funciones individuales
#   2. test-api: Pruebas de integración de la API REST
#   3. test-e2e: Pruebas End-to-End de la interfaz web completa
#
# UTILIDAD:
#   Este target es ideal para validación completa antes de:
#   - Hacer un commit importante
#   - Merge a la rama principal
#   - Despliegue a producción
#   - Validación manual del pipeline completo
#
# SALIDA:
#   Muestra un resumen con:
#   - Rutas de los 3 reportes XML (formato JUnit)
#   - Rutas de los 3 archivos de log (salida completa)
#
# NOTA:
#   Si cualquier fase falla, Make continuará con las siguientes para
#   generar un reporte completo de todos los problemas encontrados.
# ==============================================================================
test-all: test-unit test-api test-e2e
	@echo "\n$(BLUE)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC) RESUMEN FINAL DE EJECUCIÓN"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════╝$(NC)\n"
	@echo "$(BLUE)Reportes XML:$(NC)"
	@echo "  - $(UNIT_REPORT)"
	@echo "  - $(API_REPORT)"
	@echo "  - $(E2E_REPORT)"
	@echo "\n$(BLUE)Logs de ejecución:$(NC)"
	@echo "  - $(UNIT_LOG)"
	@echo "  - $(API_LOG)"
	@echo "  - $(E2E_LOG)"

# ==============================================================================
# TARGET: docker-down
# ==============================================================================
# DESCRIPCIÓN:
#   Detiene y elimina todos los contenedores Docker relacionados con el proyecto.
#   Este target es llamado desde el Jenkinsfile en la fase de limpieza (cleanup).
#
# ACCIONES REALIZADAS:
#   1. docker compose down -v --remove-orphans:
#      - Detiene todos los servicios definidos en docker-compose.yml
#      - -v: Elimina los volúmenes asociados
#      - --remove-orphans: Elimina contenedores huérfanos (no definidos en el compose)
#   
#   2. docker compose rm -f -s -v:
#      - Fuerza la eliminación de contenedores específicos
#      - -f: Force (sin confirmación)
#      - -s: Stop antes de eliminar
#      - -v: Elimina volúmenes anónimos asociados
#
# USO:
#   - Limpieza después de ejecutar pruebas
#   - Liberación de recursos del sistema
#   - Reseteo del entorno antes de nueva ejecución
#   - Fase 'Post' del Jenkinsfile (siempre se ejecuta)
#
# NOTA:
#   El '|| true' evita que falle si no hay contenedores que eliminar.
# ==============================================================================
docker-down:
	@echo "$(YELLOW)→$(NC) Deteniendo todos los contenedores..."
	@docker compose down -v --remove-orphans || true
	@docker compose rm -f -s -v calc-api calc-web cypress-e2e 2>/dev/null || true
	@echo "$(GREEN)✓$(NC) Contenedores detenidos"

# ==============================================================================
# TARGET: clean
# ==============================================================================
# DESCRIPCIÓN:
#   Realiza una limpieza profunda del entorno Docker.
#   Más exhaustivo que docker-down, asegura que no queden recursos residuales.
#
# DEPENDENCIAS:
#   - docker-down: Primero ejecuta la limpieza básica
#
# ACCIONES ADICIONALES:
#   - Elimina todos los volúmenes Docker creados
#   - Limpia las redes Docker personalizadas
#   - Libera espacio en disco
#
# CUÁNDO USAR:
#   - Al finalizar completamente el trabajo con el proyecto
#   - Cuando se detectan problemas de red o volúmenes
#   - Antes de reconstruir completamente el entorno
#   - Para liberar recursos del sistema
#
# ADVERTENCIA:
#   Esta operación eliminará datos en volúmenes. Asegúrate de que no hay
#   información importante almacenada en contenedores antes de ejecutar.
# ==============================================================================
clean: docker-down
	@echo "$(YELLOW)→$(NC) Limpiando contenedores y redes..."
	@docker compose down -v
	@echo "$(GREEN)✓$(NC) Limpieza completada"