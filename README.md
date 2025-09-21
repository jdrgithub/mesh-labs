# Mesh Labs - Bookinfo Service Mesh Demo

A comprehensive Istio service mesh demonstration project using the Bookinfo microservices application. This project showcases service mesh patterns for microservices deployment, traffic management, security, and observability.

## Features

- **Bookinfo Demo**: Complete microservices application (productpage, details, reviews, ratings)
- **Traffic Management**: Gateway, destination rules, virtual services
- **Security**: mTLS, authorization policies
- **Observability**: Metrics, logging, distributed tracing
- **Multiple Platforms**: Standard Kubernetes and OpenShift support
- **Self-Documenting**: Clear YAML manifests and step-by-step guides

## Prerequisites

- Kubernetes cluster (v1.21+)
- Istio installed and configured
- `kubectl` configured to access your cluster
- `make` utility (optional, for using Makefile)

## Quick Start

```bash
# Deploy Bookinfo application
kubectl apply -f manifests/base/

# Wait for deployments
kubectl wait --for=condition=available --timeout=300s deployment/productpage-v1 -n mesh-demo
kubectl wait --for=condition=available --timeout=300s deployment/details-v1 -n mesh-demo
kubectl wait --for=condition=available --timeout=300s deployment/reviews-v1 -n mesh-demo
kubectl wait --for=condition=available --timeout=300s deployment/ratings-v1 -n mesh-demo
kubectl wait --for=condition=available --timeout=300s deployment/test-client -n mesh-demo

# Test the application
kubectl exec -n mesh-demo deployment/test-client -- curl -s productpage:9080/productpage
```

## Project Structure

```
mesh-labs/
├── manifests/
│   └── base/                           # Core Kubernetes resources
│       ├── namespace.yaml              # Namespace with sidecar injection
│       ├── services.yaml               # All Bookinfo services
│       ├── deployments.yaml            # All Bookinfo applications
│       └── test-client.yaml            # Test client for validation
├── configs/
│   ├── traffic/                        # Traffic management
│   │   ├── gateway.yaml                # Istio gateway
│   │   ├── destination-rules.yaml      # Service subsets
│   │   └── virtual-service.yaml        # Routing rules
│   ├── mtls/                          # mTLS configuration
│   │   ├── peer-authentication-permissive.yaml
│   │   └── peer-authentication-strict.yaml
│   ├── security/                      # Authorization policies
│   │   ├── authorization-policy-deny-all.yaml
│   │   └── authorization-policy-allow-test-client.yaml
│   └── observability/                 # Gateway and monitoring
│       ├── gateway.yaml
│       └── virtual-service-gateway.yaml
├── scripts/
│   ├── deploy.sh                      # Automated deployment
│   ├── test.sh                        # Comprehensive testing
│   └── monitor.sh                     # Monitoring and debugging
├── docs/
│   ├── README.md                      # Demo overview and index
│   ├── 01-mTLS.md                     # mTLS demo
│   ├── 02-Destination-Rules.md        # Destination rules demo
│   ├── 03-Traffic-Routing.md          # Traffic routing demo
│   ├── 04-Gateway.md                  # Gateway demo
│   ├── 05-Observability.md            # Observability demo
│   ├── 06-Fault-Injection.md          # Fault injection demo
│   ├── MINIMAL.md                     # Minimal setup guide
│   ├── ISTIO-SETUP.md                 # Standard Istio installation
│   └── OPENSHIFT-SETUP.md             # OpenShift setup guide
├── Makefile                           # Common operations
└── README.md                          # This file
```

## Learning Demos

This project provides hands-on demos for learning service mesh concepts:

### [📚 Demo Index](docs/README.md)
Complete overview of all available demos and learning path.

### Individual Demos
- **[🔒 mTLS Demo](docs/01-mTLS.md)** - Learn mutual TLS encryption
- **[🎯 Destination Rules Demo](docs/02-Destination-Rules.md)** - Understand traffic policies
- **[🚦 Traffic Routing Demo](docs/03-Traffic-Routing.md)** - Master canary deployments
- **[🌐 Gateway Demo](docs/04-Gateway.md)** - Expose services externally
- **[📊 Observability Demo](docs/05-Observability.md)** - Visualize with Kiali & Jaeger
- **[💥 Fault Injection Demo](docs/06-Fault-Injection.md)** - Test application resilience

### Setup Guides
- **[⚡ Minimal Setup](docs/MINIMAL.md)** - Quick Bookinfo deployment
- **[🔧 Istio Installation](docs/ISTIO-SETUP.md)** - Standard Istio setup
- **[🔴 OpenShift Setup](docs/OPENSHIFT-SETUP.md)** - OpenShift-specific setup

## Usage Examples

### Deploy with Different Configurations

```bash
# Deploy with permissive mTLS (default)
make deploy-permissive

# Deploy with strict mTLS
make deploy-strict

# Deploy minimal configuration (no security/gateway)
make deploy-minimal
```

### Traffic Management

```bash
# Switch to canary routing (90% v1, 10% v2)
make switch-canary

# Switch to production routing (100% v1)
make switch-production

# Test traffic distribution
make test-traffic
```

### Testing and Validation

```bash
# Run comprehensive tests
make test

# Run load test
make test-load

# Check mTLS status
make check-mtls

# Validate configuration
make validate
```

### Monitoring and Debugging

```bash
# Show current status
make status

# Start continuous monitoring
make monitor-continuous

# View logs
make logs

# Get shell access
make shell
```

## Documentation

- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Detailed system architecture and design patterns
- **[DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Comprehensive deployment guide and troubleshooting

## Key Features Demonstrated

### Traffic Management
- **Canary Deployments**: Gradual traffic shifting between service versions
- **Weighted Routing**: Control traffic distribution using VirtualService
- **Circuit Breakers**: Automatic failure handling and recovery
- **Header-based Routing**: Route traffic based on request headers

### Security
- **mTLS**: Mutual TLS encryption between services
- **Authorization Policies**: Fine-grained access control
- **SPIFFE Identity**: Secure service identification
- **Deny-by-default**: Security-first approach

### Observability
- **Metrics**: Request rates, latencies, error rates
- **Logging**: Centralized access and application logs
- **Tracing**: Distributed request tracing
- **Health Checks**: Automated service health monitoring

## Cleanup

```bash
# Remove all resources
make clean

# Or manually
kubectl delete namespace mesh-demo
```

## Contributing

This project demonstrates production-ready Istio patterns. Feel free to extend it with additional features or use it as a foundation for your own service mesh implementations.

## License

This project is provided as-is for educational and demonstration purposes.