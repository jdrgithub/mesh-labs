# Mesh Demo - Production-Ready Istio Service Mesh

A comprehensive, production-ready Istio service mesh demonstration project showcasing enterprise-grade patterns for microservices deployment, traffic management, security, and observability.

## Features

- **Traffic Management**: Canary deployments, weighted routing, circuit breakers
- **Security**: mTLS, authorization policies, SPIFFE identity
- **Observability**: Metrics, logging, distributed tracing
- **Automation**: Deployment scripts, testing framework, monitoring tools
- **Production Ready**: Resource limits, health checks, best practices

## Prerequisites

- Kubernetes cluster (v1.21+)
- Istio installed and configured
- `kubectl` configured to access your cluster
- `make` utility (optional, for using Makefile)

## Quick Start

```bash
# Deploy the complete application
make deploy

# Run tests to verify deployment
make test

# Monitor the application
make monitor
```

## Project Structure

```
mesh-labs/
├── manifests/
│   └── base/                    # Core Kubernetes resources
│       ├── namespace.yaml       # Namespace with sidecar injection
│       ├── service.yaml         # Hello service definition
│       ├── deployment-v1.yaml   # Hello service version 1
│       ├── deployment-v2.yaml   # Hello service version 2
│       └── test-client.yaml     # Test client for validation
├── configs/
│   ├── traffic/                 # Traffic management
│   │   ├── destination-rule.yaml
│   │   ├── virtual-service-canary.yaml
│   │   └── virtual-service-production.yaml
│   ├── mtls/                   # mTLS configuration
│   │   ├── peer-authentication-permissive.yaml
│   │   └── peer-authentication-strict.yaml
│   ├── security/               # Authorization policies
│   │   ├── authorization-policy-deny-all.yaml
│   │   └── authorization-policy-allow-test-client.yaml
│   └── observability/          # Gateway and monitoring
│       ├── gateway.yaml
│       └── virtual-service-gateway.yaml
├── scripts/
│   ├── deploy.sh               # Automated deployment
│   ├── test.sh                 # Comprehensive testing
│   └── monitor.sh              # Monitoring and debugging
├── docs/
│   ├── ARCHITECTURE.md         # System architecture
│   └── DEPLOYMENT.md           # Detailed deployment guide
├── Makefile                    # Common operations
└── README.md                   # This file
```

## Core Concepts

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