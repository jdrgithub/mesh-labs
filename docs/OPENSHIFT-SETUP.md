# OpenShift Service Mesh Setup

Complete guide for setting up Istio service mesh on OpenShift with minimal configuration.

## Prerequisites

- OpenShift cluster (4.6+)
- `oc` CLI configured to access your cluster
- Cluster admin privileges (for Istio installation)

## Step 1: Install Service Mesh Operator

First, check if the Service Mesh operator is already installed:

```bash
# Check if operator is already installed
oc get subscription servicemeshoperator -n openshift-operators

# Check if operator pods are running
oc get pods -n openshift-operators -l name=servicemeshoperator

# Check operator status
oc get csv -n openshift-operators | grep servicemesh
```

If the operator is already installed and running, skip to Step 2. Otherwise, proceed with the installation:

Create `subscription.yaml`:
```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: servicemeshoperator
  namespace: openshift-operators
spec:
  channel: stable
  name: servicemeshoperator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
```

```bash
# Apply the subscription
oc apply -f subscription.yaml

# Wait for operator to be ready
oc wait --for=condition=AtLatestKnown subscription/servicemeshoperator -n openshift-operators --timeout=300s
```

## Step 2: Create Service Mesh Control Plane

First, check if a Service Mesh Control Plane is already installed:

```bash
# Check if ServiceMeshControlPlane exists
oc get smcp -n istio-system

# Check if istio-system namespace exists
oc get namespace istio-system

# Check if control plane pods are running
oc get pods -n istio-system

# Check control plane status and details
oc describe smcp -n istio-system
```

If a ServiceMeshControlPlane is already installed and running, you can either:
- Use the existing one (skip to Step 3)
- Delete it and create a new one: `oc delete smcp -n istio-system --all`

If no control plane exists, proceed with the installation:

Create `smcp.yaml`:
```yaml
apiVersion: maistra.io/v2
kind: ServiceMeshControlPlane
metadata:
  name: basic-install
  namespace: istio-system
spec:
  version: v2.4
  tracing:
    type: None
  policy:
    type: None
  telemetry:
    type: None
  gateways:
    openshiftRoute: false
  runtime:
    defaults:
      container:
        resources:
          requests:
            cpu: 10m
            memory: 40Mi
          limits:
            cpu: 100m
            memory: 128Mi
```

```bash
# Apply the control plane
oc apply -f smcp.yaml

# Wait for control plane to be ready
oc wait --for=condition=Ready smcp/basic-install -n istio-system --timeout=300s
```

## Step 3: Create Service Mesh Member Roll

```bash
# Create project for mesh demo
oc new-project mesh-demo --display-name="Mesh Demo" --description="Istio Service Mesh Demo"
```

Create `smmr.yaml`:
```yaml
apiVersion: maistra.io/v1
kind: ServiceMeshMemberRoll
metadata:
  name: default
  namespace: istio-system
spec:
  members:
  - mesh-demo
```

```bash
# Apply the member roll
oc apply -f smmr.yaml

# Wait for member roll to be ready
oc wait --for=condition=Ready smmr/default -n istio-system --timeout=300s
```

## Step 4: Verify Installation

```bash
# Check control plane pods
oc get pods -n istio-system

# Check ServiceMeshControlPlane status
oc get smcp -n istio-system

# Check ServiceMeshMemberRoll status
oc get smmr -n istio-system

# Verify mesh-demo project is included
oc describe smmr default -n istio-system
```

## Step 5: Deploy Basic Service

Create `service.yaml`:
```yaml
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
# Apply the service
oc apply -f service.yaml
```

## Step 6: Deploy Application

Create `deployment.yaml`:
```yaml
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
            memory: "4Mi"
            cpu: "1m"
          limits:
            memory: "8Mi"
            cpu: "10m"
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
# Apply the deployment
oc apply -f deployment.yaml
```

## Step 7: Deploy Test Client

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
# Apply the test client
oc apply -f test-client.yaml
```

## Step 8: Wait for Deployment

```bash
# Wait for deployments to be ready
oc wait --for=condition=available --timeout=300s deployment/hello-v1 -n mesh-demo
oc wait --for=condition=available --timeout=300s deployment/test-client -n mesh-demo
```

## Step 9: Test the Service Mesh

```bash
# Test basic connectivity
oc exec -n mesh-demo deployment/test-client -- curl -s hello:8080

# Check that sidecars are injected
oc get pods -n mesh-demo

# Verify Istio sidecar is running (should show 2/2 containers)
oc describe pod -n mesh-demo -l app=hello
```

## Step 10: Create OpenShift Route (Optional)

```bash
# Create route for external access
oc expose service hello -n mesh-demo

# Get the route URL
oc get route hello -n mesh-demo

# Test external access
curl http://$(oc get route hello -n mesh-demo -o jsonpath='{.spec.host}')
```

## Verification Commands

```bash
# Check pod status
oc get pods -n mesh-demo

# Check services
oc get svc -n mesh-demo

# Check routes
oc get route -n mesh-demo

# Test connectivity
oc exec -n mesh-demo deployment/test-client -- curl -s hello:8080

# Check sidecar injection
oc get pods -n mesh-demo -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].name}{"\n"}{end}'

# Check Service Mesh status
oc get smcp,smmr -n istio-system
```

## What You Get

With this OpenShift setup, you have:

1. **Service Mesh Control Plane**: Istio control plane managed by OpenShift
2. **Automatic Sidecar Injection**: All pods in mesh-demo get sidecars
3. **Service Discovery**: Services can find each other by name
4. **Basic Observability**: Istio automatically collects metrics and traces
5. **mTLS**: Automatic mutual TLS between services
6. **OpenShift Integration**: Routes, monitoring, and RBAC integration

## Troubleshooting

### Check Service Mesh Status
```bash
# Check control plane
oc get smcp -n istio-system
oc describe smcp basic-install -n istio-system

# Check member roll
oc get smmr -n istio-system
oc describe smmr default -n istio-system
```

### Check Pod Injection
```bash
# Verify sidecar injection
oc get pods -n mesh-demo -o wide
oc describe pod -n mesh-demo -l app=hello
```

### View Logs
```bash
# Control plane logs
oc logs -n istio-system -l app=istiod

# Application logs
oc logs -n mesh-demo -l app=hello
```

## Cleanup

```bash
# Delete the project (removes all resources)
oc delete project mesh-demo

# Remove Service Mesh
oc delete smmr default -n istio-system
oc delete smcp basic-install -n istio-system

# Remove operator (optional)
oc delete subscription servicemeshoperator -n openshift-operators
```

## Key Differences from Standard Istio

- Uses **ServiceMeshControlPlane** instead of `istioctl install`
- Uses **ServiceMeshMemberRoll** instead of namespace labels
- Integrated with OpenShift operators and lifecycle management
- Automatic RBAC and security context integration
- Built-in monitoring and observability integration

This setup gives you a production-ready service mesh that's fully integrated with OpenShift's platform capabilities.
