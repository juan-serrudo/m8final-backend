#!/bin/bash

# Script de despliegue para password-manager-api en KIND
# Uso: ./deploy.sh [setup|deploy|update|rollback|cleanup]

set -e

CLUSTER_NAME="password-manager"
NAMESPACE="default"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

function log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

function log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

function check_kind() {
    if ! command -v kind &> /dev/null; then
        log_error "KIND no está instalado. Por favor instálalo primero."
        exit 1
    fi
    log_info "KIND está instalado"
}

function check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl no está instalado. Por favor instálalo primero."
        exit 1
    fi
    log_info "kubectl está instalado"
}

function setup_cluster() {
    log_info "Creando cluster KIND: $CLUSTER_NAME"
    
    if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        log_warn "El cluster $CLUSTER_NAME ya existe. ¿Eliminarlo y crear uno nuevo? (y/n)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            kind delete cluster --name "$CLUSTER_NAME"
        else
            log_info "Usando cluster existente"
            kubectl cluster-info --context "kind-${CLUSTER_NAME}"
            return
        fi
    fi
    
    kind create cluster --name "$CLUSTER_NAME"
    kubectl cluster-info --context "kind-${CLUSTER_NAME}"
    
    log_info "Instalando MetalLB..."
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.4/config/manifests/metallb-native.yaml
    
    log_info "Esperando a que MetalLB esté listo..."
    kubectl wait --namespace metallb-system \
        --for=condition=ready pod \
        --selector=app=metallb \
        --timeout=90s || log_warn "MetalLB puede no estar completamente listo"
    
    log_info "Obteniendo subnet del docker network..."
    SUBNET=$(docker network inspect kind | grep -A 10 "Subnet" | grep "Subnet" | head -1 | awk -F'"' '{print $4}' || echo "")
    
    if [ -z "$SUBNET" ]; then
        log_warn "No se pudo obtener el subnet automáticamente"
        log_info "Por favor, ejecuta: docker network inspect kind | grep -A 10 'Subnet'"
        log_info "Luego edita metallb-config.yaml con el rango apropiado"
    else
        log_info "Subnet detectado: $SUBNET"
        log_info "Edita metallb-config.yaml si necesitas ajustar el rango de IPs"
    fi
    
    log_info "Aplicando configuración de MetalLB..."
    kubectl apply -f metallb-config.yaml
    
    log_info "Setup completado!"
}

function load_images() {
    log_info "¿Deseas cargar imágenes Docker locales en KIND? (y/n)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Cargando imagen v1..."
        if docker image inspect password-manager-api:v1 &> /dev/null; then
            kind load docker-image password-manager-api:v1 --name "$CLUSTER_NAME"
            log_info "Imagen v1 cargada"
        else
            log_warn "Imagen password-manager-api:v1 no encontrada localmente"
        fi
        
        log_info "Cargando imagen v2..."
        if docker image inspect password-manager-api:v2 &> /dev/null; then
            kind load docker-image password-manager-api:v2 --name "$CLUSTER_NAME"
            log_info "Imagen v2 cargada"
        else
            log_warn "Imagen password-manager-api:v2 no encontrada localmente"
        fi
    else
        log_info "Usando imágenes desde el registry remoto"
    fi
}

function deploy() {
    log_info "Desplegando aplicación..."
    
    log_info "1. Creando Secret..."
    kubectl apply -f secret.yaml
    
    log_info "2. Creando Deployment..."
    kubectl apply -f deployment.yaml
    
    log_info "3. Creando Service ClusterIP..."
    kubectl apply -f service.yaml
    
    log_info "4. Creando LoadBalancer..."
    kubectl apply -f loadbalancer.yaml
    
    log_info "Esperando a que los pods estén listos..."
    kubectl wait --for=condition=ready pod \
        -l app=password-manager-api \
        --timeout=120s || log_warn "Algunos pods pueden no estar listos todavía"
    
    log_info "Despliegue completado!"
    show_status
}

function update_to_v2() {
    log_info "Actualizando a versión v2..."
    
    kubectl set image deployment/password-manager-api \
        password-manager-api=mi-registry/password-manager-api:v2
    
    # Actualizar label de versión en el deployment
    kubectl patch deployment password-manager-api -p \
        '{"spec":{"template":{"metadata":{"labels":{"version":"v2"}}}}}'
    
    log_info "Monitoreando el rollout..."
    kubectl rollout status deployment/password-manager-api --timeout=120s
    
    log_info "Actualización completada!"
    show_status
}

