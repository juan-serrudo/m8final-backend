#!/bin/bash

# Gestor de Contraseñas Monorepo - Script de Detención
# Este script detiene toda la pila de aplicaciones

set -e

echo "🛑 Deteniendo Gestor de Contraseñas Monorepo..."

# Detener y eliminar contenedores
echo "🐳 Deteniendo servicios Docker..."
docker compose down

# Opcional: Eliminar volúmenes (descomenta si quieres resetear datos)
# echo "🗑️  Eliminando volúmenes..."
# docker compose down -v

# Opcional: Eliminar imágenes (descomenta si quieres limpiar imágenes)
# echo "🧹 Eliminando imágenes..."
# docker compose down --rmi all

echo ""
echo "✅ ¡El Gestor de Contraseñas Monorepo ha sido detenido!"
echo ""
echo "📋 Para iniciar de nuevo:"
echo "   ./deploy/start.sh"
echo ""
echo "🧹 Para limpiar todo (incluyendo datos):"
echo "   docker compose down -v --rmi all"
echo ""
echo "✨ ¡Hasta luego!"