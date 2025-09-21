# Demo 2: Destination Rules

Learn how to define traffic policies and load balancing strategies.

## What You'll Learn
- How destination rules define service subsets
- Load balancing and connection pooling
- Circuit breaker patterns

## Prerequisites
- Bookinfo application deployed
- Multiple versions of reviews service (see [03-Traffic-Routing.md](03-Traffic-Routing.md))

## Installation Commands

```bash
# Deploy multiple versions of reviews service
kubectl apply -f manifests/demos/reviews-v2-deployment.yaml
kubectl apply -f manifests/demos/reviews-v3-deployment.yaml

# Wait for deployments
kubectl wait --for=condition=available --timeout=300s deployment/reviews-v2 -n mesh-demo
kubectl wait --for=condition=available --timeout=300s deployment/reviews-v3 -n mesh-demo
```

## Demo Steps

### Step 1: Apply Destination Rules
```bash
# Apply destination rules for all services
kubectl apply -f configs/traffic/destination-rules.yaml

# View the destination rules
kubectl get destinationrule -n mesh-demo
```

### Step 2: Examine Destination Rules
```bash
# View detailed destination rules
kubectl get destinationrule -n mesh-demo -o yaml
```

### Step 3: Test Load Balancing
```bash
# Generate multiple requests to see load balancing
for i in {1..10}; do
  echo "Request $i:"
  kubectl exec -n mesh-demo deployment/test-client -- curl -s productpage:9080/productpage | grep -o "reviews-v[0-9]" || echo "No version found"
done
```

### Step 4: Check Service Endpoints
```bash
# Check which endpoints are available
kubectl get endpoints -n mesh-demo

# Check specific service endpoints
kubectl get endpoints reviews -n mesh-demo -o yaml
```

## What You Should See

- **Service Subsets**: Different versions grouped by labels
- **Load Balancing**: Requests distributed across available versions
- **Connection Pooling**: Limits on connections and requests
- **Circuit Breakers**: Automatic failure handling

## Key Concepts

### Service Subsets
Destination rules define subsets based on labels:
```yaml
subsets:
- name: v1
  labels:
    version: v1
- name: v2
  labels:
    version: v2
```

### Load Balancing
```yaml
trafficPolicy:
  loadBalancer:
    simple: ROUND_ROBIN
```

### Circuit Breaker
```yaml
trafficPolicy:
  connectionPool:
    tcp:
      maxConnections: 100
  outlierDetection:
    consecutive5xxErrors: 3
    interval: 30s
```

## Cleanup
```bash
# Remove destination rules
kubectl delete -f configs/traffic/destination-rules.yaml --ignore-not-found=true
```

## Troubleshooting
```bash
# Check destination rules
kubectl get destinationrule -n mesh-demo

# Check service endpoints
kubectl get endpoints -n mesh-demo

# Check pod labels
kubectl get pods -n mesh-demo --show-labels
```
