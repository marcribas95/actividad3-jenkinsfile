// ═══════════════════════════════════════════════════════════════════════════
// JENKINSFILE - PIPELINE DE CI/CD PARA APLICACIÓN CALCULADORA
// ═══════════════════════════════════════════════════════════════════════════
// 
// Este Jenkinsfile implementa un pipeline completo con:
// ✅ Etapas separadas para pruebas unitarias, API y E2E
// ✅ Publicación individual de resultados de cada tipo de prueba
// ✅ Archivado de archivos XML y logs
// ✅ Notificación por correo en caso de fallo (con JOB_NAME y BUILD_NUMBER)
//
// INSTRUCCIONES DE USO:
// 1. Crear un nuevo job tipo "Pipeline" en Jenkins
// 2. En la configuración, seleccionar "Pipeline script"
// 3. Copiar y pegar este código completo
// 4. Guardar y ejecutar "Construir Ahora"
//
// ═══════════════════════════════════════════════════════════════════════════

pipeline {
    agent any
    
    environment {
        // Variables de entorno del proyecto
        GIT_REPO = 'https://github.com/marcribas95/actividad3-jenkinsfile.git'
        GIT_BRANCH = 'main'
        PROJECT_DIR = "${WORKSPACE}"
        REPORTS_DIR = "${WORKSPACE}/tests-reports"
    }
    
    options {
        // Mantener los últimos 10 builds
        buildDiscarder(logRotator(numToKeepStr: '10'))
        // Timeout general del pipeline
        timeout(time: 30, unit: 'MINUTES')
        // Timestamps en el log
        timestamps()
        // No permitir builds concurrentes
        disableConcurrentBuilds()
    }
    
    stages {
        stage('🔍 Checkout') {
            steps {
                script {
                    echo '════════════════════════════════════════════════════════'
                    echo '║  DESCARGANDO CÓDIGO DEL REPOSITORIO'
                    echo '════════════════════════════════════════════════════════'
                }
                
                // Descargar código del repositorio Git
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${GIT_BRANCH}"]],
                    userRemoteConfigs: [[url: "${GIT_REPO}"]]
                ])
                
                script {
                    echo '✓ Código descargado exitosamente'
                    echo "✓ Branch: ${GIT_BRANCH}"
                    echo "✓ Workspace: ${WORKSPACE}"
                }
            }
        }
        
        stage('🔧 Setup') {
            steps {
                script {
                    echo '════════════════════════════════════════════════════════'
                    echo '║  CONFIGURANDO ENTORNO'
                    echo '════════════════════════════════════════════════════════'
                }
                
                // Configurar entorno e instalar dependencias
                sh '''
                    make setup
                '''
                
                script {
                    echo '✓ Entorno configurado correctamente'
                }
            }
        }
        
        stage('🧪 Test Unitarios') {
            steps {
                script {
                    echo '════════════════════════════════════════════════════════'
                    echo '║  EJECUTANDO PRUEBAS UNITARIAS'
                    echo '════════════════════════════════════════════════════════'
                }
                
                // Ejecutar pruebas unitarias
                sh '''
                    make test-unit
                '''
                
                script {
                    echo '✓ Pruebas unitarias completadas'
                }
            }
            post {
                always {
                    // Publicar resultados de pruebas unitarias
                    junit(
                        testResults: 'tests-reports/test-results-unit-*.xml',
                        allowEmptyResults: true,
                        skipPublishingChecks: true,
                        keepLongStdio: true
                    )
                }
            }
        }
        
        stage('🌐 Test API') {
            steps {
                script {
                    echo '════════════════════════════════════════════════════════'
                    echo '║  EJECUTANDO PRUEBAS DE API'
                    echo '════════════════════════════════════════════════════════'
                }
                
                // Ejecutar pruebas de API
                sh '''
                    make test-api
                '''
                
                script {
                    echo '✓ Pruebas de API completadas'
                }
            }
            post {
                always {
                    // Publicar resultados de pruebas de API
                    junit(
                        testResults: 'tests-reports/test-results-api-*.xml',
                        allowEmptyResults: true,
                        skipPublishingChecks: true,
                        keepLongStdio: true
                    )
                }
            }
        }
        
        stage('🚀 Test E2E') {
            steps {
                script {
                    echo '════════════════════════════════════════════════════════'
                    echo '║  EJECUTANDO PRUEBAS END-TO-END'
                    echo '════════════════════════════════════════════════════════'
                }
                
                // Ejecutar pruebas e2e con Docker
                sh '''
                    make test-e2e
                '''
                
                script {
                    echo '✓ Pruebas E2E completadas'
                }
            }
            post {
                always {
                    // Publicar resultados de pruebas E2E
                    junit(
                        testResults: 'tests-reports/test-results-e2e-*.xml',
                        allowEmptyResults: true,
                        skipPublishingChecks: true,
                        keepLongStdio: true
                    )
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo '════════════════════════════════════════════════════════'
                echo '║  LIMPIEZA Y FINALIZACIÓN'
                echo '════════════════════════════════════════════════════════'
            }
            
            // Detener servicios Docker si están corriendo
            sh '''
                make docker-down || true
            '''
            
            // Archivar logs y reportes XML
            archiveArtifacts(
                artifacts: 'tests-reports/*.xml, tests-reports/*.log',
                allowEmptyArchive: true,
                fingerprint: true
            )
            
            script {
                echo '✓ Artefactos archivados'
            }
        }
        
        success {
            script {
                echo ''
                echo '╔════════════════════════════════════════════════════════════╗'
                echo '║  ✓ BUILD EXITOSO - TODAS LAS PRUEBAS PASARON              ║'
                echo '╚════════════════════════════════════════════════════════════╝'
                echo ''
            }
        }
        
        failure {
            script {
                echo ''
                echo '╔════════════════════════════════════════════════════════════╗'
                echo '║  ✗ BUILD FALLIDO - ALGUNAS PRUEBAS FALLARON               ║'
                echo '╚════════════════════════════════════════════════════════════╝'
                echo ''
                
                // Mostrar información del correo que se enviaría
                echo "📧 INFORMACIÓN DEL CORREO QUE SE ENVIARÍA:"
                echo "   ══════════════════════════════════════════"
                echo "   Asunto: ❌ Build Fallido - ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                echo "   Para: admin@example.com"
                echo ""
                echo "   Contenido del correo:"
                echo "   - Trabajo: ${env.JOB_NAME}"
                echo "   - Número de ejecución: ${env.BUILD_NUMBER}"
                echo "   - URL del build: ${env.BUILD_URL}"
                echo "   - Estado: FAILURE"
                echo "   ══════════════════════════════════════════"
                
                // ═══════════════════════════════════════════════════════════
                // ENVÍO DE CORREO ELECTRÓNICO
                // ═══════════════════════════════════════════════════════════
                // El siguiente código está COMENTADO para evitar errores
                // de configuración SMTP en Jenkins.
                //
                // Para habilitarlo:
                // 1. Configurar servidor SMTP en Jenkins:
                //    Administrar Jenkins → Configurar el Sistema → E-mail Notification
                // 2. Instalar el plugin "Email Extension Plugin"
                // 3. Descomentar el código siguiente
                // 4. Cambiar 'admin@example.com' por un correo real
                // ═══════════════════════════════════════════════════════════
                
                /*
                emailext(
                    subject: "❌ Build Fallido - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: """
                        <html>
                        <body>
                            <h2 style="color: #d32f2f;">❌ Build Fallido</h2>
                            <hr>
                            <table style="border-collapse: collapse; width: 100%;">
                                <tr>
                                    <td style="padding: 8px; font-weight: bold;">Trabajo:</td>
                                    <td style="padding: 8px;">${env.JOB_NAME}</td>
                                </tr>
                                <tr style="background-color: #f5f5f5;">
                                    <td style="padding: 8px; font-weight: bold;">Número de ejecución:</td>
                                    <td style="padding: 8px;">${env.BUILD_NUMBER}</td>
                                </tr>
                                <tr>
                                    <td style="padding: 8px; font-weight: bold;">URL del build:</td>
                                    <td style="padding: 8px;">
                                        <a href="${env.BUILD_URL}">${env.BUILD_URL}</a>
                                    </td>
                                </tr>
                                <tr style="background-color: #f5f5f5;">
                                    <td style="padding: 8px; font-weight: bold;">Estado:</td>
                                    <td style="padding: 8px; color: #d32f2f; font-weight: bold;">FAILURE</td>
                                </tr>
                            </table>
                            <hr>
                            <p style="margin-top: 20px;">
                                Por favor, revisa los logs y resultados de las pruebas para más detalles.
                            </p>
                            <p>
                                <a href="${env.BUILD_URL}console" 
                                   style="background-color: #1976d2; color: white; padding: 10px 20px; 
                                          text-decoration: none; border-radius: 4px; display: inline-block;">
                                    Ver Console Output
                                </a>
                            </p>
                        </body>
                        </html>
                    """,
                    to: 'admin@example.com',
                    mimeType: 'text/html'
                )
                */
            }
        }
        
        unstable {
            script {
                echo ''
                echo '╔════════════════════════════════════════════════════════════╗'
                echo '║  ⚠ BUILD INESTABLE - REVISAR RESULTADOS                   ║'
                echo '╚════════════════════════════════════════════════════════════╝'
                echo ''
            }
        }
    }
}
