#!/bin/bash

# Script para gestionar el stack de Docker Swarm
# Uso: ./manage-stack.sh [comando]

set -e

STACK_NAME="password-manager"

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
    echo "Gestión del Stack Docker Swarm - Password Manager"
    echo ""
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos disponibles:"
    echo "  status      - Mostrar estado del stack y servicios"
    echo "  logs        - Mostrar logs de todos los servicios"
    echo "  scale       - Escalar servicios"
    echo "  update      - Actualizar stack"
    echo "  rollback    - Hacer rollback del stack"
    echo "  restart     - Reiniciar servicios"
    echo "  stop        - Detener stack"
    echo "  start       - Iniciar stack"
    echo "  remove      - Eliminar stack completamente"
    echo "  cleanup     - Limpiar recursos no utilizados"
    echo "  health      - Verificar salud de los servicios"
    echo "  stats       - Mostrar estadísticas de recursos"
    echo ""
}

show_status() {
    print_status "Estado del stack '$STACK_NAME':"
    echo ""
    docker stack services $STACK_NAME
    echo ""
    print_status "Nodos del cluster:"
    docker node ls
}

show_logs() {
    print_status "Logs de todos los servicios:"
    echo ""
    for service in $(docker stack services $STACK_NAME --format "{{.Name}}"); do
        echo "=== Logs de $service ==="
        docker service logs --tail 20 $service
        echo ""
    done
}

scale_services() {
    print_status "Escalando servicios..."
    echo ""
    echo "Servicios disponibles para escalar:"
    docker stack services $STACK_NAME --format "table {{.Name}}\t{{.Replicas}}"
    echo ""
    read -p "Ingresa el nombre del servicio: " service_name
    read -p "Ingresa el número de réplicas: " replicas

    if [[ $replicas =~ ^[0-9]+$ ]]; then
        docker service scale ${STACK_NAME}_${service_name}=$replicas
        print_success "Servicio ${service_name} escalado a $replicas réplicas"
    else
        print_error "Número de réplicas inválido"
    fi
}

update_stack() {
    print_status "Actualizando stack..."
    docker stack deploy -c stack-deploy.yml $STACK_NAME
    print_success "Stack actualizado"
}

rollback_stack() {
    print_status "Haciendo rollback del stack..."
    docker service rollback ${STACK_NAME}_app
    docker service rollback ${STACK_NAME}_frontend
    docker service rollback ${STACK_NAME}_nginx
    print_success "Rollback completado"
}

restart_services() {
    print_status "Reiniciando servicios..."
    docker service update --force ${STACK_NAME}_app
    docker service update --force ${STACK_NAME}_frontend
    docker service update --force ${STACK_NAME}_nginx
    print_success "Servicios reiniciados"
}

stop_stack() {
    print_status "Deteniendo stack..."
    docker stack rm $STACK_NAME
    print_success "Stack detenido"
}

start_stack() {
    print_status "Iniciando stack..."
    docker stack deploy -c stack-deploy.yml $STACK_NAME
    print_success "Stack iniciado"
}

remove_stack() {
    print_warning "Esto eliminará completamente el stack y todos sus datos."
    read -p "¿Estás seguro? (y/N): " confirm
    if [[ $confirm == "y" || $confirm == "Y" ]]; then
        print_status "Eliminando stack..."
        docker stack rm $STACK_NAME
        print_success "Stack eliminado"
    else
        print_status "Operación cancelada"
    fi
}

cleanup_resources() {
    print_status "Limpiando recursos no utilizados..."
    docker system prune -f
    docker volume prune -f
    docker network prune -f
    print_success "Limpieza completada"
}

check_health() {
    print_status "Verificando salud de los servicios:"
    echo ""
    for service in $(docker stack services $STACK_NAME --format "{{.Name}}"); do
        echo "=== Salud de $service ==="
        docker service inspect $service --format "{{.Spec.TaskTemplate.ContainerSpec.Healthcheck}}"
        echo ""
    done
}

show_stats() {
    print_status "Estadísticas de recursos:"
    echo ""
    docker stats --no-stream
}

# Función principal
case "${1:-help}" in
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    scale)
        scale_services
        ;;
    update)
        update_stack
        ;;
    rollback)
        rollback_stack
        ;;
    restart)
        restart_services
        ;;
    stop)
        stop_stack
        ;;
    start)
        start_stack
        ;;
    remove)
        remove_stack
        ;;
    cleanup)
        cleanup_resources
        ;;
    health)
        check_health
        ;;
    stats)
        show_stats
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Comando no reconocido: $1"
        show_help
        exit 1
        ;;
esac
