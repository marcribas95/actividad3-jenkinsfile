.PHONY: all build test-unit test-api test-e2e test-all clean setup-dirs setup docker-down

# Variables
TIMESTAMP := $(shell date +"%Y%m%d_%H%M%S")
REPORTS_DIR := tests-reports
UNIT_REPORT := $(REPORTS_DIR)/test-results-unit-$(TIMESTAMP).xml
API_REPORT := $(REPORTS_DIR)/test-results-api-$(TIMESTAMP).xml
E2E_REPORT := $(REPORTS_DIR)/test-results-e2e-$(TIMESTAMP).xml
UNIT_LOG := $(REPORTS_DIR)/unit-output-$(TIMESTAMP).log
API_LOG := $(REPORTS_DIR)/api-output-$(TIMESTAMP).log
E2E_LOG := $(REPORTS_DIR)/e2e-output-$(TIMESTAMP).log

# Colores para output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m

# Crear directorios necesarios
setup-dirs:
	@echo "$(BLUE)→$(NC) Configurando directorios..."
	@mkdir -p $(REPORTS_DIR)
	@echo "$(GREEN)✓$(NC) Directorio de reportes creado"

# Configurar entorno (requerido por Jenkinsfile)
setup: setup-dirs build
	@echo "$(BLUE)→$(NC) Configurando entorno completo..."
	@echo "$(GREEN)✓$(NC) Entorno configurado exitosamente"

# Construir imagen Docker
build:
	@echo "$(BLUE)→$(NC) Construyendo imagen Docker..."
	@docker compose build calc-api
	@echo "$(GREEN)✓$(NC) Imagen construida exitosamente"

# Ejecutar pruebas unitarias
test-unit: setup-dirs
	@echo "\n$(BLUE)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC) EJECUTANDO PRUEBAS UNITARIAS"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════╝$(NC)\n"
	@echo "$(YELLOW)→$(NC) Ejecutando pruebas unitarias de calc_test.py y util_test.py..."
	@docker compose run --rm -v "$(PWD)":/app calc-api pytest \
		tests/unit \
		-v \
		--tb=short \
		--junit-xml=$(UNIT_REPORT) 2>&1 | tee $(UNIT_LOG) || true
	@if [ -f $(UNIT_REPORT) ]; then \
		echo "$(GREEN)✓$(NC) Pruebas unitarias completadas"; \
		echo "$(BLUE)ℹ$(NC) Reporte: $(UNIT_REPORT)"; \
	else \
		echo "$(RED)✗$(NC) Error al generar reporte"; \
	fi

# Ejecutar pruebas de API REST
test-api: setup-dirs
	@echo "\n$(BLUE)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC) EJECUTANDO PRUEBAS DE API"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════╝$(NC)\n"
	@echo "$(YELLOW)→$(NC) Ejecutando pruebas de API..."
	@docker compose run --rm -v "$(PWD)":/app calc-api pytest \
		tests/rest/*_test*.py \
		-v \
		--tb=short \
		--junit-xml=$(API_REPORT) 2>&1 | tee $(API_LOG) || true
	@if [ -f $(API_REPORT) ]; then \
		echo "$(GREEN)✓$(NC) Pruebas de API completadas"; \
		echo "$(BLUE)ℹ$(NC) Reporte: $(API_REPORT)"; \
	else \
		echo "$(RED)✗$(NC) Error al generar reporte"; \
	fi

# Ejecutar pruebas e2e (End-to-End)
test-e2e: setup-dirs
	@echo "\n$(BLUE)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC) EJECUTANDO PRUEBAS E2E (End-to-End)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════╝$(NC)\n"
	@echo "$(YELLOW)→$(NC) Iniciando servicios necesarios con docker-compose..."
	@docker compose up -d calc-api calc-web
	@echo "$(GREEN)✓$(NC) Servicios iniciados correctamente"
	@echo "$(YELLOW)→$(NC) Esperando 10 segundos para que los servicios se inicialicen..."
	@sleep 10
	@echo "$(YELLOW)→$(NC) Ejecutando pruebas e2e con Cypress..."
	@docker compose run --rm cypress-e2e 2>&1 | tee $(E2E_LOG) || true
	@echo "$(YELLOW)→$(NC) Deteniendo servicios de docker-compose..."
	@docker compose stop calc-api calc-web
	@docker compose rm -f calc-api calc-web cypress-e2e
	@if [ -f tests/e2e/results/cypress_result.xml ]; then \
		cp tests/e2e/results/cypress_result.xml $(E2E_REPORT); \
		echo "$(GREEN)✓$(NC) Reporte e2e copiado a: $(E2E_REPORT)"; \
	else \
		echo "$(RED)✗$(NC) No se encontró el reporte XML de Cypress"; \
	fi

# Ejecutar todas las pruebas
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

# Detener y limpiar todos los contenedores (requerido por Jenkinsfile)
docker-down:
	@echo "$(YELLOW)→$(NC) Deteniendo todos los contenedores..."
	@docker compose down -v || true
	@echo "$(GREEN)✓$(NC) Contenedores detenidos"

# Limpiar contenedores y redes
clean: docker-down
	@echo "$(YELLOW)→$(NC) Limpiando contenedores y redes..."
	@docker compose down -v
	@echo "$(GREEN)✓$(NC) Limpieza completada"