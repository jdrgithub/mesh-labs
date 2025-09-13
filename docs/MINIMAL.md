# Minimal Service Mesh Setup

This guide shows how to set up the most basic Istio service mesh configuration using only the essential components from this project.

## Prerequisites

- Kubernetes cluster (v1.21+)
- Istio installed and configured
- `kubectl` configured to access your cluster

## Step 1: Create Namespace with Sidecar Injection

```yaml
# namespace.yaml
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

## Step 2: Deploy Basic Service

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: hello
  namespace: mesh-demo
  labels:
    app: hello
spec:
  selector:
    app: hello
  ports:
  - name: http
    port: 8080
    targetPort: 8080
    protocol: TCP
  type: ClusterIP
```

```bash
kubectl apply -f service.yaml
```

## Step 3: Deploy Application

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-v1
  namespace: mesh-demo
  labels:
    app: hello
    version: v1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello
      version: v1
  template:
    metadata:
      labels:
        app: hello
        version: v1
    spec:
      containers:
      - name: hello
        image: ealen/echo-server:latest
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: PORT
          value: "8080"
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

```bash
kubectl apply -f deployment.yaml
```

## Step 4: Deploy Test Client

```yaml
# test-client.yaml
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
            memory: "32Mi"
            cpu: "25m"
          limits:
            memory: "64Mi"
            cpu: "50m"
```

```bash
kubectl apply -f test-client.yaml
```

## Step 5: Wait for Deployment

```bash
kubectl wait --for=condition=available --timeout=300s deployment/hello-v1 -n mesh-demo
kubectl wait --for=condition=available --timeout=300s deployment/test-client -n mesh-demo
```

## Step 6: Test the Service Mesh

```bash
# Test basic connectivity
kubectl exec -n mesh-demo deployment/test-client -- curl -s hello:8080

# Check that sidecars are injected
kubectl get pods -n mesh-demo

# Verify Istio sidecar is running (should show 2/2 containers)
kubectl describe pod -n mesh-demo -l app=hello
```

## What You Get

With this minimal setup, you have:

1. **Automatic Sidecar Injection**: All pods in the namespace get Istio sidecars
2. **Service Discovery**: Services can find each other by name
3. **Basic Observability**: Istio automatically collects metrics and traces
4. **mTLS**: Automatic mutual TLS between services (permissive mode)
5. **Health Checks**: Liveness and readiness probes

## Verification Commands

```bash
# Check pod status
kubectl get pods -n mesh-demo

# Check services
kubectl get svc -n mesh-demo

# Test connectivity
kubectl exec -n mesh-demo deployment/test-client -- curl -s hello:8080

# Check sidecar injection
kubectl get pods -n mesh-demo -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].name}{"\n"}{end}'
```

## One-Command Deployment

You can also use the project's deployment script for minimal setup:

```bash
# Deploy with minimal configuration (no security/gateway)
./scripts/deploy.sh --no-security --no-gateway
```

## Next Steps

Once you have the basic service mesh working, you can add:

- **Traffic Management**: VirtualService and DestinationRule for routing
- **Security**: Authorization policies and strict mTLS
- **Observability**: Gateway and external access
- **Canary Deployments**: Multiple service versions with traffic splitting

See the main [README.md](../README.md) for advanced configurations.
