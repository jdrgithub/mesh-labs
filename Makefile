# Makefile for mesh-labs project

.PHONY: help deploy test monitor clean status logs

# Default target
help: ## Show this help message
	@echo "Mesh Labs - Bookinfo Service Mesh Project"
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
apply-gateway: ## Apply gateway configuration
	@echo "Applying gateway configuration..."
	kubectl apply -f configs/traffic/gateway.yaml

apply-destination-rules: ## Apply destination rules
	@echo "Applying destination rules..."
	kubectl apply -f configs/traffic/destination-rules.yaml

apply-virtual-service: ## Apply virtual service
	@echo "Applying virtual service..."
	kubectl apply -f configs/traffic/virtual-service.yaml

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

logs: ## Show logs for productpage service
	@echo "Showing logs for productpage service..."
	kubectl logs -n mesh-demo -l app=productpage --tail=50

logs-proxy: ## Show istio-proxy logs
	@echo "Showing istio-proxy logs..."
	kubectl logs -n mesh-demo -l app=productpage -c istio-proxy --tail=50

# Development helpers
port-forward: ## Port forward to productpage service
	@echo "Port forwarding to productpage service..."
	kubectl port-forward -n mesh-demo svc/productpage 9080:9080

shell: ## Get shell access to test client
	@echo "Getting shell access to test client..."
	kubectl exec -n mesh-demo -it deployment/test-client -- sh

# Validation
validate: ## Validate Istio configuration
	@echo "Validating Istio configuration..."
	istioctl analyze mesh-demo

check-mtls: ## Check mTLS status
	@echo "Checking mTLS status..."
	istioctl authn tls-check productpage.mesh-demo.svc.cluster.local

# Demo targets for service mesh learning
deploy-multiple-versions: ## Deploy multiple versions of reviews service
	@echo "Deploying multiple versions of reviews service..."
	kubectl apply -f manifests/demos/reviews-v2-deployment.yaml
	kubectl apply -f manifests/demos/reviews-v3-deployment.yaml
	kubectl wait --for=condition=available --timeout=300s deployment/reviews-v2 -n mesh-demo
	kubectl wait --for=condition=available --timeout=300s deployment/reviews-v3 -n mesh-demo

route-100-v1: ## Route 100% traffic to reviews v1
	@echo "Routing 100% traffic to reviews v1..."
	kubectl apply -f configs/traffic/virtual-service.yaml

route-90-10: ## Route 90% v1, 10% v2
	@echo "Routing 90% v1, 10% v2..."
	kubectl apply -f configs/demos/virtual-service-canary.yaml

route-50-50: ## Route 50% v1, 50% v2
	@echo "Routing 50% v1, 50% v2..."
	kubectl apply -f configs/demos/virtual-service-50-50.yaml

route-100-v2: ## Route 100% traffic to reviews v2
	@echo "Routing 100% traffic to reviews v2..."
	kubectl apply -f configs/demos/virtual-service-100-v2.yaml

apply-header-routing: ## Apply header-based routing
	@echo "Applying header-based routing..."
	kubectl apply -f configs/demos/virtual-service-header-routing.yaml

apply-fault-injection: ## Apply fault injection to ratings service
	@echo "Applying fault injection..."
	kubectl apply -f configs/demos/virtual-service-fault-injection.yaml

remove-fault-injection: ## Remove fault injection
	@echo "Removing fault injection..."
	kubectl delete -f configs/demos/virtual-service-fault-injection.yaml --ignore-not-found=true

# Testing targets
test-mtls: ## Test mTLS communication
	@echo "Testing mTLS communication..."
	kubectl exec -n mesh-demo deployment/test-client -- curl -s productpage:9080/productpage

test-routing: ## Test basic routing
	@echo "Testing basic routing..."
	kubectl exec -n mesh-demo deployment/test-client -- curl -s productpage:9080/productpage

test-header-routing: ## Test header-based routing
	@echo "Testing header-based routing..."
	@echo "Without header (should go to v1):"
	kubectl exec -n mesh-demo deployment/test-client -- curl -s productpage:9080/productpage
	@echo "With jason header (should go to v2):"
	kubectl exec -n mesh-demo deployment/test-client -- curl -s -H "end-user: jason" productpage:9080/productpage

test-traffic-distribution: ## Test traffic distribution
	@echo "Testing traffic distribution..."
	@for i in {1..10}; do \
		echo "Request $$i:"; \
		kubectl exec -n mesh-demo deployment/test-client -- curl -s productpage:9080/productpage | grep -o "reviews-v[0-9]" || echo "No version found"; \
	done

