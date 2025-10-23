#!/bin/bash

################################################################################
# Script de Automatización de Tests para Jenkins
# Ejecuta pruebas unitarias y de API, genera reportes XML y logs
# Optimizado para Jenkins CI/CD Pipeline
################################################################################

# Detener ejecución si hay errores
set -e

# Códigos de color para output en consola
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color (reset)

# Configuración de rutas del proyecto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
VENV_PATH="${PROJECT_ROOT}/.venv/bin/python"  # Python del entorno virtual
TEST_DIR="${PROJECT_ROOT}/tests"              # Directorio de tests
REPORTS_DIR="${PROJECT_ROOT}/tests-reports"   # Directorio de reportes
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")            # Timestamp para nombrar archivos

# Rutas de archivos de salida (XML para Jenkins, logs para debugging)
UNIT_REPORT="${REPORTS_DIR}/test-results-unit-${TIMESTAMP}.xml"
API_REPORT="${REPORTS_DIR}/test-results-api-${TIMESTAMP}.xml"
E2E_REPORT="${REPORTS_DIR}/test-results-e2e-${TIMESTAMP}.xml"
UNIT_LOG="${REPORTS_DIR}/unit-output-${TIMESTAMP}.log"
API_LOG="${REPORTS_DIR}/api-output-${TIMESTAMP}.log"
E2E_LOG="${REPORTS_DIR}/e2e-output-${TIMESTAMP}.log"

# Contadores para estadísticas finales
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
EXIT_CODE=0

################################################################################
# Funciones de Output Formateado
################################################################################

# Imprime un encabezado visual para secciones
print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

# Imprime un paso del proceso con flecha amarilla
print_step() {
    echo -e "${YELLOW}→${NC} $1"
}

# Imprime un mensaje de éxito con check verde
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Imprime un mensaje de error con X roja
print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Imprime un mensaje informativo con ℹ azul
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

################################################################################
# Funciones de Validación y Setup
################################################################################

# Verifica que existan el entorno virtual y pytest
check_prerequisites() {
    print_step "Verificando requisitos previos..."
    
    # Verificar que existe el ejecutable de Python en el venv
    if [ ! -f "$VENV_PATH" ]; then
        print_error "Entorno virtual no encontrado en: $VENV_PATH"
        exit 1
    fi
    
    print_success "Entorno virtual encontrado"
    
    # Verificar que pytest está instalado en el entorno virtual
    if ! "$VENV_PATH" -m pytest --version &>/dev/null; then
        print_error "pytest no está instalado"
        exit 1
    fi
    
    print_success "pytest está disponible"
}

# Crea el directorio para guardar reportes si no existe
setup_directories() {
    print_step "Configurando directorios..."
    
    mkdir -p "$REPORTS_DIR"
    print_success "Directorio de reportes creado: $REPORTS_DIR"
}

################################################################################
# Funciones de Ejecución de Tests
################################################################################

# Ejecuta las pruebas unitarias (calc y util)
run_unit_tests() {
    print_header "EJECUTANDO PRUEBAS UNITARIAS"
    
    print_step "Ejecutando pruebas unitarias de calc_test.py y util_test.py..."
    
    # Ejecuta pytest con:
    # -v: modo verbose
    # --tb=short: traceback corto en errores
    # --junit-xml: genera reporte XML para Jenkins
    # tee: guarda output en log Y lo muestra en pantalla
    if "$VENV_PATH" -m pytest \
        "${TEST_DIR}/unit/calc_test.py" \
        "${TEST_DIR}/unit/util_test.py" \
        -v \
        --tb=short \
        --junit-xml="$UNIT_REPORT" 2>&1 | tee "$UNIT_LOG"
    then
        print_success "Pruebas unitarias completadas exitosamente"
        return 0
    else
        print_error "Algunas pruebas unitarias fallaron"
        return 1
    fi
}

