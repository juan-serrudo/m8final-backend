#!/bin/bash

# Gestor de Contraseñas Monorepo - Script de Verificación de Salud
# Este script verifica la salud de todos los servicios

set -e

echo "🏥 Gestor de Contraseñas Monorepo - Verificación de Salud"
echo "========================================================"

# Colores para la salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin Color

# Función para verificar salud del servicio
check_service() {
    local name=$1
    local url=$2
    local expected_status=${3:-200}
    
    echo -n "Verificando $name... "
    
    if response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null); then
        if [ "$response" = "$expected_status" ]; then
            echo -e "${GREEN}✅ Saludable (HTTP $response)${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  Estado inesperado (HTTP $response)${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ No saludable${NC}"
        return 1
    fi
}

# Función para verificar estado del contenedor Docker
check_container() {
    local container_name=$1
    
    echo -n "Verificando contenedor $container_name... "
    
    if docker ps --filter "name=$container_name" --filter "status=running" --format "{{.Names}}" | grep -q "$container_name"; then
        echo -e "${GREEN}✅ Ejecutándose${NC}"
        return 0
    else
        echo -e "${RED}❌ No ejecutándose${NC}"
        return 1
    fi
}

echo ""
echo "🐳 Estado de Contenedores Docker:"
echo "----------------------------------"
check_container "m8final-postgres"
check_container "m8final-redis"
check_container "m8final-backend"
check_container "m8final-frontend"
check_container "m8final-nginx"

echo ""
echo "🌐 Verificaciones de Salud de Servicios:"
echo "----------------------------------------"

# Verificar salud del backend
check_service "API Backend" "http://localhost:3000/api/health"

# Verificar salud del frontend
check_service "Frontend" "http://localhost/health"

# Verificar proxy nginx
check_service "Proxy Nginx" "http://localhost:8080/health"

# Verificar endpoints de API
check_service "Documentación API" "http://localhost:3000/api-docs"

echo ""
echo "📊 Información Adicional:"
echo "-------------------------"

# Mostrar uso de recursos de contenedores
echo "Uso de Recursos de Contenedores:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" \
    m8final-postgres m8final-redis m8final-backend m8final-frontend m8final-nginx 2>/dev/null || echo "No se pudo obtener el uso de recursos"

echo ""
echo "🔍 Logs (últimas 10 líneas de cada servicio):"
echo "---------------------------------------------"

services=("m8final-postgres" "m8final-redis" "m8final-backend" "m8final-frontend" "m8final-nginx")

for service in "${services[@]}"; do
    echo ""
    echo "📋 Logs de $service:"
    docker logs --tail 10 "$service" 2>/dev/null || echo "No hay logs disponibles para $service"
done

echo ""
echo "✨ ¡Verificación de salud completada!"
echo ""
echo "💡 Si algún servicio no está saludable:"
echo "   1. Revisar los logs: docker compose logs [nombre-servicio]"
echo "   2. Reiniciar servicios: docker compose restart"
echo "   3. Reconstruir servicios: docker compose up --build"
echo ""