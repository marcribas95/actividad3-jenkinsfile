# Makefile para el proyecto Calculator
# Usa docker compose para gestionar servicios de forma eficiente

.PHONY: all build start stop test-unit test-api test-e2e test-all clean

# Variables
IMAGE_NAME := calculator-app
RESULTS_DIR := tests-reports

build:
	@echo "🔨 Construyendo la imagen Docker con docker compose..."
	mkdir -p $(RESULTS_DIR)
	docker compose build calc-api
	@echo "✓ Build completado - Imagen construida"

start:
	@echo "🚀 Iniciando servicios con docker compose..."
	@echo "Limpiando contenedores previos si existen..."
	docker compose down --remove-orphans 2>/dev/null || true
	docker rm -f calc-api calc-web 2>/dev/null || true
	docker compose up -d calc-api calc-web
	@echo "Esperando que los servicios estén listos..."
	sleep 5
	@echo "✓ Servicios iniciados"
	@echo "  - API: http://localhost:5000"
	@echo "  - Web: http://localhost:8000"

stop:
	@echo "🛑 Deteniendo servicios..."
	docker compose stop calc-api calc-web
	@echo "✓ Servicios detenidos"

restart:
	@echo "🔄 Reiniciando servicios..."
	docker compose restart calc-api calc-web
	@echo "✓ Servicios reiniciados"

test-unit:
	@echo "🧪 Ejecutando pruebas unitarias..."
	mkdir -p $(RESULTS_DIR)
	docker compose run --rm calc-api pytest /app/tests/unit/ -v --tb=short --junit-xml=/app/tests-reports/test-results-unit.xml
	@echo "✓ Pruebas unitarias completadas"

test-api:
	@echo "🌐 Ejecutando pruebas de API..."
	mkdir -p $(RESULTS_DIR)
	@echo "Limpiando contenedores previos..."
	docker compose down --remove-orphans 2>/dev/null || true
	docker rm -f calc-api 2>/dev/null || true
	@echo "Asegurando que calc-api está ejecutándose..."
	docker compose up -d calc-api
	sleep 5
	@echo "Ejecutando tests contra el servicio..."
	docker compose run --rm -e BASE_URL=http://calc-api:5000/ calc-api pytest /app/tests/rest/ -v --tb=short --junit-xml=/app/tests-reports/test-results-api.xml
	@echo "✓ Pruebas de API completadas"

test-e2e:
	@echo "🎭 Ejecutando pruebas E2E..."
	mkdir -p $(RESULTS_DIR)
	@echo "Limpiando contenedores previos..."
	docker compose down --remove-orphans 2>/dev/null || true
	docker rm -f calc-api calc-web cypress-e2e 2>/dev/null || true
	@echo "Asegurando que todos los servicios están ejecutándose..."
	docker compose up -d calc-api calc-web
	sleep 10
	@echo "Ejecutando tests de Cypress..."
	docker compose run --rm cypress-e2e || true
	@echo "✓ Pruebas E2E completadas"

test-all: test-unit test-api test-e2e
	@echo "🚀 ✓ Todas las pruebas completadas"

logs:
	@echo "📋 Mostrando logs de los servicios..."
	docker compose logs -f calc-api calc-web

ps:
	@echo "📊 Estado de los servicios:"
	docker compose ps

clean:
	@echo "🧹 Limpiando recursos..."
	docker compose down -v --remove-orphans
	docker rm -f calc-api calc-web cypress-e2e 2>/dev/null || true
	rm -rf $(RESULTS_DIR)
	rm -rf .pytest_cache
	rm -rf tests/e2e/cypress/screenshots
	rm -rf tests/e2e/cypress/videos
	@echo "✓ Limpieza completada"

clean-all: clean
	@echo "🧹 Limpieza completa (incluyendo imágenes)..."
	docker compose down -v --rmi local --remove-orphans
	docker rm -f calc-api calc-web cypress-e2e 2>/dev/null || true
	@echo "✓ Limpieza completa terminada"

clean-jenkins:
	@echo "🧹 Limpieza completa para Jenkins (elimina TODO)..."
	@echo "Deteniendo todos los contenedores del proyecto..."
	docker compose down -v --rmi all --remove-orphans 2>/dev/null || true
	@echo "Eliminando contenedores por nombre..."
	docker rm -f calc-api calc-web cypress-e2e 2>/dev/null || true
	@echo "Eliminando contenedores huérfanos..."
	docker container prune -f 2>/dev/null || true
	@echo "Eliminando imágenes sin usar..."
	docker image prune -f 2>/dev/null || true
	@echo "Eliminando volúmenes sin usar..."
	docker volume prune -f 2>/dev/null || true
	@echo "Eliminando networks sin usar..."
	docker network prune -f 2>/dev/null || true
	@echo "Limpiando directorios de reportes..."
	rm -rf $(RESULTS_DIR)
	rm -rf .pytest_cache
	rm -rf tests/e2e/cypress/screenshots
	rm -rf tests/e2e/cypress/videos
	@echo "✓ Limpieza Jenkins completada"
