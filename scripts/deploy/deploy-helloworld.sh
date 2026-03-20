#!/usr/bin/env bash
# Deploy Hello World app to current cluster (cloud or edge).
# Usage: ./deploy-helloworld.sh [cloud|edge]
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV="${1:-cloud}"
MANIFESTS="$REPO_ROOT/manifests/$ENV/hello-world.yaml"
if [[ ! -f "$MANIFESTS" ]]; then
  echo "Usage: $0 [cloud|edge]"
  echo "Manifests not found: $MANIFESTS"
  exit 1
fi
echo "Deploying Hello World ($ENV)..."
kubectl apply -f "$MANIFESTS"
kubectl rollout status deployment/hello-world -n vnf-demo --timeout=120s
echo "Done. Run verify-helloworld.sh to test."
