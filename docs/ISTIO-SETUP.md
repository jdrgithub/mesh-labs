# Istio Installation for k3s

This guide covers installing and configuring Istio on your local k3s cluster for the service mesh demos.

## Prerequisites

- k3s cluster running locally
- `kubectl` configured to access your k3s cluster
- `istioctl` installed
- `curl` or `wget` for downloading Istio

## Step 1: Download Istio

```bash
# Download latest Istio (replace with current version)
curl -L https://istio.io/downloadIstio | sh -

# Add istioctl to PATH
export PATH=$PWD/istio-*/bin:$PATH

# Verify installation
istioctl version
```

## Step 2: Install Istio Control Plane

```bash
# Install Istio with minimal profile (lightweight)
istioctl install --set values.defaultRevision=default -y

# Verify installation
kubectl get pods -n istio-system
```

## Step 3: Enable Sidecar Injection

```bash
# Enable automatic sidecar injection for default namespace (optional)
kubectl label namespace default istio-injection=enabled

# Or create a dedicated namespace with injection enabled
kubectl create namespace bookinfo
kubectl label namespace bookinfo istio-injection=enabled
```

## Step 4: Verify Istio Installation

```bash
# Check control plane pods
kubectl get pods -n istio-system

# Check Istio services
kubectl get svc -n istio-system

# Verify istioctl can connect
istioctl version --remote=false
```

## Step 5: Test Basic Functionality

```bash
# Deploy a simple test pod
kubectl run test-pod --image=curlimages/curl --rm -it --restart=Never -- sh

# Inside the pod, test Istio metrics endpoint
curl http://istiod.istio-system.svc.cluster.local:15014/version
```

## Minimal Installation Options

### Option 1: Default Profile (Recommended)
```bash
istioctl install -y
```

### Option 2: Minimal Profile (Smallest footprint)
```bash
istioctl install --set values.pilot.resources.requests.memory=128Mi -y
```

### Option 3: Demo Profile (More features, still lightweight)
```bash
istioctl install --set profile=demo -y
```

## What Gets Installed

The minimal installation includes:

- **istiod**: Control plane (pilot, citadel, galley combined)
- **istio-proxy**: Sidecar containers (injected into pods)
- **Core CRDs**: VirtualService, DestinationRule, Gateway, etc.

## Resource Usage

Minimal Istio installation typically uses:
- **istiod**: ~200-300Mi memory, ~100-200m CPU
- **istio-proxy sidecar**: ~20-50Mi memory, ~10-50m CPU per pod

## Troubleshooting

### Check Installation Status
```bash
istioctl verify-install
```

### View Installation Logs
```bash
kubectl logs -n istio-system -l app=istiod
```

### Check Sidecar Injection
```bash
kubectl get pods -n bookinfo -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].name}{"\n"}{end}'
```

### Common Issues

**Issue**: Pods not getting sidecars
```bash
# Check namespace label
kubectl get namespace bookinfo --show-labels

# Re-label if needed
kubectl label namespace bookinfo istio-injection=enabled --overwrite
```

**Issue**: istioctl not found
```bash
# Add to PATH permanently
echo 'export PATH=$PATH:/path/to/istio/bin' >> ~/.bashrc
source ~/.bashrc
```

## Uninstall Istio

```bash
# Remove Istio
istioctl uninstall --purge -y

# Remove namespace
kubectl delete namespace istio-system
```

## Next Steps

Once Istio is installed and running:

1. Follow [MINIMAL.md](MINIMAL.md) to deploy your service mesh
2. Or use the full project: `./scripts/deploy.sh --no-security --no-gateway`

## Production Considerations

For production use, consider:
- Using specific Istio versions (not latest)
- Configuring resource limits for istiod
- Setting up monitoring and alerting
- Using external certificate management
- Configuring proper security policies

This minimal setup is perfect for demos and learning, but production deployments need additional configuration.
