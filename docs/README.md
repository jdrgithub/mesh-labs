# Service Mesh Learning Demos

This directory contains step-by-step demos for learning Istio service mesh concepts.

## Demo Overview

| Demo | Concept | Time | Prerequisites |
|------|---------|------|---------------|
| [01-mTLS.md](01-mTLS.md) | Mutual TLS encryption | 10 min | Bookinfo deployed |
| [02-Destination-Rules.md](02-Destination-Rules.md) | Traffic policies | 15 min | Multiple service versions |
| [03-Traffic-Routing.md](03-Traffic-Routing.md) | Canary deployments | 20 min | Multiple service versions |
| [04-Gateway.md](04-Gateway.md) | External access | 15 min | Istio gateway |
| [05-Observability.md](05-Observability.md) | Kiali & Jaeger | 20 min | Kiali & Jaeger installed |
| [06-Fault-Injection.md](06-Fault-Injection.md) | Resilience testing | 15 min | Basic setup |

## Quick Start

1. **Deploy Bookinfo**:
   ```bash
   kubectl apply -f manifests/base/
   ```

2. **Pick a demo** and follow the installation commands

3. **Run the demo steps** to learn the concept

## Prerequisites

- Kubernetes cluster with Istio installed
- `kubectl` configured
- `istioctl` installed

## Installation Order

For a complete learning experience, run demos in order:

1. **mTLS** - Understand service-to-service encryption
2. **Destination Rules** - Learn traffic policies
3. **Traffic Routing** - Master canary deployments
4. **Gateway** - Expose services externally
5. **Observability** - Visualize and trace requests
6. **Fault Injection** - Test resilience

## Each Demo Includes

- **What You'll Learn**: Clear learning objectives
- **Installation Commands**: Simple setup steps
- **Demo Steps**: Step-by-step instructions
- **What You Should See**: Expected results
- **Key Concepts**: Technical explanations
- **Cleanup**: How to remove configurations
- **Troubleshooting**: Common issues and solutions

## Getting Help

- Check the troubleshooting section in each demo
- Verify prerequisites are met
- Ensure Istio is properly installed
- Check that sidecars are injected

Happy learning! 🚀
