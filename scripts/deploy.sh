#!/bin/bash
# Deployment script for mesh-demo application

set -e

NAMESPACE="mesh-demo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed"
        exit 1
    fi
    
    if ! command -v istioctl &> /dev/null; then
        error "istioctl is not installed"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    log "Prerequisites check passed"
}

deploy_base() {
    log "Deploying base manifests..."
    kubectl apply -f "$PROJECT_ROOT/manifests/base/"
    kubectl wait --for=condition=available --timeout=300s deployment/hello-v1 -n "$NAMESPACE"
    kubectl wait --for=condition=available --timeout=300s deployment/hello-v2 -n "$NAMESPACE"
    kubectl wait --for=condition=available --timeout=300s deployment/test-client -n "$NAMESPACE"
    log "Base deployment completed"
}

deploy_traffic_config() {
    log "Deploying traffic configuration..."
    kubectl apply -f "$PROJECT_ROOT/configs/traffic/"
    log "Traffic configuration deployed"
}

deploy_mtls_config() {
    local mode=${1:-permissive}
    log "Deploying mTLS configuration (mode: $mode)..."
    
    if [ "$mode" = "strict" ]; then
        kubectl apply -f "$PROJECT_ROOT/configs/mtls/peer-authentication-strict.yaml"
    else
        kubectl apply -f "$PROJECT_ROOT/configs/mtls/peer-authentication-permissive.yaml"
    fi
    
    log "mTLS configuration deployed"
}

deploy_security_config() {
    log "Deploying security configuration..."
    kubectl apply -f "$PROJECT_ROOT/configs/security/"
    log "Security configuration deployed"
}

deploy_gateway() {
    log "Deploying gateway configuration..."
    kubectl apply -f "$PROJECT_ROOT/configs/observability/"
    log "Gateway configuration deployed"
}

verify_deployment() {
    log "Verifying deployment..."
    
    # Check pods
    kubectl get pods -n "$NAMESPACE"
    
    # Check services
    kubectl get svc -n "$NAMESPACE"
    
    # Check Istio resources
    kubectl get destinationrule,virtualservice,gateway -n "$NAMESPACE"
    
    log "Deployment verification completed"
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --mtls MODE     mTLS mode: permissive (default) or strict"
    echo "  --no-security   Skip security configuration"
    echo "  --no-gateway    Skip gateway configuration"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                           # Deploy with permissive mTLS"
    echo "  $0 --mtls strict            # Deploy with strict mTLS"
    echo "  $0 --no-security --no-gateway # Deploy base + traffic only"
}

main() {
    local mtls_mode="permissive"
    local deploy_security=true
    local deploy_gateway=true
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --mtls)
                mtls_mode="$2"
                shift 2
                ;;
            --no-security)
                deploy_security=false
                shift
                ;;
            --no-gateway)
                deploy_gateway=false
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    log "Starting deployment with mTLS mode: $mtls_mode"
    
    check_prerequisites
    deploy_base
    deploy_traffic_config
    deploy_mtls_config "$mtls_mode"
    
    if [ "$deploy_security" = true ]; then
        deploy_security_config
    fi
    
    if [ "$deploy_gateway" = true ]; then
        deploy_gateway
    fi
    
    verify_deployment
    
    log "Deployment completed successfully!"
    log "Test the deployment with: ./scripts/test.sh"
}

main "$@"