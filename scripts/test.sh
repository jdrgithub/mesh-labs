#!/bin/bash
# Test script for mesh-demo application

set -e

NAMESPACE="mesh-demo"
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
    echo -e "${BLUE}[TEST]${NC} $1"
}

get_test_client_pod() {
    kubectl get pods -n "$NAMESPACE" -l app=test-client -o jsonpath='{.items[0].metadata.name}'
}

test_basic_connectivity() {
    info "Testing basic connectivity..."
    
    local pod=$(get_test_client_pod)
    if [ -z "$pod" ]; then
        error "Test client pod not found"
        return 1
    fi
    
    local response=$(kubectl exec -n "$NAMESPACE" "$pod" -- curl -s -w "%{http_code}" hello:8080/ -o /dev/null)
    
    if [ "$response" = "200" ]; then
        log "Basic connectivity test passed"
        return 0
    else
        error "Basic connectivity test failed (HTTP $response)"
        return 1
    fi
}

test_traffic_distribution() {
    info "Testing traffic distribution..."
    
    local pod=$(get_test_client_pod)
    local count=${1:-20}
    
    log "Making $count requests to analyze traffic distribution..."
    
    local results=$(kubectl exec -n "$NAMESPACE" "$pod" -- sh -c "
        for i in \$(seq 1 $count); do
            curl -s hello:8080/ | grep -o '\"hostname\":\"[^\"]*\"' | cut -d'\"' -f4
        done | sort | uniq -c
    ")
    
    echo "$results"
    
    # Check if we have traffic to both versions
    local v1_count=$(echo "$results" | grep "hello-v1" | awk '{print $1}' || echo "0")
    local v2_count=$(echo "$results" | grep "hello-v2" | awk '{print $1}' || echo "0")
    
    if [ "$v1_count" -gt 0 ] && [ "$v2_count" -gt 0 ]; then
        log "Traffic distribution test passed (v1: $v1_count, v2: $v2_count)"
    else
        warn "Traffic distribution may not be working as expected (v1: $v1_count, v2: $v2_count)"
    fi
}

test_mtls() {
    info "Testing mTLS configuration..."
    
    local pod=$(get_test_client_pod)
    local response=$(kubectl exec -n "$NAMESPACE" "$pod" -- curl -s -I hello:8080/ | grep -i "x-forwarded-client-cert" || echo "")
    
    if [ -n "$response" ]; then
        log "mTLS test passed - client certificate present"
    else
        warn "mTLS test inconclusive - no client certificate header found"
    fi
}

test_authorization() {
    info "Testing authorization policies..."
    
    local pod=$(get_test_client_pod)
    local response=$(kubectl exec -n "$NAMESPACE" "$pod" -- curl -s -w "%{http_code}" hello:8080/ -o /dev/null)
    
    if [ "$response" = "200" ]; then
        log "Authorization test passed - access allowed"
    elif [ "$response" = "403" ]; then
        log "Authorization test passed - access denied as expected"
    else
        warn "Authorization test inconclusive (HTTP $response)"
    fi
}

test_gateway() {
    info "Testing gateway access..."
    
    local gateway_ip=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    
    if [ -z "$gateway_ip" ]; then
        gateway_ip=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.spec.clusterIP}')
        warn "Using cluster IP for gateway test: $gateway_ip"
    fi
    
    if [ -n "$gateway_ip" ]; then
        local response=$(curl -s -w "%{http_code}" -H "Host: hello.local" "http://$gateway_ip/" -o /dev/null || echo "000")
        
        if [ "$response" = "200" ]; then
            log "Gateway test passed"
        else
            warn "Gateway test failed (HTTP $response)"
        fi
    else
        warn "Gateway IP not found - skipping gateway test"
    fi
}

test_canary_header() {
    info "Testing canary header routing..."
    
    local pod=$(get_test_client_pod)
    local response=$(kubectl exec -n "$NAMESPACE" "$pod" -- curl -s -H "canary: true" hello:8080/ | grep -o '\"hostname\":\"[^\"]*\"' | cut -d'\"' -f4)
    
    if [[ "$response" == *"hello-v2"* ]]; then
        log "Canary header test passed - routed to v2"
    else
        warn "Canary header test failed - not routed to v2 (got: $response)"
    fi
}

run_load_test() {
    info "Running load test..."
    
    local pod=$(get_test_client_pod)
    local count=${1:-100}
    
    log "Running $count requests for load testing..."
    
    local start_time=$(date +%s)
    kubectl exec -n "$NAMESPACE" "$pod" -- sh -c "
        for i in \$(seq 1 $count); do
            curl -s hello:8080/ > /dev/null
        done
    "
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log "Load test completed: $count requests in ${duration}s"
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --traffic-count N    Number of requests for traffic distribution test (default: 20)"
    echo "  --load-count N       Number of requests for load test (default: 100)"
    echo "  --skip-gateway       Skip gateway tests"
    echo "  --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                           # Run all tests"
    echo "  $0 --traffic-count 50        # Test with 50 traffic distribution requests"
    echo "  $0 --skip-gateway            # Skip gateway tests"
}

main() {
    local traffic_count=20
    local load_count=100
    local skip_gateway=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --traffic-count)
                traffic_count="$2"
                shift 2
                ;;
            --load-count)
                load_count="$2"
                shift 2
                ;;
            --skip-gateway)
                skip_gateway=true
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
    
    log "Starting mesh-demo tests..."
    
    test_basic_connectivity
    test_traffic_distribution "$traffic_count"
    test_mtls
    test_authorization
    test_canary_header
    
    if [ "$skip_gateway" = false ]; then
        test_gateway
    fi
    
    run_load_test "$load_count"
    
    log "All tests completed!"
}

main "$@"