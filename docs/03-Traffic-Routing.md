# Demo 3: Traffic Routing

Learn how to route traffic between different service versions for canary deployments.

## What You'll Learn
- Canary deployments with traffic splitting
- Header-based routing
- Gradual traffic migration

## Prerequisites
- Bookinfo application deployed
- Multiple versions of reviews service

## Installation Commands

```bash
# Deploy multiple versions of reviews service
kubectl apply -f manifests/demos/reviews-v2-deployment.yaml
kubectl apply -f manifests/demos/reviews-v3-deployment.yaml

# Apply destination rules
kubectl apply -f configs/traffic/destination-rules.yaml

# Wait for deployments
kubectl wait --for=condition=available --timeout=300s deployment/reviews-v2 -n mesh-demo
kubectl wait --for=condition=available --timeout=300s deployment/reviews-v3 -n mesh-demo
```

## Demo Steps

### Step 1: Start with 100% v1
```bash
# Apply basic virtual service (100% v1)
kubectl apply -f configs/traffic/virtual-service.yaml

# Test traffic routing
kubectl exec -n mesh-demo deployment/test-client -- curl -s productpage:9080/productpage
```

### Step 2: Canary Deployment (90% v1, 10% v2)
```bash
# Apply canary routing
kubectl apply -f configs/demos/virtual-service-canary.yaml

# Test traffic distribution
for i in {1..10}; do
  echo "Request $i:"
  kubectl exec -n mesh-demo deployment/test-client -- curl -s productpage:9080/productpage | grep -o "reviews-v[0-9]" || echo "No version found"
done
```

### Step 3: 50/50 Split
```bash
# Apply 50/50 routing
kubectl apply -f configs/demos/virtual-service-50-50.yaml

# Test traffic distribution
for i in {1..10}; do
  echo "Request $i:"
  kubectl exec -n mesh-demo deployment/test-client -- curl -s productpage:9080/productpage | grep -o "reviews-v[0-9]" || echo "No version found"
done
```

### Step 4: Complete Migration to v2
```bash
# Apply 100% v2 routing
kubectl apply -f configs/demos/virtual-service-100-v2.yaml

# Test traffic routing
kubectl exec -n mesh-demo deployment/test-client -- curl -s productpage:9080/productpage
```

### Step 5: Header-Based Routing
```bash
# Apply header-based routing
kubectl apply -f configs/demos/virtual-service-header-routing.yaml

# Test without header (goes to v1)
echo "Without header (should go to v1):"
kubectl exec -n mesh-demo deployment/test-client -- curl -s productpage:9080/productpage | grep -o "reviews-v[0-9]"

# Test with jason header (goes to v2)
echo "With jason header (should go to v2):"
kubectl exec -n mesh-demo deployment/test-client -- curl -s -H "end-user: jason" productpage:9080/productpage | grep -o "reviews-v[0-9]"
```

## What You Should See

- **Traffic Splitting**: Requests distributed according to weights
- **Gradual Migration**: Smooth transition between versions
- **Header Routing**: Different users get different versions
- **Zero Downtime**: No service interruption during changes

## Key Concepts

### Weighted Routing
```yaml
http:
- route:
  - destination:
      host: reviews
      subset: v1
    weight: 90
  - destination:
      host: reviews
      subset: v2
    weight: 10
```

### Header-Based Routing
```yaml
http:
- match:
  - headers:
      end-user:
        exact: jason
  route:
  - destination:
      host: reviews
      subset: v2
```

## Cleanup
```bash
# Remove virtual services
kubectl delete -f configs/demos/ --ignore-not-found=true
kubectl delete -f configs/traffic/virtual-service.yaml --ignore-not-found=true
```

## Troubleshooting
```bash
# Check virtual services
kubectl get virtualservice -n mesh-demo

# Check destination rules
kubectl get destinationrule -n mesh-demo

# Check service endpoints
kubectl get endpoints -n mesh-demo
```
