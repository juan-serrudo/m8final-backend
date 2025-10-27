# Docker Swarm Deployment - Password Manager

Este directorio contiene todos los archivos necesarios para desplegar la aplicación Password Manager usando Docker Swarm con características avanzadas de escalabilidad, alta disponibilidad y gestión de secretos.

## 🚀 Características del Despliegue

### ✅ Escalabilidad y Réplicas
- **Backend (NestJS)**: 3 réplicas con balanceo de carga automático
- **Frontend (React)**: 2 réplicas para alta disponibilidad
- **Nginx**: 2 réplicas para redundancia del proxy
- **PostgreSQL**: 1 réplica (nodo manager) para consistencia de datos
- **Redis**: 1 réplica (nodo manager) para cache distribuido

### ✅ Políticas de Actualización y Rollback
- **Update Policy**: Actualización gradual con monitoreo
- **Rollback Policy**: Rollback automático en caso de fallos
- **Health Checks**: Verificación de salud de todos los servicios
- **Graceful Shutdown**: Cierre ordenado de contenedores

### ✅ Gestión de Secretos y Configuraciones
- **Secrets**: Contraseñas de base de datos almacenadas de forma segura
- **Configs**: Configuraciones externas para nginx y aplicación
- **No Hardcoding**: Eliminación de credenciales hardcodeadas

### ✅ Volúmenes y Redes
- **Network Overlay**: Red encriptada para comunicación entre servicios
- **Volúmenes Persistentes**: Datos de PostgreSQL y Redis persistentes
- **Bind Mounts**: Montaje de directorios del host para persistencia

## 📁 Estructura de Archivos

```
deploy/
├── stack-deploy.yml          # Stack principal de Docker Swarm
├── setup-swarm.sh            # Script de configuración inicial
├── manage-stack.sh           # Script de gestión del stack
├── nginx-swarm.conf          # Configuración de nginx optimizada
└── README.md                 # Esta documentación
```

## 🛠️ Instalación y Configuración

### 1. Configuración Inicial

```bash
# Hacer ejecutable el script de configuración
chmod +x setup-swarm.sh

# Ejecutar configuración completa
./setup-swarm.sh
```

El script realizará:
- Inicialización de Docker Swarm
- Creación de directorios para volúmenes
- Creación de secrets y configs
- Construcción de imágenes Docker
- Despliegue del stack

### 2. Gestión del Stack

```bash
# Hacer ejecutable el script de gestión
chmod +x manage-stack.sh

# Ver estado del stack
./manage-stack.sh status

# Ver logs de todos los servicios
./manage-stack.sh logs

# Escalar servicios
./manage-stack.sh scale

# Actualizar stack
./manage-stack.sh update

# Hacer rollback
./manage-stack.sh rollback
```

## 🔧 Comandos Útiles

### Gestión del Stack
```bash
# Ver servicios del stack
docker stack services password-manager

# Ver logs de un servicio específico
docker service logs password-manager_app

# Escalar un servicio
docker service scale password-manager_app=5

# Actualizar stack
docker stack deploy -c stack-deploy.yml password-manager

# Eliminar stack
docker stack rm password-manager
```

### Gestión de Secrets
```bash
# Listar secrets
docker secret ls

# Crear un nuevo secret
echo "nueva_password" | docker secret create db_password_new -

# Eliminar un secret
docker secret rm db_password_old
```

### Gestión de Configs
```bash
# Listar configs
docker config ls

# Crear un nuevo config
docker config create nginx_config_new ./nginx-new.conf

# Eliminar un config
docker config rm nginx_config_old
```

### Monitoreo y Debugging
```bash
# Ver estadísticas de recursos
docker stats

# Ver nodos del cluster
docker node ls

# Inspeccionar un servicio
docker service inspect password-manager_app

# Ver tareas de un servicio
docker service ps password-manager_app
```

## 🌐 Acceso a la Aplicación

Una vez desplegado, la aplicación estará disponible en:

- **Frontend**: http://localhost:8080
- **API Backend**: http://localhost:8080/api
- **Documentación Swagger**: http://localhost:8080/api-docs
- **Adminer (DB Management)**: http://localhost:8081
- **Health Check**: http://localhost:8080/health

## 🔒 Seguridad

