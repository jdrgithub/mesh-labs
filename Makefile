# Makefile for mesh-labs project

.PHONY: help deploy test monitor clean status logs

# Default target
help: ## Show this help message
	@echo "Mesh Labs - Bookinfo Service Mesh Project for k3s"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Deployment targets
deploy: ## Deploy the complete bookinfo application
	@echo "Deploying bookinfo application..."
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
	@echo "Running bookinfo tests..."
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
	@echo "Showing bookinfo status..."
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
clean: ## Remove all bookinfo resources
	@echo "Cleaning up bookinfo resources..."
	kubectl delete namespace bookinfo --ignore-not-found=true

clean-configs: ## Remove only Istio configurations
	@echo "Cleaning up Istio configurations..."
	kubectl delete -f configs/ --ignore-not-found=true

# Status and debugging
status: ## Show comprehensive status
	@echo "=== Pod Status ==="
	kubectl get pods -n bookinfo -o wide
	@echo ""
	@echo "=== Service Status ==="
	kubectl get svc -n bookinfo
	@echo ""
	@echo "=== Istio Resources ==="
	kubectl get destinationrule,virtualservice,gateway,peerauthentication,authorizationpolicy -n bookinfo

logs: ## Show logs for productpage service
	@echo "Showing logs for productpage service..."
	kubectl logs -n bookinfo -l app=productpage --tail=50

logs-proxy: ## Show istio-proxy logs
	@echo "Showing istio-proxy logs..."
	kubectl logs -n bookinfo -l app=productpage -c istio-proxy --tail=50

# Development helpers
port-forward: ## Port forward to productpage service
	@echo "Port forwarding to productpage service..."
	kubectl port-forward -n bookinfo svc/productpage 9080:9080

shell: ## Get shell access to test client
	@echo "Getting shell access to test client..."
	kubectl exec -n bookinfo -it deployment/test-client -- sh

# Validation
validate: ## Validate Istio configuration
	@echo "Validating Istio configuration..."
	istioctl analyze bookinfo

check-mtls: ## Check mTLS status
	@echo "Checking mTLS status..."
	istioctl authn tls-check productpage.bookinfo.svc.cluster.local

# Demo targets for service mesh learning
deploy-multiple-versions: ## Deploy multiple versions of reviews service
	@echo "Deploying multiple versions of reviews service..."
	kubectl apply -f manifests/demos/reviews-v2-deployment.yaml
	kubectl apply -f manifests/demos/reviews-v3-deployment.yaml
	kubectl wait --for=condition=available --timeout=300s deployment/reviews-v2 -n bookinfo
	kubectl wait --for=condition=available --timeout=300s deployment/reviews-v3 -n bookinfo

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
	kubectl exec -n bookinfo deployment/test-client -- curl -s productpage:9080/productpage

test-routing: ## Test basic routing
	@echo "Testing basic routing..."
	kubectl exec -n bookinfo deployment/test-client -- curl -s productpage:9080/productpage

test-header-routing: ## Test header-based routing
	@echo "Testing header-based routing..."
	@echo "Without header (should go to v1):"
	kubectl exec -n bookinfo deployment/test-client -- curl -s productpage:9080/productpage
	@echo "With jason header (should go to v2):"
	kubectl exec -n bookinfo deployment/test-client -- curl -s -H "end-user: jason" productpage:9080/productpage

test-traffic-distribution: ## Test traffic distribution
	@echo "Testing traffic distribution..."
	@for i in {1..10}; do \
		echo "Request $$i:"; \
		kubectl exec -n bookinfo deployment/test-client -- curl -s productpage:9080/productpage | grep -o "reviews-v[0-9]" || echo "No version found"; \
	done

test-load-balancing: ## Test load balancing
	@echo "Testing load balancing..."
	@for i in {1..10}; do \
		echo "Request $$i:"; \
		kubectl exec -n bookinfo deployment/test-client -- curl -s productpage:9080/productpage | grep -o "reviews-v[0-9]" || echo "No version found"; \
	done

