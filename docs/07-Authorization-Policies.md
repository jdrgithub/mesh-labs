# Authorization Policies Demo

This demo shows how to implement fine-grained access control using Istio authorization policies with SPIFFE identities.

## Table of Contents

1. [SPIFFE Identities](#spiffe-identities)
2. [Deny-All Policy](#deny-all-policy)
3. [SPIFFE-Based Authorization](#spiffe-based-authorization)
4. [Gateway Authorization](#gateway-authorization)
5. [Testing Authorization Policies](#testing-authorization-policies)
6. [Authorization Policy Inspection](#authorization-policy-inspection)

## SPIFFE Identities

### Concept

SPIFFE (Secure Production Identity Framework For Everyone) provides a standardized way to identify workloads. In Istio, each service account gets a unique SPIFFE identity.

**SPIFFE Identity Format**: `cluster.local/ns/<namespace>/sa/<service-account>`

### Commands

```bash
# Show SPIFFE identities for Bookinfo services
kubectl get pods -n bookinfo -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.serviceAccountName}{"\n"}{end}'
```

### Example Output

```
details-v1-55cddc9798-2mdwz        default
productpage-v1-5fb5d4c744-w5nxx    default
ratings-v1-5b54db4474-9h7qr        default
reviews-v1-8678f67585-vhxhh         default
reviews-v2-7c6d4847b8-sg5kd        default
reviews-v3-7f866f88c4-tkhbv        default
test-client-64d9fd78f5-7v2dg       default
```

**SPIFFE Identity**: `cluster.local/ns/bookinfo/sa/default` (used by all Bookinfo services)

## Deny-All Policy

### Concept

A security-first approach where all traffic is denied by default, then explicitly allowed.

### Commands

```bash
# Apply deny-all authorization policy
kubectl apply -f configs/auth-policies/deny-all.yaml

# Test access (should return 403)
kubectl exec -n bookinfo deployment/test-client -- curl -s -w "%{http_code}" productpage:9080/productpage -o /dev/null
```

### What it does

- Blocks all traffic between services
- Forces explicit authorization rules
- Demonstrates zero-trust security model

## SPIFFE-Based Authorization

### Concept

Use SPIFFE identities to control access between services based on their service accounts.

### Commands

```bash
# Apply SPIFFE-based authorization policies
kubectl apply -f configs/auth-policies/allow-productpage-spiffe.yaml
kubectl apply -f configs/auth-policies/allow-reviews-to-ratings.yaml
kubectl apply -f configs/auth-policies/allow-test-client.yaml
```

### Key Components

- **Source**: SPIFFE identity of the calling service
- **Destination**: Target service and operations
- **Conditions**: Additional constraints (namespace, headers, etc.)

## Gateway Authorization

### Concept

Control external access through the ingress gateway using its SPIFFE identity.

### Commands

```bash
# Apply gateway authorization policy
kubectl apply -f configs/auth-policies/allow-gateway-ingress.yaml

# Test external access
curl -s -w "%{http_code}" http://localhost:8081/productpage -o /dev/null
```

### What it shows

- Gateway service account: `istio-ingressgateway-service-account`
- Allowed paths: `/productpage*`, `/static/*`, `/login*`, etc.
- Namespace restriction: `istio-system`

## Testing Authorization Policies

### Concept

Verify that authorization policies work as expected by testing access.

### Commands

```bash
# Test internal access
kubectl exec -n bookinfo deployment/test-client -- curl -s -w "%{http_code}" productpage:9080/productpage -o /dev/null

# Test external access
curl -s -w "%{http_code}" http://localhost:8081/productpage -o /dev/null
```

### What it shows

- HTTP response codes (200 = success, 403 = forbidden)
- Access granted or denied based on policies
- Real-time policy enforcement

### Example Scenarios

1. **Deny-All**: All requests return 403 Forbidden
2. **SPIFFE-Based**: Only authorized services can access
3. **Gateway**: External access through ingress gateway works

## Authorization Policy Inspection

### Concept

Examine the current authorization policies and their effects.

### Commands

```bash
# Show all authorization policies
kubectl get authorizationpolicy -n bookinfo -o wide

# Show detailed policy configuration
kubectl get authorizationpolicy -n bookinfo -o yaml
```

### Example Output

```
NAME                       ACTION   AGE
allow-gateway-ingress               3s
allow-productpage-spiffe            4s
allow-reviews-to-ratings            4s
allow-test-client                   3s
```

## Running the Demo

### Individual Commands

```bash
# Check current policies
kubectl get authorizationpolicy -n bookinfo -o wide

# Apply deny-all policy
kubectl apply -f configs/auth-policies/deny-all.yaml

# Test deny-all (should fail)
kubectl exec -n bookinfo deployment/test-client -- curl -s -w "%{http_code}" productpage:9080/productpage -o /dev/null

# Apply SPIFFE-based policies
kubectl apply -f configs/auth-policies/allow-test-client.yaml
kubectl apply -f configs/auth-policies/allow-productpage-spiffe.yaml
kubectl apply -f configs/auth-policies/allow-reviews-to-ratings.yaml
kubectl apply -f configs/auth-policies/allow-gateway-ingress.yaml

# Test with policies (should work)
kubectl exec -n bookinfo deployment/test-client -- curl -s -w "%{http_code}" productpage:9080/productpage -o /dev/null

# Test external access
curl -s -w "%{http_code}" http://localhost:8081/productpage -o /dev/null
```

### Using Makefile

```bash
# Run complete authorization policies demo
make demo-auth-policies
```

## Key Takeaways

1. **SPIFFE Identities**: Service account-based identity system for secure communication
2. **Deny-All Policy**: Security-first approach with explicit allow rules
3. **Service-Specific Policies**: Using selectors to target specific services
4. **Gateway Authorization**: Controlling external access through ingress gateway
5. **Policy Enforcement**: Real-time authorization with 403/200 responses

## Authorization Policy Types

1. **Deny-All**: Blocks all traffic (empty rules array)
2. **SPIFFE-Based**: Uses service account identities for access control
3. **Service-Specific**: Targets specific services using selectors
4. **Gateway**: Controls external access through ingress gateway