### Secrets Management
- Las contraseñas se almacenan como Docker secrets
- Los secrets se encriptan en tránsito y en reposo
- No se almacenan en archivos de configuración

### Network Security
- Red overlay encriptada entre servicios
- Rate limiting en nginx
- Headers de seguridad configurados
- CORS configurado apropiadamente

### Resource Limits
- Límites de CPU y memoria para cada servicio
- Prevención de consumo excesivo de recursos
- Health checks para detección temprana de problemas

## 📊 Escalabilidad

### Escalado Horizontal
```bash
# Escalar backend a 5 réplicas
docker service scale password-manager_app=5

# Escalar frontend a 3 réplicas
docker service scale password-manager_frontend=3

# Escalar nginx a 3 réplicas
docker service scale password-manager_nginx=3
```

### Escalado Vertical
Modificar los límites de recursos en `stack-deploy.yml`:
```yaml
resources:
  limits:
    memory: 2G
    cpus: '2.0'
  reservations:
    memory: 1G
    cpus: '1.0'
```

## 🔄 Actualizaciones y Rollbacks

### Actualización Gradual
```bash
# Actualizar stack con nueva versión
docker stack deploy -c stack-deploy.yml password-manager

# Verificar estado de la actualización
docker service ps password-manager_app
```

### Rollback Manual
```bash
# Hacer rollback de un servicio específico
docker service rollback password-manager_app

# Hacer rollback de todo el stack
./manage-stack.sh rollback
```

## 🗂️ Persistencia de Datos

### Volúmenes
- **PostgreSQL**: `/opt/password-manager/postgres-data`
- **Redis**: `/opt/password-manager/redis-data`

### Backup de Datos
```bash
# Backup de PostgreSQL
docker exec $(docker ps -q -f name=password-manager_postgres) pg_dump -U postgres password_manager > backup.sql

# Backup de Redis
docker exec $(docker ps -q -f name=password-manager_redis) redis-cli BGSAVE
```

## 🚨 Troubleshooting

### Problemas Comunes

1. **Servicios no inician**
   ```bash
   # Ver logs de servicios
   docker service logs password-manager_app

   # Verificar estado de nodos
   docker node ls
   ```

2. **Problemas de conectividad**
   ```bash
   # Verificar red overlay
   docker network ls
   docker network inspect password-manager_app-network
   ```

3. **Problemas de recursos**
   ```bash
   # Ver estadísticas de recursos
   docker stats

   # Verificar límites de servicios
   docker service inspect password-manager_app
   ```

### Logs y Debugging
```bash
# Logs en tiempo real
docker service logs -f password-manager_app

# Logs con timestamps
docker service logs -t password-manager_app

# Logs de todos los servicios
./manage-stack.sh logs
```

## 📈 Monitoreo

### Health Checks
Todos los servicios incluyen health checks configurados:
- **Backend**: `/health` endpoint
- **Frontend**: Verificación de disponibilidad
- **Nginx**: `/nginx-health` endpoint
- **PostgreSQL**: `pg_isready` command
- **Redis**: `redis-cli ping` command

### Métricas
```bash
# Ver estadísticas de recursos
docker stats

# Ver información detallada de servicios
docker service inspect password-manager_app
```

## 🔧 Personalización

### Variables de Entorno
Modificar el archivo de configuración de la aplicación en el script `setup-swarm.sh`:
```bash
# Editar variables de entorno
cat > /tmp/app.env << EOF
NODE_ENV=production
PORT=3000
# ... otras variables
EOF
```

### Configuración de Nginx
Modificar `nginx-swarm.conf` para ajustar:
- Rate limiting
- Timeouts
- Headers de seguridad
- Upstreams

### Recursos y Límites
Ajustar en `stack-deploy.yml`:
```yaml
resources:
  limits:
    memory: 1G
    cpus: '1.0'
  reservations:
    memory: 512M
    cpus: '0.5'
```

## 📚 Referencias

- [Docker Swarm Documentation](https://docs.docker.com/engine/swarm/)
- [Docker Stack Deploy](https://docs.docker.com/engine/reference/commandline/stack_deploy/)
- [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)
- [Docker Configs](https://docs.docker.com/engine/swarm/configs/)
- [Nginx Load Balancing](https://nginx.org/en/docs/http/load_balancing.html)