test-load-balancing: ## Test load balancing
	@echo "Testing load balancing..."
	@for i in {1..10}; do \
		echo "Request $$i:"; \
		kubectl exec -n mesh-demo deployment/test-client -- curl -s productpage:9080/productpage | grep -o "reviews-v[0-9]" || echo "No version found"; \
	done

test-fault-tolerance: ## Test fault tolerance
	@echo "Testing fault tolerance..."
	@for i in {1..10}; do \
		echo "Request $$i:"; \
		kubectl exec -n mesh-demo deployment/test-client -- curl -s -w "HTTP Status: %{http_code}\n" productpage:9080/productpage | tail -1; \
	done

# Observability targets
open-kiali: ## Open Kiali in browser
	@echo "Opening Kiali..."
	@echo "Kiali should be accessible at: http://localhost:20001"
	@echo "Run: kubectl port-forward -n istio-system svc/kiali 20001:20001"
	@kubectl port-forward -n istio-system svc/kiali 20001:20001 &

open-jaeger: ## Open Jaeger in browser
	@echo "Opening Jaeger..."
	@echo "Jaeger should be accessible at: http://localhost:16686"
	@echo "Run: kubectl port-forward -n istio-system svc/jaeger 16686:16686"
	@kubectl port-forward -n istio-system svc/jaeger 16686:16686 &

generate-traffic: ## Generate traffic for observability
	@echo "Generating traffic..."
	@for i in {1..50}; do \
		kubectl exec -n mesh-demo deployment/test-client -- curl -s productpage:9080/productpage > /dev/null; \
	done
	@echo "Traffic generation complete"

generate-traced-requests: ## Generate traced requests
	@echo "Generating traced requests..."
	@for i in {1..20}; do \
		kubectl exec -n mesh-demo deployment/test-client -- curl -s -H "x-b3-traceid: $$(openssl rand -hex 16)" productpage:9080/productpage > /dev/null; \
	done
	@echo "Traced requests generated"

# Gateway targets
check-gateway: ## Check gateway status
	@echo "Checking gateway status..."
	kubectl get pods -n istio-system | grep gateway
	kubectl get svc -n istio-system | grep gateway

get-external-url: ## Get external access URL
	@echo "Getting external access URL..."
	@echo "Gateway external IP:"
	kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
	@echo ""
	@echo "Port forward command:"
	@echo "kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80"

test-external-access: ## Test external access
	@echo "Testing external access..."
	@echo "Access the application at: http://localhost:8080/productpage"
	@echo "Or run: curl http://localhost:8080/productpage"

# Troubleshooting targets
troubleshoot-gateway: ## Troubleshoot gateway issues
	@echo "Troubleshooting gateway..."
	@echo "=== Gateway Pods ==="
	kubectl get pods -n istio-system | grep gateway
	@echo "=== Gateway Service ==="
	kubectl get svc -n istio-system | grep gateway
	@echo "=== Gateway Logs ==="
	kubectl logs -n istio-system -l app=istio-proxy --tail=20

troubleshoot-mtls: ## Troubleshoot mTLS issues
	@echo "Troubleshooting mTLS..."
	@echo "=== mTLS Status ==="
	istioctl authn tls-check productpage.mesh-demo.svc.cluster.local
	@echo "=== Peer Authentication ==="
	kubectl get peerauthentication -n mesh-demo

troubleshoot-routing: ## Troubleshoot routing issues
	@echo "Troubleshooting routing..."
	@echo "=== Virtual Services ==="
	kubectl get virtualservice -n mesh-demo
	@echo "=== Destination Rules ==="
	kubectl get destinationrule -n mesh-demo
	@echo "=== Service Endpoints ==="
	kubectl get endpoints -n mesh-demo

check-sidecars: ## Check sidecar injection
	@echo "Checking sidecar injection..."
	kubectl get pods -n mesh-demo -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].name}{"\n"}{end}'

show-destination-rules: ## Show destination rules
	@echo "Showing destination rules..."
	kubectl get destinationrule -n mesh-demo -o yaml

show-service-graph: ## Show service graph info
	@echo "Service graph information:"
	@echo "Access Kiali at: http://localhost:20001"
	@echo "Or run: make open-kiali"

show-metrics: ## Show service metrics
	@echo "Showing service metrics..."
	kubectl exec -n mesh-demo deployment/test-client -- curl -s productpage:9080/productpage | grep -o "reviews-v[0-9]"

show-traces: ## Show traces info
	@echo "Trace information:"
	@echo "Access Jaeger at: http://localhost:16686"
	@echo "Or run: make open-jaeger"

analyze-traces: ## Analyze traces
	@echo "Analyzing traces..."
	@echo "Check Jaeger UI for detailed trace analysis"