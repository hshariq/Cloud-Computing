#!/usr/bin/env bash
# Ensure the edge environment is running:
# - Multipass VM `edge-k3s` is running
# - K3s is installed and active inside it
# - Writes a working kubeconfig to: ~/.kube/edge-k3s.yaml (server points to VM IPv4)
#
# Usage: ./scripts/ensure-edge.sh
set -e

VM_NAME="edge-k3s"
KUBECONFIG_PATH="${HOME}/.kube/edge-k3s.yaml"

log() { echo "[ensure-edge] $*"; }

if ! command -v multipass >/dev/null 2>&1; then
  log "Error: multipass not found. Install Multipass and create VM '${VM_NAME}'."
  exit 1
fi

# Ensure VM exists
if ! multipass info "${VM_NAME}" >/dev/null 2>&1; then
  log "Error: Multipass VM '${VM_NAME}' not found."
  log "Create it (example): multipass launch --name ${VM_NAME} --cpus 1 --memory 1G --disk 10G jammy"
  exit 1
fi

log "Starting '${VM_NAME}' (if needed)..."
multipass start "${VM_NAME}" >/dev/null 2>&1 || true

# Get VM IPv4 (first one listed by multipass info)
VM_IP="$(multipass info "${VM_NAME}" | awk '/^IPv4:/ {print $2; exit}')"
if [[ -z "${VM_IP}" ]]; then
  log "Error: could not determine IPv4 for '${VM_NAME}'."
  exit 1
fi
log "VM IPv4: ${VM_IP}"

# Ensure K3s active (install if missing)
log "Checking K3s service..."
K3S_ACTIVE="$(multipass exec "${VM_NAME}" -- sudo systemctl is-active k3s 2>/dev/null || true)"
if [[ "${K3S_ACTIVE}" != "active" ]]; then
  # If k3s is already installed, just start it instead of reinstalling.
  if multipass exec "${VM_NAME}" -- bash -lc "command -v k3s >/dev/null 2>&1"; then
    log "K3s installed but not active; starting K3s service..."
    multipass exec "${VM_NAME}" -- sudo systemctl start k3s >/dev/null 2>&1 || true
    # Wait up to ~60s for k3s to become active
    for _ in {1..30}; do
      K3S_ACTIVE="$(multipass exec "${VM_NAME}" -- sudo systemctl is-active k3s 2>/dev/null || true)"
      [[ "${K3S_ACTIVE}" == "active" ]] && break
      sleep 2
    done
  else
    log "K3s not installed; installing K3s (this may take a minute)..."
    multipass exec "${VM_NAME}" -- bash -lc "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--disable traefik,servicelb' sh -" >/dev/null
    K3S_ACTIVE="$(multipass exec "${VM_NAME}" -- sudo systemctl is-active k3s 2>/dev/null || true)"
  fi
fi

if [[ "${K3S_ACTIVE}" != "active" ]]; then
  log "Error: K3s is not active inside '${VM_NAME}'."
  exit 1
fi
log "K3s is active."

# Write kubeconfig to Mac with correct server IP
log "Writing kubeconfig to ${KUBECONFIG_PATH} ..."
mkdir -p "$(dirname "${KUBECONFIG_PATH}")"

python3 - <<PY
import subprocess, re, os, sys
vm_name = "${VM_NAME}"
vm_ip = "${VM_IP}"
out_path = os.path.expanduser("${KUBECONFIG_PATH}")

raw = subprocess.check_output(
    ["multipass", "exec", vm_name, "--", "sudo", "cat", "/etc/rancher/k3s/k3s.yaml"],
    text=True,
)
raw = raw.replace("server: https://127.0.0.1:6443", f"server: https://{vm_ip}:6443")
os.makedirs(os.path.dirname(out_path), exist_ok=True)
with open(out_path, "w", encoding="utf-8") as f:
    f.write(raw)

print(f"Wrote {out_path}")
print(f"server: https://{vm_ip}:6443")
PY

log "Verifying kubectl access using KUBECONFIG..."
KUBECONFIG="${KUBECONFIG_PATH}" kubectl get nodes >/dev/null
log "Edge cluster is reachable."

