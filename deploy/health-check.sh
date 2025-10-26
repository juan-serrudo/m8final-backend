#!/bin/bash

# Password Manager Monorepo - Health Check Script
# This script checks the health of all services

set -e

echo "🏥 Password Manager Monorepo - Health Check"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check service health
check_service() {
    local name=$1
    local url=$2
    local expected_status=${3:-200}
    
    echo -n "Checking $name... "
    
    if response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null); then
        if [ "$response" = "$expected_status" ]; then
            echo -e "${GREEN}✅ Healthy (HTTP $response)${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  Unexpected status (HTTP $response)${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Unhealthy${NC}"
        return 1
    fi
}

# Function to check Docker container status
check_container() {
    local container_name=$1
    
    echo -n "Checking container $container_name... "
    
    if docker ps --filter "name=$container_name" --filter "status=running" --format "{{.Names}}" | grep -q "$container_name"; then
        echo -e "${GREEN}✅ Running${NC}"
        return 0
    else
        echo -e "${RED}❌ Not running${NC}"
        return 1
    fi
}

echo ""
echo "🐳 Docker Container Status:"
echo "---------------------------"
check_container "m8final-postgres"
check_container "m8final-redis"
check_container "m8final-backend"
check_container "m8final-frontend"
check_container "m8final-nginx"

echo ""
echo "🌐 Service Health Checks:"
echo "-------------------------"

# Check backend health
check_service "Backend API" "http://localhost:3000/health"

# Check frontend health
check_service "Frontend" "http://localhost/health"

# Check nginx proxy
check_service "Nginx Proxy" "http://localhost:8080/health"

# Check API endpoints
check_service "API Documentation" "http://localhost:3000/api-docs"

echo ""
echo "📊 Additional Information:"
echo "-------------------------"

# Show container resource usage
echo "Container Resource Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" \
    m8final-postgres m8final-redis m8final-backend m8final-frontend m8final-nginx 2>/dev/null || echo "Unable to get resource usage"

echo ""
echo "🔍 Logs (last 10 lines from each service):"
echo "----------------------------------------"

services=("m8final-postgres" "m8final-redis" "m8final-backend" "m8final-frontend" "m8final-nginx")

for service in "${services[@]}"; do
    echo ""
    echo "📋 $service logs:"
    docker logs --tail 10 "$service" 2>/dev/null || echo "No logs available for $service"
done

echo ""
echo "✨ Health check complete!"
echo ""
echo "💡 If any services are unhealthy:"
echo "   1. Check the logs: docker-compose logs [service-name]"
echo "   2. Restart services: docker-compose restart"
echo "   3. Rebuild services: docker-compose up --build"
echo ""
