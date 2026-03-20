#!/usr/bin/env python3
"""
Task (d): Run a full experiment — traffic generation + metrics collection.
Generates traffic in background while collecting CPU/memory, then reports
latency, throughput, and resource utilization.
Usage:
  python3 run_experiment.py --url http://<LB-IP> --duration 30
  python3 run_experiment.py --url http://127.0.0.1:8080 --duration 60 --out-dir ../results
"""
import argparse
import os
import subprocess
import sys
import threading
import time

# Add sibling paths for imports
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
TRAFFIC_DIR = os.path.join(REPO_ROOT, "scripts", "traffic")
sys.path.insert(0, TRAFFIC_DIR)
sys.path.insert(0, SCRIPT_DIR)

from collect_metrics import collect_loop
from generate_traffic import run_traffic


def main():
    p = argparse.ArgumentParser(description="Run experiment: traffic + metrics")
    p.add_argument("--url", required=True, help="Target URL for traffic")
    p.add_argument("--namespace", default="vnf-demo", help="Namespace for metrics")
    p.add_argument("--duration", type=int, default=30, help="Traffic duration (seconds)")
    p.add_argument("--workers", type=int, default=4, help="Concurrent traffic workers")
    p.add_argument("--metrics-interval", type=int, default=5, help="Metrics sample interval (seconds)")
    p.add_argument("--out-dir", default=None, help="Write results here (e.g. results/)")
    args = p.parse_args()

    out_dir = args.out_dir or os.path.join(REPO_ROOT, "results")
    os.makedirs(out_dir, exist_ok=True)

    traffic_stats = None

    def traffic_worker():
        nonlocal traffic_stats
        traffic_stats = run_traffic(args.url, args.duration, args.workers)

    # Start traffic in background
    th = threading.Thread(target=traffic_worker)
    th.start()
    # Collect metrics while traffic runs (samples every metrics_interval)
    samples_count = max(1, args.duration // args.metrics_interval)
    metrics = collect_loop(args.namespace, args.metrics_interval, samples_count, None)
    th.join()

    # Summary
    metrics_path = os.path.join(out_dir, "metrics_experiment.csv")
    with open(metrics_path, "w", newline="") as f:
        import csv
        w = csv.writer(f)
        w.writerow(["timestamp", "sample", "pod", "cpu_millicores", "memory_mib"])
        for s in metrics:
            for pod in s["pods"]:
                w.writerow([s["timestamp"], s["sample"], pod["pod"], pod["cpu_millicores"], pod["memory_mib"]])

    traffic_path = os.path.join(out_dir, "traffic_experiment.json")
    with open(traffic_path, "w") as f:
        import json
        json.dump(traffic_stats, f, indent=2)

    print("\n--- Experiment summary ---")
    print("Traffic:", traffic_stats)
    print(f"Metrics: {len(metrics)} samples written to {metrics_path}")
    print(f"Traffic stats: {traffic_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
