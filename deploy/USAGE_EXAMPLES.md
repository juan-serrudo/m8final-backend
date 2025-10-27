# Ejemplos de Uso - Docker Swarm Deployment

Este archivo contiene ejemplos prácticos de cómo usar el sistema de despliegue Docker Swarm para Password Manager.

## 🚀 Inicio Rápido

### 1. Configuración Inicial
```bash
# Navegar al directorio de despliegue
cd deploy/

# Configurar y desplegar el stack completo
./setup-swarm.sh
```

### 2. Verificar el Despliegue
```bash
# Ver estado de todos los servicios
./manage-stack.sh status

# Ver logs de todos los servicios
./manage-stack.sh logs

# Verificar salud de la aplicación
curl http://localhost:8080/health
```

## 📊 Monitoreo y Gestión

### Monitoreo Continuo
```bash
# Monitoreo cada 30 segundos (default)
./monitor-stack.sh

# Monitoreo cada 60 segundos
./monitor-stack.sh 60

# Monitoreo cada 10 segundos (más frecuente)
./monitor-stack.sh 10
```

### Verificaciones Específicas
```bash
# Solo verificar salud del stack
./monitor-stack.sh health

# Solo verificar recursos
./monitor-stack.sh resources

# Solo verificar red
./monitor-stack.sh network

# Solo verificar almacenamiento
./monitor-stack.sh storage

# Solo verificar endpoints
./monitor-stack.sh endpoints
```

## 🔧 Gestión del Stack

### Escalado de Servicios
```bash
# Escalar backend a 5 réplicas
docker service scale password-manager_app=5

# Escalar frontend a 3 réplicas
docker service scale password-manager_frontend=3

# Escalar nginx a 3 réplicas
docker service scale password-manager_nginx=3

# Usar script de gestión
./manage-stack.sh scale
```

### Actualizaciones
```bash
# Actualizar stack completo
./manage-stack.sh update

# Actualizar con nueva imagen
docker build -t password-manager-backend:v2.0 ./apps/backend
# Editar stack-deploy.yml para usar la nueva imagen
docker stack deploy -c stack-deploy.yml password-manager
```

### Rollbacks
```bash
# Rollback manual de un servicio
docker service rollback password-manager_app

# Rollback completo usando script
./manage-stack.sh rollback
```

## 🔒 Gestión de Secretos

### Crear Nuevos Secretos
```bash
# Crear nuevo secret para contraseña de DB
echo "nueva_password_segura" | docker secret create db_password_new -

# Actualizar secret existente
echo "password_actualizada" | docker secret create postgres_password_v2 -
```

### Listar y Gestionar Secretos
```bash
# Listar todos los secrets
docker secret ls

# Inspeccionar un secret
docker secret inspect postgres_password

# Eliminar un secret
docker secret rm db_password_old
```

## ⚙️ Gestión de Configuraciones

### Crear Nuevas Configuraciones
```bash
# Crear nueva configuración de nginx
docker config create nginx_config_v2 ./nginx-swarm.conf

# Crear nueva configuración de aplicación
cat > /tmp/app-v2.env << EOF
NODE_ENV=production
PORT=3000
ENV_ENTORNO=production
# ... otras variables
EOF
docker config create app_config_v2 /tmp/app-v2.env
rm /tmp/app-v2.env
```

### Actualizar Configuraciones
```bash
# Listar configs
docker config ls

# Inspeccionar config
docker config inspect nginx_config

# Eliminar config antiguo
docker config rm nginx_config_old
```

## 📈 Escalabilidad Avanzada

### Escalado Basado en Carga
```bash
# Monitorear carga y escalar dinámicamente
while true; do
    # Obtener métricas de CPU
    cpu_usage=$(docker stats --no-stream --format "{{.CPUPerc}}" password-manager_app.1 | sed 's/%//')

    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        echo "CPU alta ($cpu_usage%), escalando..."
        docker service scale password-manager_app=5
    elif (( $(echo "$cpu_usage < 30" | bc -l) )); then
        echo "CPU baja ($cpu_usage%), reduciendo..."
        docker service scale password-manager_app=2
    fi

    sleep 60
done
```

### Escalado por Horario
```bash
# Script para escalado automático por horario
#!/bin/bash
current_hour=$(date +%H)

if [ "$current_hour" -ge 9 ] && [ "$current_hour" -le 17 ]; then
    # Horario laboral - más réplicas
    docker service scale password-manager_app=5
    docker service scale password-manager_frontend=3
else
    # Horario no laboral - menos réplicas
    docker service scale password-manager_app=2
    docker service scale password-manager_frontend=1
fi
```

## 🔄 Backup y Restauración

### Backup de Base de Datos
```bash
# Backup completo de PostgreSQL
docker exec $(docker ps -q -f name=password-manager_postgres) \
    pg_dump -U postgres password_manager > backup_$(date +%Y%m%d_%H%M%S).sql

# Backup solo esquema
docker exec $(docker ps -q -f name=password-manager_postgres) \
    pg_dump -U postgres -s password_manager > schema_$(date +%Y%m%d_%H%M%S).sql

# Backup solo datos
docker exec $(docker ps -q -f name=password-manager_postgres) \
    pg_dump -U postgres -a password_manager > data_$(date +%Y%m%d_%H%M%S).sql
```

### Backup de Redis
```bash
# Backup de Redis
docker exec $(docker ps -q -f name=password-manager_redis) \
    redis-cli BGSAVE

# Copiar archivo de backup
docker cp $(docker ps -q -f name=password-manager_redis):/data/dump.rdb \
    redis_backup_$(date +%Y%m%d_%H%M%S).rdb
```