test-fault-tolerance: ## Test fault tolerance
	@echo "Testing fault tolerance..."
	@for i in {1..10}; do \
		echo "Request $$i:"; \
		kubectl exec -n bookinfo deployment/test-client -- curl -s -w "HTTP Status: %{http_code}\n" productpage:9080/productpage | tail -1; \
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
		kubectl exec -n bookinfo deployment/test-client -- curl -s productpage:9080/productpage > /dev/null; \
	done
	@echo "Traffic generation complete"

generate-traced-requests: ## Generate traced requests
	@echo "Generating traced requests..."
	@for i in {1..20}; do \
		kubectl exec -n bookinfo deployment/test-client -- curl -s -H "x-b3-traceid: $$(openssl rand -hex 16)" productpage:9080/productpage > /dev/null; \
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

# Istioctl Demo targets - Understanding the Service Mesh Under the Hood
demo-istioctl: ## Run comprehensive istioctl demo
	@echo "=== Istioctl Service Mesh Deep Dive Demo ==="
	@echo "This demo shows what's happening under the hood in your service mesh"
	@echo "Run individual targets: make demo-proxy-config, make demo-proxy-status, etc."

demo-proxy-config: ## Show proxy configuration (clusters, listeners, routes)
	@echo "=== Proxy Configuration Deep Dive ==="
	@echo "Getting productpage pod name..."
	@POD=$$(kubectl get pods -n bookinfo -l app=productpage -o jsonpath='{.items[0].metadata.name}'); \
	echo "Using pod: $$POD"; \
	echo ""; \
	echo "=== 1. CLUSTERS (Upstream Services) ==="; \
	echo "Clusters define upstream services that Envoy can route to:"; \
	istioctl proxy-config cluster $$POD.bookinfo --fqdn productpage.bookinfo.svc.cluster.local; \
	echo ""; \
	echo "=== 2. LISTENERS (Inbound/Outbound Ports) ==="; \
	echo "Listeners define what ports Envoy listens on:"; \
	istioctl proxy-config listener $$POD.bookinfo --port 9080; \
	echo ""; \
	echo "=== 3. ROUTES (Traffic Routing Rules) ==="; \
	echo "Routes define how traffic is routed to clusters:"; \
	istioctl proxy-config route $$POD.bookinfo --name 9080

demo-proxy-status: ## Show proxy status and configuration summary
	@echo "=== Proxy Status and Configuration Summary ==="
	@POD=$$(kubectl get pods -n bookinfo -l app=productpage -o jsonpath='{.items[0].metadata.name}'); \
	echo "Using pod: $$POD"; \
	echo ""; \
	echo "=== 1. PROXY STATUS ==="; \
	echo "Shows proxy configuration status and sync state:"; \
	istioctl proxy-status $$POD.bookinfo; \
	echo ""; \
	echo "=== 2. PROXY CONFIG DUMP ==="; \
	echo "Complete configuration dump (first 50 lines):"; \
	istioctl proxy-config dump $$POD.bookinfo | head -50

demo-service-mesh: ## Show service mesh topology and connectivity
	@echo "=== Service Mesh Topology and Connectivity ==="
	@echo "=== 1. ALL PROXY STATUS ==="; \
	echo "Shows all proxies in the mesh and their sync status:"; \
	istioctl proxy-status; \
	echo ""; \
	echo "=== 2. SERVICE ENDPOINTS ==="; \
	echo "Shows service endpoints and their health:"; \
	istioctl proxy-config endpoint $$(kubectl get pods -n bookinfo -l app=productpage -o jsonpath='{.items[0].metadata.name}').bookinfo --cluster productpage.bookinfo.svc.cluster.local

demo-traffic-management: ## Show traffic management configuration
	@echo "=== Traffic Management Configuration ==="
	@echo "=== 1. VIRTUAL SERVICES ==="; \
	echo "Virtual services define traffic routing rules:"; \
	kubectl get virtualservice -n bookinfo -o wide; \
	echo ""; \
	echo "=== 2. DESTINATION RULES ==="; \
	echo "Destination rules define traffic policies and subsets:"; \
	kubectl get destinationrule -n bookinfo -o wide; \
	echo ""; \
	echo "=== 3. GATEWAYS ==="; \
	echo "Gateways define ingress/egress points:"; \
	kubectl get gateway --all-namespaces -o wide

