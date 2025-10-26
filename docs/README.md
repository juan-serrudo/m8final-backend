# 🔐 Gestor de Contraseñas - Monorepo

Un sistema seguro de gestión de contraseñas construido con una arquitectura moderna de monorepo, que incluye un backend NestJS, frontend React y despliegue unificado con Docker.

## 📁 Estructura del Proyecto

```
m8final-backend/
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

### 1. Clonar y Configurar

```bash
# Clonar el repositorio
git clone <url-del-repositorio>
cd m8final-backend

# Copiar configuración de entorno
cp env.example .env

# Revisar y actualizar el archivo .env si es necesario
```

### 2. Iniciar la Aplicación

```bash
# Hacer ejecutables los scripts
chmod +x deploy/*.sh

# Iniciar todos los servicios
./deploy/start.sh
```

### 3. Acceder a la Aplicación

- **Frontend**: http://localhost:8080
- **Backend API**: http://localhost:3000
- **Documentación API**: http://localhost:3000/api-docs
- **Verificación de Salud**: http://localhost:8080/health

## 🛠️ Desarrollo

### Desarrollo del Backend

```bash
cd apps/backend

# Instalar dependencias
npm install

# Iniciar en modo desarrollo
npm run start:dev

# Ejecutar pruebas
npm run test

# Ejecutar migraciones
npm run migration:run
```

### Desarrollo del Frontend

```bash
cd apps/frontend

# Instalar dependencias
npm install

# Iniciar servidor de desarrollo
npm run dev

# Ejecutar pruebas
npm run test

# Construir para producción
npm run build
```

### Desarrollo Full Stack

Para desarrollo full-stack con recarga automática:

```bash
# Terminal 1: Backend
cd apps/backend && npm run start:dev

# Terminal 2: Frontend
cd apps/frontend && npm run dev

# Terminal 3: Base de datos (opcional, si no se usa Docker)
# Iniciar PostgreSQL y Redis localmente
```

## 🐳 Servicios Docker

La aplicación consta de los siguientes servicios:

### Servicios Principales

- **postgres**: Base de datos PostgreSQL 16
- **redis**: Cache Redis 7
- **app**: API Backend NestJS
- **frontend**: Frontend React + Vite
- **nginx**: Proxy inverso y balanceador de carga

### Puertos de Servicio

- **80**: Nginx (punto de entrada principal)
- **8080**: Nginx (puerto alternativo)
- **3000**: Backend API (acceso directo)
- **5432**: PostgreSQL
- **6379**: Redis

## 🔧 Configuración

### Variables de Entorno

Variables de entorno clave (ver `env.example` para la lista completa):

```bash
# Configuración del Backend
NODE_ENV=production
PORT=3000
DB_HOST=postgres
DB_PASSWORD=tu_contraseña_segura

# Configuración del Frontend
VITE_API_BASE_URL=http://localhost:3000/api

# Configuración de Base de Datos
POSTGRES_DB=password_manager
POSTGRES_USER=postgres
POSTGRES_PASSWORD=tu_contraseña_segura
```

### Configuración de Nginx

El servicio nginx actúa como proxy inverso:

- `/api/*` → API Backend
- `/api-docs` → Documentación API
- `/health` → Verificación de Salud
- `/*` → Frontend SPA (con fallback a index.html)

## 🧪 Pruebas

### Pruebas del Backend

```bash
cd apps/backend

# Pruebas unitarias
npm run test

# Pruebas E2E
npm run test:e2e

# Cobertura de pruebas
npm run test:cov
```

### Pruebas del Frontend

```bash
cd apps/frontend

# Ejecutar pruebas
npm run test

# Ejecutar pruebas con UI
npm run test:ui

# Cobertura de pruebas
npm run test:coverage
```

### Verificaciones de Salud

```bash
# Verificar todos los servicios
./deploy/health-check.sh

# Verificar servicio específico
curl http://localhost:8080/health
curl http://localhost:3000/health
```

## 📊 Monitoreo

### Endpoints de Salud

- **Salud General**: `GET /health`
- **Salud del Backend**: `GET /api/health`
- **Salud de Base de Datos**: Incluido en verificación de salud del backend
- **Salud del Cache**: Incluido en verificación de salud del backend

### Logs

```bash
# Ver todos los logs
docker compose logs -f

# Ver logs de servicio específico
docker compose logs -f app
docker compose logs -f frontend
docker compose logs -f nginx
```

## 🚀 Despliegue

### Despliegue Local (Desarrollo)

1. **Actualizar Variables de Entorno**:
   ```bash
   cp env.example .env
   # Editar .env con valores de desarrollo
   ```

2. **Iniciar Entorno de Desarrollo**:
   ```bash
   ./dev-start.sh
   ```

3. **Verificar Despliegue**:
   ```bash
   ./deploy/health-check.sh
   ```

### Despliegue con Docker Hub (Producción)

Para desplegar usando imágenes pre-construidas desde Docker Hub:

#### 1. Preparación de Docker Hub

```bash
# Crear repositorios en Docker Hub:
# - <usuario>/m8final-backend
# - <usuario>/m8final-frontend

# Generar Access Token en Docker Hub
# Configurar variables de entorno
export DOCKERHUB_USER=tu_usuario
export DOCKERHUB_TOKEN=tu_token
export POSTGRES_PASSWORD=tu_password_seguro
```

#### 2. Construir y Publicar Imágenes

```bash
# Construir y publicar versión v1
./scripts/build_and_push.sh v1

# Construir y publicar versión v2
./scripts/build_and_push.sh v2
```

#### 3. Desplegar en Producción

```bash
# Desplegar versión v1
./scripts/deploy.sh v1

# Cambiar a versión v2
./scripts/deploy.sh v2

# Ver estado de servicios
./scripts/deploy.sh v1 status

# Ver logs
./scripts/deploy.sh v1 logs
```

#### 4. Verificar Despliegue

```bash
# Health check
curl http://localhost:8080/health

# Información de versión
curl http://localhost:8080/version

# Acceso al frontend
curl http://localhost:8080/

# Adminer (gestión de BD)
curl http://localhost:8081
```

**📖 Para más detalles sobre Docker Hub, consulta [DOCKERHUB.md](./DOCKERHUB.md)**

### Escalado

Para escalar servicios específicos:

```bash
# Escalar instancias del backend
docker compose up -d --scale app=3

# Escalar instancias del frontend
docker compose up -d --scale frontend=2
```

## 🔒 Características de Seguridad

- **Cifrado de Contraseñas**: Cifrado AES con clave maestra
- **Configuración CORS**: Políticas de origen cruzado configurables
- **Limitación de Velocidad**: Throttling para prevenir abuso
- **Verificaciones de Salud**: Monitoreo integral
- **Contenedores No-root**: Imágenes Docker endurecidas en seguridad
- **Aislamiento de Entorno**: Configuraciones separadas desarrollo/producción

## 📚 Documentación de API

Una vez que la aplicación esté ejecutándose, visita:
- **Swagger UI**: http://localhost:3000/api-docs
- **Especificación OpenAPI**: http://localhost:3000/api-docs-json

### Endpoints Clave de la API

- `GET /api/password-manager/` - Listar todas las contraseñas
- `POST /api/password-manager/` - Crear nueva contraseña
- `PUT /api/password-manager/:id` - Actualizar contraseña
- `DELETE /api/password-manager/:id` - Eliminar contraseña
- `POST /api/password-manager/:id/decrypt` - Descifrar contraseña

## 🛠️ Solución de Problemas

### Problemas Comunes

1. **Conflictos de Puerto**:
   ```bash
   # Verificar qué está usando los puertos
   lsof -i :80 -i :3000 -i :5432 -i :6379
   ```

2. **Problemas de Conexión a Base de Datos**:
   ```bash
   # Verificar logs de base de datos
   docker compose logs postgres
   ```

3. **Frontend No Carga**:
   ```bash
   # Verificar logs de nginx
   docker compose logs nginx
   ```

4. **Fallos de Construcción**:
   ```bash
   # Reconstruir sin cache
   docker compose build --no-cache
   ```

### Reiniciar Todo

```bash
# Detener y eliminar todo
docker compose down -v --rmi all

# Eliminar todos los contenedores e imágenes
docker system prune -a

# Iniciar desde cero
./deploy/start.sh
```

## 📝 Flujo de Desarrollo

### Agregar Nuevas Características

1. **Backend**: Agregar a `backend/src/`
2. **Frontend**: Agregar a `frontend/src/`
3. **Pruebas**: Agregar pruebas correspondientes
4. **Documentación**: Actualizar este README

### Calidad del Código

```bash
# Linting del backend
cd apps/backend && npm run lint

# Linting del frontend
cd apps/frontend && npm run lint

# Formatear código
cd apps/backend && npm run format
```

## 🤝 Contribuir

1. Fork del repositorio
2. Crear rama de característica
3. Hacer cambios
4. Agregar pruebas
5. Enviar pull request

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo LICENSE para detalles.

## 🆘 Soporte

Para soporte y preguntas:

- **Issues**: Crear un issue en GitHub
- **Documentación**: Revisar este README y docs de API
- **Verificación de Salud**: Ejecutar `./deploy/health-check.sh`

---

**¡Feliz Programación! 🚀**