### Restauración
```bash
# Restaurar base de datos
docker exec -i $(docker ps -q -f name=password-manager_postgres) \
    psql -U postgres password_manager < backup_20241227_120000.sql

# Restaurar Redis
docker cp redis_backup_20241227_120000.rdb \
    $(docker ps -q -f name=password-manager_redis):/data/dump.rdb
docker exec $(docker ps -q -f name=password-manager_redis) redis-cli FLUSHALL
```

## 🚨 Troubleshooting

### Problemas de Conectividad
```bash
# Verificar red overlay
docker network ls
docker network inspect password-manager_app-network

# Probar conectividad entre servicios
docker exec -it $(docker ps -q -f name=password-manager_app) ping frontend
docker exec -it $(docker ps -q -f name=password-manager_app) ping postgres
```

### Problemas de Recursos
```bash
# Ver estadísticas detalladas
docker stats

# Ver límites de recursos
docker service inspect password-manager_app --format '{{.Spec.TaskTemplate.Resources}}'

# Ajustar límites de recursos
docker service update --limit-memory 2G password-manager_app
docker service update --limit-cpu 2.0 password-manager_app
```

### Problemas de Salud
```bash
# Ver logs de health checks
docker service logs password-manager_app | grep health

# Ejecutar health check manualmente
docker exec $(docker ps -q -f name=password-manager_app) wget -q --spider http://localhost:3000/health

# Verificar configuración de health check
docker service inspect password-manager_app --format '{{.Spec.TaskTemplate.ContainerSpec.Healthcheck}}'
```

## 🔧 Personalización Avanzada

### Variables de Entorno Personalizadas
```bash
# Crear archivo de configuración personalizado
cat > /tmp/app-custom.env << EOF
NODE_ENV=production
PORT=3000
ENV_ENTORNO=production
ENV_CORS=https://mi-dominio.com
ENV_SWAGGER_SHOW=false
DB_HOST=postgres
DB_PORT=5432
DB_USER=postgres
DB_NAME=password_manager
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_DB=0
THROTTLE_TTL=60
THROTTLE_LIMIT=20
EOF

# Crear config personalizado
docker config create app_config_custom /tmp/app-custom.env
rm /tmp/app-custom.env
```

### Configuración de Nginx Personalizada
```bash
# Crear configuración personalizada de nginx
cat > nginx-custom.conf << EOF
events {
    worker_connections 1024;
}

http {
    # Configuración personalizada aquí
    server {
        listen 80;
        server_name mi-dominio.com;

        # Configuración específica
    }
}
EOF

# Crear config de nginx personalizado
docker config create nginx_config_custom nginx-custom.conf
```

## 📊 Métricas y Logging

### Centralización de Logs
```bash
# Configurar logging driver para todos los servicios
docker service update --log-driver json-file --log-opt max-size=10m --log-opt max-file=3 password-manager_app
docker service update --log-driver json-file --log-opt max-size=10m --log-opt max-file=3 password-manager_frontend
docker service update --log-driver json-file --log-opt max-size=10m --log-opt max-file=3 password-manager_nginx
```

### Exportar Métricas
```bash
# Exportar estadísticas a archivo
docker stats --no-stream > metrics_$(date +%Y%m%d_%H%M%S).txt

# Monitoreo continuo con logging
./monitor-stack.sh 30 > monitoring.log 2>&1 &
```

## 🧹 Limpieza y Mantenimiento

### Limpieza Completa
```bash
# Limpieza con confirmación
./cleanup-swarm.sh

# Limpieza forzada (sin confirmación)
./cleanup-swarm.sh --force
```

### Mantenimiento Regular
```bash
# Limpieza semanal de recursos no utilizados
docker system prune -f
docker volume prune -f
docker network prune -f

# Actualización de imágenes base
docker pull postgres:16-alpine
docker pull redis:7-alpine
docker pull nginx:alpine
```

## 🔐 Seguridad

### Rotación de Secretos
```bash
# Crear nuevo secret
echo "nueva_password_super_segura" | docker secret create db_password_rotated -

# Actualizar servicio para usar nuevo secret
docker service update --secret-rm db_password --secret-add db_password_rotated password-manager_app

# Eliminar secret antiguo
docker secret rm db_password
```

### Auditoría de Seguridad
```bash
# Verificar configuración de red
docker network inspect password-manager_app-network | grep -i encrypt

# Verificar secrets
docker secret ls
docker secret inspect postgres_password

# Verificar configs
docker config ls
docker config inspect nginx_config
```

## 📚 Comandos de Referencia Rápida

### Comandos Esenciales
```bash
# Estado del stack
docker stack services password-manager

# Logs de servicio
docker service logs password-manager_app

# Escalar servicio
docker service scale password-manager_app=5

# Actualizar stack
docker stack deploy -c stack-deploy.yml password-manager

# Eliminar stack
docker stack rm password-manager
```

### Scripts Disponibles
```bash
# Configuración inicial
./setup-swarm.sh

# Gestión del stack
./manage-stack.sh [comando]

# Monitoreo
./monitor-stack.sh [intervalo]

# Limpieza
./cleanup-swarm.sh [--force]
```

### URLs de Acceso
- **Aplicación**: http://localhost:8080
- **API**: http://localhost:8080/api
- **Swagger**: http://localhost:8080/api-docs
- **Health Check**: http://localhost:8080/health
- **Adminer**: http://localhost:8081