demo-security: ## Show security configuration (mTLS, auth policies)
	@echo "=== Security Configuration ==="
	@echo "=== 1. PEER AUTHENTICATION (mTLS) ==="; \
	echo "Peer authentication defines mTLS settings:"; \
	kubectl get peerauthentication -n bookinfo -o wide; \
	echo ""; \
	echo "=== 2. AUTHORIZATION POLICIES ==="; \
	echo "Authorization policies define access control:"; \
	kubectl get authorizationpolicy -n bookinfo -o wide; \
	echo ""; \
	echo "=== 3. REQUEST AUTHENTICATION ==="; \
	echo "Request authentication for JWT/end-user auth:"; \
	kubectl get requestauthentication -n bookinfo -o wide

demo-observability: ## Show observability and telemetry configuration
	@echo "=== Observability and Telemetry ==="
	@echo "=== 1. TELEMETRY CONFIGURATION ==="; \
	echo "Telemetry defines metrics and tracing:"; \
	kubectl get telemetry -n bookinfo -o wide; \
	echo ""; \
	echo "=== 2. PROXY METRICS ==="; \
	echo "Envoy proxy metrics (first 20 lines):"; \
	kubectl exec -n bookinfo $$(kubectl get pods -n bookinfo -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- curl -s localhost:15000/stats | head -20

demo-debugging: ## Show debugging and troubleshooting commands
	@echo "=== Debugging and Troubleshooting ==="
	@echo "=== 1. CONFIGURATION ANALYSIS ==="; \
	echo "Analyze configuration for issues:"; \
	istioctl analyze -n bookinfo; \
	echo ""; \
	echo "=== 2. PROXY LOGS ==="; \
	echo "Recent proxy logs (last 10 lines):"; \
	kubectl logs -n bookinfo $$(kubectl get pods -n bookinfo -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy --tail=10

demo-istioctl-x: ## Demonstrate istioctl x subcommands
	@echo "=== Istioctl X Subcommands Demo ==="
	@echo "=== 1. PRECHECK ==="; \
	echo "Pre-installation checks:"; \
	istioctl x precheck; \
	echo ""; \
	echo "=== 2. DESCRIBE POD ==="; \
	echo "Describe pod configuration:"; \
	istioctl x describe pod $$(kubectl get pods -n bookinfo -l app=productpage -o jsonpath='{.items[0].metadata.name}') -n bookinfo; \
	echo ""; \
	echo "=== 3. VERSION INFO ==="; \
	echo "Istio version information:"; \
	istioctl version

demo-secrets: ## Show secrets and certificate information
	@echo "=== Secrets and Certificates ==="
	@echo "=== 1. ISTIO SECRETS ==="; \
	echo "Istio system secrets:"; \
	kubectl get secrets -n istio-system | grep -E "(ca|cert)"; \
	echo ""; \
	echo "=== 2. CERTIFICATE DETAILS ==="; \
	echo "Certificate information for productpage pod:"; \
	istioctl x describe pod $$(kubectl get pods -n bookinfo -l app=productpage -o jsonpath='{.items[0].metadata.name}') -n bookinfo | grep -A 10 -B 5 -i cert; \
	echo ""; \
	echo "=== 3. WORKLOAD CERTIFICATES ==="; \
	echo "Workload certificate status:"; \
	kubectl get secrets -n bookinfo | grep -E "(istio|ca|cert)"

demo-troubleshoot-mtls: ## Troubleshoot mTLS issues
	@echo "=== mTLS Troubleshooting ==="
	@echo "=== 1. PEER AUTHENTICATION ==="; \
	echo "Current peer authentication policies:"; \
	kubectl get peerauthentication -n bookinfo -o wide; \
	echo ""; \
	echo "=== 2. mTLS CONFIGURATION ==="; \
	echo "mTLS configuration for productpage:"; \
	istioctl x describe pod $$(kubectl get pods -n bookinfo -l app=productpage -o jsonpath='{.items[0].metadata.name}') -n bookinfo | grep -i mtls; \
	echo ""; \
	echo "=== 3. CERTIFICATE STATUS ==="; \
	echo "Certificate secrets in istio-system:"; \
	kubectl get secrets -n istio-system | grep ca

demo-troubleshoot-auth: ## Troubleshoot authorization policy issues
	@echo "=== Authorization Policy Troubleshooting ==="
	@echo "=== 1. AUTHORIZATION POLICIES ==="; \
	echo "Current authorization policies:"; \
	kubectl get authorizationpolicy -n bookinfo -o wide; \
	echo ""; \
	echo "=== 2. SPIFFE IDENTITIES ==="; \
	echo "Service accounts and SPIFFE identities:"; \
	kubectl get pods -n bookinfo -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.serviceAccountName}{"\n"}{end}' | while read pod sa; do \
		echo "Pod: $$pod, SA: $$sa, SPIFFE: cluster.local/ns/bookinfo/sa/$$sa"; \
	done; \
	echo ""; \
	echo "=== 3. POLICY ENFORCEMENT ==="; \
	echo "Policy enforcement for productpage:"; \
	istioctl x describe pod $$(kubectl get pods -n bookinfo -l app=productpage -o jsonpath='{.items[0].metadata.name}') -n bookinfo | grep -A 5 -B 5 -i auth

demo-troubleshoot-network: ## Troubleshoot network connectivity issues
	@echo "=== Network Troubleshooting ==="
	@echo "=== 1. SERVICE ENDPOINTS ==="; \
	echo "Service endpoints for productpage:"; \
	istioctl proxy-config endpoint $$(kubectl get pods -n bookinfo -l app=productpage -o jsonpath='{.items[0].metadata.name}').bookinfo --cluster productpage.bookinfo.svc.cluster.local; \
	echo ""; \
	echo "=== 2. ROUTE CONFIGURATION ==="; \
	echo "Route configuration for productpage:"; \
	istioctl proxy-config route $$(kubectl get pods -n bookinfo -l app=productpage -o jsonpath='{.items[0].metadata.name}').bookinfo --name 9080 | head -10; \
	echo ""; \
	echo "=== 3. LISTENER CONFIGURATION ==="; \
	echo "Listener configuration for port 9080:"; \
	istioctl proxy-config listener $$(kubectl get pods -n bookinfo -l app=productpage -o jsonpath='{.items[0].metadata.name}').bookinfo --port 9080

demo-troubleshoot-performance: ## Troubleshoot performance issues
	@echo "=== Performance Troubleshooting ==="
	@echo "=== 1. PROXY METRICS ==="; \
	echo "Proxy metrics (first 20 lines):"; \
	kubectl exec -n bookinfo $$(kubectl get pods -n bookinfo -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- curl -s localhost:15000/stats | head -20; \
	echo ""; \
	echo "=== 2. RESOURCE USAGE ==="; \
	echo "Pod resource usage:"; \
	kubectl top pods -n bookinfo; \
	echo ""; \
	echo "=== 3. PROXY LOGS ==="; \
	echo "Recent proxy logs (last 5 lines):"; \
	kubectl logs -n bookinfo $$(kubectl get pods -n bookinfo -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy --tail=5

demo-auth-policies: ## Demonstrate authorization policies with SPIFFE identities
	@echo "=== Authorization Policies Deep Dive ==="
	@echo "=== 1. CURRENT AUTHORIZATION POLICIES ==="; \
	echo "Show existing authorization policies:"; \
	kubectl get authorizationpolicy -n bookinfo -o wide; \
	echo ""; \
	echo "=== 2. SPIFFE IDENTITIES ==="; \
	echo "Show SPIFFE identities for Bookinfo services:"; \
	kubectl get pods -n bookinfo -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.serviceAccountName}{"\n"}{end}' | while read pod sa; do \
		echo "Pod: $$pod, SA: $$sa, SPIFFE: cluster.local/ns/bookinfo/sa/$$sa"; \
	done; \
	echo ""; \
	echo "=== 3. APPLY DENY-ALL POLICY ==="; \
	echo "Apply deny-all authorization policy:"; \
	kubectl apply -f configs/auth-policies/deny-all.yaml; \
	echo ""; \
	echo "=== 4. TEST DENY-ALL (Should Fail) ==="; \
	echo "Testing access with deny-all policy:"; \
	kubectl exec -n bookinfo deployment/test-client -- curl -s -w "%{http_code}" productpage:9080/productpage -o /dev/null || echo "Connection failed"; \
	echo ""; \
	echo "=== 5. APPLY SPIFFE-BASED POLICIES ==="; \
	echo "Apply SPIFFE-based authorization policies:"; \
	kubectl apply -f configs/auth-policies/allow-productpage-spiffe.yaml; \
	kubectl apply -f configs/auth-policies/allow-reviews-to-ratings.yaml; \
	kubectl apply -f configs/auth-policies/allow-test-client.yaml; \
	kubectl apply -f configs/auth-policies/allow-gateway-ingress.yaml; \
	echo ""; \
	echo "=== 6. TEST WITH SPIFFE POLICIES ==="; \
	echo "Testing access with SPIFFE-based policies:"; \
	kubectl exec -n bookinfo deployment/test-client -- curl -s -w "%{http_code}" productpage:9080/productpage -o /dev/null; \
	echo ""; \
	echo "=== 7. SHOW FINAL POLICIES ==="; \
	echo "Final authorization policies:"; \
	kubectl get authorizationpolicy -n bookinfo -o wide

demo-complete: ## Run all istioctl demos in sequence
	@echo "=== Complete Istioctl Service Mesh Deep Dive ==="
	@$(MAKE) demo-proxy-config
	@echo ""; echo "=========================================="; echo ""
	@$(MAKE) demo-proxy-status
	@echo ""; echo "=========================================="; echo ""
	@$(MAKE) demo-service-mesh
	@echo ""; echo "=========================================="; echo ""
	@$(MAKE) demo-traffic-management
	@echo ""; echo "=========================================="; echo ""
	@$(MAKE) demo-security
	@echo ""; echo "=========================================="; echo ""
	@$(MAKE) demo-istioctl-x
	@echo ""; echo "=========================================="; echo ""
	@$(MAKE) demo-secrets
	@echo ""; echo "=========================================="; echo ""
	@$(MAKE) demo-troubleshoot-mtls
	@echo ""; echo "=========================================="; echo ""
	@$(MAKE) demo-troubleshoot-auth
	@echo ""; echo "=========================================="; echo ""
	@$(MAKE) demo-troubleshoot-network
	@echo ""; echo "=========================================="; echo ""
	@$(MAKE) demo-troubleshoot-performance
	@echo ""; echo "=========================================="; echo ""
	@$(MAKE) demo-observability
	@echo ""; echo "=========================================="; echo ""
	@$(MAKE) demo-debugging

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
	istioctl authn tls-check productpage.bookinfo.svc.cluster.local
	@echo "=== Peer Authentication ==="
	kubectl get peerauthentication -n bookinfo

troubleshoot-routing: ## Troubleshoot routing issues
	@echo "Troubleshooting routing..."
	@echo "=== Virtual Services ==="
	kubectl get virtualservice -n bookinfo
	@echo "=== Destination Rules ==="
	kubectl get destinationrule -n bookinfo
	@echo "=== Service Endpoints ==="
	kubectl get endpoints -n bookinfo

check-sidecars: ## Check sidecar injection
	@echo "Checking sidecar injection..."
	kubectl get pods -n bookinfo -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].name}{"\n"}{end}'

show-destination-rules: ## Show destination rules
	@echo "Showing destination rules..."
	kubectl get destinationrule -n bookinfo -o yaml

show-service-graph: ## Show service graph info
	@echo "Service graph information:"
	@echo "Access Kiali at: http://localhost:20001"
	@echo "Or run: make open-kiali"

show-metrics: ## Show service metrics
	@echo "Showing service metrics..."
	kubectl exec -n bookinfo deployment/test-client -- curl -s productpage:9080/productpage | grep -o "reviews-v[0-9]"

show-traces: ## Show traces info
	@echo "Trace information:"
	@echo "Access Jaeger at: http://localhost:16686"
	@echo "Or run: make open-jaeger"

analyze-traces: ## Analyze traces
	@echo "Analyzing traces..."
	@echo "Check Jaeger UI for detailed trace analysis"