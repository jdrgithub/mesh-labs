# Demo 6: Fault Injection

Learn how to test application resilience by injecting failures.

## What You'll Learn
- How to inject delays and errors
- Testing fault tolerance
- Circuit breaker behavior

## Prerequisites
- Bookinfo application deployed
- Traffic routing configured

## Installation Commands

```bash
# Deploy Bookinfo
kubectl apply -f manifests/base/

# Apply traffic configuration
kubectl apply -f configs/traffic/

# Wait for deployments
kubectl wait --for=condition=available --timeout=300s deployment/productpage-v1 -n bookinfo
kubectl wait --for=condition=available --timeout=300s deployment/details-v1 -n bookinfo
kubectl wait --for=condition=available --timeout=300s deployment/reviews-v1 -n bookinfo
kubectl wait --for=condition=available --timeout=300s deployment/ratings-v1 -n bookinfo
kubectl wait --for=condition=available --timeout=300s deployment/test-client -n bookinfo
```

## Demo Steps

### Step 1: Test Normal Operation
```bash
# Test normal operation
kubectl exec -n bookinfo deployment/test-client -- curl -s productpage:9080/productpage

# Test multiple requests
for i in {1..5}; do
  echo "Request $i:"
  kubectl exec -n bookinfo deployment/test-client -- curl -s -w "HTTP Status: %{http_code}\n" productpage:9080/productpage | tail -1
done
```

### Step 2: Apply Fault Injection
```bash
# Apply fault injection to ratings service
kubectl apply -f configs/demos/virtual-service-fault-injection.yaml

# Check the configuration
kubectl get virtualservice ratings -n bookinfo -o yaml
```

### Step 3: Test Fault Tolerance
```bash
# Test with fault injection
for i in {1..10}; do
  echo "Request $i:"
  kubectl exec -n bookinfo deployment/test-client -- curl -s -w "HTTP Status: %{http_code}\n" productpage:9080/productpage | tail -1
done
```

### Step 4: Observe Behavior
```bash
# Check if circuit breaker activates
kubectl exec -n bookinfo deployment/test-client -- curl -s productpage:9080/productpage

# Check service logs
kubectl logs -n bookinfo -l app=productpage --tail=10
```

### Step 5: Remove Fault Injection
```bash
# Remove fault injection
kubectl delete -f configs/demos/virtual-service-fault-injection.yaml

# Test normal operation again
kubectl exec -n bookinfo deployment/test-client -- curl -s productpage:9080/productpage
```

## What You Should See

- **Normal Operation**: All requests succeed
- **Fault Injection**: Some requests fail or are delayed
- **Circuit Breaker**: Automatic failure handling
- **Recovery**: Normal operation after removing faults

## Key Concepts

### Fault Injection Types
```yaml
fault:
  delay:
    percentage:
      value: 0.1
    fixedDelay: 5s
  abort:
    percentage:
      value: 10
    httpStatus: 500
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
    baseEjectionTime: 30s
```

## Cleanup
```bash
# Remove fault injection
kubectl delete -f configs/demos/virtual-service-fault-injection.yaml --ignore-not-found=true

# Remove traffic configuration
kubectl delete -f configs/traffic/ --ignore-not-found=true
```

## Troubleshooting
```bash
# Check virtual services
kubectl get virtualservice -n bookinfo

# Check destination rules
kubectl get destinationrule -n bookinfo

# Check service logs
kubectl logs -n bookinfo -l app=productpage --tail=20

# Check service status
kubectl get pods -n bookinfo
```
