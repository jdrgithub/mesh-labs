# Demo 4: Gateway and External Access

Learn how to expose services externally through Istio gateway.

## What You'll Learn
- How Istio gateway works
- External access to services
- Port forwarding for local development

## Prerequisites
- Bookinfo application deployed
- Istio gateway installed

## Installation Commands

```bash
# Check if gateway is available
kubectl get pods -n istio-system | grep gateway

# If no gateway, install it
istioctl install --set values.gateways.istio-ingressgateway.enabled=true

# Deploy Bookinfo
kubectl apply -f manifests/base/

# Apply gateway configuration
kubectl apply -f configs/traffic/gateway.yaml
```

## Demo Steps

### Step 1: Check Gateway Status
```bash
# Check gateway pods
kubectl get pods -n istio-system | grep gateway

# Check gateway service
kubectl get svc -n istio-system | grep gateway
```

### Step 2: Apply Gateway Configuration
```bash
# Apply gateway configuration
kubectl apply -f configs/traffic/gateway.yaml

# Apply virtual service for external access
kubectl apply -f configs/traffic/virtual-service.yaml

# Check gateway configuration
kubectl get gateway -n mesh-demo
```

### Step 3: Get External Access
```bash
# Check external IP (if available)
kubectl get svc -n istio-system istio-ingressgateway

# For local development, use port forwarding
kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80
```

### Step 4: Test External Access
```bash
# Test external access (in another terminal)
curl http://localhost:8080/productpage

# Or open in browser
echo "Open http://localhost:8080/productpage in your browser"
```

### Step 5: Test Different Endpoints
```bash
# Test productpage
curl http://localhost:8080/productpage

# Test static content
curl http://localhost:8080/static/bootstrap/bootstrap.min.css

# Test API
curl http://localhost:8080/api/v1/products
```

## What You Should See

- **Gateway Pod**: Running in istio-system namespace
- **External Access**: Bookinfo accessible from outside cluster
- **Port Forwarding**: Local access via localhost:8080
- **Multiple Endpoints**: Different paths routed correctly

## Key Concepts

### Gateway Configuration
```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: bookinfo-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
```

### Virtual Service for Gateway
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: bookinfo
spec:
  hosts:
  - "*"
  gateways:
  - bookinfo-gateway
  http:
  - match:
    - uri:
        exact: /productpage
    route:
    - destination:
        host: productpage
        port:
          number: 9080
```

## Cleanup
```bash
# Remove gateway configuration
kubectl delete -f configs/traffic/gateway.yaml --ignore-not-found=true
kubectl delete -f configs/traffic/virtual-service.yaml --ignore-not-found=true

# Stop port forwarding (Ctrl+C)
```

## Troubleshooting
```bash
# Check gateway pods
kubectl get pods -n istio-system | grep gateway

# Check gateway service
kubectl get svc -n istio-system | grep gateway

# Check gateway logs
kubectl logs -n istio-system -l app=istio-proxy --tail=20

# Check gateway configuration
kubectl get gateway -n mesh-demo
kubectl describe gateway bookinfo-gateway -n mesh-demo
```