function rollback() {
    log_info "Haciendo rollback a versión anterior..."
    
    kubectl rollout undo deployment/password-manager-api
    kubectl rollout status deployment/password-manager-api --timeout=120s
    
    log_info "Rollback completado!"
    show_status
}

function show_status() {
    echo ""
    log_info "=== Estado del Deployment ==="
    kubectl get deployment password-manager-api
    echo ""
    log_info "=== Pods ==="
    kubectl get pods -l app=password-manager-api
    echo ""
    log_info "=== Services ==="
    kubectl get svc -l app=password-manager-api
    echo ""
    
    EXTERNAL_IP=$(kubectl get svc password-manager-api-loadbalancer -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    if [ "$EXTERNAL_IP" != "pending" ] && [ -n "$EXTERNAL_IP" ]; then
        log_info "IP Externa del LoadBalancer: $EXTERNAL_IP"
        log_info "Probar con: curl http://$EXTERNAL_IP/api/health"
    else
        log_warn "El LoadBalancer aún no tiene IP asignada"
    fi
}

function verify() {
    log_info "Verificando despliegue..."
    
    log_info "1. Verificando pods..."
    kubectl get pods -l app=password-manager-api
    
    log_info "2. Verificando endpoints..."
    kubectl get endpoints password-manager-api-service
    
    log_info "3. Probando conectividad interna..."
    kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- \
        curl -s http://password-manager-api-service:3000/api/health || log_warn "Health check falló"
    
    log_info "4. Verificando variables de entorno..."
    POD_NAME=$(kubectl get pod -l app=password-manager-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    if [ -n "$POD_NAME" ]; then
        log_info "Variables de entorno en pod $POD_NAME:"
        kubectl exec "$POD_NAME" -- env | grep -E "DB_PASSWORD|JWT_SECRET|PORT" || log_warn "No se encontraron las variables esperadas"
    fi
}

function cleanup() {
    log_warn "Esto eliminará todos los recursos del despliegue. ¿Continuar? (y/n)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Eliminando recursos..."
        kubectl delete -f loadbalancer.yaml --ignore-not-found=true
        kubectl delete -f service.yaml --ignore-not-found=true
        kubectl delete -f deployment.yaml --ignore-not-found=true
        kubectl delete -f replicaset.yaml --ignore-not-found=true
        kubectl delete -f secret.yaml --ignore-not-found=true
        log_info "Limpieza completada!"
    else
        log_info "Limpieza cancelada"
    fi
}

function cleanup_all() {
    log_warn "Esto eliminará el cluster KIND completo. ¿Continuar? (y/n)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        kind delete cluster --name "$CLUSTER_NAME"
        log_info "Cluster eliminado!"
    else
        log_info "Operación cancelada"
    fi
}

# Menú principal
case "${1:-}" in
    setup)
        check_kind
        check_kubectl
        setup_cluster
        load_images
        ;;
    deploy)
        check_kubectl
        deploy
        ;;
    update)
        check_kubectl
        update_to_v2
        ;;
    rollback)
        check_kubectl
        rollback
        ;;
    status)
        check_kubectl
        show_status
        ;;
    verify)
        check_kubectl
        verify
        ;;
    cleanup)
        check_kubectl
        cleanup
        ;;
    cleanup-all)
        cleanup_all
        ;;
    *)
        echo "Uso: $0 {setup|deploy|update|rollback|status|verify|cleanup|cleanup-all}"
        echo ""
        echo "Comandos:"
        echo "  setup        - Crea el cluster KIND y configura MetalLB"
        echo "  deploy       - Despliega la aplicación"
        echo "  update       - Actualiza a versión v2"
        echo "  rollback     - Hace rollback a versión anterior"
        echo "  status       - Muestra el estado actual"
        echo "  verify       - Verifica el funcionamiento"
        echo "  cleanup      - Elimina los recursos de la aplicación"
        echo "  cleanup-all  - Elimina el cluster completo"
        exit 1
        ;;
esac

