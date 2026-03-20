#!/usr/bin/env bash
# Test LB path (curl) then run traffic generator. Uses port-forward if no external IP.
# Usage:
#   ./test-lb-and-traffic.sh cloud [duration_sec]
#   ./test-lb-and-traffic.sh edge  [duration_sec]
#   ./test-lb-and-traffic.sh [duration_sec]   # defaults to cloud

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

ENV_ARG="${1:-cloud}"
if [[ "${ENV_ARG}" == "cloud" || "${ENV_ARG}" == "edge" ]]; then
  shift
else
  ENV_ARG="cloud"
fi

# Force correct kubeconfig selection per environment
if [[ "${ENV_ARG}" == "cloud" ]]; then
  unset KUBECONFIG
else
  export KUBECONFIG="${HOME}/.kube/edge-k3s.yaml"
fi

# Only use first argument if it looks like a number
RAW="${1:-30}"
DURATION="$([[ "$RAW" =~ ^[0-9]+$ ]] && echo "$RAW" || echo "30")"
NAMESPACE="vnf-demo"
SVC="vnf-nginx-lb"

# Use 9080 for port-forward to avoid clashing with existing 8080 (e.g. from a previous run)
PORT=9080

# Fail fast if the service doesn't exist in the *current* cluster/context
if ! kubectl get svc "$SVC" -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "Error: Service $SVC not found in namespace $NAMESPACE."
  echo ""
  echo "This usually means kubectl is pointing at the wrong cluster."
  echo "Current context: $(kubectl config current-context 2>/dev/null || echo unknown)"
  echo "Nodes:"
  kubectl get nodes 2>/dev/null || true
  echo ""
  echo "Cloud test (Minikube): unset KUBECONFIG and use minikube context."
  echo "Edge test (K3s): export KUBECONFIG=~/.kube/edge-k3s.yaml"
  exit 1
fi

# Get URL: external IP or port-forward
EXTERNAL_IP=$(kubectl get svc "$SVC" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
if [[ -n "$EXTERNAL_IP" ]]; then
  URL="http://$EXTERNAL_IP"
  echo "Using LoadBalancer IP: $URL"
else
  URL="http://127.0.0.1:$PORT"
  echo "No external IP; starting port-forward on $PORT..."
  # Kill any existing port-forward on this port so we don't get duplicate output
  pkill -f "port-forward.*${SVC}.*${PORT}:80" 2>/dev/null || true
  sleep 1
  # Start port-forward and capture logs so we can show real errors if it fails
  PF_LOG="$(mktemp)"
  nohup kubectl port-forward -n "$NAMESPACE" "svc/$SVC" "$PORT:80" </dev/null >"$PF_LOG" 2>&1 &
  PF_PID=$!
  # Wait until it actually responds (otherwise traffic test will be all errors)
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    if curl -s -m 2 "$URL" >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done
  if ! curl -s -m 2 "$URL" >/dev/null 2>&1; then
    echo ""
    echo "Error: port-forward did not become ready."
    echo "Port-forward log:"
    tail -n 30 "$PF_LOG" 2>/dev/null || true
    kill "$PF_PID" 2>/dev/null || true
    exit 1
  fi
fi

echo ""
echo "=== 1. Curl LB (Hello World) ==="
curl -s -m 5 "$URL"
echo ""
echo ""
echo "=== 2. Generate traffic (${DURATION}s) ==="
python3 "$REPO_ROOT/scripts/traffic/generate_traffic.py" --url "$URL" --duration "$DURATION" --workers 4

[[ -n "$PF_PID" ]] && kill $PF_PID 2>/dev/null || true
