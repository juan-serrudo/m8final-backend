# Ejemplos de Uso de la API

## Health Checks

### Verificar estado general del sistema
```bash
curl -X GET http://localhost:3000/health
```

### Verificar estado de la base de datos
```bash
curl -X GET http://localhost:3000/health/db
```

### Verificar estado de Redis
```bash
curl -X GET http://localhost:3000/health/redis
```

## Gestión de Contraseñas

### 1. Obtener todas las contraseñas (con caché)
```bash
curl -X GET http://localhost:3000/password-manager
```

### 2. Obtener una contraseña específica (con caché)
```bash
curl -X GET http://localhost:3000/password-manager/1
```

### 3. Crear nueva entrada (invalida caché)
```bash
curl -X POST http://localhost:3000/password-manager \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Gmail Personal",
    "description": "Cuenta principal de Gmail",
    "username": "usuario@gmail.com",
    "password": "miPasswordSegura123",
    "url": "https://gmail.com",
    "category": "Email",
    "notes": "Cuenta principal para trabajo y personal",
    "masterKey": "miClaveMaestraSegura123"
  }'
```

### 4. Actualizar entrada (invalida caché)
```bash
curl -X PUT http://localhost:3000/password-manager/1 \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Gmail Personal Actualizado",
    "masterKey": "miClaveMaestraSegura123"
  }'
```

### 5. Descifrar contraseña
```bash
curl -X POST http://localhost:3000/password-manager/1/decrypt \
  -H "Content-Type: application/json" \
  -d '{
    "masterKey": "miClaveMaestraSegura123"
  }'
```

### 6. Eliminar entrada (invalida caché)
```bash
curl -X DELETE "http://localhost:3000/password-manager/1?masterKey=miClaveMaestraSegura123"
```

### 7. Filtrar por categoría
```bash
curl -X GET http://localhost:3000/password-manager/category/Email
```

## Rate Limiting

El sistema implementa rate limiting con las siguientes configuraciones por defecto:
- **TTL**: 60 segundos
- **Límite**: 10 requests por ventana de tiempo

Cuando se excede el límite, recibirás un error 429 (Too Many Requests).

## Caché

### Comportamiento del caché:
- **GET requests**: Se cachean por 5 minutos
- **POST/PUT/DELETE**: Invalidan automáticamente el caché relacionado
- **Patrones de invalidación**: 
  - `passwords:all` - Lista completa
  - `passwords:{id}` - Entrada específica
  - `passwords:*` - Todas las entradas

## Docker Compose

### Levantar todos los servicios
```bash
docker compose up -d
```

### Ver logs
```bash
docker compose logs -f app
```

### Ejecutar migraciones
```bash
docker compose exec app npm run migration:run
```

### Ejecutar seeds
```bash
docker compose exec app npm run seed:run
```

### Parar servicios
```bash
docker compose down
```

## Variables de Entorno

### Para desarrollo local
```bash
# Copiar archivo de ejemplo
cp env.example .env

# Editar variables según tu configuración
nano .env
```

### Para Docker
Las variables están configuradas en `docker compose.yml` y se aplican automáticamente.

## Monitoreo

### Verificar estado de servicios
```bash
# Estado de contenedores
docker compose ps

# Logs de PostgreSQL
docker compose logs postgres

# Logs de Redis
docker compose logs redis

# Logs de la aplicación
docker compose logs app
```

### Métricas de rendimiento
- **Caché hit rate**: Monitorear logs de Redis
- **Rate limiting**: Verificar logs de throttler
- **Health checks**: Endpoints `/health/*` para monitoreo
