#!/bin/bash

# ===========================================
# Script de Build y Push a Docker Hub
# ===========================================
# Este script construye y publica imágenes multi-architectura
# para backend y frontend con etiquetas OCI

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

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 <version>"
    echo ""
    echo "Argumentos:"
    echo "  version    Versión a construir y publicar (Ejemplo: v1, v2)"
    echo ""
    echo "Variables de entorno requeridas:"
    echo "  DOCKERHUB_USER    Usuario de Docker Hub"
    echo "  DOCKERHUB_TOKEN   Token de acceso de Docker Hub"
    echo ""
    echo "Ejemplos:"
    echo "  $0 v1"
    echo "  $0 v2"
    echo ""
    echo "Antes de ejecutar:"
    echo "  1. Crear repositorios en Docker Hub:"
    echo "     - <usuario>/m9final-backend"
    echo "     - <usuario>/m9final-frontend"
    echo "  2. Generar Access Token en Docker Hub"
    echo "  3. Configurar variables de entorno:"
    echo "     export DOCKERHUB_USER=tu_usuario"
    echo "     export DOCKERHUB_TOKEN=tu_token"
}

# Verificar argumentos
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

VERSION=$1

# Validar formato de versión
if [[ ! $VERSION =~ ^v[0-9]+$ ]]; then
    print_error "Formato de versión inválido. Use: v1, v2, v3, etc."
    exit 1
fi

print_message "Iniciando build y push para versión: $VERSION"

# Verificar variables de entorno
if [ -z "$DOCKERHUB_USER" ]; then
    print_error "DOCKERHUB_USER no está definido"
    print_message "Ejecuta: export DOCKERHUB_USER=tu_usuario"
    exit 1
fi

if [ -z "$DOCKERHUB_TOKEN" ]; then
    print_error "DOCKERHUB_TOKEN no está definido"
    print_message "Ejecuta: export DOCKERHUB_TOKEN=tu_token"
    exit 1
fi

# Verificar dependencias
print_message "Verificando dependencias..."

if ! command -v docker >/dev/null 2>&1; then
    print_error "Docker no está instalado"
    exit 1
fi

if ! command -v docker buildx >/dev/null 2>&1; then
    print_error "Docker Buildx no está disponible"
    print_message "Instala Docker Buildx o actualiza Docker"
    exit 1
fi

print_success "Dependencias verificadas"

# Login a Docker Hub
print_message "Autenticando en Docker Hub..."
echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USER" --password-stdin

if [ $? -eq 0 ]; then
    print_success "Autenticación exitosa en Docker Hub"
else
    print_error "Error en la autenticación de Docker Hub"
    exit 1
fi

# Crear builder multi-arch si no existe
BUILDER_NAME="m9final-builder"
print_message "Configurando builder multi-architectura..."

if ! docker buildx inspect "$BUILDER_NAME" >/dev/null 2>&1; then
    print_message "Creando builder: $BUILDER_NAME"
    docker buildx create --name "$BUILDER_NAME" --use
else
    print_message "Usando builder existente: $BUILDER_NAME"
    docker buildx use "$BUILDER_NAME"
fi

# Verificar que el builder soporte multi-arch
docker buildx inspect --bootstrap

# Obtener información del repositorio
REPO_URL=$(git config --get remote.origin.url 2>/dev/null || echo "local")
COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

print_message "Información del build:"
print_message "  Repositorio: $REPO_URL"
print_message "  Commit: $COMMIT_HASH"
print_message "  Fecha: $BUILD_DATE"
print_message "  Versión: $VERSION"

# Función para construir y publicar imagen
build_and_push() {
    local service=$1
    local dockerfile=$2
    local context=$3
    local image_name="$DOCKERHUB_USER/m9final-$service"

    print_message "Construyendo y publicando: $image_name:$VERSION"

    # Etiquetas OCI
    local labels=(
        "--label" "org.opencontainers.image.title=m9final-$service"
        "--label" "org.opencontainers.image.description=Password Manager $service"
        "--label" "org.opencontainers.image.version=$VERSION"
        "--label" "org.opencontainers.image.created=$BUILD_DATE"
        "--label" "org.opencontainers.image.source=$REPO_URL"
        "--label" "org.opencontainers.image.revision=$COMMIT_HASH"
        "--label" "org.opencontainers.image.vendor=Juan Victor Serrudo"
        "--label" "org.opencontainers.image.licenses=MIT"
    )

    # Construir y publicar multi-arch
    docker buildx build \
        --platform linux/amd64,linux/arm64 \
        --file "$dockerfile" \
        --tag "$image_name:$VERSION" \
        --tag "$image_name:latest" \
        "${labels[@]}" \
        --push \
        "$context"

    if [ $? -eq 0 ]; then
        print_success "Imagen publicada: $image_name:$VERSION"
        print_message "  Plataformas: linux/amd64, linux/arm64"
        print_message "  Etiquetas: $VERSION, latest"
    else
        print_error "Error al publicar: $image_name:$VERSION"
        return 1
    fi
}

# Construir backend
print_message "=== CONSTRUYENDO BACKEND ==="
build_and_push "backend" "apps/backend/Dockerfile" "apps/backend/"

# Construir frontend
print_message "=== CONSTRUYENDO FRONTEND ==="
build_and_push "frontend" "apps/frontend/Dockerfile" "apps/frontend/"

# Verificar imágenes publicadas
print_message "=== VERIFICANDO IMÁGENES PUBLICADAS ==="

# Función para verificar imagen
verify_image() {
    local service=$1
    local image_name="$DOCKERHUB_USER/m9final-$service"

    print_message "Verificando: $image_name:$VERSION"

    # Obtener manifest
    if docker manifest inspect "$image_name:$VERSION" >/dev/null 2>&1; then
        print_success "Imagen verificada: $image_name:$VERSION"

        # Mostrar información del manifest
        local manifest_info=$(docker manifest inspect "$image_name:$VERSION" 2>/dev/null)
        if [ $? -eq 0 ]; then
            local platforms=$(echo "$manifest_info" | jq -r '.manifests[].platform | "\(.os)/\(.architecture)"' 2>/dev/null || echo "N/A")
            print_message "  Plataformas disponibles: $platforms"
        fi
    else
        print_error "No se pudo verificar: $image_name:$VERSION"
        return 1
    fi
}

verify_image "backend"
verify_image "frontend"

# Mostrar URLs de las imágenes
print_success "=== BUILD Y PUSH COMPLETADO ==="
print_message ""
print_message "Imágenes publicadas:"
print_message "  Backend:  docker.io/$DOCKERHUB_USER/m9final-backend:$VERSION"
print_message "  Frontend: docker.io/$DOCKERHUB_USER/m9final-frontend:$VERSION"
print_message ""
print_message "Para desplegar con estas imágenes:"
print_message "  export VERSION=$VERSION"
print_message "  export DOCKERHUB_USER=$DOCKERHUB_USER"
print_message "  docker-compose -f deploy/compose.release.yml up -d"
print_message ""
print_message "Para verificar el despliegue:"
print_message "  curl http://localhost:8080/health"
print_message "  curl http://localhost:8080/version"
print_message "  curl http://localhost:8080/"

# Logout de Docker Hub
print_message "Cerrando sesión de Docker Hub..."
docker logout

print_success "Proceso completado exitosamente!"