# Ejecuta las pruebas de API REST
run_api_tests() {
    print_header "EJECUTANDO PRUEBAS DE API"
    
    print_step "Ejecutando pruebas de API..."
    
    # Similar a unit tests pero para API REST
    if "$VENV_PATH" -m pytest \
        "${TEST_DIR}/rest/api_test_local.py" \
        -v \
        --tb=short \
        --junit-xml="$API_REPORT" 2>&1 | tee "$API_LOG"
    then
        print_success "Pruebas de API completadas exitosamente"
        return 0
    else
        print_error "Algunas pruebas de API fallaron"
        return 1
    fi
}

# Ejecuta las pruebas e2e con Cypress
run_e2e_tests() {
    print_header "EJECUTANDO PRUEBAS E2E (End-to-End)"
    
    print_step "Verificando si Docker está disponible..."
    
    # Verificar que Docker esté instalado y funcionando
    if ! command -v docker &> /dev/null; then
        print_error "Docker no está instalado o no está disponible"
        return 1
    fi
    
    print_success "Docker está disponible"
    
    print_step "Verificando si docker-compose está disponible..."
    
    # Verificar que docker-compose esté instalado
    if ! command -v docker compose &> /dev/null; then
        print_error "docker compose no está instalado o no está disponible"
        return 1
    fi
    
    print_success "docker compose está disponible"
    
    print_step "Iniciando servicios necesarios con docker-compose..."
    
    # Levantar los servicios necesarios (API y web)
    cd "$PROJECT_ROOT"
    if ! docker compose up -d calc-api calc-web 2>&1 | tee -a "$E2E_LOG"; then
        print_error "Error al iniciar servicios con docker-compose"
        return 1
    fi
    
    print_success "Servicios iniciados correctamente"
    
    # Esperar unos segundos para que los servicios estén listos
    print_step "Esperando 10 segundos para que los servicios se inicialicen..."
    sleep 10
    
    print_step "Ejecutando pruebas e2e con Cypress..."
    
    # Ejecutar Cypress en modo headless
    # Crear directorio temporal para resultados de Cypress
    E2E_RESULTS_DIR="${PROJECT_ROOT}/cypress-results"
    mkdir -p "$E2E_RESULTS_DIR"
    
    # Ejecutar Cypress con Docker
    if docker compose run --rm \
        -v "${E2E_RESULTS_DIR}:/results" \
        cypress-e2e 2>&1 | tee -a "$E2E_LOG"
    then
        print_success "Pruebas e2e completadas exitosamente"
        E2E_STATUS=0
    else
        print_error "Algunas pruebas e2e fallaron"
        E2E_STATUS=1
    fi
    
    # Copiar el reporte XML generado por Cypress al directorio de reportes
    if [ -f "${E2E_RESULTS_DIR}/cypress_result.xml" ]; then
        cp "${E2E_RESULTS_DIR}/cypress_result.xml" "$E2E_REPORT"
        print_success "Reporte e2e copiado a: $E2E_REPORT"
    else
        print_error "No se encontró el reporte XML de Cypress"
    fi
    
    print_step "Deteniendo servicios de docker-compose..."
    docker compose stop calc-api calc-web cypress-e2e 2>&1 | tee -a "$E2E_LOG"
    docker compose rm -f calc-api calc-web cypress-e2e 2>&1 | tee -a "$E2E_LOG"
    
    # Limpiar directorio temporal
    rm -rf "$E2E_RESULTS_DIR"
    
    return $E2E_STATUS
}

################################################################################
# Funciones de Análisis de Resultados
################################################################################

