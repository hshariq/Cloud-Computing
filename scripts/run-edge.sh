#!/usr/bin/env bash
# One command to run edge (Multipass + K3s) + deploy VNF + Hello World.
# Usage: ./scripts/run-edge.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "Step 1: Ensure edge VM + K3s is running"
"${REPO_ROOT}/scripts/ensure-edge.sh"

echo ""
echo "Step 2: Deploy Hello World + nginx LB VNF (edge)"
export KUBECONFIG="${HOME}/.kube/edge-k3s.yaml"
"${REPO_ROOT}/scripts/deploy/deploy-vnf-nginx.sh" edge

echo ""
echo "Done"
echo "Test (recommended):"
echo "  ./scripts/deploy/test-lb-and-traffic.sh edge 30"

