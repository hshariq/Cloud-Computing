#!/usr/bin/env bash
# Stop all project-related background stuff: port-forwards, Minikube, and Multipass.
set -e

echo "1. Stopping all port-forwards..."
pkill -f "kubectl port-forward" 2>/dev/null || true

echo "2. Stopping Cloud (Minikube)..."
minikube stop 2>/dev/null || true

echo "3. Stopping Edge (Multipass VMs)..."
# This stops all running Multipass instances
if command -v multipass &>/dev/null; then
  multipass stop --all 2>/dev/null || true
fi

echo ""
echo "Done. Your Mac's RAM is now free!"
echo "Run ./run to start Cloud or ./run-edge to start Edge."