#!/usr/bin/env bash
# Verify Hello World (and optional LB). Uses port-forward if no LoadBalancer IP.
# Usage: ./verify-helloworld.sh [nginx|loxilb]
#   nginx  = test via vnf-nginx-lb service (default)
#   loxilb = test via hello-world-lb service
set -e
MODE="${1:-nginx}"
NAMESPACE="vnf-demo"
if [[ "$MODE" == "loxilb" ]]; then
  SVC="hello-world-lb"
else
  SVC="vnf-nginx-lb"
fi
echo "Checking service: $SVC (mode: $MODE)"
if ! kubectl get svc "$SVC" -n "$NAMESPACE" &>/dev/null; then
  echo "Service $SVC not found. Deploy with deploy-vnf-nginx.sh or deploy-vnf-loxilb.sh first."
  exit 1
fi
EXTERNAL_IP=$(kubectl get svc "$SVC" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [[ -n "$EXTERNAL_IP" ]]; then
  echo "Testing: curl http://$EXTERNAL_IP"
  curl -s -m 5 "http://$EXTERNAL_IP" || true
else
  echo "No external IP yet. Using port-forward..."
  kubectl port-forward -n "$NAMESPACE" "svc/$SVC" 8080:80 &
  PF_PID=$!
  sleep 2
  curl -s -m 5 "http://127.0.0.1:8080" || true
  kill $PF_PID 2>/dev/null || true
fi
echo ""
echo "Direct ClusterIP test (hello-world):"
kubectl run curl-test-"$$" --rm -i --restart=Never --image=curlimages/curl:latest -- curl -s -m 5 "http://hello-world.vnf-demo.svc.cluster.local" 2>/dev/null || true
