#!/bin/bash
# Monitoring script for bookinfo application

set -e

NAMESPACE="bookinfo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

info() {
    echo -e "${BLUE}[MONITOR]${NC} $1"
}

show_pod_status() {
    info "Pod Status:"
    kubectl get pods -n "$NAMESPACE" -o wide
    echo ""
}

show_service_status() {
    info "Service Status:"
    kubectl get svc -n "$NAMESPACE"
    echo ""
}

show_istio_resources() {
    info "Istio Resources:"
    kubectl get destinationrule,virtualservice,gateway,peerauthentication,authorizationpolicy -n "$NAMESPACE"
    echo ""
}

show_traffic_metrics() {
    info "Traffic Metrics:"
    
    local pod=$(kubectl get pods -n "$NAMESPACE" -l app=test-client -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -n "$pod" ]; then
        kubectl exec -n "$NAMESPACE" "$pod" -- curl -s localhost:15000/stats | grep -E "(productpage|reviews|details|ratings|cluster)" | head -20
    else
        warn "Test client pod not found - cannot show traffic metrics"
    fi
    echo ""
}

show_mtls_status() {
    info "mTLS Status:"
    istioctl authn tls-check productpage."$NAMESPACE".svc.cluster.local 2>/dev/null || warn "Could not check mTLS status"
    echo ""
}

show_authorization_status() {
    info "Authorization Status:"
    kubectl get authorizationpolicy -n "$NAMESPACE" -o yaml
    echo ""
}

show_gateway_status() {
    info "Gateway Status:"
    kubectl get gateway -n "$NAMESPACE" -o yaml
    echo ""
}

show_logs() {
    local service=${1:-productpage}
    local lines=${2:-50}
    
    info "Recent logs for $service (last $lines lines):"
    kubectl logs -n "$NAMESPACE" -l app="$service" --tail="$lines" -c istio-proxy
    echo ""
}

show_continuous_monitoring() {
    info "Starting continuous monitoring (Ctrl+C to stop)..."
    
    while true; do
        clear
        echo "=== Mesh Demo Monitoring - $(date) ==="
        echo ""
        
        show_pod_status
        show_service_status
        show_istio_resources
        
        sleep 5
    done
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --logs [SERVICE] [LINES]  Show logs for service (default: productpage, 50 lines)"
    echo "  --continuous              Start continuous monitoring"
    echo "  --mtls                    Show mTLS status"
    echo "  --auth                    Show authorization status"
    echo "  --gateway                 Show gateway status"
    echo "  --metrics                 Show traffic metrics"
    echo "  --help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                        # Show basic status"
    echo "  $0 --continuous           # Start continuous monitoring"
    echo "  $0 --logs productpage 100 # Show 100 lines of productpage service logs"
    echo "  $0 --mtls --auth          # Show mTLS and authorization status"
}

main() {
    local show_logs_flag=false
    local service="productpage"
    local lines=50
    local continuous=false
    local show_mtls=false
    local show_auth=false
    local show_gateway=false
    local show_metrics=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --logs)
                show_logs_flag=true
                if [ -n "$2" ] && [[ ! "$2" =~ ^-- ]]; then
                    service="$2"
                    shift
                fi
                if [ -n "$2" ] && [[ ! "$2" =~ ^-- ]]; then
                    lines="$2"
                    shift
                fi
                shift
                ;;
            --continuous)
                continuous=true
                shift
                ;;
            --mtls)
                show_mtls=true
                shift
                ;;
            --auth)
                show_auth=true
                shift
                ;;
            --gateway)
                show_gateway=true
                shift
                ;;
            --metrics)
                show_metrics=true
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
    
    if [ "$continuous" = true ]; then
        show_continuous_monitoring
        return
    fi
    
    log "Mesh Demo Monitoring Dashboard"
    echo ""
    
    show_pod_status
    show_service_status
    show_istio_resources
    
    if [ "$show_mtls" = true ]; then
        show_mtls_status
    fi
    
    if [ "$show_auth" = true ]; then
        show_authorization_status
    fi
    
    if [ "$show_gateway" = true ]; then
        show_gateway_status
    fi
    
    if [ "$show_metrics" = true ]; then
        show_traffic_metrics
    fi
    
    if [ "$show_logs_flag" = true ]; then
        show_logs "$service" "$lines"
    fi
}

main "$@"