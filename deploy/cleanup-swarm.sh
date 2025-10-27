#!/bin/bash

# Script de limpieza para Docker Swarm Stack
# Uso: ./cleanup-swarm.sh [--force]

set -e

STACK_NAME="password-manager"
FORCE_CLEANUP=false

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
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

show_help() {
    echo "Limpieza de Docker Swarm Stack - Password Manager"
    echo ""
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  --force     - Forzar limpieza sin confirmación"
    echo "  --help      - Mostrar esta ayuda"
    echo ""
    echo "Este script eliminará:"
    echo "  - Stack completo de Docker Swarm"
    echo "  - Secrets y configs"
    echo "  - Volúmenes persistentes"
    echo "  - Directorios de datos"
    echo "  - Imágenes Docker no utilizadas"
    echo ""
    echo "⚠️  ADVERTENCIA: Esta operación eliminará TODOS los datos!"
    echo ""
}

confirm_cleanup() {
    if [ "$FORCE_CLEANUP" = true ]; then
        return 0
    fi

    print_warning "⚠️  ADVERTENCIA: Esta operación eliminará TODOS los datos del stack!"
    print_warning "Esto incluye:"
    print_warning "  - Base de datos PostgreSQL"
    print_warning "  - Cache Redis"
    print_warning "  - Todos los datos de la aplicación"
    echo ""
    read -p "¿Estás seguro de que quieres continuar? (escribe 'yes' para confirmar): " confirm

    if [ "$confirm" != "yes" ]; then
        print_status "Operación cancelada"
        exit 0
    fi
}

stop_and_remove_stack() {
    print_status "Deteniendo y eliminando stack '$STACK_NAME'..."

    if docker stack ls | grep -q "$STACK_NAME"; then
        docker stack rm "$STACK_NAME"
        print_success "Stack eliminado"

        # Esperar a que se eliminen todos los servicios
        print_status "Esperando a que se eliminen todos los servicios..."
        while docker stack services "$STACK_NAME" 2>/dev/null | grep -q "$STACK_NAME"; do
            sleep 2
        done
        print_success "Todos los servicios eliminados"
    else
        print_warning "Stack '$STACK_NAME' no encontrado"
    fi
}

remove_secrets() {
    print_status "Eliminando secrets..."

    local secrets=("postgres_password" "db_password")

    for secret in "${secrets[@]}"; do
        if docker secret ls | grep -q "$secret"; then
            docker secret rm "$secret"
            print_success "Secret '$secret' eliminado"
        else
            print_warning "Secret '$secret' no encontrado"
        fi
    done
}

remove_configs() {
    print_status "Eliminando configs..."

    local configs=("nginx_config" "app_config")

    for config in "${configs[@]}"; do
        if docker config ls | grep -q "$config"; then
            docker config rm "$config"
            print_success "Config '$config' eliminado"
        else
            print_warning "Config '$config' no encontrado"
        fi
    done
}

remove_volumes() {
    print_status "Eliminando volúmenes..."

    local volumes=("${STACK_NAME}_postgres_data" "${STACK_NAME}_redis_data")

    for volume in "${volumes[@]}"; do
        if docker volume ls | grep -q "$volume"; then
            docker volume rm "$volume"
            print_success "Volumen '$volume' eliminado"
        else
            print_warning "Volumen '$volume' no encontrado"
        fi
    done
}

remove_directories() {
    print_status "Eliminando directorios de datos..."

    local directories=("/opt/password-manager/postgres-data" "/opt/password-manager/redis-data")

    for dir in "${directories[@]}"; do
        if [ -d "$dir" ]; then
            sudo rm -rf "$dir"
            print_success "Directorio '$dir' eliminado"
        else
            print_warning "Directorio '$dir' no encontrado"
        fi
    done
}

remove_images() {
    print_status "Eliminando imágenes Docker..."

    local images=("password-manager-backend:latest" "password-manager-frontend:latest")

    for image in "${images[@]}"; do
        if docker images | grep -q "$image"; then
            docker rmi "$image"
            print_success "Imagen '$image' eliminada"
        else
            print_warning "Imagen '$image' no encontrada"
        fi
    done
}

cleanup_docker_system() {
    print_status "Limpiando sistema Docker..."

    # Eliminar contenedores parados
    docker container prune -f
    print_success "Contenedores parados eliminados"

    # Eliminar redes no utilizadas
    docker network prune -f
    print_success "Redes no utilizadas eliminadas"

    # Eliminar volúmenes no utilizados
    docker volume prune -f
    print_success "Volúmenes no utilizados eliminados"

    # Eliminar imágenes no utilizadas
    docker image prune -f
    print_success "Imágenes no utilizadas eliminadas"

    # Limpieza completa del sistema
    docker system prune -af
    print_success "Limpieza completa del sistema realizada"
}

verify_cleanup() {
    print_status "Verificando limpieza..."

    local remaining_items=0

    # Verificar stack
    if docker stack ls | grep -q "$STACK_NAME"; then
        print_warning "Stack '$STACK_NAME' aún existe"
        remaining_items=$((remaining_items + 1))
    fi

    # Verificar secrets
    if docker secret ls | grep -q "postgres_password\|db_password"; then
        print_warning "Algunos secrets aún existen"
        remaining_items=$((remaining_items + 1))
    fi

    # Verificar configs
    if docker config ls | grep -q "nginx_config\|app_config"; then
        print_warning "Algunos configs aún existen"
        remaining_items=$((remaining_items + 1))
    fi

    # Verificar volúmenes
    if docker volume ls | grep -q "${STACK_NAME}_"; then
        print_warning "Algunos volúmenes aún existen"
        remaining_items=$((remaining_items + 1))
    fi

    # Verificar directorios
    if [ -d "/opt/password-manager" ]; then
        print_warning "Directorio /opt/password-manager aún existe"
        remaining_items=$((remaining_items + 1))
    fi

    if [ $remaining_items -eq 0 ]; then
        print_success "✅ Limpieza completada exitosamente"
    else
        print_warning "⚠️  $remaining_items elementos aún existen"
    fi
}

# Procesar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_CLEANUP=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            print_error "Opción no reconocida: $1"
            show_help
            exit 1
            ;;
    esac
done

# Función principal
main() {
    echo "🧹 Limpieza de Docker Swarm Stack - Password Manager"
    echo ""

    # Confirmar limpieza
    confirm_cleanup

    echo ""
    print_status "Iniciando limpieza completa..."
    echo ""

    # Detener y eliminar stack
    stop_and_remove_stack
    echo ""

    # Eliminar secrets
    remove_secrets
    echo ""

    # Eliminar configs
    remove_configs
    echo ""

    # Eliminar volúmenes
    remove_volumes
    echo ""

    # Eliminar directorios
    remove_directories
    echo ""

    # Eliminar imágenes
    remove_images
    echo ""

    # Limpieza del sistema Docker
    cleanup_docker_system
    echo ""

    # Verificar limpieza
    verify_cleanup
    echo ""

    print_success "🎉 Limpieza completada!"
    print_status "Para volver a desplegar el stack, ejecuta:"
    print_status "  ./setup-swarm.sh"
}

# Ejecutar función principal
main
