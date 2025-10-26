#!/bin/bash

# ===========================================
# Script de Prueba para Entorno de Desarrollo
# ===========================================
# Este script verifica que el entorno de desarrollo esté funcionando correctamente

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

# Función para verificar si un puerto está en uso
port_in_use() {
    lsof -i :$1 >/dev/null 2>&1
}

# Función para hacer una petición HTTP
test_endpoint() {
    local url=$1
    local expected_status=$2
    local service_name=$3
    
    print_message "Probando $service_name en $url..."
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "$expected_status"; then
        print_success "$service_name responde correctamente"
        return 0
    else
        print_error "$service_name no responde correctamente"
        return 1
    fi
}

print_message "Iniciando pruebas del entorno de desarrollo..."

# Verificar que los archivos necesarios existan
if [ ! -f "dev-start.sh" ]; then
    print_error "Archivo dev-start.sh no encontrado"
    exit 1
fi

if [ ! -f "dev-stop.sh" ]; then
    print_error "Archivo dev-stop.sh no encontrado"
    exit 1
fi

if [ ! -f "docker-compose.dev.yml" ]; then
    print_error "Archivo docker-compose.dev.yml no encontrado"
    exit 1
fi

print_success "Archivos de desarrollo encontrados"

# Verificar dependencias
print_message "Verificando dependencias..."

if ! command -v docker >/dev/null 2>&1; then
    print_error "Docker no está instalado"
    exit 1
fi

if ! command -v docker-compose >/dev/null 2>&1; then
    print_error "Docker Compose no está instalado"
    exit 1
fi

if ! command -v node >/dev/null 2>&1; then
    print_error "Node.js no está instalado"
    exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
    print_error "npm no está instalado"
    exit 1
fi

print_success "Todas las dependencias están instaladas"

# Verificar que los scripts sean ejecutables
if [ ! -x "dev-start.sh" ]; then
    print_warning "Haciendo dev-start.sh ejecutable..."
    chmod +x dev-start.sh
fi

if [ ! -x "dev-stop.sh" ]; then
    print_warning "Haciendo dev-stop.sh ejecutable..."
    chmod +x dev-stop.sh
fi

print_success "Scripts de desarrollo están ejecutables"

# Verificar estructura del proyecto
if [ ! -d "backend" ]; then
    print_error "Directorio backend no encontrado"
    exit 1
fi

if [ ! -d "frontend" ]; then
    print_error "Directorio frontend no encontrado"
    exit 1
fi

if [ ! -f "backend/package.json" ]; then
    print_error "package.json del backend no encontrado"
    exit 1
fi

if [ ! -f "frontend/package.json" ]; then
    print_error "package.json del frontend no encontrado"
    exit 1
fi

print_success "Estructura del proyecto es correcta"

# Verificar configuración de Docker Compose
print_message "Verificando configuración de Docker Compose..."
if docker-compose -f docker-compose.dev.yml config >/dev/null 2>&1; then
    print_success "Configuración de Docker Compose es válida"
else
    print_error "Configuración de Docker Compose tiene errores"
    exit 1
fi

print_success "Todas las pruebas básicas pasaron!"
print_message ""
print_message "El entorno de desarrollo está listo para usar."
print_message "Para iniciar el entorno de desarrollo, ejecuta:"
print_message "  ./dev-start.sh"
print_message ""
print_message "Para detener el entorno de desarrollo, ejecuta:"
print_message "  ./dev-stop.sh"
print_message ""
print_message "Para más información, consulta DEVELOPMENT.md"