# Parsea un archivo XML de JUnit y extrae estadísticas
parse_xml_report() {
    local xml_file=$1
    local report_type=$2
    
    if [ ! -f "$xml_file" ]; then
        print_error "Archivo de reporte no encontrado: $xml_file"
        return 1
    fi
    
    # Extraer valores de atributos del XML usando grep con regex
    local tests=$(grep -oP 'tests="\K[^"]+' "$xml_file" | head -1)
    local failures=$(grep -oP 'failures="\K[^"]+' "$xml_file" | head -1)
    local errors=$(grep -oP 'errors="\K[^"]+' "$xml_file" | head -1)
    local skipped=$(grep -oP 'skipped="\K[^"]+' "$xml_file" | head -1)
    
    # Asignar 0 si no se encontró valor
    tests=${tests:-0}
    failures=${failures:-0}
    errors=${errors:-0}
    skipped=${skipped:-0}
    
    # Calcular pruebas exitosas
    local passed=$((tests - failures - errors - skipped))
    
    # Mostrar resumen
    echo "$report_type"
    echo "  Total:    $tests"
    echo "  Pasadas:  $passed"
    echo "  Fallos:   $failures"
    echo "  Errores:  $errors"
    echo "  Omitidas: $skipped"
    
    # Actualizar contadores globales
    TOTAL_TESTS=$((TOTAL_TESTS + tests))
    PASSED_TESTS=$((PASSED_TESTS + passed))
    FAILED_TESTS=$((FAILED_TESTS + failures + errors))
    
    # Retornar error si hay fallos
    if [ "$failures" -gt 0 ] || [ "$errors" -gt 0 ]; then
        return 1
    fi
    return 0
}

################################################################################
# Función Principal
################################################################################

main() {
    clear
    print_header "SISTEMA AUTOMATIZADO DE PRUEBAS - CALCULADORA"
    
    # Paso 1: Verificar que todo esté listo para ejecutar
    check_prerequisites
    
    # Paso 2: Crear directorios necesarios
    setup_directories
    
    # Inicializar flags de estado
    UNIT_FAILED=0
    API_FAILED=0
    E2E_FAILED=0
    
    # Paso 3: Ejecutar todos los tipos de pruebas (continúa aunque falle uno)
    run_unit_tests || UNIT_FAILED=1
    run_api_tests || API_FAILED=1
    run_e2e_tests || E2E_FAILED=1
    
    # Paso 4: Analizar resultados de los XML generados
    print_header "ANÁLISIS DE RESULTADOS"
    
    if [ -f "$UNIT_REPORT" ]; then
        print_info "Analizando resultados de pruebas unitarias..."
        parse_xml_report "$UNIT_REPORT" "PRUEBAS UNITARIAS" || true
        echo ""
    fi
    
    if [ -f "$API_REPORT" ]; then
        print_info "Analizando resultados de pruebas de API..."
        parse_xml_report "$API_REPORT" "PRUEBAS DE API" || true
        echo ""
    fi
    
    if [ -f "$E2E_REPORT" ]; then
        print_info "Analizando resultados de pruebas e2e..."
        parse_xml_report "$E2E_REPORT" "PRUEBAS E2E" || true
        echo ""
    fi
    
    # Paso 5: Mostrar resumen final
    print_header "RESUMEN FINAL DE EJECUCIÓN"
    
    echo -e "Total de Pruebas:    ${YELLOW}$TOTAL_TESTS${NC}"
    echo -e "Pruebas Exitosas:    ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Pruebas Fallidas:    ${RED}$FAILED_TESTS${NC}"
    
    # Determinar exit code según resultados
    if [ "$UNIT_FAILED" -eq 0 ] && [ "$API_FAILED" -eq 0 ] && [ "$E2E_FAILED" -eq 0 ]; then
        echo -e "\n${GREEN}✓ TODAS LAS PRUEBAS COMPLETADAS EXITOSAMENTE${NC}"
        EXIT_CODE=0
    else
        echo -e "\n${RED}✗ ALGUNAS PRUEBAS FALLARON${NC}"
        EXIT_CODE=1
    fi
    
    # Paso 6: Listar archivos generados
    print_header "ARCHIVOS GENERADOS"
    echo -e "${BLUE}Reportes XML:${NC}"
    echo "  - $UNIT_REPORT"
    echo "  - $API_REPORT"
    echo "  - $E2E_REPORT"
    echo -e "\n${BLUE}Logs de ejecución:${NC}"
    echo "  - $UNIT_LOG"
    echo "  - $API_LOG"
    echo "  - $E2E_LOG"
    echo ""
    
    # Salir con código apropiado (0=éxito, 1=falló)
    exit $EXIT_CODE
}

# Ejecutar función principal
main