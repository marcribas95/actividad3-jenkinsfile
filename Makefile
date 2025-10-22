# Makefile para el proyecto Calculator
# Facilita la ejecución de tests y builds

.PHONY: help build test-unit test-api test-e2e test-all clean

# Variables
PYTHON := .venv/bin/python
PYTEST := .venv/bin/pytest
REPORTS_DIR := tests-reports

help:
	@echo "Comandos disponibles:"
	@echo "  make build       - Construir el entorno y las imágenes Docker"
	@echo "  make test-unit   - Ejecutar pruebas unitarias"
	@echo "  make test-api    - Ejecutar pruebas de API"
	@echo "  make test-e2e    - Ejecutar pruebas End-to-End"
	@echo "  make test-all    - Ejecutar todas las pruebas"
	@echo "  make clean       - Limpiar archivos generados"

build:
	@echo "🔨 Construyendo el proyecto..."
	python3 -m venv .venv
	. .venv/bin/activate && pip install --upgrade pip
	. .venv/bin/activate && pip install -r requirements.txt
	docker compose build calc-api
	@echo "✓ Build completado"

test-unit:
	@echo "🧪 Ejecutando pruebas unitarias..."
	mkdir -p $(REPORTS_DIR)
	$(PYTEST) tests/unit/calc_test.py tests/unit/util_test.py \
		-v \
		--tb=short \
		--junit-xml=$(REPORTS_DIR)/test-results-unit.xml
	@echo "✓ Pruebas unitarias completadas"

test-api:
	@echo "🌐 Ejecutando pruebas de API..."
	mkdir -p $(REPORTS_DIR)
	$(PYTEST) tests/rest/api_test_local.py \
		-v \
		--tb=short \
		--junit-xml=$(REPORTS_DIR)/test-results-api.xml
	@echo "✓ Pruebas de API completadas"

test-e2e:
	@echo "🎭 Ejecutando pruebas E2E..."
	mkdir -p $(REPORTS_DIR)
	mkdir -p cypress-results
	docker compose up -d calc-api calc-web
	@echo "Esperando servicios..."
	sleep 10
	docker compose run --rm -v $$(pwd)/cypress-results:/results cypress-e2e || true
	[ -f cypress-results/cypress_result.xml ] && cp cypress-results/cypress_result.xml $(REPORTS_DIR)/test-results-e2e.xml || true
	docker compose stop calc-api calc-web
	docker compose rm -f calc-api calc-web
	rm -rf cypress-results
	@echo "✓ Pruebas E2E completadas"

test-all:
	@echo "🚀 Ejecutando todas las pruebas..."
	./run_tests.sh

clean:
	@echo "🧹 Limpiando archivos generados..."
	rm -rf $(REPORTS_DIR)
	rm -rf .venv
	rm -rf .pytest_cache
	rm -rf cypress-results
	rm -rf tests/e2e/cypress/screenshots
	rm -rf tests/e2e/cypress/videos
	docker compose down -v 2>/dev/null || true
	@echo "✓ Limpieza completada"
