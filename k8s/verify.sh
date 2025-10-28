#!/bin/bash

# Script de verificación rápida para password-manager-api en Kubernetes

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

function log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

function log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

function log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

function log_error() {
    echo -e "${RED}✗${NC} $1"
}

function log_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Verificar que kubectl está disponible
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl no está instalado"
    exit 1
fi

log_section "1. Estado del Deployment"
if kubectl get deployment password-manager-api &> /dev/null; then
    kubectl get deployment password-manager-api
    log_success "Deployment existe"
else
    log_error "Deployment no encontrado"
fi

log_section "2. Estado de los Pods"
PODS=$(kubectl get pods -l app=password-manager-api --no-headers 2>/dev/null | wc -l)
if [ "$PODS" -gt 0 ]; then
    kubectl get pods -l app=password-manager-api
    READY=$(kubectl get pods -l app=password-manager-api --no-headers 2>/dev/null | grep -c "Running\|Completed" || echo "0")
    if [ "$READY" -gt 0 ]; then
        log_success "$READY pod(s) en estado Running"
    else
        log_warn "Pods no están en estado Running"
    fi
else
    log_error "No se encontraron pods"
fi

log_section "3. Estado de los Services"
if kubectl get svc password-manager-api-service &> /dev/null; then
    kubectl get svc password-manager-api-service
    log_success "Service ClusterIP existe"
else
    log_warn "Service ClusterIP no encontrado"
fi

if kubectl get svc password-manager-api-loadbalancer &> /dev/null; then
    kubectl get svc password-manager-api-loadbalancer
    EXTERNAL_IP=$(kubectl get svc password-manager-api-loadbalancer -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "pending" ]; then
        log_success "LoadBalancer tiene IP: $EXTERNAL_IP"
    else
        log_warn "LoadBalancer IP pendiente"
    fi
else
    log_warn "Service LoadBalancer no encontrado"
fi

log_section "4. Endpoints"
if kubectl get endpoints password-manager-api-service &> /dev/null; then
    ENDPOINTS=$(kubectl get endpoints password-manager-api-service -o jsonpath='{.subsets[0].addresses[*].ip}' 2>/dev/null || echo "")
    if [ -n "$ENDPOINTS" ]; then
        log_success "Endpoints activos: $ENDPOINTS"
        kubectl get endpoints password-manager-api-service
    else
        log_warn "No hay endpoints activos"
    fi
else
    log_warn "No se encontraron endpoints"
fi

log_section "5. Secrets"
if kubectl get secret password-manager-api-secrets &> /dev/null; then
    log_success "Secret existe"
    kubectl get secret password-manager-api-secrets
else
    log_warn "Secret no encontrado"
fi

log_section "6. Health Check"
POD_NAME=$(kubectl get pod -l app=password-manager-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$POD_NAME" ]; then
    if kubectl exec "$POD_NAME" -- wget -qO- --timeout=5 http://localhost:3000/api/health &> /dev/null; then
        log_success "Health check exitoso en pod $POD_NAME"
        kubectl exec "$POD_NAME" -- wget -qO- http://localhost:3000/api/health
    else
        log_warn "Health check falló en pod $POD_NAME"
    fi
else
    log_warn "No hay pods disponibles para health check"
fi

log_section "7. Conectividad Interna"
if kubectl run curl-test --image=curlimages/curl --rm -i --restart=Never -- \
    curl -s --max-time 5 http://password-manager-api-service:3000/api/health &> /dev/null; then
    log_success "Conectividad interna exitosa"
    echo ""
    kubectl run curl-test --image=curlimages/curl --rm -i --restart=Never -- \
        curl -s http://password-manager-api-service:3000/api/health
else
    log_warn "Conectividad interna falló"
fi

log_section "8. Variables de Entorno"
if [ -n "$POD_NAME" ]; then
    if kubectl exec "$POD_NAME" -- printenv DB_PASSWORD &> /dev/null; then
        log_success "Variables de entorno del Secret están disponibles"
        echo "DB_PASSWORD: $(kubectl exec "$POD_NAME" -- printenv DB_PASSWORD | head -c 5)..."
        echo "JWT_SECRET: $(kubectl exec "$POD_NAME" -- printenv JWT_SECRET | head -c 5)..."
    else
        log_warn "Variables de entorno del Secret no disponibles"
    fi
fi

log_section "9. Versionado"
V1_PODS=$(kubectl get pods -l app=password-manager-api,version=v1 --no-headers 2>/dev/null | wc -l)
V2_PODS=$(kubectl get pods -l app=password-manager-api,version=v2 --no-headers 2>/dev/null | wc -l)
log_info "Pods v1: $V1_PODS"
log_info "Pods v2: $V2_PODS"

echo -e "\n${GREEN}Verificación completada${NC}"

