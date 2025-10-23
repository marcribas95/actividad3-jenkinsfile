# Makefile para el proyecto Calculator
# Facilita la ejecución de tests y builds usando Docker directo

.PHONY: all build test-unit test-api test-e2e test-all clean run server interactive

# Variables
IMAGE_NAME := calculator-app
RESULTS_DIR := tests-reports

build:
	@echo "🔨 Construyendo la imagen Docker..."
	docker build -t $(IMAGE_NAME):latest .
	@echo "✓ Build completado - Imagen $(IMAGE_NAME):latest construida"

run:
	docker run --rm --volume `pwd`:/opt/calc --env PYTHONPATH=/opt/calc -w /opt/calc $(IMAGE_NAME):latest python -B app/calc.py

server:
	docker run --rm --volume `pwd`:/opt/calc --name apiserver --env PYTHONPATH=/opt/calc --env FLASK_APP=app/api.py -p 5000:5000 -w /opt/calc $(IMAGE_NAME):latest flask run --host=0.0.0.0

interactive:
	docker run -ti --rm --volume `pwd`:/opt/calc --env PYTHONPATH=/opt/calc -w /opt/calc $(IMAGE_NAME):latest bash

test-unit:
	@echo "🧪 Ejecutando pruebas unitarias..."
	mkdir -p $(RESULTS_DIR)
	docker run --rm --volume `pwd`:/opt/calc --env PYTHONPATH=/opt/calc -w /opt/calc $(IMAGE_NAME):latest pytest /opt/calc/tests/unit/ --junit-xml=/opt/calc/$(RESULTS_DIR)/test-results-unit.xml -v || true
	@echo "✓ Pruebas unitarias completadas"

test-api:
	@echo "🌐 Ejecutando pruebas de API..."
	mkdir -p $(RESULTS_DIR)
	docker network create calc-test-api || true
	docker stop apiserver || true
	docker rm --force apiserver || true
	docker run -d --rm --volume `pwd`:/opt/calc --network calc-test-api --env PYTHONPATH=/opt/calc --name apiserver --env FLASK_APP=app/api.py -p 5000:5000 -w /opt/calc $(IMAGE_NAME):latest flask run --host=0.0.0.0
	@echo "Esperando que la API esté lista..."
	sleep 5
	docker run --rm --volume `pwd`:/opt/calc --network calc-test-api --env PYTHONPATH=/opt/calc --env BASE_URL=http://apiserver:5000/ -w /opt/calc $(IMAGE_NAME):latest pytest /opt/calc/tests/rest/ --junit-xml=/opt/calc/$(RESULTS_DIR)/test-results-api.xml -v || true
	docker stop apiserver || true
	docker rm --force apiserver || true
	docker network rm calc-test-api || true
	@echo "✓ Pruebas de API completadas"

test-e2e:
	@echo "🎭 Ejecutando pruebas E2E..."
	mkdir -p $(RESULTS_DIR)
	docker network create calc-test-e2e || true
	docker stop apiserver || true
	docker rm --force apiserver || true
	docker stop calc-web || true
	docker rm --force calc-web || true
	docker run -d --rm --volume `pwd`:/opt/calc --network calc-test-e2e --env PYTHONPATH=/opt/calc --name apiserver --env FLASK_APP=app/api.py -p 5000:5000 -w /opt/calc $(IMAGE_NAME):latest flask run --host=0.0.0.0
	docker run -d --rm --volume `pwd`/web:/usr/share/nginx/html --volume `pwd`/web/nginx.conf:/etc/nginx/conf.d/default.conf --network calc-test-e2e --name calc-web -p 8000:80 nginx:alpine
	@echo "Esperando servicios..."
	sleep 10
	docker run --rm --volume `pwd`/tests/e2e/cypress.json:/cypress.json --volume `pwd`/tests/e2e/cypress:/cypress --volume `pwd`/$(RESULTS_DIR):/results --network calc-test-e2e cypress/included:15.5.0 --browser chrome || true
	docker rm --force apiserver || true
	docker rm --force calc-web || true
	docker network rm calc-test-e2e || true
	@echo "✓ Pruebas E2E completadas"

test-all: test-unit test-api test-e2e
	@echo "🚀 ✓ Todas las pruebas completadas"

clean:
	@echo "🧹 Limpiando archivos generados..."
	rm -rf $(RESULTS_DIR)
	rm -rf .pytest_cache
	docker stop apiserver 2>/dev/null || true
	docker rm --force apiserver 2>/dev/null || true
	docker stop calc-web 2>/dev/null || true
	docker rm --force calc-web 2>/dev/null || true
	docker network rm calc-test-api 2>/dev/null || true
	docker network rm calc-test-e2e 2>/dev/null || true
	@echo "✓ Limpieza completada"
