# 🔐 Gestor de Contraseñas - Monorepo

Un sistema seguro de gestión de contraseñas construido con una arquitectura moderna de monorepo, que incluye un backend NestJS, frontend React y despliegue unificado con Docker.

## 📁 Estructura del Proyecto

```
m9final-backend/
├── 📁 apps/                    # Aplicaciones principales
│   ├── backend/               # Backend NestJS
│   └── frontend/              # Frontend React + Vite
├── 📁 config/                 # Configuraciones
│   └── nginx/                 # Configuración Nginx
├── 📁 deploy/                 # Configuración de despliegue
│   ├── compose.release.yml   # Compose para producción
│   ├── docker-compose.yml    # Compose para desarrollo
│   ├── env.example           # Variables de entorno
│   ├── health-check.sh       # Health check
│   ├── start.sh              # Iniciar servicios
│   └── stop.sh               # Detener servicios
├── 📁 docs/                   # Documentación
│   ├── ADMINER.md            # Guía de Adminer
│   ├── DEVELOPMENT.md        # Guía de desarrollo
│   ├── DOCKER.md             # Guía de Docker
│   ├── DOCKERHUB.md          # Guía de Docker Hub
│   ├── MIGRATION_SUMMARY.md  # Resumen de migraciones
│   ├── MONOREPO_SUMMARY.md   # Resumen del monorepo
│   └── README.md             # Documentación principal
├── 📁 scripts/                # Scripts de automatización
│   ├── build_and_push.sh    # Build y push a Docker Hub
│   ├── deploy.sh             # Despliegue en producción
│   ├── dev-start.sh          # Iniciar desarrollo local
│   ├── dev-stop.sh           # Detener desarrollo local
│   ├── docker-start.sh       # Iniciar con Docker
│   ├── example_usage.sh      # Ejemplo de uso completo
│   └── test-dev-setup.sh     # Verificar entorno dev
├── 📁 tools/                  # Herramientas y utilidades
│   └── (archivos de herramientas)
├── package.json               # Configuración del monorepo
└── yarn.lock                  # Lock file de dependencias
```

## 🚀 Inicio Rápido

### Prerrequisitos

- Docker y Docker Compose
- Node.js 20+ (para desarrollo local)
- Git

### 1. Desarrollo Local

```bash
# Iniciar entorno de desarrollo completo
./scripts/dev-start.sh

# Detener entorno de desarrollo
./scripts/dev-stop.sh

# Verificar configuración
./scripts/test-dev-setup.sh
```

### 2. Despliegue con Docker Hub

```bash
# Configurar variables de entorno
export DOCKERHUB_USER=tu_usuario
export DOCKERHUB_TOKEN=tu_token

# Construir y publicar imágenes
./scripts/build_and_push.sh v1

# Desplegar en producción
./scripts/deploy.sh v1
```

### 3. Acceso a la Aplicación

- **Frontend**: http://localhost:8080
- **Backend API**: http://localhost:3000
- **Swagger UI**: http://localhost:3000/api-docs
- **Adminer**: http://localhost:8081
- **Health Check**: http://localhost:8080/health
- **Version Info**: http://localhost:8080/version

## 📚 Documentación

- **[Guía de Desarrollo](docs/DEVELOPMENT.md)** - Desarrollo local completo
- **[Docker Hub](docs/DOCKERHUB.md)** - Build, push y despliegue
- **[Adminer](docs/ADMINER.md)** - Gestión de base de datos
- **[Docker](docs/DOCKER.md)** - Configuración Docker
- **[README Principal](docs/README.md)** - Documentación detallada

## 🛠️ Scripts Disponibles

### Desarrollo
- `./scripts/dev-start.sh` - Iniciar entorno de desarrollo
- `./scripts/dev-stop.sh` - Detener entorno de desarrollo
- `./scripts/test-dev-setup.sh` - Verificar configuración

### Producción
- `./scripts/build_and_push.sh <version>` - Build y push a Docker Hub
- `./scripts/deploy.sh <version>` - Desplegar en producción
- `./scripts/example_usage.sh` - Ejemplo completo de uso

### Utilidades
- `./scripts/docker-start.sh` - Iniciar con Docker Compose

## 🔧 Configuración

### Variables de Entorno

Copia el archivo de ejemplo y configura las variables:

```bash
cp deploy/env.example .env
# Editar .env con tus valores
```

### Archivos de Configuración

- `deploy/env.example` - Variables de entorno
- `deploy/docker-compose.yml` - Desarrollo
- `deploy/compose.release.yml` - Producción
- `config/nginx/nginx.conf` - Proxy reverso

## 🧪 Verificación

```bash
# Health check general
curl http://localhost:8080/health

# Información de versión
curl http://localhost:8080/version

# Estado de servicios
./scripts/deploy.sh v1 status
```

## 🤝 Contribuir

1. Fork del repositorio
2. Crear rama de característica
3. Hacer cambios siguiendo la estructura del proyecto
4. Agregar pruebas
5. Enviar pull request

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT.
