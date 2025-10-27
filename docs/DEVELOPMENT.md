# Entorno de Desarrollo Local - Password Manager

Este documento describe cómo configurar y ejecutar el entorno de desarrollo local para el proyecto Password Manager.

## Requisitos Previos

Antes de comenzar, asegúrate de tener instalado:

- **Docker** y **Docker Compose**
- **Node.js** (versión 18 o superior)
- **npm** (incluido con Node.js)
- **Git**

## Configuración Rápida

### 1. Iniciar el Entorno de Desarrollo

Ejecuta el script de desarrollo que configurará automáticamente todos los servicios:

```bash
./dev-start.sh
```

Este script:
- ✅ Verifica las dependencias necesarias
- ✅ Crea archivos de configuración para desarrollo
- ✅ Inicia PostgreSQL y Redis usando Docker
- ✅ Instala dependencias del backend y frontend
- ✅ Ejecuta migraciones de base de datos
- ✅ Inicia ambas aplicaciones en modo desarrollo

### 2. Acceder a las Aplicaciones

Una vez iniciado, tendrás acceso a:

- **Frontend**: http://localhost:5173
- **Backend API**: http://localhost:3000
- **Swagger UI**: http://localhost:3000/api
- **Adminer**: http://localhost:8081
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

### 3. Detener el Entorno de Desarrollo

Para detener todos los servicios:

```bash
./dev-stop.sh
```

## Configuración Manual (Alternativa)

Si prefieres configurar manualmente:

### 1. Servicios de Base de Datos

```bash
# Iniciar PostgreSQL y Redis
docker compose -f docker-compose.dev.yml up -d

# Verificar que estén corriendo
docker compose -f docker-compose.dev.yml ps
```

### 2. Backend

```bash
cd backend

# Instalar dependencias
npm install

# Ejecutar migraciones
npm run migration:run

# Ejecutar seeds (opcional)
npm run seed:run

# Iniciar en modo desarrollo
npm run start:dev
```

### 3. Frontend

```bash
cd frontend

# Instalar dependencias
npm install

# Iniciar en modo desarrollo
npm run dev
```

## Estructura del Proyecto

```
m9final-backend/
├── backend/                 # Aplicación NestJS
│   ├── src/
│   ├── package.json
│   └── ...
├── frontend/               # Aplicación React + Vite
│   ├── src/
│   ├── package.json
│   └── ...
├── dev-start.sh           # Script de inicio para desarrollo
├── dev-stop.sh            # Script de parada para desarrollo
├── docker-compose.dev.yml # Servicios Docker para desarrollo
└── .env                   # Variables de entorno (se crea automáticamente)
```

## Variables de Entorno

El script `dev-start.sh` crea automáticamente un archivo `.env` basado en `env.example` con configuraciones optimizadas para desarrollo:

- `NODE_ENV=development`
- `ENV_SYNCHRONIZE=true` (para sincronización automática de BD)
- `DB_HOST=localhost`
- `REDIS_HOST=localhost`

## Comandos Útiles

### Backend

```bash
cd backend

# Desarrollo
npm run start:dev

# Debug
npm run start:debug

# Migraciones
npm run migration:generate -- -n NombreMigracion
npm run migration:run
npm run migration:revert

# Seeds
npm run seed:run

# Tests
npm run test
npm run test:e2e
```

### Frontend

```bash
cd frontend

# Desarrollo
npm run dev

# Build
npm run build

# Preview
npm run preview

# Tests
npm run test
npm run test:ui
```

## Solución de Problemas

### Puerto ya en uso

Si encuentras errores de puerto ocupado:

```bash
# Verificar qué proceso usa el puerto
lsof -i :3000  # Backend
lsof -i :5173  # Frontend
lsof -i :5432  # PostgreSQL
lsof -i :6379  # Redis

# Detener proceso específico
kill -9 <PID>
```

### Limpiar datos de desarrollo

```bash
# Detener y eliminar contenedores y volúmenes
docker compose -f docker-compose.dev.yml down -v

# Eliminar volúmenes específicos
docker volume rm password-manager_postgres_dev_data
docker volume rm password-manager_redis_dev_data
```

### Reinstalar dependencias

```bash
# Backend
cd backend
rm -rf node_modules package-lock.json
npm install

# Frontend
cd frontend
rm -rf node_modules package-lock.json
npm install
```

## Base de Datos

### Credenciales por defecto

- **Host**: localhost
- **Puerto**: 5432
- **Usuario**: postgres
- **Contraseña**: password123
- **Base de datos**: password_manager

### Adminer - Gestión Web de Base de Datos

Adminer es una herramienta web ligera para administrar bases de datos PostgreSQL. Está disponible en:

- **URL**: http://localhost:8081
- **Sistema**: PostgreSQL
- **Servidor**: postgres-dev (desarrollo) / postgres (producción)
- **Usuario**: postgres
- **Contraseña**: password123
- **Base de datos**: password_manager

#### Características de Adminer:
- ✅ Interfaz web intuitiva
- ✅ Ejecutar consultas SQL
- ✅ Ver y editar datos
- ✅ Gestionar estructura de tablas
- ✅ Importar/exportar datos
- ✅ Tema oscuro (pepa-linha-dark)

### Conexión manual

```bash
# Usando psql
psql -h localhost -p 5432 -U postgres -d password_manager

# Usando Docker
docker exec -it password-manager-postgres-dev psql -U postgres -d password_manager
```

## Redis

### Conexión manual

```bash
# Usando redis-cli
redis-cli -h localhost -p 6379

# Usando Docker
docker exec -it password-manager-redis-dev redis-cli
```

## Desarrollo con Hot Reload

Ambas aplicaciones están configuradas para recarga automática:

- **Backend**: Usa `nest start --watch` para recarga automática
- **Frontend**: Usa Vite que incluye HMR (Hot Module Replacement)

## Logs y Debugging

### Ver logs de Docker

```bash
# Todos los servicios
docker compose -f docker-compose.dev.yml logs -f

# Servicio específico
docker compose -f docker-compose.dev.yml logs -f postgres-dev
docker compose -f docker-compose.dev.yml logs -f redis-dev
```

### Debug del Backend

```bash
cd backend
npm run start:debug
```

Luego conecta tu debugger a `localhost:9229`.

## Contribuir

1. Asegúrate de que todos los tests pasen
2. Ejecuta el linter antes de hacer commit
3. Sigue las convenciones de código del proyecto

```bash
# Backend
cd backend
npm run lint
npm run test

# Frontend
cd frontend
npm run lint
npm run test
```

---

Para más información sobre el proyecto, consulta el README principal.
