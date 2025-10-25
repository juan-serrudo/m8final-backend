# Gestor de Contraseñas - Backend

## Descripción

Sistema de gestión de contraseñas seguro desarrollado con NestJS, que implementa técnicas de criptografía avanzada para el almacenamiento seguro de credenciales. Migrado a PostgreSQL con Redis para caché y rate limiting.

## Características de Seguridad

- **Cifrado AES**: Las contraseñas se cifran usando el algoritmo AES antes de ser almacenadas
- **Hash bcrypt**: Las claves maestras se hashean con bcrypt (12 rounds) para máxima seguridad
- **Verificación de clave maestra**: Todas las operaciones sensibles requieren verificación de la clave maestra
- **Almacenamiento seguro**: No se almacenan contraseñas en texto plano
- **PostgreSQL**: Base de datos robusta con migraciones
- **Redis**: Caché de alto rendimiento y rate limiting
- **Health Checks**: Monitoreo de estado de servicios

## Tecnologías Utilizadas

- **NestJS 11**: Framework de Node.js
- **TypeORM**: ORM para base de datos con migraciones
- **PostgreSQL 16**: Base de datos principal
- **Redis 7**: Caché y rate limiting
- **bcryptjs**: Hashing de claves maestras
- **crypto-js**: Cifrado AES de contraseñas
- **@nestjs/terminus**: Health checks
- **@nestjs/throttler**: Rate limiting
- **Swagger**: Documentación de API
- **class-validator**: Validación de DTOs

## Instalación

### Con Docker (Recomendado)

```bash
# Clonar el repositorio
git clone <repository-url>
cd m8final-backend

# Copiar archivo de entorno
cp env.example .env

# Levantar todos los servicios (PostgreSQL, Redis, App)
docker-compose up -d

# Ejecutar migraciones
docker-compose exec app npm run migration:run

# Ejecutar seeds (datos de ejemplo)
docker-compose exec app npm run seed:run
```

### Desarrollo Local

```bash
# Instalar dependencias
npm install

# Configurar variables de entorno
cp env.example .env

# Asegúrate de tener PostgreSQL y Redis ejecutándose localmente

# Ejecutar migraciones
npm run migration:run

# Ejecutar seeds
npm run seed:run

# Desarrollo
npm run start:dev

# Producción
npm run build
npm run start:prod
```

## Variables de Entorno

```bash
# Puerto del servidor
PORT=3000

# Tamaño máximo de requests
APP_MAX_SIZE=10mb

# Entorno (dev/prod)
ENV_ENTORNO=dev

# CORS (para producción)
ENV_CORS=https://dominio1.com,https://dominio2.com

# Habilitar Swagger
ENV_SWAGGER_SHOW=true

# Sincronización de base de datos (solo desarrollo)
ENV_SYNCHRONIZE=false

# Configuración de PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=password123
DB_NAME=password_manager

# Configuración de Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# Configuración de Rate Limiting
THROTTLE_TTL=60
THROTTLE_LIMIT=10
```

## Endpoints de la API

### Gestión de Contraseñas

- `GET /password-manager` - Obtener todas las entradas (con caché)
- `GET /password-manager/:id` - Obtener entrada específica (con caché)
- `GET /password-manager/category/:category` - Filtrar por categoría
- `POST /password-manager` - Crear nueva entrada (invalida caché)
- `PUT /password-manager/:id` - Actualizar entrada (invalida caché)
- `DELETE /password-manager/:id?masterKey=xxx` - Eliminar entrada (invalida caché)
- `POST /password-manager/:id/decrypt` - Descifrar contraseña

### Health Checks

- `GET /health` - Estado general del sistema
- `GET /health/db` - Estado de la base de datos PostgreSQL
- `GET /health/redis` - Estado de Redis

### Documentación Swagger

Una vez iniciado el servidor, accede a:
- **Swagger UI**: `http://localhost:3000/api`

