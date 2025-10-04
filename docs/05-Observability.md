# Demo 5: Observability with Kiali and Jaeger

Learn how to visualize service mesh topology and trace requests.

## What You'll Learn
- Service mesh visualization with Kiali
- Distributed tracing with Jaeger
- Performance monitoring and metrics

## Prerequisites
- Bookinfo application deployed
- Kiali and Jaeger installed

## Installation Commands

```bash
# Check if Kiali and Jaeger are installed
kubectl get pods -n istio-system | grep -E "(kiali|jaeger)"

# If not installed, install them
istioctl install --set values.kiali.enabled=true --set values.tracing.enabled=true

# Deploy Bookinfo
kubectl apply -f manifests/base/

# Apply traffic configuration
kubectl apply -f configs/traffic/
```

## Demo Steps

### Step 1: Access Kiali
```bash
# Port forward to Kiali
kubectl port-forward -n istio-system svc/kiali 20001:20001 &

# Open Kiali in browser
echo "Open http://localhost:20001 in your browser"
echo "Default login: admin/admin"
```

### Step 2: Generate Traffic
```bash
# Generate traffic for visualization
for i in {1..50}; do
  kubectl exec -n bookinfo deployment/test-client -- curl -s productpage:9080/productpage > /dev/null
done

echo "Traffic generated for Kiali visualization"
```

### Step 3: View Service Graph
```bash
# In Kiali UI:
# 1. Go to Graph
# 2. Select bookinfo namespace
# 3. View service topology
# 4. Observe request flow
```

### Step 4: Access Jaeger
```bash
# Port forward to Jaeger
kubectl port-forward -n istio-system svc/jaeger 16686:16686 &

# Open Jaeger in browser
echo "Open http://localhost:16686 in your browser"
```

### Step 5: Generate Traced Requests
```bash
# Generate requests with tracing headers
for i in {1..20}; do
  kubectl exec -n bookinfo deployment/test-client -- curl -s -H "x-b3-traceid: $(openssl rand -hex 16)" productpage:9080/productpage > /dev/null
done

echo "Traced requests generated for Jaeger"
```

### Step 6: View Traces
```bash
# In Jaeger UI:
# 1. Select productpage service
# 2. Click Find Traces
# 3. View request traces
# 4. Analyze timing and dependencies
```

## What You Should See

### Kiali
- **Service Graph**: Visual topology of your services
- **Request Flow**: Arrows showing request paths
- **Metrics**: Request rates, error rates, latencies
- **Health Status**: Service health indicators

### Jaeger
- **Request Traces**: Complete request journeys
- **Timing Information**: How long each service takes
- **Service Dependencies**: Which services call which
- **Performance Bottlenecks**: Slow services identified

## Key Concepts

### Service Graph
- **Nodes**: Represent services
- **Edges**: Represent request flow
- **Colors**: Indicate health status
- **Thickness**: Indicate request volume

### Distributed Tracing
- **Spans**: Individual operations
- **Traces**: Complete request journeys
- **Tags**: Metadata about operations
- **Logs**: Additional context

## Cleanup
```bash
# Stop port forwarding (Ctrl+C for each)
# Remove traffic configuration
kubectl delete -f configs/traffic/ --ignore-not-found=true
```

## Troubleshooting
```bash
# Check Kiali status
kubectl get pods -n istio-system | grep kiali

# Check Jaeger status
kubectl get pods -n istio-system | grep jaeger

# Check if tracing is enabled
kubectl get pods -n bookinfo -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].name}{"\n"}{end}'

# Check service mesh status
kubectl get pods -n bookinfo
```
