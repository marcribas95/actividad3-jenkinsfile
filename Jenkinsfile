pipeline {
    agent {
        label 'docker'
    }
    
    environment {
        // Variables de entorno para el proyecto
        PROJECT_NAME = 'Calculator CI/CD Pipeline'
        REPORTS_DIR = 'tests-reports'
    }
    
    stages {
        stage('Source') {
            steps {
                echo '📥 Verificando código fuente...'
                script {
                    // Intenta clonar el repositorio, pero continúa si falla
                    // (útil cuando se ejecuta desde SCM)
                    try {
                        git branch: 'main',
                            url: 'https://github.com/marcribas95/actividad3-jenkinsfile.git'
                    } catch (Exception e) {
                        echo "⚠️ No se pudo clonar el repositorio: ${e.message}"
                        echo "Continuando con el código ya presente en el workspace..."
                    }
                }
                
                // Verificar que los archivos necesarios existen
                sh '''
                    echo "Verificando estructura del proyecto..."
                    ls -la
                    
                    if [ -f "requirements.txt" ]; then
                        echo "✓ requirements.txt encontrado"
                    else
                        echo "✗ requirements.txt no encontrado"
                        exit 1
                    fi
                    
                    if [ -d "app" ]; then
                        echo "✓ Directorio app/ encontrado"
                    else
                        echo "✗ Directorio app/ no encontrado"
                        exit 1
                    fi
                    
                    if [ -d "tests" ]; then
                        echo "✓ Directorio tests/ encontrado"
                    else
                        echo "✗ Directorio tests/ no encontrado"
                        exit 1
                    fi
                '''
            }
        }
        
        stage('Build') {
            steps {
                echo '🔨 Construyendo la aplicación...'
                sh '''
                    echo "Construyendo imágenes Docker..."
                    docker compose build calc-api
                    
                    echo "Verificando imagen construida..."
                    docker images | grep calc-api || echo "Imagen calc-api creada"
                '''
            }
        }
        
        stage('Unit Tests') {
            steps {
                echo '🧪 Ejecutando pruebas unitarias...'
                sh '''
                    # Crear directorio de reportes si no existe
                    mkdir -p ${REPORTS_DIR}
                    
                    # Ejecutar pruebas unitarias dentro del contenedor Docker
                    docker compose run --rm calc-api \
                        python -m pytest /app/tests/unit/calc_test.py /app/tests/unit/util_test.py \
                        -v \
                        --tb=short \
                        --junit-xml=/app/tests-reports/test-results-unit.xml \
                        || true
                    
                    # Verificar si se generó el reporte
                    if [ -f ${REPORTS_DIR}/test-results-unit.xml ]; then
                        echo "✓ Reporte de pruebas unitarias generado"
                    else
                        echo "⚠ No se generó el reporte de pruebas unitarias"
                    fi
                '''
                
                // Archivar resultados de pruebas unitarias
                archiveArtifacts artifacts: "${REPORTS_DIR}/test-results-unit.xml",
                                 allowEmptyArchive: true,
                                 fingerprint: true
            }
        }
        
        stage('API Tests') {
            steps {
                echo '🌐 Ejecutando pruebas de API...'
                sh '''
                    # Iniciar el servicio de API
                    echo "Iniciando servicio calc-api..."
                    docker compose up -d calc-api
                    
                    # Esperar a que la API esté lista
                    echo "Esperando 5 segundos para que la API se inicialice..."
                    sleep 5
                    
                    # Ejecutar pruebas de API dentro del contenedor
                    docker compose run --rm calc-api \
                        python -m pytest /app/tests/rest/api_test_local.py \
                        -v \
                        --tb=short \
                        --junit-xml=/app/tests-reports/test-results-api.xml \
                        || true
                    
                    # Detener servicio
                    echo "Deteniendo servicio calc-api..."
                    docker compose stop calc-api
                    docker compose rm -f calc-api
                    
                    # Verificar si se generó el reporte
                    if [ -f ${REPORTS_DIR}/test-results-api.xml ]; then
                        echo "✓ Reporte de pruebas de API generado"
                    else
                        echo "⚠ No se generó el reporte de pruebas de API"
                    fi
                '''
                
                // Archivar resultados de pruebas de API
                archiveArtifacts artifacts: "${REPORTS_DIR}/test-results-api.xml",
                                 allowEmptyArchive: true,
                                 fingerprint: true
            }
        }
        
        stage('E2E Tests') {
            steps {
                echo '🎭 Ejecutando pruebas End-to-End con Cypress...'
                sh '''
                    # Crear directorio para resultados de Cypress
                    mkdir -p ${REPORTS_DIR}
                    mkdir -p cypress-results
                    
                    # Iniciar servicios necesarios para E2E
                    echo "Iniciando servicios calc-api y calc-web..."
                    docker compose up -d calc-api calc-web
                    
                    # Esperar a que los servicios estén listos
                    echo "Esperando 10 segundos para que los servicios se inicialicen..."
                    sleep 10
                    
                    # Ejecutar pruebas E2E con Cypress
                    echo "Ejecutando Cypress..."
                    docker compose run --rm \
                        -v $(pwd)/cypress-results:/results \
                        cypress-e2e || true
                    
                    # Copiar resultados si existen
                    if [ -f cypress-results/cypress_result.xml ]; then
                        cp cypress-results/cypress_result.xml ${REPORTS_DIR}/test-results-e2e.xml
                        echo "✓ Reporte E2E copiado exitosamente"
                    else
                        echo "⚠ No se encontró el reporte XML de Cypress"
                    fi
                    
                    # Detener servicios
                    echo "Deteniendo servicios..."
                    docker compose stop calc-api calc-web
                    docker compose rm -f calc-api calc-web
                    
                    # Limpiar
                    rm -rf cypress-results
                '''
                
                // Archivar resultados de pruebas E2E
                archiveArtifacts artifacts: "${REPORTS_DIR}/test-results-e2e.xml",
                                 allowEmptyArchive: true,
                                 fingerprint: true
                
                // Archivar screenshots de Cypress si existen
                archiveArtifacts artifacts: 'tests/e2e/cypress/screenshots/**/*.png',
                                 allowEmptyArchive: true,
                                 fingerprint: true
            }
        }
        
        stage('Report') {
            steps {
                echo '📊 Generando informes de pruebas...'
                script {
                    // Mostrar resumen de pruebas
                    sh '''
                        echo "==================================="
                        echo "  RESUMEN DE PRUEBAS"
                        echo "==================================="
                        
                        if [ -f ${REPORTS_DIR}/test-results-unit.xml ]; then
                            echo "✓ Pruebas Unitarias: Completadas"
                        fi
                        
                        if [ -f ${REPORTS_DIR}/test-results-api.xml ]; then
                            echo "✓ Pruebas de API: Completadas"
                        fi
                        
                        if [ -f ${REPORTS_DIR}/test-results-e2e.xml ]; then
                            echo "✓ Pruebas E2E: Completadas"
                        fi
                        
                        echo "==================================="
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo '📋 Publicando resultados de pruebas...'
            
            // Publicar resultados de todas las pruebas en formato JUnit
            junit testResults: "${REPORTS_DIR}/*.xml",
                  allowEmptyResults: true,
                  skipPublishingChecks: false
            
            echo '🧹 Limpiando workspace...'
            // Usar deleteDir() en lugar de cleanWs() si el plugin no está disponible
            script {
                try {
                    cleanWs()
                } catch (Exception e) {
                    echo "cleanWs() no disponible, usando deleteDir()"
                    deleteDir()
                }
            }
        }
        
        success {
            echo '✅ Pipeline ejecutado exitosamente!'
        }
        
        failure {
            echo '❌ Pipeline falló. Enviando notificación por correo...'
            
            script {
                // Preparar el cuerpo del correo
                def emailBody = """
                    <h2>Pipeline Fallido</h2>
                    <p><strong>Proyecto:</strong> ${env.JOB_NAME}</p>
                    <p><strong>Número de Ejecución:</strong> ${env.BUILD_NUMBER}</p>
                    <p><strong>Estado:</strong> <span style="color: red;">FALLIDO</span></p>
                    <p><strong>URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    <hr>
                    <p>Por favor, revisa los logs para más detalles.</p>
                """
                
                // Mostrar el contenido del correo en los logs (para verificación)
                echo "==================================="
                echo "CONTENIDO DEL CORREO:"
                echo "==================================="
                echo "Para: devops-team@example.com"
                echo "Asunto: [FALLO] Pipeline ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}"
                echo "Cuerpo:"
                echo "Proyecto: ${env.JOB_NAME}"
                echo "Número de Ejecución: ${env.BUILD_NUMBER}"
                echo "Estado: FALLIDO"
                echo "URL: ${env.BUILD_URL}"
                echo "==================================="
                
                // Enviar correo (comentado para no requerir configuración SMTP)
                // Descomentar cuando Jenkins esté configurado para enviar correos
                /*
                emailext (
                    subject: "[FALLO] Pipeline ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                    body: emailBody,
                    mimeType: 'text/html',
                    to: 'devops-team@example.com',
                    from: 'jenkins@example.com',
                    replyTo: 'jenkins@example.com',
                    attachLog: true
                )
                */
            }
        }
        
        unstable {
            echo '⚠️  Pipeline inestable - Algunas pruebas fallaron'
            
            script {
                // También enviar correo en caso de inestabilidad
                echo "==================================="
                echo "NOTIFICACIÓN: Pipeline Inestable"
                echo "Proyecto: ${env.JOB_NAME}"
                echo "Build: #${env.BUILD_NUMBER}"
                echo "==================================="
            }
        }
    }
}
