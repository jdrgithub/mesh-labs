# Deployment Guide

## Prerequisites

### System Requirements
- Kubernetes cluster (v1.21+)
- Istio installed and configured
- kubectl configured for cluster access
- Make utility (optional, for using Makefile)

### Istio Installation
```bash
# Install Istio
istioctl install --set values.defaultRevision=default

# Enable sidecar injection
kubectl label namespace default istio-injection=enabled
```

## Quick Start

### 1. Deploy Complete Application
```bash
# Deploy with default configuration (permissive mTLS)
make deploy

# Or use script directly
./scripts/deploy.sh
```

### 2. Verify Deployment
```bash
# Check deployment status
make status

# Run tests
make test
```

### 3. Monitor Application
```bash
# Show current status
make monitor

# Start continuous monitoring
make monitor-continuous
```

## Deployment Options

### mTLS Configuration

#### Permissive mTLS (Default)
```bash
make deploy-permissive
# or
./scripts/deploy.sh --mtls permissive
```

#### Strict mTLS
```bash
make deploy-strict
# or
./scripts/deploy.sh --mtls strict
```

### Minimal Deployment
```bash
# Deploy base application only (no security/gateway)
make deploy-minimal
# or
./scripts/deploy.sh --no-security --no-gateway
```

## Manual Deployment Steps

### 1. Base Application
```bash
# Apply base manifests
kubectl apply -f manifests/base/

# Verify pods are running
kubectl get pods -n bookinfo
```

### 2. Traffic Configuration
```bash
# Apply traffic management
kubectl apply -f configs/traffic/

# Check traffic routing
kubectl get virtualservice,destinationrule -n bookinfo
```

### 3. Security Configuration
```bash
# Apply mTLS (choose one)
kubectl apply -f configs/mtls/peer-authentication-permissive.yaml
# or
kubectl apply -f configs/mtls/peer-authentication-strict.yaml

# Apply authorization policies
kubectl apply -f configs/security/
```

### 4. Gateway Configuration
```bash
# Apply gateway for external access
kubectl apply -f configs/observability/
```

## Testing and Validation

### Basic Connectivity Test
```bash
# Get test client pod
CLIENT_POD=$(kubectl get pods -n bookinfo -l app=test-client -o jsonpath='{.items[0].metadata.name}')

# Test connectivity
kubectl exec -n bookinfo $CLIENT_POD -- curl -s productpage:9080/productpage
```

### Traffic Distribution Test
```bash
# Test traffic splitting
make test-traffic

# Or manually
for i in {1..20}; do
  kubectl exec -n bookinfo $CLIENT_POD -- curl -s productpage:9080/productpage | jq -r '.hostname'
done | sort | uniq -c
```

### mTLS Verification
```bash
# Check mTLS status
make check-mtls

# Or manually
istioctl authn tls-check productpage.bookinfo.svc.cluster.local
```

### Authorization Test
```bash
# Test authorization policies
kubectl exec -n bookinfo $CLIENT_POD -- curl -s -w "%{http_code}" productpage:9080/productpage
```

## Traffic Management

### Switch to Canary Routing
```bash
make switch-canary
# or
kubectl apply -f configs/traffic/virtual-service-canary.yaml
```

### Switch to Production Routing
```bash
make switch-production
# or
kubectl apply -f configs/traffic/virtual-service-production.yaml
```

### Test Canary Header Routing
```bash
# Route to v2 using canary header
kubectl exec -n bookinfo $CLIENT_POD -- curl -s -H "canary: true" productpage:9080/productpage
```

## Monitoring and Debugging

### View Logs
```bash
# Application logs
make logs

# Istio proxy logs
make logs-proxy

# Specific service logs
kubectl logs -n bookinfo -l app=productpage --tail=100
```

### Check Status
```bash
# Comprehensive status
make status

# Specific components
make monitor-mtls
make monitor-auth
make monitor-metrics
```

### Port Forwarding
```bash
# Access service locally
make port-forward

# Then access via http://localhost:8080
```

### Shell Access
```bash
# Get shell in test client
make shell

# Or specific pod
kubectl exec -n bookinfo -it deployment/test-client -- sh
```

## Troubleshooting

### Common Issues

#### Pods Not Starting
```bash
# Check pod status
kubectl describe pod -n bookinfo <pod-name>

# Check events
kubectl get events -n bookinfo --sort-by='.lastTimestamp'
```

#### Traffic Not Routing
```bash
# Check VirtualService
kubectl get virtualservice -n bookinfo -o yaml

# Check DestinationRule
kubectl get destinationrule -n bookinfo -o yaml

# Check proxy configuration
istioctl proxy-config route -n bookinfo <pod-name>
```

#### mTLS Issues
```bash
# Check mTLS configuration
kubectl get peerauthentication -n bookinfo -o yaml

# Verify mTLS status
istioctl authn tls-check productpage.bookinfo.svc.cluster.local
```

#### Authorization Problems
```bash
# Check authorization policies
kubectl get authorizationpolicy -n bookinfo -o yaml

# Check proxy logs for authz
kubectl logs -n bookinfo -l app=productpage -c istio-proxy | grep authz
```

### Validation Commands
```bash
# Validate Istio configuration
make validate

# Check cluster connectivity
kubectl cluster-info

# Verify Istio installation
istioctl version
```

## Cleanup

### Remove Application
```bash
# Remove all resources
make clean

# Or manually
kubectl delete namespace bookinfo
```

### Remove Configurations Only
```bash
# Remove Istio configurations
make clean-configs

# Or manually
kubectl delete -f configs/ --ignore-not-found=true
```

## Production Considerations

### Resource Limits
- All containers have resource requests and limits
- Adjust based on actual usage patterns
- Monitor resource utilization

### Security
- Use strict mTLS in production
- Implement comprehensive authorization policies
- Regular security audits and updates

### Monitoring
- Set up proper monitoring and alerting
- Use production-grade observability tools
- Implement automated health checks

### Backup and Recovery
- Regular configuration backups
- Documented rollback procedures
- Tested disaster recovery plans