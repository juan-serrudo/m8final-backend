#!/bin/bash

# Script para configurar Docker Swarm y desplegar el stack
# Uso: ./setup-swarm.sh

set -e

echo "🚀 Configurando Docker Swarm para Password Manager..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con color
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

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    print_error "Docker no está instalado. Por favor instala Docker primero."
    exit 1
fi

# Verificar si Docker Swarm está inicializado
if ! docker info | grep -q "Swarm: active"; then
    print_status "Inicializando Docker Swarm..."
    docker swarm init
    print_success "Docker Swarm inicializado correctamente"
else
    print_success "Docker Swarm ya está inicializado"
fi

# Crear directorios para volúmenes persistentes
print_status "Creando directorios para volúmenes persistentes..."
sudo mkdir -p /opt/password-manager/postgres-data
sudo mkdir -p /opt/password-manager/redis-data
sudo chown -R 999:999 /opt/password-manager/postgres-data
sudo chown -R 999:999 /opt/password-manager/redis-data
print_success "Directorios de volúmenes creados"

# Crear secrets
print_status "Creando secrets..."
echo "password123" | docker secret create postgres_password -
echo "password123" | docker secret create db_password -
print_success "Secrets creados correctamente"

# Crear configs
print_status "Creando configs..."

# Config para nginx
docker config create nginx_config ./config/nginx/nginx.conf

# Config para aplicación (variables de entorno)
cat > /tmp/app.env << EOF
NODE_ENV=production
PORT=3000
ENV_ENTORNO=production
ENV_CORS=*
ENV_SWAGGER_SHOW=true
ENV_SYNCHRONIZE=false
APP_MAX_SIZE=10mb
DB_HOST=postgres
DB_PORT=5432
DB_USER=postgres
DB_NAME=password_manager
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_DB=0
THROTTLE_TTL=60
THROTTLE_LIMIT=10
EOF

docker config create app_config /tmp/app.env
rm /tmp/app.env

print_success "Configs creados correctamente"

# Construir imágenes
print_status "Construyendo imágenes Docker..."
docker build -t password-manager-backend:latest ./apps/backend
docker build -t password-manager-frontend:latest ./apps/frontend
print_success "Imágenes construidas correctamente"

# Desplegar stack
print_status "Desplegando stack..."
docker stack deploy -c stack-deploy.yml password-manager
print_success "Stack desplegado correctamente"

# Mostrar estado del stack
print_status "Estado del stack:"
docker stack services password-manager

print_success "🎉 Configuración de Docker Swarm completada!"
print_status "La aplicación estará disponible en:"
print_status "  - Frontend: http://localhost:8080"
print_status "  - API: http://localhost:8080/api"
print_status "  - Swagger: http://localhost:8080/api-docs"
print_status "  - Adminer: http://localhost:8081"
print_status ""
print_status "Comandos útiles:"
print_status "  - Ver servicios: docker stack services password-manager"
print_status "  - Ver logs: docker service logs password-manager_app"
print_status "  - Escalar servicio: docker service scale password-manager_app=5"
print_status "  - Eliminar stack: docker stack rm password-manager"
