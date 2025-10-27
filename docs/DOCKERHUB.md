# Docker Hub - Build, Push y Despliegue

Este documento describe cómo construir, publicar y desplegar las imágenes de la aplicación Password Manager en Docker Hub.

## 📋 Tabla de Contenidos

- [Preparación de Docker Hub](#preparación-de-docker-hub)
- [Build y Push de Imágenes](#build-y-push-de-imágenes)
- [Despliegue en Producción](#despliegue-en-producción)
- [Verificación del Despliegue](#verificación-del-despliegue)
- [Gestión de Versiones](#gestión-de-versiones)
- [Solución de Problemas](#solución-de-problemas)

## 🐳 Preparación de Docker Hub

### 1. Crear Repositorios

Crea los siguientes repositorios públicos en Docker Hub:

- `m9final-backend`
- `m9final-frontend`

**Pasos:**
1. Ve a [Docker Hub](https://hub.docker.com/)
2. Inicia sesión con tu cuenta
3. Haz clic en "Create Repository"
4. Nombre: `m9final-backend`, Visibilidad: Public
5. Repite para `m9final-frontend`

### 2. Generar Access Token

**Pasos:**
1. Ve a [Account Settings > Security](https://hub.docker.com/settings/security)
2. Haz clic en "New Access Token"
3. Nombre: `m9final-deployment`
4. Permisos: Read, Write, Delete
5. Copia el token generado

### 3. Configurar Variables de Entorno

```bash
# Configurar usuario y token
export DOCKERHUB_USER=tu_usuario
export DOCKERHUB_TOKEN=tu_token_generado

# Opcional: contraseña segura para PostgreSQL
export POSTGRES_PASSWORD=tu_password_seguro
```

**Para hacer permanente:**
```bash
# Agregar al ~/.bashrc o ~/.zshrc
echo 'export DOCKERHUB_USER=tu_usuario' >> ~/.bashrc
echo 'export DOCKERHUB_TOKEN=tu_token_generado' >> ~/.bashrc
echo 'export POSTGRES_PASSWORD=tu_password_seguro' >> ~/.bashrc
source ~/.bashrc
```

## 🚀 Build y Push de Imágenes

### Script de Build y Push

El script `scripts/build_and_push.sh` construye imágenes multi-architectura (AMD64/ARM64) con etiquetas OCI.

#### Uso Básico

```bash
# Construir y publicar versión v1
./scripts/build_and_push.sh v1

# Construir y publicar versión v2
./scripts/build_and_push.sh v2
```

#### Características del Script

- ✅ **Multi-architectura**: AMD64 y ARM64
- ✅ **Etiquetas OCI**: source, revision, date, version
- ✅ **Verificación**: Valida imágenes publicadas
- ✅ **Autenticación**: Login automático a Docker Hub
- ✅ **Builder**: Usa Docker Buildx para multi-arch

#### Imágenes Generadas

Para cada versión se generan:

```bash
# Backend
docker.io/<usuario>/m9final-backend:v1
docker.io/<usuario>/m9final-backend:latest

# Frontend
docker.io/<usuario>/m9final-frontend:v1
docker.io/<usuario>/m9final-frontend:latest
```

#### Etiquetas OCI Incluidas

```yaml
org.opencontainers.image.title: m9final-backend/frontend
org.opencontainers.image.description: Password Manager backend/frontend
org.opencontainers.image.version: v1
org.opencontainers.image.created: 2024-01-15T10:30:00Z
org.opencontainers.image.source: https://github.com/usuario/repo
org.opencontainers.image.revision: abc1234
org.opencontainers.image.vendor: Juan Victor Serrudo
org.opencontainers.image.licenses: MIT
```

## 🎯 Despliegue en Producción

### Script de Despliegue

El script `scripts/deploy.sh` facilita el despliegue usando imágenes pre-construidas.

#### Comandos Disponibles

```bash
# Desplegar versión v1
./scripts/deploy.sh v1

# Desplegar versión v2
./scripts/deploy.sh v2 up

# Detener servicios
./scripts/deploy.sh v1 down

# Ver logs
./scripts/deploy.sh v1 logs

# Ver estado
./scripts/deploy.sh v1 status

# Reiniciar servicios
./scripts/deploy.sh v1 restart
```

### Compose de Release

El archivo `deploy/compose.release.yml` contiene la configuración de producción:

#### Servicios Incluidos

- **PostgreSQL**: Base de datos principal
- **Redis**: Cache y sesiones
- **Adminer**: Gestión web de BD
- **Backend**: API NestJS (imagen Docker Hub)
- **Frontend**: React + Vite (imagen Docker Hub)
- **Nginx**: Proxy reverso

#### Variables de Entorno

```bash
# Requeridas
VERSION=v1                    # Versión a desplegar
DOCKERHUB_USER=tu_usuario     # Usuario Docker Hub

# Opcionales
POSTGRES_PASSWORD=password123  # Contraseña PostgreSQL
BUILD_DATE=2024-01-15T10:30:00Z  # Fecha de build
```

#### Uso Manual

```bash
# Configurar variables
export VERSION=v1
export DOCKERHUB_USER=tu_usuario
export POSTGRES_PASSWORD=tu_password_seguro

# Desplegar
docker-compose -f deploy/compose.release.yml up -d

# Ver estado
docker-compose -f deploy/compose.release.yml ps

# Ver logs
docker-compose -f deploy/compose.release.yml logs -f

# Detener
docker-compose -f deploy/compose.release.yml down
```

## ✅ Verificación del Despliegue

### Endpoints de Verificación

Una vez desplegado, verifica que todo funcione:

```bash
# Health check general
curl http://localhost:8080/health

# Información de versión
curl http://localhost:8080/version

# Health check de base de datos
curl http://localhost:8080/health/db

# Health check de Redis
curl http://localhost:8080/health/redis

# Acceso al frontend
curl http://localhost:8080/

# Swagger UI
curl http://localhost:8080/api

# Adminer
curl http://localhost:8081
```

### Respuesta Esperada

#### Health Check
```json
{
  "status": "ok",
  "message": "Sistema funcionando correctamente",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "uptime": 123.456
}
```

#### Version Info
```json
{
  "name": "password-manager",
  "version": "0.0.1",
  "description": "Bienvenido al Gestor de Contraseñas",
  "author": "Juan Victor Serrudo Chavez",
  "license": "MIT",
  "build": {
    "version": "v1",
    "date": "2024-01-15T10:30:00Z",
    "node": "v18.17.0",
    "platform": "linux",
    "arch": "x64"
  },
  "environment": {
    "nodeEnv": "production",
    "entorno": "production"
  },
  "timestamp": "2024-01-15T10:30:00.000Z",
  "uptime": 123.456
}
```

## 🔄 Gestión de Versiones

### Cambiar de Versión

```bash
# Desplegar nueva versión
./scripts/deploy.sh v2

# Verificar nueva versión
curl http://localhost:8080/version

# Si hay problemas, volver a versión anterior
./scripts/deploy.sh v1
```

### Rollback

```bash
# Detener versión actual
./scripts/deploy.sh v2 down

# Desplegar versión anterior
./scripts/deploy.sh v1 up
```

### Actualización de Imágenes

```bash
# Construir nueva versión
./scripts/build_and_push.sh v3

# Desplegar nueva versión
./scripts/deploy.sh v3
```

## 🐛 Solución de Problemas

### Problemas Comunes

#### 1. Error de Autenticación Docker Hub

```bash
# Verificar variables
echo $DOCKERHUB_USER
echo $DOCKERHUB_TOKEN

# Login manual
echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USER" --password-stdin
```

#### 2. Imagen No Encontrada

```bash
# Verificar que la imagen existe
docker manifest inspect $DOCKERHUB_USER/m9final-backend:v1

# Si no existe, construir y publicar
./scripts/build_and_push.sh v1
```

#### 3. Puerto Ocupado

```bash
# Verificar puertos
lsof -i :8080
lsof -i :8081

# Detener servicios anteriores
docker-compose -f deploy/compose.release.yml down
```

#### 4. Problemas de Salud

```bash
# Ver logs de servicios
./scripts/deploy.sh v1 logs

# Verificar estado
./scripts/deploy.sh v1 status

# Reiniciar servicios
./scripts/deploy.sh v1 restart
```

### Logs Útiles

```bash
# Logs de todos los servicios
docker-compose -f deploy/compose.release.yml logs

# Logs de servicio específico
docker-compose -f deploy/compose.release.yml logs app
docker-compose -f deploy/compose.release.yml logs frontend
docker-compose -f deploy/compose.release.yml logs nginx

# Logs en tiempo real
docker-compose -f deploy/compose.release.yml logs -f
```

### Limpieza

```bash
# Detener y eliminar contenedores
docker-compose -f deploy/compose.release.yml down

# Eliminar volúmenes (¡CUIDADO! Elimina datos)
docker-compose -f deploy/compose.release.yml down -v

# Limpiar imágenes no utilizadas
docker image prune -f

# Limpiar todo (¡CUIDADO!)
docker system prune -af
```

## 📊 Monitoreo

### Métricas Básicas

```bash
# Uso de recursos
docker stats

# Espacio en disco
docker system df

# Volúmenes
docker volume ls
```

### Health Checks

Los servicios incluyen health checks automáticos:

- **PostgreSQL**: `pg_isready`
- **Redis**: `redis-cli ping`
- **Backend**: HTTP GET `/health`
- **Frontend**: HTTP GET `/health`
- **Nginx**: HTTP GET `/health`
- **Adminer**: HTTP GET `/`

## 🔒 Seguridad

### Consideraciones de Producción

1. **Contraseñas**: Usa contraseñas seguras para PostgreSQL
2. **Red**: Limita acceso a puertos sensibles
3. **Imágenes**: Usa imágenes oficiales y actualizadas
4. **Volúmenes**: Configura backups de datos
5. **Logs**: Monitorea logs por seguridad

### Configuración Segura

```bash
# Contraseña segura
export POSTGRES_PASSWORD=$(openssl rand -base64 32)

# Variables de entorno en archivo
cat > .env.production << EOF
VERSION=v1
DOCKERHUB_USER=tu_usuario
POSTGRES_PASSWORD=password_muy_seguro
EOF

# Usar archivo de entorno
docker-compose -f deploy/compose.release.yml --env-file .env.production up -d
```

---

**Nota**: Este sistema está diseñado para facilitar el despliegue y gestión de versiones. Siempre prueba en un entorno de desarrollo antes de desplegar en producción.
