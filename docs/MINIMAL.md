# Minimal Bookinfo Service Mesh Setup

This guide shows how to set up the most basic Istio service mesh configuration using the Bookinfo demo application.

## Prerequisites

- Kubernetes cluster (v1.21+)
- Istio installed and configured
- `kubectl` configured to access your cluster

## Step 1: Create Namespace with Sidecar Injection

Create `namespace.yaml`:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: mesh-demo
  labels:
    istio-injection: "enabled"
```

```bash
kubectl apply -f namespace.yaml
```

## Step 2: Deploy Bookinfo Services

Create `services.yaml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: productpage
  namespace: mesh-demo
  labels:
    app: productpage
spec:
  selector:
    app: productpage
  ports:
  - name: http
    port: 9080
    targetPort: 9080
    protocol: TCP
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: details
  namespace: mesh-demo
  labels:
    app: details
spec:
  selector:
    app: details
  ports:
  - name: http
    port: 9080
    targetPort: 9080
    protocol: TCP
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: reviews
  namespace: mesh-demo
  labels:
    app: reviews
spec:
  selector:
    app: reviews
  ports:
  - name: http
    port: 9080
    targetPort: 9080
    protocol: TCP
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: ratings
  namespace: mesh-demo
  labels:
    app: ratings
spec:
  selector:
    app: ratings
  ports:
  - name: http
    port: 9080
    targetPort: 9080
    protocol: TCP
  type: ClusterIP
```

```bash
kubectl apply -f services.yaml
```

## Step 3: Deploy Bookinfo Applications

Create `deployments.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: productpage-v1
  namespace: mesh-demo
  labels:
    app: productpage
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: productpage
      version: v1
  template:
    metadata:
      labels:
        app: productpage
        version: v1
    spec:
      containers:
      - name: productpage
        image: docker.io/istio/examples-bookinfo-productpage-v1:1.17.0
        ports:
        - containerPort: 9080
          name: http
        resources:
          requests:
            memory: "4Mi"
            cpu: "1m"
          limits:
            memory: "8Mi"
            cpu: "10m"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: details-v1
  namespace: mesh-demo
  labels:
    app: details
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: details
      version: v1
  template:
    metadata:
      labels:
        app: details
        version: v1
    spec:
      containers:
      - name: details
        image: docker.io/istio/examples-bookinfo-details-v1:1.17.0
        ports:
        - containerPort: 9080
          name: http
        resources:
          requests:
            memory: "4Mi"
            cpu: "1m"
          limits:
            memory: "8Mi"
            cpu: "10m"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reviews-v1
  namespace: mesh-demo
  labels:
    app: reviews
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reviews
      version: v1
  template:
    metadata:
      labels:
        app: reviews
        version: v1
    spec:
      containers:
      - name: reviews
        image: docker.io/istio/examples-bookinfo-reviews-v1:1.17.0
        ports:
        - containerPort: 9080
          name: http
        resources:
          requests:
            memory: "4Mi"
            cpu: "1m"
          limits:
            memory: "8Mi"
            cpu: "10m"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ratings-v1
  namespace: mesh-demo
  labels:
    app: ratings
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ratings
      version: v1
  template:
    metadata:
      labels:
        app: ratings
        version: v1
    spec:
      containers:
      - name: ratings
        image: docker.io/istio/examples-bookinfo-ratings-v1:1.17.0
        ports:
        - containerPort: 9080
          name: http
        resources:
          requests:
            memory: "4Mi"
            cpu: "1m"
          limits:
            memory: "8Mi"
            cpu: "10m"
```

```bash
kubectl apply -f deployments.yaml
```

## Step 4: Deploy Test Client

Create `test-client.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-client
  namespace: mesh-demo
  labels:
    app: test-client
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-client
  template:
    metadata:
      labels:
        app: test-client
    spec:
      containers:
      - name: curl
        image: curlimages/curl:8.9.1
        command: ["sleep", "infinity"]
        resources:
          requests:
            memory: "2Mi"
            cpu: "1m"
          limits:
            memory: "4Mi"
            cpu: "5m"
```

```bash
kubectl apply -f test-client.yaml
```

## Step 5: Wait for Deployment

```bash
kubectl wait --for=condition=available --timeout=300s deployment/productpage-v1 -n mesh-demo
kubectl wait --for=condition=available --timeout=300s deployment/details-v1 -n mesh-demo
kubectl wait --for=condition=available --timeout=300s deployment/reviews-v1 -n mesh-demo
kubectl wait --for=condition=available --timeout=300s deployment/ratings-v1 -n mesh-demo
kubectl wait --for=condition=available --timeout=300s deployment/test-client -n mesh-demo
```

## Step 6: Test the Service Mesh

```bash
# Test basic connectivity to productpage
kubectl exec -n mesh-demo deployment/test-client -- curl -s productpage:9080

# Test full bookinfo flow
kubectl exec -n mesh-demo deployment/test-client -- curl -s productpage:9080/productpage

# Check that sidecars are injected
kubectl get pods -n mesh-demo

# Verify Istio sidecar is running (should show 2/2 containers)
kubectl describe pod -n mesh-demo -l app=productpage
```

## What You Get

With this minimal setup, you have:

1. **Automatic Sidecar Injection**: All pods in the namespace get Istio sidecars
2. **Service Discovery**: Services can find each other by name
3. **Basic Observability**: Istio automatically collects metrics and traces
4. **mTLS**: Automatic mutual TLS between services (permissive mode)
5. **Bookinfo Demo**: Complete microservices application for testing

## Verification Commands

```bash
# Check pod status
kubectl get pods -n mesh-demo

# Check services
kubectl get svc -n mesh-demo

# Test connectivity
kubectl exec -n mesh-demo deployment/test-client -- curl -s productpage:9080

# Check sidecar injection
kubectl get pods -n mesh-demo -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].name}{"\n"}{end}'
```

## Next Steps

Once you have the basic service mesh working, you can add:

- **Traffic Management**: VirtualService and DestinationRule for routing
- **Security**: Authorization policies and strict mTLS
- **Observability**: Gateway and external access
- **Canary Deployments**: Multiple service versions with traffic splitting

See [OPENSHIFT-SETUP.md](OPENSHIFT-SETUP.md) for OpenShift-specific setup or [ISTIO-SETUP.md](ISTIO-SETUP.md) for standard Istio installation.