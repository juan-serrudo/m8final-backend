#!/bin/bash

# Gestor de Contraseñas Monorepo - Script de Inicio
# Este script inicia toda la pila de aplicaciones

set -e

echo "🚀 Iniciando Gestor de Contraseñas Monorepo..."

# Verificar si Docker está ejecutándose
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker no está ejecutándose. Por favor inicia Docker e intenta de nuevo."
    exit 1
fi

# Verificar si docker-compose está disponible
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose no está instalado. Por favor instala docker-compose e intenta de nuevo."
    exit 1
fi

# Crear archivo .env si no existe
if [ ! -f .env ]; then
    echo "📝 Creando archivo .env desde env.example..."
    cp env.example .env
    echo "✅ Archivo .env creado. Por favor revisa y actualiza la configuración si es necesario."
fi

# Crear directorios necesarios
echo "📁 Creando directorios necesarios..."
mkdir -p backend/data
mkdir -p deploy/logs

# Iniciar los servicios
echo "🐳 Iniciando servicios Docker..."
docker-compose up -d

# Esperar a que los servicios estén listos
echo "⏳ Esperando a que los servicios estén listos..."
sleep 10

# Verificar salud de los servicios
echo "🔍 Verificando salud de los servicios..."

# Verificar salud del backend
if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    echo "✅ Backend está saludable"
else
    echo "⚠️  La verificación de salud del backend falló, pero el servicio podría estar iniciándose..."
fi

# Verificar salud del frontend
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo "✅ Frontend está saludable"
else
    echo "⚠️  La verificación de salud del frontend falló, pero el servicio podría estar iniciándose..."
fi

# Verificar proxy nginx
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ Proxy Nginx está saludable"
else
    echo "⚠️  La verificación de salud del proxy nginx falló, pero el servicio podría estar iniciándose..."
fi

echo ""
echo "🎉 ¡El Gestor de Contraseñas Monorepo está iniciándose!"
echo ""
echo "📋 URLs de Servicios:"
echo "   🌐 Frontend (vía Nginx): http://localhost:8080"
echo "   🔧 Backend API: http://localhost:3000"
echo "   📚 Documentación API: http://localhost:3000/api-docs"
echo "   🏥 Verificación de Salud: http://localhost:8080/health"
echo ""
echo "📊 Para ver logs:"
echo "   docker-compose logs -f"
echo ""
echo "🛑 Para detener servicios:"
echo "   docker-compose down"
echo ""
echo "✨ ¡Feliz programación!"