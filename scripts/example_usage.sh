#!/bin/bash

# ===========================================
# Ejemplo de Uso Completo - Docker Hub
# ===========================================
# Este script demuestra el flujo completo de build,
# push y despliegue usando Docker Hub

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

print_message "=== EJEMPLO DE USO COMPLETO - DOCKER HUB ==="
print_message ""

# Verificar que estamos en el directorio correcto
if [ ! -f "scripts/build_and_push.sh" ]; then
    print_error "Este script debe ejecutarse desde el directorio raíz del proyecto"
    exit 1
fi

print_message "Paso 1: Configurar variables de entorno"
print_message "Ejecuta los siguientes comandos antes de continuar:"
print_message ""
print_message "export DOCKERHUB_USER=tu_usuario"
print_message "export DOCKERHUB_TOKEN=tu_token"
print_message "export POSTGRES_PASSWORD=tu_password_seguro"
print_message ""

read -p "¿Has configurado las variables de entorno? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Configura las variables de entorno y ejecuta este script nuevamente"
    exit 1
fi

# Verificar variables
if [ -z "$DOCKERHUB_USER" ]; then
    print_error "DOCKERHUB_USER no está configurado"
    exit 1
fi

if [ -z "$DOCKERHUB_TOKEN" ]; then
    print_error "DOCKERHUB_TOKEN no está configurado"
    exit 1
fi

print_success "Variables de entorno configuradas correctamente"
print_message ""

print_message "Paso 2: Construir y publicar versión v1"
print_message "Ejecutando: ./scripts/build_and_push.sh v1"
print_message ""

read -p "¿Continuar con el build y push de v1? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./scripts/build_and_push.sh v1
    
    if [ $? -eq 0 ]; then
        print_success "Build y push de v1 completado exitosamente"
    else
        print_error "Error en build y push de v1"
        exit 1
    fi
else
    print_warning "Saltando build y push de v1"
fi

print_message ""
print_message "Paso 3: Desplegar versión v1"
print_message "Ejecutando: ./scripts/deploy.sh v1"
print_message ""

read -p "¿Continuar con el despliegue de v1? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./scripts/deploy.sh v1
    
    if [ $? -eq 0 ]; then
        print_success "Despliegue de v1 completado exitosamente"
    else
        print_error "Error en despliegue de v1"
        exit 1
    fi
else
    print_warning "Saltando despliegue de v1"
fi

print_message ""
print_message "Paso 4: Verificar despliegue"
print_message "Probando endpoints..."

# Esperar un momento para que los servicios se inicien
sleep 5

# Verificar health check
if curl -s http://localhost:8080/health >/dev/null 2>&1; then
    print_success "Health check: OK"
else
    print_warning "Health check: No disponible aún"
fi

# Verificar version endpoint
if curl -s http://localhost:8080/version >/dev/null 2>&1; then
    print_success "Version endpoint: OK"
    print_message "Información de versión:"
    curl -s http://localhost:8080/version | jq '.' 2>/dev/null || curl -s http://localhost:8080/version
else
    print_warning "Version endpoint: No disponible aún"
fi

print_message ""
print_message "Paso 5: Construir y publicar versión v2"
print_message "Ejecutando: ./scripts/build_and_push.sh v2"
print_message ""

read -p "¿Continuar con el build y push de v2? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./scripts/build_and_push.sh v2
    
    if [ $? -eq 0 ]; then
        print_success "Build y push de v2 completado exitosamente"
    else
        print_error "Error en build y push de v2"
        exit 1
    fi
else
    print_warning "Saltando build y push de v2"
fi

print_message ""
print_message "Paso 6: Actualizar a versión v2"
print_message "Ejecutando: ./scripts/deploy.sh v2"
print_message ""

read -p "¿Continuar con el despliegue de v2? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./scripts/deploy.sh v2
    
    if [ $? -eq 0 ]; then
        print_success "Actualización a v2 completada exitosamente"
    else
        print_error "Error en actualización a v2"
        exit 1
    fi
else
    print_warning "Saltando actualización a v2"
fi

print_message ""
print_message "Paso 7: Verificar actualización"
print_message "Probando endpoints..."

# Esperar un momento para que los servicios se actualicen
sleep 5

# Verificar version endpoint
if curl -s http://localhost:8080/version >/dev/null 2>&1; then
    print_success "Version endpoint: OK"
    print_message "Información de versión actualizada:"
    curl -s http://localhost:8080/version | jq '.' 2>/dev/null || curl -s http://localhost:8080/version
else
    print_warning "Version endpoint: No disponible"
fi

print_message ""
print_success "=== EJEMPLO COMPLETADO ==="
print_message ""
print_message "Servicios disponibles:"
print_message "  - Aplicación: http://localhost:8080"
print_message "  - Health Check: http://localhost:8080/health"
print_message "  - Version Info: http://localhost:8080/version"
print_message "  - Swagger UI: http://localhost:8080/api"
print_message "  - Adminer: http://localhost:8081"
print_message ""
print_message "Comandos útiles:"
print_message "  - Ver estado: ./scripts/deploy.sh v2 status"
print_message "  - Ver logs: ./scripts/deploy.sh v2 logs"
print_message "  - Detener: ./scripts/deploy.sh v2 down"
print_message "  - Rollback: ./scripts/deploy.sh v1"
print_message ""
print_message "Para más información:"
print_message "  - Docker Hub: cat DOCKERHUB.md"
print_message "  - Desarrollo: cat DEVELOPMENT.md"
print_message "  - Adminer: cat ADMINER.md"
