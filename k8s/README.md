# Despliegue en Kubernetes con KIND

Este directorio contiene los manifiestos de Kubernetes para desplegar `password-manager-api` en un cluster KIND (Kubernetes in Docker).

## Estructura de Manifiestos

- **secret.yaml**: Secret con credenciales (DB_PASSWORD, JWT_SECRET)
- **replicaset.yaml**: ReplicaSet simple con versión v1
- **deployment.yaml**: Deployment con estrategia RollingUpdate, probes y replicas
- **service.yaml**: Service tipo ClusterIP para acceso interno
- **loadbalancer.yaml**: Service tipo LoadBalancer para acceso externo (requiere MetalLB en KIND)

## Requisitos Previos

1. **KIND instalado**:
   ```bash
   curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
   chmod +x ./kind
   sudo mv ./kind /usr/local/bin/kind
   ```

2. **kubectl instalado**:
   ```bash
   kubectl version --client
   ```

## Pasos de Despliegue

### 1. Crear Cluster KIND

```bash
# Crear un cluster KIND
kind create cluster --name password-manager

# Verificar que el cluster está listo
kubectl cluster-info --context kind-password-manager
```

### 2. Instalar MetalLB (para LoadBalancer)

MetalLB es necesario para que los servicios tipo LoadBalancer funcionen en KIND.

```bash
# Aplicar MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.4/config/manifests/metallb-native.yaml

# Esperar a que MetalLB esté listo
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s

# Obtener el rango de IPs del docker network de KIND
docker network inspect kind | grep -A 10 "Subnet"

# Crear configuración de MetalLB con el pool de IPs
# Ejemplo: si el subnet es 172.18.0.0/16, usar 172.18.255.200-172.18.255.250
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default
  namespace: metallb-system
spec:
  addresses:
  - 172.18.255.200-172.18.255.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - default
EOF
```

### 3. Cargar Imagen Docker en KIND (si usas imagen local)

Si tienes una imagen local que quieres usar en KIND:

```bash
# Construir la imagen localmente
cd apps/backend
docker build -t password-manager-api:v1 .
docker build -t password-manager-api:v2 .

# Cargar las imágenes en KIND
kind load docker-image password-manager-api:v1 --name password-manager
kind load docker-image password-manager-api:v2 --name password-manager
```

**Nota**: Si usas `ealen/echo-server:0.6.0`, KIND puede descargarlo automáticamente desde Docker Hub.

### 4. Desplegar los Manifiestos

```bash
# Ir al directorio k8s
cd k8s

# 1. Crear el Secret primero
kubectl apply -f secret.yaml

# 2. Crear el Deployment (recomendado sobre ReplicaSet)
kubectl apply -f deployment.yaml

# Alternativamente, si quieres usar solo ReplicaSet:
# kubectl apply -f replicaset.yaml

# 3. Crear el Service ClusterIP
kubectl apply -f service.yaml

# 4. Crear el LoadBalancer (después de instalar MetalLB)
kubectl apply -f loadbalancer.yaml
```

### 5. Verificar el Despliegue

```bash
# Verificar pods
kubectl get pods -l app=password-manager-api

# Verificar servicios
kubectl get svc

# Ver detalles del deployment
kubectl describe deployment password-manager-api

# Ver logs de los pods
kubectl logs -l app=password-manager-api --tail=50

# Verificar que los secrets están montados correctamente
kubectl get secret password-manager-api-secrets -o yaml

# Verificar variables de entorno en un pod
kubectl exec -it $(kubectl get pod -l app=password-manager-api -o jsonpath='{.items[0].metadata.name}') -- env | grep -E "DB_PASSWORD|JWT_SECRET"
```

### 6. Probar la Aplicación

#### Usando ClusterIP (desde dentro del cluster)

```bash
# Port-forward para acceder localmente
kubectl port-forward svc/password-manager-api-service 3000:3000

# En otra terminal, probar
curl http://localhost:3000/api/health
curl http://localhost:3000/api

# O acceder desde un pod temporal
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- curl http://password-manager-api-service:3000/api/health
```

#### Usando LoadBalancer

```bash
# Obtener la IP externa del LoadBalancer
kubectl get svc password-manager-api-loadbalancer

# Esperar a que se asigne la IP (puede tardar unos segundos)
watch kubectl get svc password-manager-api-loadbalancer

# Una vez asignada la IP, hacer peticiones
EXTERNAL_IP=$(kubectl get svc password-manager-api-loadbalancer -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$EXTERNAL_IP/api/health
curl http://$EXTERNAL_IP/api
```

## Actualización y Rollback

### Actualizar de v1 a v2

```bash
# Método 1: Usando kubectl set image
kubectl set image deployment/password-manager-api \
  password-manager-api=mi-registry/password-manager-api:v2

# Método 2: Editar el deployment
kubectl edit deployment password-manager-api
# Cambiar la imagen en el editor

# Método 3: Aplicar deployment actualizado
# Editar deployment.yaml cambiando version: v2 e image: v2
kubectl apply -f deployment.yaml
```

### Monitorear la Actualización

```bash
# Ver el estado del rollout
kubectl rollout status deployment/password-manager-api

# Ver el historial de despliegues
kubectl rollout history deployment/password-manager-api

# Ver detalles de un rollout específico
kubectl rollout history deployment/password-manager-api --revision=2
```

### Hacer Rollback a v1

```bash
# Rollback a la versión anterior (v1)
kubectl rollout undo deployment/password-manager-api

# Rollback a una revisión específica
kubectl rollout undo deployment/password-manager-api --to-revision=1

# Verificar el rollback
kubectl rollout status deployment/password-manager-api
```

## Comandos Útiles

```bash
# Escalar el deployment
kubectl scale deployment password-manager-api --replicas=3

# Ver recursos en todos los namespaces
kubectl get all -A

# Eliminar recursos
kubectl delete -f deployment.yaml
kubectl delete -f service.yaml
kubectl delete -f loadbalancer.yaml
kubectl delete -f secret.yaml

# Eliminar todo el namespace (si usaste un namespace específico)
kubectl delete namespace <namespace-name>

# Eliminar el cluster KIND
kind delete cluster --name password-manager
```

## Notas Importantes

1. **Secrets**: Los valores en `secret.yaml` están codificados en base64. Para crear tus propios secrets:
   ```bash
   echo -n "tu-password" | base64
   ```

2. **Imagen de prueba**: Si no tienes tu propia imagen, puedes modificar los manifiestos para usar `ealen/echo-server:0.6.0` descomentando las líneas correspondientes.

3. **Health Checks**: El deployment usa `/api/health` como endpoint de health check (debido al prefijo global `api` en la aplicación NestJS).

4. **MetalLB**: En producción real, los LoadBalancers obtienen IPs automáticamente del proveedor de cloud. En KIND, MetalLB simula este comportamiento.

5. **Versiones**: Los labels `version: v1` y `version: v2` ayudan a identificar y filtrar pods por versión durante las actualizaciones.

## Troubleshooting

```bash
# Ver eventos del cluster
kubectl get events --sort-by='.lastTimestamp'

# Describir un pod con problemas
kubectl describe pod <pod-name>

# Ver logs detallados
kubectl logs <pod-name> --previous

# Verificar conectividad de red
kubectl run debug --image=busybox -it --rm --restart=Never -- nslookup password-manager-api-service
```

