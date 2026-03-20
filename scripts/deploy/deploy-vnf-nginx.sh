#!/usr/bin/env bash
# Deploy nginx load balancer VNF + Hello World (works on any cluster).
# Usage: ./deploy-vnf-nginx.sh [cloud|edge]
# Prerequisite: cluster must be running (e.g. minikube start for cloud, k3s for edge).
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV="${1:-cloud}"

if ! kubectl cluster-info &>/dev/null; then
  echo "Error: kubectl cannot reach a cluster (connection refused to localhost:8080)."
  echo "Start your cluster first:"
  echo "  Cloud (Minikube):  minikube start"
  echo "  Edge (K3s):       ensure K3s is running and KUBECONFIG is set"
  exit 1
fi

echo "Deploying Hello World ($ENV)..."
kubectl apply -f "$REPO_ROOT/manifests/$ENV/hello-world.yaml"
kubectl rollout status deployment/hello-world -n vnf-demo --timeout=120s
echo "Deploying nginx LB VNF ($ENV)..."
kubectl apply -f "$REPO_ROOT/manifests/$ENV/vnf-nginx-lb.yaml"
kubectl rollout status deployment/vnf-nginx-lb -n vnf-demo --timeout=120s
echo "Done. Get external IP: kubectl get svc vnf-nginx-lb -n vnf-demo"
echo "Then: curl http://<EXTERNAL-IP>"
echo ""
echo "Tests (recommended):"
echo "  chmod +x scripts/deploy/test-lb-and-traffic.sh"
echo "  ./scripts/deploy/test-lb-and-traffic.sh 30"
echo ""
echo "Manual port-forward test:"
echo "  kubectl port-forward -n vnf-demo svc/vnf-nginx-lb 9080:80"
echo "  curl http://127.0.0.1:9080"
