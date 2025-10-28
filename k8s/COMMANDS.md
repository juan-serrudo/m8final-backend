# Comandos de Verificación y Gestión - Kubernetes KIND

Este documento contiene todos los comandos necesarios para verificar y gestionar el despliegue de `password-manager-api` en Kubernetes.

## Verificación de Funcionamiento

### 1. Verificar Estado del Cluster

```bash
# Información del cluster
kubectl cluster-info --context kind-password-manager

# Ver todos los recursos
kubectl get all

# Ver recursos con labels específicos
kubectl get all -l app=password-manager-api
```

### 2. Verificar Pods

```bash
# Listar pods
kubectl get pods -l app=password-manager-api

# Ver pods con más detalles
kubectl get pods -l app=password-manager-api -o wide

# Ver pods por versión
kubectl get pods -l version=v1
kubectl get pods -l version=v2

# Describir un pod específico
kubectl describe pod <pod-name>

# Ver logs de todos los pods
kubectl logs -l app=password-manager-api --tail=50

# Ver logs de un pod específico
kubectl logs <pod-name>

# Ver logs en tiempo real (seguimiento)
kubectl logs -l app=password-manager-api -f

# Ver logs del contenedor anterior (si se reinició)
kubectl logs <pod-name> --previous
```

### 3. Verificar Deployment

```bash
# Estado del deployment
kubectl get deployment password-manager-api

# Detalles del deployment
kubectl describe deployment password-manager-api

# Ver historial de rollouts
kubectl rollout history deployment/password-manager-api

# Ver detalles de una revisión específica
kubectl rollout history deployment/password-manager-api --revision=2

# Estado del rollout actual
kubectl rollout status deployment/password-manager-api
```

### 4. Verificar Services

```bash
# Listar servicios
kubectl get svc

# Detalles del ClusterIP service
kubectl describe svc password-manager-api-service

# Detalles del LoadBalancer service
kubectl describe svc password-manager-api-loadbalancer

# Ver endpoints (pods detrás del service)
kubectl get endpoints password-manager-api-service

# Ver endpoints con detalles
kubectl describe endpoints password-manager-api-service
```

### 5. Verificar Secrets

```bash
# Listar secrets
kubectl get secrets

# Ver detalles del secret
kubectl describe secret password-manager-api-secrets

# Ver el secret en YAML (valores en base64)
kubectl get secret password-manager-api-secrets -o yaml

# Decodificar un valor del secret
kubectl get secret password-manager-api-secrets -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
echo ""

kubectl get secret password-manager-api-secrets -o jsonpath='{.data.JWT_SECRET}' | base64 -d
echo ""
```

### 6. Verificar Variables de Entorno

```bash
# Obtener nombre de un pod
POD_NAME=$(kubectl get pod -l app=password-manager-api -o jsonpath='{.items[0].metadata.name}')

# Ver todas las variables de entorno
kubectl exec $POD_NAME -- env

# Ver solo las variables del secret
kubectl exec $POD_NAME -- env | grep -E "DB_PASSWORD|JWT_SECRET"

# Ver variable específica (sin mostrar el valor completo por seguridad)
kubectl exec $POD_NAME -- printenv DB_PASSWORD
```

### 7. Pruebas de Conectividad

#### Desde el Host (usando port-forward)

```bash
# Port-forward al ClusterIP service
kubectl port-forward svc/password-manager-api-service 3000:3000

# En otra terminal, hacer peticiones
curl http://localhost:3000/api/health
curl http://localhost:3000/api

# Port-forward directamente a un pod
kubectl port-forward <pod-name> 3000:3000
```

#### Desde dentro del Cluster

```bash
# Crear un pod temporal para hacer peticiones
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- \
    curl -v http://password-manager-api-service:3000/api/health

# Test más completo
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- \
    sh -c "curl -s http://password-manager-api-service:3000/api/health && echo '' && curl -s http://password-manager-api-service:3000/api"

# Usar DNS completo (namespace.service.svc.cluster.local)
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- \
    curl http://password-manager-api-service.default.svc.cluster.local:3000/api/health
```

#### Desde el LoadBalancer (externo)

```bash
# Obtener la IP externa
EXTERNAL_IP=$(kubectl get svc password-manager-api-loadbalancer -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Si la IP está pendiente, verificar MetalLB
if [ -z "$EXTERNAL_IP" ] || [ "$EXTERNAL_IP" == "pending" ]; then
    echo "Esperando IP del LoadBalancer..."
    kubectl get svc password-manager-api-loadbalancer -w
fi

# Hacer peticiones a la IP externa
curl http://$EXTERNAL_IP/api/health
curl http://$EXTERNAL_IP/api

# Test con verbose
curl -v http://$EXTERNAL_IP/api/health
```

### 8. Verificar Health Probes

