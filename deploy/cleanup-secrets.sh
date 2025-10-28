#!/bin/bash

# Script para limpiar secrets y configs existentes antes del setup
# Uso: ./cleanup-secrets.sh

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo "🧹 Limpiando secrets y configs existentes..."

# Limpiar secrets
print_status "Limpiando secrets..."
secrets=("postgres_password" "db_password")

for secret in "${secrets[@]}"; do
    if docker secret ls | grep -q "$secret"; then
        docker secret rm "$secret"
        print_success "Secret '$secret' eliminado"
    else
        print_warning "Secret '$secret' no encontrado"
    fi
done

# Limpiar configs
print_status "Limpiando configs..."
configs=("nginx_config" "app_config")

for config in "${configs[@]}"; do
    if docker config ls | grep -q "$config"; then
        docker config rm "$config"
        print_success "Config '$config' eliminado"
    else
        print_warning "Config '$config' no encontrado"
    fi
done

print_success "✅ Limpieza de secrets y configs completada!"
print_status "Ahora puedes ejecutar ./setup-swarm.sh sin errores"

