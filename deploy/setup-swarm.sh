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
if [ -w "/opt" ]; then
    mkdir -p /opt/password-manager/postgres-data
    mkdir -p /opt/password-manager/redis-data
    chown -R 999:999 /opt/password-manager/postgres-data 2>/dev/null || true
    chown -R 999:999 /opt/password-manager/redis-data 2>/dev/null || true
    print_success "Directorios de volúmenes creados"
else
    print_warning "No se tienen permisos para crear directorios en /opt"
    print_warning "Los volúmenes usarán el directorio local ./data"
    mkdir -p ./data/postgres-data
    mkdir -p ./data/redis-data
    print_success "Directorios locales de volúmenes creados"
fi

# Crear secrets
print_status "Creando secrets..."
if ! docker secret ls | grep -q "postgres_password"; then
    echo "password123" | docker secret create postgres_password -
    print_success "Secret postgres_password creado"
else
    print_warning "Secret postgres_password ya existe"
fi

if ! docker secret ls | grep -q "db_password"; then
    echo "password123" | docker secret create db_password -
    print_success "Secret db_password creado"
else
    print_warning "Secret db_password ya existe"
fi

# Crear configs
print_status "Creando configs..."

# Config para nginx
if ! docker config ls | grep -q "nginx_config"; then
    docker config create nginx_config ./nginx-swarm.conf
    print_success "Config nginx_config creado"
else
    print_warning "Config nginx_config ya existe"
fi

# Config para aplicación (variables de entorno)
if ! docker config ls | grep -q "app_config"; then
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
    print_success "Config app_config creado"
else
    print_warning "Config app_config ya existe"
fi

# Construir imágenes
print_status "Construyendo imágenes Docker..."

# Construir imagen del backend
print_status "Construyendo imagen del backend..."
if docker build -t password-manager-backend:latest ../apps/backend; then
    print_success "Imagen del backend construida correctamente"
else
    print_error "Error al construir imagen del backend"
    exit 1
fi

# Construir imagen del frontend
print_status "Construyendo imagen del frontend..."
if docker build -t password-manager-frontend:latest ../apps/frontend; then
    print_success "Imagen del frontend construida correctamente"
else
    print_error "Error al construir imagen del frontend"
    exit 1
fi

# Desplegar stack
print_status "Desplegando stack..."
if docker stack deploy -c stack-deploy.yml password-manager; then
    print_success "Stack desplegado correctamente"
else
    print_error "Error al desplegar el stack"
    exit 1
fi

# Esperar a que los servicios estén listos
print_status "Esperando a que los servicios estén listos..."
sleep 10

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
