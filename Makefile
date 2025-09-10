# Makefile for mesh-demo project

.PHONY: help deploy test monitor clean status logs

# Default target
help: ## Show this help message
	@echo "Mesh Demo - Istio Service Mesh Project"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Deployment targets
deploy: ## Deploy the complete mesh-demo application
	@echo "Deploying mesh-demo application..."
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh

deploy-permissive: ## Deploy with permissive mTLS
	@echo "Deploying with permissive mTLS..."
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh --mtls permissive

deploy-strict: ## Deploy with strict mTLS
	@echo "Deploying with strict mTLS..."
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh --mtls strict

deploy-minimal: ## Deploy base application only (no security/gateway)
	@echo "Deploying minimal configuration..."
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh --no-security --no-gateway

# Testing targets
test: ## Run all tests
	@echo "Running mesh-demo tests..."
	@chmod +x scripts/test.sh
	@./scripts/test.sh

test-traffic: ## Test traffic distribution with 50 requests
	@echo "Testing traffic distribution..."
	@chmod +x scripts/test.sh
	@./scripts/test.sh --traffic-count 50

test-load: ## Run load test with 200 requests
	@echo "Running load test..."
	@chmod +x scripts/test.sh
	@./scripts/test.sh --load-count 200

# Monitoring targets
monitor: ## Show current status
	@echo "Showing mesh-demo status..."
	@chmod +x scripts/monitor.sh
	@./scripts/monitor.sh

monitor-continuous: ## Start continuous monitoring
	@echo "Starting continuous monitoring..."
	@chmod +x scripts/monitor.sh
	@./scripts/monitor.sh --continuous

monitor-logs: ## Show recent logs
	@echo "Showing recent logs..."
	@chmod +x scripts/monitor.sh
	@./scripts/monitor.sh --logs

monitor-mtls: ## Show mTLS status
	@echo "Showing mTLS status..."
	@chmod +x scripts/monitor.sh
	@./scripts/monitor.sh --mtls

monitor-auth: ## Show authorization status
	@echo "Showing authorization status..."
	@chmod +x scripts/monitor.sh
	@./scripts/monitor.sh --auth

monitor-metrics: ## Show traffic metrics
	@echo "Showing traffic metrics..."
	@chmod +x scripts/monitor.sh
	@./scripts/monitor.sh --metrics

# Configuration management
apply-base: ## Apply base manifests only
	@echo "Applying base manifests..."
	kubectl apply -f manifests/base/

apply-traffic: ## Apply traffic configuration
	@echo "Applying traffic configuration..."
	kubectl apply -f configs/traffic/

apply-mtls-permissive: ## Apply permissive mTLS
	@echo "Applying permissive mTLS..."
	kubectl apply -f configs/mtls/peer-authentication-permissive.yaml

apply-mtls-strict: ## Apply strict mTLS
	@echo "Applying strict mTLS..."
	kubectl apply -f configs/mtls/peer-authentication-strict.yaml

apply-security: ## Apply security configuration
	@echo "Applying security configuration..."
	kubectl apply -f configs/security/

apply-gateway: ## Apply gateway configuration
	@echo "Applying gateway configuration..."
	kubectl apply -f configs/observability/

# Traffic management
switch-canary: ## Switch to canary traffic routing
	@echo "Switching to canary routing..."
	kubectl apply -f configs/traffic/virtual-service-canary.yaml

switch-production: ## Switch to production traffic routing
	@echo "Switching to production routing..."
	kubectl apply -f configs/traffic/virtual-service-production.yaml

# Cleanup targets
clean: ## Remove all mesh-demo resources
	@echo "Cleaning up mesh-demo resources..."
	kubectl delete namespace mesh-demo --ignore-not-found=true

clean-configs: ## Remove only Istio configurations
	@echo "Cleaning up Istio configurations..."
	kubectl delete -f configs/ --ignore-not-found=true

# Status and debugging
status: ## Show comprehensive status
	@echo "=== Pod Status ==="
	kubectl get pods -n mesh-demo -o wide
	@echo ""
	@echo "=== Service Status ==="
	kubectl get svc -n mesh-demo
	@echo ""
	@echo "=== Istio Resources ==="
	kubectl get destinationrule,virtualservice,gateway,peerauthentication,authorizationpolicy -n mesh-demo

logs: ## Show logs for hello service
	@echo "Showing logs for hello service..."
	kubectl logs -n mesh-demo -l app=hello --tail=50

logs-proxy: ## Show istio-proxy logs
	@echo "Showing istio-proxy logs..."
	kubectl logs -n mesh-demo -l app=hello -c istio-proxy --tail=50

# Development helpers
port-forward: ## Port forward to hello service
	@echo "Port forwarding to hello service..."
	kubectl port-forward -n mesh-demo svc/hello 8080:8080

shell: ## Get shell access to test client
	@echo "Getting shell access to test client..."
	kubectl exec -n mesh-demo -it deployment/test-client -- sh

# Validation
validate: ## Validate Istio configuration
	@echo "Validating Istio configuration..."
	istioctl analyze mesh-demo

check-mtls: ## Check mTLS status
	@echo "Checking mTLS status..."
	istioctl authn tls-check hello.mesh-demo.svc.cluster.local