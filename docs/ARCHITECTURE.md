# Mesh Demo Architecture

## Overview

Mesh Demo is a comprehensive Istio service mesh demonstration project that showcases production-ready patterns for microservices deployment, traffic management, security, and observability.

## Architecture Components

### Core Services

```
┌─────────────────┐    ┌─────────────────┐
│   Test Client   │    │   Hello v1      │
│   (curl pod)    │───▶│   (echo-server) │
│                 │    │                 │
└─────────────────┘    └─────────────────┘
         │                       │
         │              ┌─────────────────┐
         └─────────────▶│   Hello v2      │
                        │   (echo-server) │
                        │                 │
                        └─────────────────┘
```

### Service Mesh Components

1. **Sidecar Proxies (Envoy)**
   - Automatic injection via namespace labeling
   - Handles all service-to-service communication
   - Provides observability, security, and traffic management

2. **Control Plane (Istio)**
   - Manages proxy configuration
   - Handles service discovery
   - Enforces policies and routing rules

3. **Data Plane**
   - Envoy proxies intercepting all traffic
   - mTLS encryption between services
   - Load balancing and health checking

## Traffic Flow

### Request Path
1. Client request → Istio Ingress Gateway (if external)
2. Gateway → VirtualService (routing rules)
3. VirtualService → DestinationRule (load balancing)
4. DestinationRule → Service Endpoints
5. Service → Application Container
6. Response follows reverse path

### Canary Deployment Flow
1. Deploy v2 alongside v1
2. Configure DestinationRule with subsets
3. Use VirtualService to control traffic weights
4. Gradually shift traffic: 90/10 → 50/50 → 0/100
5. Monitor metrics and rollback if needed

## Security Model

### mTLS Configuration
- **Permissive Mode**: Allows both plaintext and mTLS
- **Strict Mode**: Requires mTLS for all communication
- Automatic certificate management by Istio

### Authorization Policies
- **Deny-by-default**: All traffic blocked initially
- **Explicit allow**: Specific service accounts and paths
- **SPIFFE identity**: Secure service identification

## Configuration Management

### Directory Structure
```
mesh-labs/
├── manifests/base/          # Core Kubernetes resources
├── configs/
│   ├── traffic/            # Traffic management (VirtualService, DestinationRule)
│   ├── mtls/              # mTLS configuration
│   ├── security/          # Authorization policies
│   └── observability/     # Gateway and monitoring
├── scripts/               # Deployment and testing automation
└── docs/                  # Documentation
```

### Environment Separation
- **Base**: Core application manifests
- **Configs**: Istio-specific configurations
- **Scripts**: Automation and testing tools

## Deployment Patterns

### Blue-Green Deployment
- Deploy v2 alongside v1
- Switch traffic using VirtualService weights
- Instant rollback capability

### Canary Deployment
- Gradual traffic shifting
- Header-based routing for testing
- Automatic rollback on failure

### Circuit Breaker
- Connection pooling limits
- Outlier detection
- Automatic endpoint ejection

## Observability

### Metrics
- Request rates and latencies
- Error rates and response codes
- mTLS connection status
- Circuit breaker state

### Logging
- Access logs from Envoy proxies
- Application logs from containers
- Security audit logs

### Tracing
- Distributed request tracing
- Service dependency mapping
- Performance bottleneck identification

## Best Practices

### Resource Management
- Resource limits and requests defined
- Health checks for all services
- Proper labeling and selectors

### Security
- Principle of least privilege
- mTLS for all service communication
- Regular security policy updates

### Monitoring
- Comprehensive health checks
- Automated testing and validation
- Continuous monitoring and alerting

### Configuration
- GitOps for configuration management
- Environment-specific overlays
- Automated deployment pipelines