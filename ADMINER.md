# Adminer - Gestión de Base de Datos

Este proyecto incluye **Adminer** como herramienta web para la gestión de la base de datos PostgreSQL tanto en desarrollo como en producción.

## 🚀 Acceso Rápido

### Desarrollo
- **URL**: http://localhost:8081
- **Sistema**: PostgreSQL
- **Servidor**: postgres-dev
- **Usuario**: postgres
- **Contraseña**: password123
- **Base de datos**: password_manager

### Producción
- **URL**: http://localhost:8081
- **Sistema**: PostgreSQL
- **Servidor**: postgres
- **Usuario**: postgres
- **Contraseña**: password123
- **Base de datos**: password_manager

## 📋 Características

### ✅ Funcionalidades Principales
- **Interfaz Web Intuitiva**: Gestión completa de base de datos desde el navegador
- **Ejecutar Consultas SQL**: Editor SQL con resaltado de sintaxis
- **Ver y Editar Datos**: Tabla de datos con filtros y búsqueda
- **Gestionar Estructura**: Crear, modificar y eliminar tablas, índices, etc.
- **Importar/Exportar**: Soporte para múltiples formatos (SQL, CSV, JSON)
- **Tema Oscuro**: Interfaz moderna con tema pepa-linha-dark

### 🔧 Configuración Técnica
- **Imagen**: adminer:4.8.1
- **Puerto**: 8081
- **Health Check**: Verificación automática de disponibilidad
- **Dependencias**: Se inicia después de PostgreSQL
- **Restart Policy**: unless-stopped

## 🛠️ Uso

### 1. Iniciar Adminer

Adminer se inicia automáticamente con el entorno de desarrollo:

```bash
./dev-start.sh
```

O manualmente con Docker Compose:

```bash
# Desarrollo
docker-compose -f docker-compose.dev.yml up -d adminer-dev

# Producción
docker-compose up -d adminer
```

### 2. Acceder a Adminer

1. Abre tu navegador
2. Ve a http://localhost:8081
3. Completa el formulario de conexión:
   - **Sistema**: PostgreSQL
   - **Servidor**: postgres-dev (desarrollo) / postgres (producción)
   - **Usuario**: postgres
   - **Contraseña**: password123
   - **Base de datos**: password_manager

### 3. Operaciones Comunes

#### Ver Datos
- Selecciona una tabla en el panel izquierdo
- Los datos se mostrarán en formato tabla
- Usa los filtros para buscar registros específicos

#### Ejecutar Consultas SQL
- Haz clic en "SQL command"
- Escribe tu consulta SQL
- Ejecuta con Ctrl+Enter o el botón "Execute"

#### Editar Datos
- Selecciona una tabla
- Haz clic en "Select data"
- Usa los iconos de edición para modificar registros

#### Gestionar Estructura
- Usa "Create table" para nuevas tablas
- "Alter table" para modificar estructura existente
- "Drop table" para eliminar tablas

## 🔍 Consultas Útiles

### Ver todas las tablas
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';
```

### Ver estructura de una tabla
```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'password_manager';
```

### Ver índices
```sql
SELECT indexname, tablename, indexdef
FROM pg_indexes
WHERE schemaname = 'public';
```

### Estadísticas de tablas
```sql
SELECT 
    schemaname,
    tablename,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    n_live_tup as live_tuples,
    n_dead_tup as dead_tuples
FROM pg_stat_user_tables;
```

## 🐛 Solución de Problemas

### Adminer no responde
```bash
# Verificar estado del contenedor
docker ps | grep adminer

# Ver logs
docker logs password-manager-adminer-dev

# Reiniciar servicio
docker-compose -f docker-compose.dev.yml restart adminer-dev
```

### Error de conexión
1. Verifica que PostgreSQL esté corriendo
2. Confirma las credenciales
3. Verifica que el servidor sea correcto:
   - Desarrollo: `postgres-dev`
   - Producción: `postgres`

### Puerto ocupado
```bash
# Verificar qué usa el puerto 8081
lsof -i :8081

# Detener proceso si es necesario
kill -9 <PID>
```

## 🔒 Seguridad

### Consideraciones de Producción
- Adminer expone la base de datos en la red
- Considera usar autenticación adicional en producción
- Limita el acceso por IP si es necesario
- Usa HTTPS en producción

### Configuración Segura
```yaml
# Ejemplo de configuración más segura
adminer:
  image: adminer:4.8.1
  ports:
    - "127.0.0.1:8081:8080"  # Solo localhost
  environment:
    ADMINER_DEFAULT_SERVER: postgres
    ADMINER_DESIGN: pepa-linha-dark
```

## 📚 Recursos Adicionales

- [Documentación oficial de Adminer](https://www.adminer.org/)
- [Temas disponibles](https://www.adminer.org/en/plugins/)
- [Plugins de Adminer](https://www.adminer.org/en/plugins/)

## 🆘 Soporte

Si encuentras problemas con Adminer:

1. Verifica los logs del contenedor
2. Confirma que PostgreSQL esté disponible
3. Revisa la configuración de red
4. Consulta la documentación oficial

---

**Nota**: Adminer es una herramienta muy útil para desarrollo y debugging, pero ten cuidado con su uso en producción ya que proporciona acceso completo a la base de datos.
