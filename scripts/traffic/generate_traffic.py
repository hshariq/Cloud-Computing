#!/usr/bin/env python3
"""
Task (d): Generate realistic traffic and measure latency + throughput.
Uses Python only (stdlib + optional requests). No iperf3/wrk required.
Usage:
  python3 generate_traffic.py --url http://<LB-IP> --duration 30 --workers 4
  python3 generate_traffic.py --url http://127.0.0.1:8080  # port-forward
"""
import argparse
import statistics
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Optional, Tuple
from urllib.request import urlopen, Request
from urllib.error import URLError, HTTPError

try:
    import requests
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False


def request_urllib(url: str, timeout: float) -> Tuple[float, int, Optional[str]]:
    """One request with urllib. Returns (latency_sec, status_code, error)."""
    start = time.perf_counter()
    try:
        req = Request(url, headers={"User-Agent": "COMP5123M-traffic-gen/1.0"})
        with urlopen(req, timeout=timeout) as r:
            r.read()
        return time.perf_counter() - start, 200, None
    except HTTPError as e:
        return time.perf_counter() - start, e.code, str(e)
    except URLError as e:
        return time.perf_counter() - start, -1, str(e)
    except Exception as e:
        return time.perf_counter() - start, -1, str(e)


def request_requests(url: str, timeout: float) -> Tuple[float, int, Optional[str]]:
    """One request with requests lib. Returns (latency_sec, status_code, error)."""
    start = time.perf_counter()
    try:
        r = requests.get(url, timeout=timeout)
        return time.perf_counter() - start, r.status_code, None
    except Exception as e:
        return time.perf_counter() - start, -1, str(e)


def run_traffic(url: str, duration_sec: int, workers: int, timeout: float = 10.0) -> dict:
    """Generate HTTP traffic and return latency/throughput stats."""
    do_request = request_requests if HAS_REQUESTS else request_urllib
    end_time = time.monotonic() + duration_sec
    latencies: list[float] = []
    total_requests = 0
    errors = 0

    def worker():
        nonlocal total_requests, errors
        while time.monotonic() < end_time:
            lat, code, err = do_request(url, timeout)
            total_requests += 1
            if err or code != 200:
                errors += 1
            else:
                latencies.append(lat)

    with ThreadPoolExecutor(max_workers=workers) as ex:
        futures = [ex.submit(worker) for _ in range(workers)]
        for f in as_completed(futures):
            f.result()

    duration_actual = duration_sec
    ok = len(latencies)
    throughput_total_rps = total_requests / duration_actual if duration_actual > 0 else 0
    throughput_success_rps = ok / duration_actual if duration_actual > 0 else 0
    return {
        "url": url,
        "duration_sec": duration_actual,
        "total_requests": total_requests,
        "successful_requests": ok,
        "errors": errors,
        "throughput_total_rps": round(throughput_total_rps, 2),
        "throughput_success_rps": round(throughput_success_rps, 2),
        "latency_mean_ms": round(statistics.mean(latencies) * 1000, 2) if latencies else None,
        "latency_p50_ms": round(statistics.median(latencies) * 1000, 2) if latencies else None,
        "latency_p95_ms": round(sorted(latencies)[int(len(latencies) * 0.95) - 1] * 1000, 2) if len(latencies) >= 20 else (round(statistics.median(latencies) * 1000, 2) if latencies else None),
        "latency_min_ms": round(min(latencies) * 1000, 2) if latencies else None,
        "latency_max_ms": round(max(latencies) * 1000, 2) if latencies else None,
    }


def main():
    p = argparse.ArgumentParser(description="Generate HTTP traffic and measure latency/throughput")
    p.add_argument("--url", required=True, help="Target URL (e.g. http://<LB-IP> or http://127.0.0.1:8080)")
    p.add_argument("--duration", type=int, default=30, help="Duration in seconds (default 30)")
    p.add_argument("--workers", type=int, default=4, help="Concurrent workers (default 4)")
    p.add_argument("--timeout", type=float, default=10.0, help="Request timeout seconds")
    p.add_argument("--json", action="store_true", help="Output only JSON")
    args = p.parse_args()

    stats = run_traffic(args.url, args.duration, args.workers, args.timeout)
    if args.json:
        import json
        print(json.dumps(stats))
    else:
        print("Traffic run results:")
        print(f"  URL: {stats['url']}")
        print(f"  Duration: {stats['duration_sec']} s")
        print(f"  Total requests: {stats['total_requests']} (ok: {stats['successful_requests']}, errors: {stats['errors']})")
        print(f"  Throughput (attempted): {stats['throughput_total_rps']} req/s")
        print(f"  Throughput (successful): {stats['throughput_success_rps']} req/s")
        print(f"  Latency (ms) — mean: {stats['latency_mean_ms']}, p50: {stats['latency_p50_ms']}, p95: {stats['latency_p95_ms']}, min: {stats['latency_min_ms']}, max: {stats['latency_max_ms']}")
    return 0 if stats["errors"] < stats["total_requests"] else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\nInterrupted.", file=sys.stderr)
        import os
        os._exit(130)  # exit immediately, skip threading shutdown (avoids traceback)
