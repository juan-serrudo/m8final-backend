#!/bin/bash

# ===========================================
# Script para Detener Entorno de Desarrollo
# ===========================================
# Este script detiene todos los servicios del entorno de desarrollo

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

print_message "Deteniendo entorno de desarrollo..."

# Detener contenedores de desarrollo
if [ -f "docker-compose.dev.yml" ]; then
    print_message "Deteniendo contenedores Docker..."
    docker-compose -f docker-compose.dev.yml down
    print_success "Contenedores Docker detenidos"
else
    print_warning "Archivo docker-compose.dev.yml no encontrado"
fi

# Detener procesos de Node.js
print_message "Deteniendo procesos de Node.js..."

# Detener backend (puerto 3000)
if lsof -i :3000 >/dev/null 2>&1; then
    print_message "Deteniendo backend en puerto 3000..."
    lsof -ti :3000 | xargs kill -9 2>/dev/null || true
    print_success "Backend detenido"
fi

# Detener frontend (puerto 5173)
if lsof -i :5173 >/dev/null 2>&1; then
    print_message "Deteniendo frontend en puerto 5173..."
    lsof -ti :5173 | xargs kill -9 2>/dev/null || true
    print_success "Frontend detenido"
fi

# Detener cualquier proceso npm/node relacionado con el proyecto
print_message "Deteniendo procesos npm/node del proyecto..."
pkill -f "nest start --watch" 2>/dev/null || true
pkill -f "vite" 2>/dev/null || true

print_success "Entorno de desarrollo detenido completamente"
print_message ""
print_message "Para limpiar completamente los datos de desarrollo:"
print_message "  docker-compose -f docker-compose.dev.yml down -v"
print_message "  docker volume rm password-manager_postgres_dev_data password-manager_redis_dev_data"
print_message ""
