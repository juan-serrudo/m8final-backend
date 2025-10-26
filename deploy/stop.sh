#!/bin/bash

# Password Manager Monorepo - Stop Script
# This script stops the entire application stack

set -e

echo "🛑 Stopping Password Manager Monorepo..."

# Stop and remove containers
echo "🐳 Stopping Docker services..."
docker-compose down

# Optional: Remove volumes (uncomment if you want to reset data)
# echo "🗑️  Removing volumes..."
# docker-compose down -v

# Optional: Remove images (uncomment if you want to clean up images)
# echo "🧹 Removing images..."
# docker-compose down --rmi all

echo ""
echo "✅ Password Manager Monorepo has been stopped!"
echo ""
echo "📋 To start again:"
echo "   ./deploy/start.sh"
echo ""
echo "🧹 To clean up everything (including data):"
echo "   docker-compose down -v --rmi all"
echo ""
echo "✨ Goodbye!"
