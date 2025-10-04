# Demo 1: mTLS (Mutual TLS)

Learn how Istio automatically encrypts service-to-service communication.

## What You'll Learn
- How mTLS works in Istio
- Difference between permissive and strict mTLS
- How to verify mTLS status

## Prerequisites
- Bookinfo application deployed (see [MINIMAL.md](MINIMAL.md))

## Installation Commands

```bash
# Deploy Bookinfo if not already deployed
kubectl apply -f manifests/base/

# Wait for deployments
kubectl wait --for=condition=available --timeout=300s deployment/productpage-v1 -n bookinfo
kubectl wait --for=condition=available --timeout=300s deployment/details-v1 -n bookinfo
kubectl wait --for=condition=available --timeout=300s deployment/reviews-v1 -n bookinfo
kubectl wait --for=condition=available --timeout=300s deployment/ratings-v1 -n bookinfo
kubectl wait --for=condition=available --timeout=300s deployment/test-client -n bookinfo
```

## Demo Steps

### Step 1: Check Current mTLS Status
```bash
# Check mTLS status for productpage service
istioctl authn tls-check productpage.bookinfo.svc.cluster.local
```

### Step 2: Test Service Communication
```bash
# Test basic communication between services
kubectl exec -n bookinfo deployment/test-client -- curl -s productpage:9080/productpage
```

### Step 3: Apply Permissive mTLS (Default)
```bash
# Apply permissive mTLS configuration
kubectl apply -f configs/mtls/peer-authentication-permissive.yaml

# Verify the configuration
kubectl get peerauthentication -n bookinfo
```

### Step 4: Test with Permissive mTLS
```bash
# Test communication (should work)
kubectl exec -n bookinfo deployment/test-client -- curl -s productpage:9080/productpage

# Check mTLS status again
istioctl authn tls-check productpage.bookinfo.svc.cluster.local
```

### Step 5: Switch to Strict mTLS
```bash
# Apply strict mTLS configuration
kubectl apply -f configs/mtls/peer-authentication-strict.yaml

# Verify the configuration
kubectl get peerauthentication -n bookinfo
```

### Step 6: Test with Strict mTLS
```bash
# Test communication (should still work with sidecars)
kubectl exec -n bookinfo deployment/test-client -- curl -s productpage:9080/productpage

# Check mTLS status
istioctl authn tls-check productpage.bookinfo.svc.cluster.local
```

## What You Should See

- **Permissive mTLS**: Services can communicate with or without encryption
- **Strict mTLS**: All communication is encrypted between sidecars
- **Status Check**: Shows which services are using mTLS

## Cleanup
```bash
# Remove mTLS configuration
kubectl delete -f configs/mtls/ --ignore-not-found=true
```

## Troubleshooting
```bash
# Check if sidecars are injected
kubectl get pods -n bookinfo -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].name}{"\n"}{end}'

# Check peer authentication
kubectl get peerauthentication -n bookinfo

# Check mTLS status for all services
istioctl authn tls-check -n bookinfo
```
