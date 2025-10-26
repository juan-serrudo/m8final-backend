#!/bin/bash

# ===========================================
# Script de Verificación Post-Reorganización
# ===========================================
# Este script verifica que la reorganización del proyecto
# se haya realizado correctamente

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

print_message "=== VERIFICACIÓN POST-REORGANIZACIÓN ==="
print_message ""

# Verificar estructura de directorios
print_message "1. Verificando estructura de directorios..."

# Directorios principales
REQUIRED_DIRS=("apps" "config" "deploy" "docs" "scripts")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        print_success "Directorio $dir existe"
    else
        print_error "Directorio $dir no existe"
        exit 1
    fi
done

# Subdirectorios
if [ -d "apps/backend" ]; then
    print_success "apps/backend existe"
else
    print_error "apps/backend no existe"
    exit 1
fi

if [ -d "apps/frontend" ]; then
    print_success "apps/frontend existe"
else
    print_error "apps/frontend no existe"
    exit 1
fi

if [ -d "config/nginx" ]; then
    print_success "config/nginx existe"
else
    print_error "config/nginx no existe"
    exit 1
fi

print_message ""
print_message "2. Verificando archivos críticos..."

# Archivos de configuración
REQUIRED_FILES=(
    "deploy/docker-compose.yml"
    "deploy/compose.release.yml"
    "deploy/env.example"
    "config/nginx/nginx.conf"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "Archivo $file existe"
    else
        print_error "Archivo $file no existe"
        exit 1
    fi
done

# Scripts principales
REQUIRED_SCRIPTS=(
    "scripts/dev-start.sh"
    "scripts/dev-stop.sh"
    "scripts/build_and_push.sh"
    "scripts/deploy.sh"
    "scripts/test-dev-setup.sh"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        print_success "Script $script existe"
        if [ -x "$script" ]; then
            print_success "Script $script es ejecutable"
        else
            print_warning "Script $script no es ejecutable"
        fi
    else
        print_error "Script $script no existe"
        exit 1
    fi
done

print_message ""
print_message "3. Verificando referencias en scripts..."

# Verificar que los scripts usen las rutas correctas
print_message "Verificando scripts/dev-start.sh..."
if grep -q "apps/backend" scripts/dev-start.sh; then
    print_success "dev-start.sh usa apps/backend"
else
    print_error "dev-start.sh no usa apps/backend"
fi

if grep -q "apps/frontend" scripts/dev-start.sh; then
    print_success "dev-start.sh usa apps/frontend"
else
    print_error "dev-start.sh no usa apps/frontend"
fi

print_message "Verificando scripts/build_and_push.sh..."
if grep -q "apps/backend/Dockerfile" scripts/build_and_push.sh; then
    print_success "build_and_push.sh usa apps/backend/Dockerfile"
else
    print_error "build_and_push.sh no usa apps/backend/Dockerfile"
fi

if grep -q "apps/frontend/Dockerfile" scripts/build_and_push.sh; then
    print_success "build_and_push.sh usa apps/frontend/Dockerfile"
else
    print_error "build_and_push.sh no usa apps/frontend/Dockerfile"
fi

print_message ""
print_message "4. Verificando configuración Docker..."

# Verificar docker-compose
if grep -q "apps/backend" deploy/docker-compose.yml; then
    print_success "docker-compose.yml usa apps/backend"
else
    print_error "docker-compose.yml no usa apps/backend"
fi

if grep -q "apps/frontend" deploy/docker-compose.yml; then
    print_success "docker-compose.yml usa apps/frontend"
else
    print_error "docker-compose.yml no usa apps/frontend"
fi

if grep -q "config/nginx/nginx.conf" deploy/docker-compose.yml; then
    print_success "docker-compose.yml usa config/nginx/nginx.conf"
else
    print_error "docker-compose.yml no usa config/nginx/nginx.conf"
fi

print_message ""
print_message "5. Verificando documentación..."

# Verificar que la documentación esté en docs/
if [ -f "docs/README.md" ]; then
    print_success "docs/README.md existe"
else
    print_error "docs/README.md no existe"
fi

if [ -f "docs/DEVELOPMENT.md" ]; then
    print_success "docs/DEVELOPMENT.md existe"
else
    print_error "docs/DEVELOPMENT.md no existe"
fi

if [ -f "docs/DOCKERHUB.md" ]; then
    print_success "docs/DOCKERHUB.md existe"
else
    print_error "docs/DOCKERHUB.md no existe"
fi

print_message ""
print_message "6. Verificando que no queden archivos en raíz..."

# Verificar que no queden archivos .sh en raíz
if ls *.sh 2>/dev/null; then
    print_warning "Aún hay archivos .sh en la raíz:"
    ls *.sh
else
    print_success "No hay archivos .sh en la raíz"
fi

# Verificar que no queden archivos .md en raíz (excepto README.md)
MD_FILES=$(ls *.md 2>/dev/null | grep -v README.md || true)
if [ -n "$MD_FILES" ]; then
    print_warning "Aún hay archivos .md en la raíz (excepto README.md):"
    echo "$MD_FILES"
else
    print_success "Solo README.md está en la raíz (correcto)"
fi

print_message ""
print_message "7. Verificando aplicaciones..."

# Verificar package.json de aplicaciones
if [ -f "apps/backend/package.json" ]; then
    print_success "apps/backend/package.json existe"
else
    print_error "apps/backend/package.json no existe"
fi

if [ -f "apps/frontend/package.json" ]; then
    print_success "apps/frontend/package.json existe"
else
    print_error "apps/frontend/package.json no existe"
fi

# Verificar Dockerfiles
if [ -f "apps/backend/Dockerfile" ]; then
    print_success "apps/backend/Dockerfile existe"
else
    print_error "apps/backend/Dockerfile no existe"
fi

if [ -f "apps/frontend/Dockerfile" ]; then
    print_success "apps/frontend/Dockerfile existe"
else
    print_error "apps/frontend/Dockerfile no existe"
fi

print_message ""
print_success "=== VERIFICACIÓN COMPLETADA ==="
print_message ""
print_message "Estructura del proyecto verificada:"
print_message "  📁 apps/backend/     - Backend NestJS"
print_message "  📁 apps/frontend/    - Frontend React"
print_message "  📁 config/nginx/     - Configuración Nginx"
print_message "  📁 deploy/           - Configuración despliegue"
print_message "  📁 docs/             - Documentación"
print_message "  📁 scripts/          - Scripts automatización"
print_message ""
print_message "Para probar la nueva estructura:"
print_message "  ./scripts/test-dev-setup.sh"
print_message "  ./scripts/dev-start.sh"
print_message ""
print_message "¡Reorganización exitosa! 🎉"
