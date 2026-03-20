#!/usr/bin/env bash
# One command to run cloud (Minikube) + deploy VNF + Hello World.
# Usage: ./scripts/run-cloud.sh
# From repo root: ./scripts/run-cloud.sh
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

unset KUBECONFIG

echo "Step 1: Ensure cluster is running (Docker + Minikube)"
"$REPO_ROOT/scripts/ensure-cluster.sh" cloud

echo ""
echo "Step 2: Deploy Hello World + nginx LB VNF"
"$REPO_ROOT/scripts/deploy/deploy-vnf-nginx.sh" cloud

echo ""
echo "Done"
echo "export KUBECONFIG=${HOME}/.kube/minikube-k8s.yaml"
echo "Then test:"
echo "then ./scripts/deploy/test-lb-and-traffic.sh 30"


# In a Bash script, when you see a string wrapped in quotes on its own line 
# like "$REPO_ROOT/scripts/ensure-cluster.sh" cloud, that is how you execute a file

# Execution (Calling the Sub-script)
# Because this line starts with a path to a file (and you previously gave it permission with chmod +x),
# the computer treats it as a command.
# It pauses the current script (run-cloud.sh).
# It jumps over to ensure-cluster.sh and starts running the code inside that file.
# It passes the word cloud as an argument (a specific instruction) to that script.