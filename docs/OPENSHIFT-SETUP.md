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

## Step 5: Deploy Bookinfo Services

Create `productpage-service.yaml`:
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
```

Create `details-service.yaml`:
```yaml
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
```

Create `reviews-service.yaml`:
```yaml
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
```

Create `ratings-service.yaml`:
```yaml
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
# Apply all services
oc apply -f productpage-service.yaml
oc apply -f details-service.yaml
oc apply -f reviews-service.yaml
oc apply -f ratings-service.yaml
```

## Step 6: Deploy Bookinfo Applications

Create `productpage-deployment.yaml`:
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
```

Create `details-deployment.yaml`:
```yaml
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
```

Create `reviews-deployment.yaml`:
```yaml
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
```

Create `ratings-deployment.yaml`:
```yaml
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
# Apply all deployments
oc apply -f productpage-deployment.yaml
oc apply -f details-deployment.yaml
oc apply -f reviews-deployment.yaml
oc apply -f ratings-deployment.yaml
```

## Step 7: Deploy Istio Gateway

Create `gateway.yaml`:
```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: bookinfo-gateway
  namespace: mesh-demo
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

```bash
# Apply the gateway
oc apply -f gateway.yaml
```

## Step 8: Deploy Destination Rules

Create `destination-rules.yaml`:
```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: productpage
  namespace: mesh-demo
spec:
  host: productpage
  subsets:
  - name: v1
    labels:
      version: v1
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: reviews
  namespace: mesh-demo
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
  - name: v3
    labels:
      version: v3
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: ratings
  namespace: mesh-demo
spec:
  host: ratings
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: details
  namespace: mesh-demo
spec:
  host: details
  subsets:
  - name: v1
    labels:
      version: v1
```

```bash
# Apply destination rules
oc apply -f destination-rules.yaml
```

## Step 9: Deploy Virtual Service

Create `virtual-service.yaml`:
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: bookinfo
  namespace: mesh-demo
spec:
  hosts:
  - "*"
  gateways:
  - bookinfo-gateway
  http:
  - match:
    - uri:
        exact: /productpage
    - uri:
        prefix: /static
    - uri:
        exact: /login
    - uri:
        exact: /logout
    - uri:
        prefix: /api/v1/products
    route:
    - destination:
        host: productpage
        port:
          number: 9080
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: reviews
  namespace: mesh-demo
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: ratings
  namespace: mesh-demo
spec:
  hosts:
  - ratings
  http:
  - route:
    - destination:
        host: ratings
        subset: v1
```

```bash
# Apply virtual services
oc apply -f virtual-service.yaml
```

## Step 10: Deploy Test Client

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

## Step 11: Wait for Deployment

```bash
# Wait for deployments to be ready
oc wait --for=condition=available --timeout=300s deployment/productpage-v1 -n mesh-demo
oc wait --for=condition=available --timeout=300s deployment/details-v1 -n mesh-demo
oc wait --for=condition=available --timeout=300s deployment/reviews-v1 -n mesh-demo
oc wait --for=condition=available --timeout=300s deployment/ratings-v1 -n mesh-demo
oc wait --for=condition=available --timeout=300s deployment/test-client -n mesh-demo
```

## Step 12: Test the Service Mesh

```bash
# Test basic connectivity to productpage
oc exec -n mesh-demo deployment/test-client -- curl -s productpage:9080

# Check that sidecars are injected
oc get pods -n mesh-demo

# Verify Istio sidecar is running (should show 2/2 containers)
oc describe pod -n mesh-demo -l app=productpage
```

## Step 13: Create OpenShift Route (Optional)

```bash
# Create route for external access to productpage
oc expose service productpage -n mesh-demo

# Get the route URL
oc get route productpage -n mesh-demo

# Test external access
curl http://$(oc get route productpage -n mesh-demo -o jsonpath='{.spec.host}')
```

## Verification Commands

```bash
# Check pod status
oc get pods -n mesh-demo

# Check services
oc get svc -n mesh-demo

# Check routes
oc get route -n mesh-demo

# Test connectivity to productpage
oc exec -n mesh-demo deployment/test-client -- curl -s productpage:9080

# Test full bookinfo flow
oc exec -n mesh-demo deployment/test-client -- curl -s productpage:9080/productpage

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
