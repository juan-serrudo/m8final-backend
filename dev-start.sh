#!/bin/bash

# ===========================================
# Script de Desarrollo Local - Password Manager
# ===========================================
# Este script configura y ejecuta el entorno de desarrollo local
# con Redis, PostgreSQL y las aplicaciones backend/frontend

set -e  # Salir si cualquier comando falla

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con colores
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

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Función para verificar si un puerto está en uso
port_in_use() {
    lsof -i :$1 >/dev/null 2>&1
}

# Función para esperar que un servicio esté disponible
wait_for_service() {
    local host=$1
    local port=$2
    local service_name=$3
    local max_attempts=30
    local attempt=1

    print_message "Esperando que $service_name esté disponible en $host:$port..."

    while [ $attempt -le $max_attempts ]; do
        if nc -z $host $port 2>/dev/null; then
            print_success "$service_name está disponible!"
            return 0
        fi

        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done

    print_error "$service_name no está disponible después de $max_attempts intentos"
    return 1
}

# Función para limpiar procesos al salir
cleanup() {
    print_message "Limpiando procesos..."

    # Matar procesos en background
    jobs -p | xargs -r kill 2>/dev/null || true

    # Detener contenedores de desarrollo
    if [ -f "docker-compose.dev.yml" ]; then
        docker-compose -f docker-compose.dev.yml down 2>/dev/null || true
    fi

    print_success "Limpieza completada"
}

# Configurar trap para limpiar al salir
trap cleanup EXIT INT TERM

# Verificar dependencias
print_message "Verificando dependencias..."

if ! command_exists docker; then
    print_error "Docker no está instalado. Por favor instala Docker."
    exit 1
fi

if ! command_exists docker-compose; then
    print_error "Docker Compose no está instalado. Por favor instala Docker Compose."
    exit 1
fi

if ! command_exists node; then
    print_error "Node.js no está instalado. Por favor instala Node.js."
    exit 1
fi

if ! command_exists npm; then
    print_error "npm no está instalado. Por favor instala npm."
    exit 1
fi

print_success "Todas las dependencias están instaladas"

# Crear archivo de entorno para desarrollo si no existe
if [ ! -f ".env" ]; then
    print_message "Creando archivo .env para desarrollo..."
    cp env.example .env

    # Actualizar configuración para desarrollo local
    sed -i 's/NODE_ENV=production/NODE_ENV=development/' .env
    sed -i 's/ENV_ENTORNO=production/ENV_ENTORNO=development/' .env
    sed -i 's/ENV_SYNCHRONIZE=false/ENV_SYNCHRONIZE=true/' .env
    sed -i 's/DB_HOST=postgres/DB_HOST=localhost/' .env
    sed -i 's/REDIS_HOST=redis/REDIS_HOST=localhost/' .env

    print_success "Archivo .env creado para desarrollo"
fi

# Crear docker-compose para servicios de desarrollo
print_message "Creando configuración Docker Compose para desarrollo..."
cat > docker-compose.dev.yml << 'EOF'
version: '3.8'

services:
  # PostgreSQL Database para desarrollo
  postgres-dev:
    image: postgres:16-alpine
    container_name: password-manager-postgres-dev
    environment:
      POSTGRES_DB: password_manager
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password123
    ports:
      - "5432:5432"
    volumes:
      - postgres_dev_data:/var/lib/postgresql/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d password_manager"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis Cache para desarrollo
  redis-dev:
    image: redis:7-alpine
    container_name: password-manager-redis-dev
    ports:
      - "6379:6379"
    volumes:
      - redis_dev_data:/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_dev_data:
    driver: local
  redis_dev_data:
    driver: local
EOF

print_success "Configuración Docker Compose creada"

# Verificar si los puertos están disponibles
if port_in_use 5432; then
    print_warning "Puerto 5432 ya está en uso. Verificando si PostgreSQL ya está corriendo..."
    if ! nc -z localhost 5432 2>/dev/null; then
        print_error "Puerto 5432 está ocupado por otro proceso"
        exit 1
    fi
fi

if port_in_use 6379; then
    print_warning "Puerto 6379 ya está en uso. Verificando si Redis ya está corriendo..."
    if ! nc -z localhost 6379 2>/dev/null; then
        print_error "Puerto 6379 está ocupado por otro proceso"
        exit 1
    fi
fi

# Iniciar servicios de base de datos
print_message "Iniciando servicios de base de datos..."
docker-compose -f docker-compose.dev.yml up -d

# Esperar a que los servicios estén disponibles
wait_for_service localhost 5432 "PostgreSQL"
wait_for_service localhost 6379 "Redis"

# Instalar dependencias del backend
print_message "Instalando dependencias del backend..."
cd backend

if [ ! -d "node_modules" ]; then
    npm install
else
    print_message "Dependencias del backend ya están instaladas"
fi

# Ejecutar migraciones
print_message "Ejecutando migraciones de la base de datos..."
npm run migration:run

# Ejecutar seeds si existen
if [ -f "src/seeds/index.ts" ]; then
    print_message "Ejecutando seeds de la base de datos..."
    npm run seed:run
fi

# Volver al directorio raíz
cd ..

# Instalar dependencias del frontend
print_message "Instalando dependencias del frontend..."
cd frontend

if [ ! -d "node_modules" ]; then
    npm install
else
    print_message "Dependencias del frontend ya están instaladas"
fi

# Volver al directorio raíz
cd ..

print_success "Configuración completada!"
print_message "Iniciando aplicaciones en modo desarrollo..."

# Función para ejecutar backend en background
start_backend() {
    print_message "Iniciando backend en puerto 3000..."
    cd backend
    npm run start:dev &
    BACKEND_PID=$!
    cd ..
}

# Función para ejecutar frontend en background
start_frontend() {
    print_message "Iniciando frontend en puerto 5173..."
    cd frontend
    npm run dev &
    FRONTEND_PID=$!
    cd ..
}

# Iniciar aplicaciones
start_backend
start_frontend

# Esperar un momento para que las aplicaciones se inicien
sleep 5

# Verificar que las aplicaciones estén corriendo
if port_in_use 3000; then
    print_success "Backend está corriendo en http://localhost:3000"
    print_message "Swagger UI disponible en http://localhost:3000/api"
else
    print_error "Backend no se inició correctamente"
fi

if port_in_use 5173; then
    print_success "Frontend está corriendo en http://localhost:5173"
else
    print_error "Frontend no se inició correctamente"
fi

print_success "Entorno de desarrollo iniciado exitosamente!"
print_message ""
print_message "Servicios disponibles:"
print_message "  - PostgreSQL: localhost:5432"
print_message "  - Redis: localhost:6379"
print_message "  - Backend API: http://localhost:3000"
print_message "  - Frontend: http://localhost:5173"
print_message "  - Swagger UI: http://localhost:3000/api"
print_message ""
print_message "Para detener el entorno de desarrollo, presiona Ctrl+C"
print_message ""

# Mantener el script corriendo y mostrar logs
print_message "Presiona Ctrl+C para detener todos los servicios..."

# Función para mostrar logs
show_logs() {
    while true; do
        sleep 10
        # Mostrar estado de los servicios
        if port_in_use 3000 && port_in_use 5173; then
            echo -e "${GREEN}[STATUS]${NC} Todos los servicios están corriendo correctamente"
        else
            echo -e "${YELLOW}[STATUS]${NC} Algunos servicios pueden haber fallado"
        fi
    done
}

# Mostrar logs en background
show_logs &
LOGS_PID=$!

# Esperar hasta que se presione Ctrl+C
wait
