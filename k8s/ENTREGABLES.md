# Entregables - Despliegue Kubernetes con KIND

## 📋 Resumen de Archivos Entregados

### Manifiestos YAML Principales

1. **secret.yaml**
   - Secret tipo Opaque con `DB_PASSWORD` y `JWT_SECRET`
   - Valores codificados en base64
   - Labels: `app: password-manager-api`

2. **replicaset.yaml**
   - ReplicaSet simple para versión v1
   - 2 réplicas
   - Labels: `app: password-manager-api`, `version: v1`
   - Usa `envFrom` con `secretRef` para cargar variables del Secret
   - Puerto 3000

3. **deployment.yaml**
   - Deployment con estrategia `RollingUpdate`
   - 2 réplicas
   - Versión inicial: v1
   - `readinessProbe` y `livenessProbe` en `/api/health` puerto 3000
   - `envFrom` para usar Secret
   - Configuración de recursos (requests/limits)

4. **service.yaml**
   - Service tipo `ClusterIP`
   - Puerto 3000 → targetPort 3000
   - Selector: `app: password-manager-api`

5. **loadbalancer.yaml**
   - Service tipo `LoadBalancer`
   - Puerto 80 → targetPort 3000
   - Selector: `app: password-manager-api`
   - Anotación comentada para MetalLB

### Archivos de Configuración y Utilidades

6. **metallb-config.yaml**
   - Configuración de IPAddressPool para MetalLB
   - L2Advertisement para anunciar las IPs
   - Rango de IPs configurable

7. **deployment-v2.yaml.example**
   - Ejemplo de deployment para versión v2
   - Referencia para actualizaciones
   - Muestra cómo cambiar labels e imagen

8. **deploy.sh**
   - Script de automatización para despliegue
   - Comandos: setup, deploy, update, rollback, status, verify, cleanup
   - Manejo de errores y mensajes informativos

9. **verify.sh**
   - Script de verificación rápida
   - Comprueba estado de pods, services, endpoints
   - Realiza health checks y pruebas de conectividad

### Documentación

10. **README.md**
    - Documentación completa del despliegue
    - Instrucciones paso a paso
    - Configuración de KIND y MetalLB
    - Comandos de actualización y rollback

11. **COMMANDS.md**
    - Lista exhaustiva de comandos kubectl
    - Comandos de verificación
    - Comandos de gestión y debugging
    - Ejemplos de uso

12. **ENTREGABLES.md** (este archivo)
    - Resumen de todos los entregables

## ✅ Cumplimiento de Requisitos

### ✓ Manifiestos YAML
- [x] replicaset.yaml
- [x] deployment.yaml
- [x] service.yaml
- [x] loadbalancer.yaml
- [x] secret.yaml

### ✓ Versionamiento
- [x] Versión v1 inicial en todos los manifiestos
- [x] Ejemplo de v2 (deployment-v2.yaml.example)
- [x] Procedimiento de actualización documentado
- [x] Procedimiento de rollback documentado
- [x] Labels `version: v1` y `version: v2`

### ✓ Configuración
- [x] Labels consistentes: `app: password-manager-api`
- [x] `envFrom` con `secretRef` en ReplicaSet y Deployment
- [x] Puerto 3000 configurado correctamente
- [x] Health probes (readiness y liveness)
- [x] Estrategia RollingUpdate

### ✓ LoadBalancer
- [x] Service tipo LoadBalancer
- [x] Configuración de MetalLB incluida
- [x] Instrucciones para instalación de MetalLB

### ✓ Secrets
- [x] Secret tipo Opaque
- [x] Variables: DB_PASSWORD, JWT_SECRET
- [x] Valores en base64
- [x] Integración con Deployment/ReplicaSet

## 🚀 Inicio Rápido

```bash
# 1. Ir al directorio k8s
cd k8s

# 2. Setup del cluster y MetalLB
./deploy.sh setup

# 3. Desplegar aplicación
./deploy.sh deploy

# 4. Verificar
./verify.sh

# 5. Actualizar a v2
./deploy.sh update

# 6. Rollback si es necesario
./deploy.sh rollback
```

## 📝 Notas Importantes

1. **Imagen Docker**: Los manifiestos usan `mi-registry/password-manager-api:v1` por defecto. Puedes:
   - Cambiar a tu registry real
   - Usar `ealen/echo-server:0.6.0` para pruebas (descomentar en los manifiestos)
   - Cargar imágenes locales con `kind load docker-image`

2. **MetalLB**: Necesario para LoadBalancer en KIND. El script `deploy.sh setup` lo instala automáticamente.

3. **Secrets**: Los valores en `secret.yaml` son ejemplos. Para producción:
   ```bash
   echo -n "tu-password-real" | base64
   ```

4. **Health Endpoint**: La aplicación usa `/api/health` como endpoint de health check (prefijo global `api` configurado en NestJS).

5. **Red KIND**: Ajusta el rango de IPs en `metallb-config.yaml` según tu configuración de Docker.

## 🔍 Verificación Rápida

Después del despliegue, ejecuta:

```bash
# Ver estado general
./verify.sh

# O manualmente
kubectl get all -l app=password-manager-api
kubectl get svc password-manager-api-loadbalancer
```

## 📚 Recursos Adicionales

- **README.md**: Documentación completa
- **COMMANDS.md**: Comandos de kubectl para todas las operaciones
- Scripts ejecutables: `deploy.sh` y `verify.sh`

---

**Fecha de creación**: $(date)
**Versión**: 1.0

