#!/bin/bash

# ===========================================
# Script de Despliegue en Producción
# ===========================================
# Este script despliega la aplicación usando imágenes
# pre-construidas y publicadas en Docker Hub

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 <version> [comando]"
    echo ""
    echo "Argumentos:"
    echo "  version    Versión a desplegar (ej: v1, v2)"
    echo "  comando    Comando a ejecutar (up, down, logs, status)"
    echo ""
    echo "Variables de entorno requeridas:"
    echo "  DOCKERHUB_USER    Usuario de Docker Hub"
    echo ""
    echo "Variables de entorno opcionales:"
    echo "  POSTGRES_PASSWORD Contraseña de PostgreSQL (default: password123)"
    echo ""
    echo "Comandos disponibles:"
    echo "  up        Desplegar la aplicación (default)"
    echo "  down      Detener la aplicación"
    echo "  logs      Mostrar logs de todos los servicios"
    echo "  status    Mostrar estado de los servicios"
    echo "  restart   Reiniciar la aplicación"
    echo ""
    echo "Ejemplos:"
    echo "  $0 v1                    # Desplegar versión v1"
    echo "  $0 v2 up                 # Desplegar versión v2"
    echo "  $0 v1 down               # Detener versión v1"
    echo "  $0 v1 logs               # Ver logs de v1"
    echo "  $0 v1 status             # Ver estado de v1"
    echo ""
    echo "Antes de ejecutar:"
    echo "  1. Asegúrate de que las imágenes estén publicadas en Docker Hub"
    echo "  2. Configurar variables de entorno:"
    echo "     export DOCKERHUB_USER=tu_usuario"
    echo "     export POSTGRES_PASSWORD=tu_password_seguro"
}

# Verificar argumentos
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

VERSION=$1
COMMAND=${2:-up}

# Validar formato de versión
if [[ ! $VERSION =~ ^v[0-9]+$ ]]; then
    print_error "Formato de versión inválido. Use: v1, v2, v3, etc."
    exit 1
fi

# Verificar variables de entorno
if [ -z "$DOCKERHUB_USER" ]; then
    print_error "DOCKERHUB_USER no está definido"
    print_message "Ejecuta: export DOCKERHUB_USER=tu_usuario"
    exit 1
fi

# Configurar variables de entorno
export VERSION=$VERSION
export BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

print_message "Configuración de despliegue:"
print_message "  Versión: $VERSION"
print_message "  Usuario Docker Hub: $DOCKERHUB_USER"
print_message "  Comando: $COMMAND"
print_message "  Fecha de build: $BUILD_DATE"

# Archivo de compose
COMPOSE_FILE="deploy/compose.release.yml"

# Verificar que el archivo existe
if [ ! -f "$COMPOSE_FILE" ]; then
    print_error "Archivo de compose no encontrado: $COMPOSE_FILE"
    exit 1
fi

# Función para verificar imágenes
verify_images() {
    print_message "Verificando imágenes en Docker Hub..."

    local backend_image="$DOCKERHUB_USER/m9final-backend:$VERSION"
    local frontend_image="$DOCKERHUB_USER/m9final-frontend:$VERSION"

    # Verificar backend
    if docker manifest inspect "$backend_image" >/dev/null 2>&1; then
        print_success "Imagen backend encontrada: $backend_image"
    else
        print_error "Imagen backend no encontrada: $backend_image"
        print_message "Ejecuta primero: scripts/build_and_push.sh $VERSION"
        exit 1
    fi

    # Verificar frontend
    if docker manifest inspect "$frontend_image" >/dev/null 2>&1; then
        print_success "Imagen frontend encontrada: $frontend_image"
    else
        print_error "Imagen frontend no encontrada: $frontend_image"
        print_message "Ejecuta primero: scripts/build_and_push.sh $VERSION"
        exit 1
    fi
}

# Función para mostrar estado
show_status() {
    print_message "Estado de los servicios:"
    docker compose -f "$COMPOSE_FILE" ps
}

# Función para mostrar logs
show_logs() {
    print_message "Mostrando logs de los servicios:"
    docker compose -f "$COMPOSE_FILE" logs --tail=50 -f
}

# Función para verificar salud
check_health() {
    print_message "Verificando salud de la aplicación..."

    # Esperar un momento para que los servicios se inicien
    sleep 10

    # Verificar health endpoint
    if curl -s http://localhost:8080/health >/dev/null 2>&1; then
        print_success "Health check: OK"
    else
        print_warning "Health check: No disponible aún"
    fi

    # Verificar version endpoint
    if curl -s http://localhost:8080/version >/dev/null 2>&1; then
        print_success "Version endpoint: OK"
        print_message "Información de versión:"
        curl -s http://localhost:8080/version | jq '.' 2>/dev/null || curl -s http://localhost:8080/version
    else
        print_warning "Version endpoint: No disponible aún"
    fi
}

# Ejecutar comando
case $COMMAND in
    "up")
        print_message "Iniciando despliegue de versión $VERSION..."
        verify_images

        # Detener versión anterior si existe
        print_message "Deteniendo servicios anteriores..."
        docker compose -f "$COMPOSE_FILE" down 2>/dev/null || true

        # Iniciar servicios
        print_message "Iniciando servicios..."
        docker compose -f "$COMPOSE_FILE" up -d

        # Mostrar estado
        show_status

        # Verificar salud
        check_health

        print_success "Despliegue completado!"
        print_message ""
        print_message "Servicios disponibles:"
        print_message "  - Aplicación: http://localhost:8080"
        print_message "  - Health Check: http://localhost:8080/health"
        print_message "  - Version Info: http://localhost:8080/version"
        print_message "  - Swagger UI: http://localhost:8080/api"
        print_message "  - Adminer: http://localhost:8081"
        print_message ""
        print_message "Para ver logs: $0 $VERSION logs"
        print_message "Para ver estado: $0 $VERSION status"
        ;;

    "down")
        print_message "Deteniendo servicios de versión $VERSION..."
        docker compose -f "$COMPOSE_FILE" down
        print_success "Servicios detenidos"
        ;;

    "restart")
        print_message "Reiniciando servicios de versión $VERSION..."
        docker compose -f "$COMPOSE_FILE" restart
        show_status
        check_health
        print_success "Servicios reiniciados"
        ;;

    "logs")
        show_logs
        ;;

    "status")
        show_status
        ;;

    *)
        print_error "Comando no reconocido: $COMMAND"
        print_message "Comandos disponibles: up, down, logs, status, restart"
        exit 1
        ;;
esac
