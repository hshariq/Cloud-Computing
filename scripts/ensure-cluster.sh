#!/usr/bin/env bash
# Ensures a Kubernetes cluster is running (for cloud: Minikube with Docker).
# Usage: ./ensure-cluster.sh [cloud]
# Exits 0 when kubectl can reach a cluster; starts Docker + Minikube if needed.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log() { echo "[ensure-cluster] $*"; }

# Checks if a cluster is already reachable- prevents new cluster deployment if one already exists
if kubectl cluster-info &>/dev/null; then
  log "Cluster already reachable."
  exit 0
fi

log "No cluster reachable. Setting up..."


# Checks if Docker is running
docker_ok() {
  docker info &>/dev/null
}

# Starts Docker Desktop if it is not running
start_docker_macos() {
  if ! docker_ok; then
    if [[ "$(uname)" != "Darwin" ]]; then
      return 1
    fi
    if [[ -d /Applications/Docker.app ]]; then
      log "Starting Docker Desktop..."
      open -a Docker
      local waited=0
      while ! docker_ok; do
        sleep 5
        waited=$((waited + 5))
        if [[ $waited -ge 90 ]]; then
          log "Docker did not become ready in time. Open Docker Desktop manually and re-run."
          return 1
        fi
        log "Waiting for Docker... (${waited}s)"
      done
      log "Docker is ready."
    else
      return 1
    fi
  fi
  return 0
}


if start_docker_macos; then
  true
else
  log ""
  log "No working container runtime found. Do ONE of the following, then re-run this script:"
  log ""
  log "  Option A — Docker Desktop:"
  log "    brew install --cask docker"
  log "    Open Docker Desktop from Applications, wait until it's running, then re-run."
  log ""
  exit 1
fi

# Once docker is running, checks if Minikube is running
# Starts Minikube if it is not running
if ! kubectl cluster-info &>/dev/null; then
  log "Starting Minikube (driver=docker)..."
  # This command creates a single-node Kubernetes cluster inside a Docker container.
  minikube start --driver=docker
fi

# if still not reachable, logs an error and exits
if ! kubectl cluster-info &>/dev/null; then
  log "Minikube started but kubectl still cannot reach cluster. Check: minikube status"
  exit 1
fi

# if reachable, logs a success message and exits
log "Cluster is ready."
