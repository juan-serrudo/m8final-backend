#!/bin/bash

# Script de monitoreo para Docker Swarm Stack
# Uso: ./monitor-stack.sh [intervalo_en_segundos]

set -e

STACK_NAME="password-manager"
INTERVAL=${1:-30}

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

check_stack_health() {
    local unhealthy_services=()
    local total_services=0

    print_status "Verificando salud del stack '$STACK_NAME'..."

    # Obtener lista de servicios
    local services=$(docker stack services $STACK_NAME --format "{{.Name}}" 2>/dev/null)

    if [ -z "$services" ]; then
        print_error "Stack '$STACK_NAME' no encontrado o no está ejecutándose"
        return 1
    fi

    for service in $services; do
        total_services=$((total_services + 1))

        # Verificar estado del servicio
        local replicas=$(docker service inspect $service --format "{{.Spec.Mode.Replicated.Replicas}}" 2>/dev/null)
        local running=$(docker service ps $service --filter "desired-state=running" --format "{{.CurrentState}}" | grep -c "Running" 2>/dev/null || echo "0")

        if [ "$running" -lt "$replicas" ]; then
            unhealthy_services+=("$service")
            print_warning "Servicio $service: $running/$replicas réplicas ejecutándose"
        else
            print_success "Servicio $service: $running/$replicas réplicas ejecutándose"
        fi
    done

    echo ""
    print_status "Resumen: $((total_services - ${#unhealthy_services[@]}))/$total_services servicios saludables"

    if [ ${#unhealthy_services[@]} -gt 0 ]; then
        print_error "Servicios con problemas: ${unhealthy_services[*]}"
        return 1
    else
        print_success "Todos los servicios están saludables"
        return 0
    fi
}

check_resource_usage() {
    print_status "Verificando uso de recursos..."

    # Verificar uso de CPU y memoria
    local stats=$(docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | grep -v "CONTAINER" || echo "")

    if [ -n "$stats" ]; then
        echo "$stats" | while read container cpu mem; do
            if [ -n "$container" ]; then
                # Extraer porcentaje de CPU (remover %)
                local cpu_percent=$(echo "$cpu" | sed 's/%//')
                local mem_usage="$mem"

                # Verificar si CPU > 80%
                if (( $(echo "$cpu_percent > 80" | bc -l) )); then
                    print_warning "Alto uso de CPU en $container: $cpu"
                fi

                print_status "$container: CPU=$cpu, Memoria=$mem_usage"
            fi
        done
    else
        print_warning "No se pudieron obtener estadísticas de recursos"
    fi
}

check_network_connectivity() {
    print_status "Verificando conectividad de red..."

    # Verificar red overlay
    local overlay_network=$(docker network ls --filter "driver=overlay" --format "{{.Name}}" | grep "$STACK_NAME" || echo "")

    if [ -n "$overlay_network" ]; then
        print_success "Red overlay '$overlay_network' está activa"

        # Verificar conectividad entre servicios principales
        local app_service="${STACK_NAME}_app"
        local frontend_service="${STACK_NAME}_frontend"
        local nginx_service="${STACK_NAME}_nginx"

        # Verificar que los servicios pueden comunicarse
        for service in $app_service $frontend_service $nginx_service; do
            local tasks=$(docker service ps $service --filter "desired-state=running" --format "{{.ID}}" 2>/dev/null | wc -l)
            if [ "$tasks" -gt 0 ]; then
                print_success "Servicio $service tiene $tasks tareas ejecutándose"
            else
                print_warning "Servicio $service no tiene tareas ejecutándose"
            fi
        done
    else
        print_error "Red overlay no encontrada"
    fi
}

check_storage() {
    print_status "Verificando almacenamiento..."

    # Verificar volúmenes
    local volumes=$(docker volume ls --filter "name=$STACK_NAME" --format "{{.Name}}" 2>/dev/null)

    if [ -n "$volumes" ]; then
        for volume in $volumes; do
            print_success "Volumen $volume está disponible"
        done
    else
        print_warning "No se encontraron volúmenes del stack"
    fi

    # Verificar espacio en disco
    local disk_usage=$(df -h /opt/password-manager 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//' || echo "0")

    if [ "$disk_usage" -gt 80 ]; then
        print_warning "Uso de disco alto: ${disk_usage}%"
    else
        print_success "Uso de disco normal: ${disk_usage}%"
    fi
}

check_application_endpoints() {
    print_status "Verificando endpoints de la aplicación..."

    # Verificar endpoint de salud
    local health_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health 2>/dev/null || echo "000")

    if [ "$health_response" = "200" ]; then
        print_success "Endpoint de salud responde correctamente"
    else
        print_error "Endpoint de salud no responde (HTTP $health_response)"
    fi

    # Verificar endpoint principal
    local main_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null || echo "000")

    if [ "$main_response" = "200" ]; then
        print_success "Endpoint principal responde correctamente"
    else
        print_error "Endpoint principal no responde (HTTP $main_response)"
    fi
}

send_alert() {
    local message="$1"
    print_error "🚨 ALERTA: $message"

    # Aquí puedes agregar lógica para enviar alertas por email, Slack, etc.
    # Ejemplo:
    # curl -X POST -H 'Content-type: application/json' \
    #      --data '{"text":"'$message'"}' \
    #      $SLACK_WEBHOOK_URL
}

monitor_loop() {
    print_status "Iniciando monitoreo continuo (intervalo: ${INTERVAL}s)"
    print_status "Presiona Ctrl+C para detener"
    echo ""

    while true; do
        echo "=========================================="
        print_status "Verificación de salud del stack"
        echo "=========================================="

        # Verificar salud del stack
        if ! check_stack_health; then
            send_alert "Stack tiene servicios con problemas"
        fi

        echo ""

        # Verificar uso de recursos
        check_resource_usage
        echo ""

        # Verificar conectividad de red
        check_network_connectivity
        echo ""

        # Verificar almacenamiento
        check_storage
        echo ""

        # Verificar endpoints de aplicación
        check_application_endpoints
        echo ""

        print_status "Esperando ${INTERVAL} segundos para la siguiente verificación..."
        sleep $INTERVAL
    done
}

show_help() {
    echo "Monitoreo de Docker Swarm Stack - Password Manager"
    echo ""
    echo "Uso: $0 [intervalo_en_segundos]"
    echo ""
    echo "Parámetros:"
    echo "  intervalo_en_segundos  - Intervalo entre verificaciones (default: 30)"
    echo ""
    echo "Ejemplos:"
    echo "  $0          # Monitoreo cada 30 segundos"
    echo "  $0 60       # Monitoreo cada 60 segundos"
    echo "  $0 10       # Monitoreo cada 10 segundos"
    echo ""
    echo "El script verificará:"
    echo "  - Salud de servicios y réplicas"
    echo "  - Uso de recursos (CPU, memoria)"
    echo "  - Conectividad de red"
    echo "  - Estado de volúmenes"
    echo "  - Disponibilidad de endpoints"
    echo ""
}

# Función principal
case "${1:-monitor}" in
    monitor)
        monitor_loop
        ;;
    health)
        check_stack_health
        ;;
    resources)
        check_resource_usage
        ;;
    network)
        check_network_connectivity
        ;;
    storage)
        check_storage
        ;;
    endpoints)
        check_application_endpoints
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        if [[ "$1" =~ ^[0-9]+$ ]]; then
            monitor_loop
        else
            print_error "Comando no reconocido: $1"
            show_help
            exit 1
        fi
        ;;
esac
