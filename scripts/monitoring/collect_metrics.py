#!/usr/bin/env python3
"""
Task (d): Collect CPU and memory utilization for VNF demo workloads.
Uses kubectl top (requires metrics-server in cluster).
Usage:
  python3 collect_metrics.py --namespace vnf-demo --interval 5 --samples 12
  python3 collect_metrics.py --namespace vnf-demo --output results/metrics.csv
"""
import argparse
import csv
import json
import subprocess
import sys
import time
from typing import Optional


def kubectl_top_pods(namespace: str) -> list[dict]:
    """Return list of {name, cpu, memory} for pods in namespace."""
    cmd = [
        "kubectl", "top", "pods",
        "-n", namespace,
        "--no-headers",
    ]
    try:
        out = subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL)
    except (subprocess.CalledProcessError, FileNotFoundError):
        return []
    rows = []
    for line in out.strip().splitlines():
        parts = line.split()
        if len(parts) >= 3:
            name = parts[0]
            # Handle pod name with optional prefix (e.g. "hello-world-xxx")
            cpu_raw = parts[1].replace("m", "") if "m" in parts[1] else parts[1]
            mem_raw = parts[2].replace("Mi", "").replace("Gi", "")
            try:
                cpu_m = int(cpu_raw) if cpu_raw.isdigit() else 0
                mem_mi = int(mem_raw) if mem_raw.isdigit() else 0
                if "Gi" in parts[2]:
                    mem_mi = int(mem_raw) * 1024
            except ValueError:
                cpu_m, mem_mi = 0, 0
            rows.append({"pod": name, "cpu_millicores": cpu_m, "memory_mib": mem_mi})
    return rows


def collect_loop(namespace: str, interval_sec: int, samples: int, output_path: Optional[str]) -> list:
    """Collect metrics every interval_sec, for samples times. Optionally write CSV."""
    all_samples = []
    for i in range(samples):
        ts = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        pods = kubectl_top_pods(namespace)
        sample = {"timestamp": ts, "sample": i + 1, "pods": pods}
        all_samples.append(sample)
        total_cpu = sum(p["cpu_millicores"] for p in pods)
        total_mem = sum(p["memory_mib"] for p in pods)
        print(f"[{ts}] sample {i+1}/{samples} — pods: {len(pods)}, total CPU: {total_cpu}m, total memory: {total_mem}Mi")
        if i < samples - 1:
            time.sleep(interval_sec)
    if output_path:
        with open(output_path, "w", newline="") as f:
            w = csv.writer(f)
            w.writerow(["timestamp", "sample", "pod", "cpu_millicores", "memory_mib"])
            for s in all_samples:
                for p in s["pods"]:
                    w.writerow([s["timestamp"], s["sample"], p["pod"], p["cpu_millicores"], p["memory_mib"]])
        print(f"Wrote {output_path}")
    return all_samples


def main():
    p = argparse.ArgumentParser(description="Collect CPU/memory metrics from Kubernetes pods")
    p.add_argument("--namespace", default="vnf-demo", help="Namespace (default vnf-demo)")
    p.add_argument("--interval", type=int, default=5, help="Seconds between samples (default 5)")
    p.add_argument("--samples", type=int, default=12, help="Number of samples (default 12)")
    p.add_argument("--output", "-o", help="Write CSV to this path")
    p.add_argument("--json", action="store_true", help="Print last sample as JSON")
    args = p.parse_args()

    samples = collect_loop(args.namespace, args.interval, args.samples, args.output)
    if args.json and samples:
        print(json.dumps(samples[-1], indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