```bash
# Verificar que los probes están configurados
kubectl get deployment password-manager-api -o yaml | grep -A 20 "readinessProbe\|livenessProbe"

# Ver eventos relacionados con probes
kubectl get events --field-selector involvedObject.kind=Pod --sort-by='.lastTimestamp'

# Ver estado de readiness y liveness en los pods
kubectl get pods -l app=password-manager-api -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[*].type}{"\t"}{.status.conditions[*].status}{"\n"}{end}'
```

### 9. Verificar MetalLB

```bash
# Ver estado de MetalLB
kubectl get pods -n metallb-system

# Ver configuración de IPAddressPool
kubectl get ipaddresspool -n metallb-system

# Ver detalles del pool
kubectl describe ipaddresspool default -n metallb-system

# Ver L2Advertisement
kubectl get l2advertisement -n metallb-system

# Ver logs de MetalLB
kubectl logs -n metallb-system -l app=metallb

# Verificar que las IPs están asignadas
kubectl get svc --all-namespaces | grep LoadBalancer
```

## Comandos de Gestión

### Escalado

```bash
# Escalar a 3 réplicas
kubectl scale deployment password-manager-api --replicas=3

# Escalar a 1 réplica
kubectl scale deployment password-manager-api --replicas=1

# Ver el número actual de réplicas
kubectl get deployment password-manager-api -o jsonpath='{.spec.replicas}'
```

### Actualización

```bash
# Actualizar imagen a v2
kubectl set image deployment/password-manager-api \
    password-manager-api=mi-registry/password-manager-api:v2

# Actualizar y cambiar el label de versión
kubectl patch deployment password-manager-api -p \
    '{"spec":{"template":{"metadata":{"labels":{"version":"v2"}}}}}'

# Monitorear la actualización
kubectl rollout status deployment/password-manager-api

# Ver el progreso durante la actualización
watch kubectl get pods -l app=password-manager-api
```

### Rollback

```bash
# Rollback a versión anterior
kubectl rollout undo deployment/password-manager-api

# Rollback a una revisión específica
kubectl rollout undo deployment/password-manager-api --to-revision=1

# Ver historial antes de hacer rollback
kubectl rollout history deployment/password-manager-api
```

### Debugging

```bash
# Ejecutar un shell en un pod
kubectl exec -it <pod-name> -- /bin/sh

# Si el pod no tiene shell, usar busybox
kubectl run debug -it --rm --image=busybox --restart=Never -- /bin/sh

# Ver eventos del cluster
kubectl get events --sort-by='.lastTimestamp'

# Ver eventos de un recurso específico
kubectl describe pod <pod-name>

# Ver configuraciones actuales
kubectl get deployment password-manager-api -o yaml
kubectl get svc password-manager-api-service -o yaml
```

### Eliminación

```bash
# Eliminar recursos específicos
kubectl delete -f deployment.yaml
kubectl delete -f service.yaml
kubectl delete -f loadbalancer.yaml
kubectl delete -f secret.yaml

# Eliminar por label
kubectl delete all -l app=password-manager-api

# Eliminar deployment (elimina automáticamente los pods)
kubectl delete deployment password-manager-api

# Eliminar secret
kubectl delete secret password-manager-api-secrets

# Eliminar todo en un namespace
kubectl delete all --all
```

## Monitoreo Continuo

### Watch en tiempo real

```bash
# Watch pods
watch kubectl get pods -l app=password-manager-api

# Watch services
watch kubectl get svc

# Watch deployment
watch kubectl get deployment password-manager-api

# Watch eventos
watch kubectl get events --sort-by='.lastTimestamp'
```

### Métricas y Recursos

```bash
# Ver uso de recursos de los pods
kubectl top pods -l app=password-manager-api

# Ver uso de recursos de los nodos
kubectl top nodes

# Ver recursos solicitados y límites
kubectl describe pods -l app=password-manager-api | grep -A 5 "Limits\|Requests"
```

## Scripts de Verificación Rápida

### Health Check Completo

```bash
#!/bin/bash
echo "=== Estado del Deployment ==="
kubectl get deployment password-manager-api

echo -e "\n=== Pods ==="
kubectl get pods -l app=password-manager-api

echo -e "\n=== Services ==="
kubectl get svc -l app=password-manager-api

echo -e "\n=== Endpoints ==="
kubectl get endpoints password-manager-api-service

echo -e "\n=== Health Check ==="
POD_NAME=$(kubectl get pod -l app=password-manager-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD_NAME" ]; then
    kubectl exec $POD_NAME -- wget -qO- http://localhost:3000/api/health || echo "Health check falló"
else
    echo "No hay pods disponibles"
fi
```

### Test de Conectividad Completo

```bash
#!/bin/bash
echo "=== Test ClusterIP (interno) ==="
kubectl run curl-test --image=curlimages/curl --rm -i --restart=Never -- \
    curl -s http://password-manager-api-service:3000/api/health

echo -e "\n=== Test LoadBalancer (externo) ==="
EXTERNAL_IP=$(kubectl get svc password-manager-api-loadbalancer -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "pending" ]; then
    curl -s http://$EXTERNAL_IP/api/health
else
    echo "LoadBalancer IP pendiente o no disponible"
fi
```

