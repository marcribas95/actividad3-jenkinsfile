# Makefile para proyecto de calculadora con tests automatizados
# Basado en run_tests.sh

# Variables de configuración
PYTHON := python3
VENV_DIR := .venv
VENV_PYTHON := $(VENV_DIR)/bin/python
PIP := $(VENV_DIR)/bin/pip
PYTEST := $(VENV_DIR)/bin/pytest
PROJECT_ROOT := $(shell pwd)
TEST_DIR := $(PROJECT_ROOT)/tests
REPORTS_DIR := $(PROJECT_ROOT)/tests-reports
TIMESTAMP := $(shell date +"%Y%m%d_%H%M%S")

# Archivos de reporte
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
NC := \033[0m # No Color

.PHONY: all help clean setup venv install test test-unit test-api test-e2e docker-up docker-down reports

# Target por defecto
all: setup test

# Muestra ayuda con los comandos disponibles
help:
	@echo "$(BLUE)Makefile para Sistema de Pruebas - Calculadora$(NC)"
	@echo ""
	@echo "Targets disponibles:"
	@echo "  $(YELLOW)make setup$(NC)          - Configura el entorno virtual e instala dependencias"
	@echo "  $(YELLOW)make test$(NC)           - Ejecuta todas las pruebas (unit, api, e2e)"
	@echo "  $(YELLOW)make test-unit$(NC)      - Ejecuta solo pruebas unitarias"
	@echo "  $(YELLOW)make test-api$(NC)       - Ejecuta solo pruebas de API"
	@echo "  $(YELLOW)make test-e2e$(NC)       - Ejecuta solo pruebas e2e con Docker"
	@echo "  $(YELLOW)make docker-up$(NC)      - Inicia servicios Docker"
	@echo "  $(YELLOW)make docker-down$(NC)    - Detiene servicios Docker"
	@echo "  $(YELLOW)make clean$(NC)          - Limpia archivos temporales y reportes"
	@echo "  $(YELLOW)make reports$(NC)        - Crea directorio de reportes"
	@echo ""

# Limpia archivos temporales, cache de Python y reportes antiguos
clean:
	@echo "$(YELLOW)→$(NC) Limpiando archivos temporales..."
	rm -rf $(VENV_DIR)
	rm -rf __pycache__
	rm -rf app/__pycache__
	rm -rf tests/__pycache__
	rm -rf .pytest_cache
	rm -rf cypress-results
	@echo "$(GREEN)✓$(NC) Limpieza completada"

# Crea el directorio de reportes
reports:
	@echo "$(YELLOW)→$(NC) Creando directorio de reportes..."
	mkdir -p $(REPORTS_DIR)
	@echo "$(GREEN)✓$(NC) Directorio creado: $(REPORTS_DIR)"

# Crea el entorno virtual de Python
venv:
	@echo "$(YELLOW)→$(NC) Creando entorno virtual..."
	$(PYTHON) -m venv $(VENV_DIR)
	@echo "$(GREEN)✓$(NC) Entorno virtual creado"

# Instala las dependencias del proyecto
install: venv
	@echo "$(YELLOW)→$(NC) Instalando dependencias..."
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt
	@echo "$(GREEN)✓$(NC) Dependencias instaladas"

# Setup completo del entorno
setup: venv install reports
	@echo "$(GREEN)✓$(NC) Setup completado exitosamente"

# Ejecuta pruebas unitarias
test-unit: reports
	@echo ""
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC) EJECUTANDO PRUEBAS UNITARIAS"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)→$(NC) Ejecutando pruebas unitarias de calc_test.py y util_test.py..."
	@$(VENV_PYTHON) -m pytest \
		$(TEST_DIR)/unit/calc_test.py \
		$(TEST_DIR)/unit/util_test.py \
		-v \
		--tb=short \
		--junit-xml=$(UNIT_REPORT) 2>&1 | tee $(UNIT_LOG) || true
	@echo "$(GREEN)✓$(NC) Pruebas unitarias completadas"

# Ejecuta pruebas de API REST
test-api: reports
	@echo ""
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC) EJECUTANDO PRUEBAS DE API"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)→$(NC) Ejecutando pruebas de API..."
	@$(VENV_PYTHON) -m pytest \
		$(TEST_DIR)/rest/api_test_local.py \
		-v \
		--tb=short \
		--junit-xml=$(API_REPORT) 2>&1 | tee $(API_LOG) || true
	@echo "$(GREEN)✓$(NC) Pruebas de API completadas"

# Inicia servicios Docker necesarios
docker-up:
	@echo "$(YELLOW)→$(NC) Iniciando servicios Docker..."
	docker compose up -d calc-api calc-web
	@echo "$(GREEN)✓$(NC) Servicios iniciados"
	@echo "$(YELLOW)→$(NC) Esperando 10 segundos para inicialización..."
	@sleep 10
	@echo "$(GREEN)✓$(NC) Servicios listos"

# Detiene servicios Docker
docker-down:
	@echo "$(YELLOW)→$(NC) Deteniendo servicios Docker..."
	docker compose stop calc-api calc-web cypress-e2e || true
	docker compose rm -f calc-api calc-web cypress-e2e || true
	@echo "$(GREEN)✓$(NC) Servicios detenidos"

# Ejecuta pruebas e2e con Cypress
test-e2e: reports docker-up
	@echo ""
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC) EJECUTANDO PRUEBAS E2E (End-to-End)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)→$(NC) Ejecutando pruebas e2e con Cypress..."
	@mkdir -p $(PROJECT_ROOT)/cypress-results
	@docker compose run --rm \
		-v "$(PROJECT_ROOT)/cypress-results:/results" \
		cypress-e2e 2>&1 | tee $(E2E_LOG) || true
	@if [ -f "$(PROJECT_ROOT)/cypress-results/cypress_result.xml" ]; then \
		cp $(PROJECT_ROOT)/cypress-results/cypress_result.xml $(E2E_REPORT); \
		echo "$(GREEN)✓$(NC) Reporte e2e copiado a: $(E2E_REPORT)"; \
	else \
		echo "$(RED)✗$(NC) No se encontró el reporte XML de Cypress"; \
	fi
	@rm -rf $(PROJECT_ROOT)/cypress-results
	@$(MAKE) docker-down
	@echo "$(GREEN)✓$(NC) Pruebas e2e completadas"

# Ejecuta todas las pruebas
test: test-unit test-api test-e2e
	@echo ""
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC) RESUMEN FINAL DE EJECUCIÓN"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(BLUE)Archivos generados:$(NC)"
	@echo "  Reportes XML:"
	@echo "    - $(UNIT_REPORT)"
	@echo "    - $(API_REPORT)"
	@echo "    - $(E2E_REPORT)"
	@echo ""
	@echo "  Logs de ejecución:"
	@echo "    - $(UNIT_LOG)"
	@echo "    - $(API_LOG)"
	@echo "    - $(E2E_LOG)"
	@echo ""
	@echo "$(GREEN)✓ TODAS LAS PRUEBAS COMPLETADAS$(NC)"