## Ejemplo de Uso

### 1. Crear nueva entrada

```json
POST /password-manager
{
  "title": "Gmail Personal",
  "description": "Cuenta principal de Gmail",
  "username": "usuario@gmail.com",
  "password": "miContraseñaSegura123!",
  "url": "https://gmail.com",
  "category": "Email",
  "notes": "Cuenta creada en 2020",
  "masterKey": "miClaveMaestraSegura123!"
}
```

### 2. Descifrar contraseña

```json
POST /password-manager/1/decrypt
{
  "masterKey": "miClaveMaestraSegura123!"
}
```

### 3. Actualizar entrada

```json
PUT /password-manager/1
{
  "title": "Gmail Personal Actualizado",
  "masterKey": "miClaveMaestraSegura123!"
}
```

## Arquitectura de Seguridad

### Cifrado de Contraseñas
- **Algoritmo**: AES (Advanced Encryption Standard)
- **Clave**: Derivada de la clave maestra del usuario
- **Resultado**: Contraseña cifrada almacenada en base de datos

### Hash de Clave Maestra
- **Algoritmo**: bcrypt
- **Rounds**: 12 (configurable)
- **Propósito**: Verificación segura sin almacenar la clave original

### Flujo de Seguridad
1. Usuario proporciona clave maestra
2. Sistema verifica hash con bcrypt
3. Si es válida, permite operaciones
4. Para descifrar: usa AES con clave maestra
5. Para cifrar: usa AES con clave maestra

## Estructura del Proyecto

```
src/
├── entitys/
│   └── password-manager.entity.ts    # Entidad de base de datos
├── dto/
│   └── password-manager.dto.ts       # DTOs de validación
├── modules/
│   └── password-manager/
│       ├── password-manager.controller.ts
│       └── password-manager.service.ts
├── providers/
│   ├── password-manager.providers.ts # Proveedores de repositorio
│   └── redis.providers.ts           # Proveedores de Redis
├── services/
│   └── cache.service.ts              # Servicio de caché
├── health/
│   ├── health.controller.ts          # Health checks
│   └── health.module.ts
├── configurations/
│   ├── configuration.ts              # Configuración de entorno
│   ├── data-source.ts               # Configuración TypeORM
│   ├── throttler.config.ts          # Configuración rate limiting
│   └── redis-storage.ts             # Storage Redis para throttler
├── migrations/
│   └── *.ts                          # Migraciones de base de datos
└── seeds/
    ├── *.ts                          # Seeds de datos
    └── index.ts                      # Ejecutor de seeds
```

## Comandos de Migración y Seeds

```bash
# Generar nueva migración
npm run migration:generate -- src/migrations/NombreMigracion

# Ejecutar migraciones
npm run migration:run

# Revertir última migración
npm run migration:revert

# Ejecutar seeds
npm run seed:run
```

## Consideraciones de Seguridad

1. **Nunca almacenar claves maestras en texto plano**
2. **Usar HTTPS en producción**
3. **Rate limiting implementado con Redis**
4. **Caché con invalidación automática**
5. **Health checks para monitoreo**
6. **Logs de auditoría para operaciones sensibles**
7. **Backup seguro de la base de datos**

## Características de Rendimiento

- **Caché Redis**: Respuestas rápidas para consultas frecuentes
- **Rate Limiting**: Protección contra abuso de API
- **Health Checks**: Monitoreo en tiempo real
- **Migraciones**: Control de versiones de base de datos
- **Seeds**: Datos de ejemplo para desarrollo

## Desarrollo

```bash
# Ejecutar en modo desarrollo
npm run start:dev

# Ejecutar tests
npm run test

# Tests e2e
npm run test:e2e

# Linting
npm run lint
```

## Autor

**Juan Victor Serrudo Chavez**
- Email: juan.serrudo@ucb.edu.bo
- Proyecto: Módulo 8 - Maestría UCB
