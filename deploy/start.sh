#!/bin/bash

# Password Manager Monorepo - Start Script
# This script starts the entire application stack

set -e

echo "🚀 Starting Password Manager Monorepo..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose is not installed. Please install docker-compose and try again."
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from env.example..."
    cp env.example .env
    echo "✅ .env file created. Please review and update the configuration if needed."
fi

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p backend/data
mkdir -p deploy/logs

# Start the services
echo "🐳 Starting Docker services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check service health
echo "🔍 Checking service health..."

# Check backend health
if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    echo "✅ Backend is healthy"
else
    echo "⚠️  Backend health check failed, but service might still be starting..."
fi

# Check frontend health
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo "✅ Frontend is healthy"
else
    echo "⚠️  Frontend health check failed, but service might still be starting..."
fi

# Check nginx proxy
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ Nginx proxy is healthy"
else
    echo "⚠️  Nginx proxy health check failed, but service might still be starting..."
fi

echo ""
echo "🎉 Password Manager Monorepo is starting up!"
echo ""
echo "📋 Service URLs:"
echo "   🌐 Frontend (via Nginx): http://localhost:8080"
echo "   🔧 Backend API: http://localhost:3000"
echo "   📚 API Documentation: http://localhost:3000/api-docs"
echo "   🏥 Health Check: http://localhost:8080/health"
echo ""
echo "📊 To view logs:"
echo "   docker-compose logs -f"
echo ""
echo "🛑 To stop services:"
echo "   docker-compose down"
echo ""
echo "✨ Happy coding!"
