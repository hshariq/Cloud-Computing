#!/usr/bin/env python3
"""
COMP5123M Coursework 2 — Task (a): Selection of VNF(s)
Run this script to see the VNF selection, justification, and resource requirements.
Usage: python3 task1_vnf_selection.py
"""

import json
from textwrap import dedent

# --- Task 1 data (VNF selection) ---
CONSTRAINT = {
    "max_ram_gb": 2,
    "multi_cpu": "avoid",
    "relevance": "telecom (e.g. Free5GC, Open5GS, firewalls, load balancers)",
}

VNF_PRIMARY = {
    "name": "LoxiLB",
    "type": "Telco-oriented load balancer (L4/L7)",
    "description": (
        "eBPF-based cloud-native load balancer for Kubernetes, edge, and telco. "
        "Supports GTP-U, SCTP, SRv6. Suitable as VNF for 5G/edge user-plane or NF load balancing."
    ),
    "resources": {
        "memory_mib": (512, 1024),
        "memory_note": "512 Mi – 1 Gi",
        "cpu_cores": (0.5, 1.0),
        "cpu_note": "0.5 – 1 core",
        "storage": "Minimal (container image)",
    },
    "constraint_check": {
        "ram_ok": True,
        "single_cpu_ok": True,
    },
    "justification": [
        "Telecom relevance: L4/L7 load balancing, GTP/SCTP/SRv6 for 5G/edge.",
        "Fits ≤2 GB RAM and single-CPU; no dedicated multi-CPU requirement.",
        "Kubernetes-native; works on Minikube/kind and K3s/MicroK8s.",
        "Same VNF deployable in both cloud-like and edge-like environments.",
    ],
    "references": {
        "GitHub": "https://github.com/loxilb-io/loxilb",
        "Docs": "https://loxilb-io.github.io/loxilbdocs/",
    },
}

VNF_OPTIONAL = {
    "name": "Lightweight firewall (iptables/nftables in container)",
    "resources": {"memory_mib": (64, 256), "cpu_note": "0.25 – 0.5 core"},
    "relevance": "Packet filtering at edge (e.g. UPF, N3/N6 interfaces).",
}

WHY_NOT_FULL_5G = [
    "Free5GC / Open5GS are full 5G core stacks (AMF, SMF, UPF, etc.).",
    "Full deployments typically need 4 GB+ RAM and multiple cores.",
    "Brief allows 'firewalls, load balancers' as valid VNFs; LoxiLB is justified.",
]


def print_section(title: str, char: str = "=") -> None:
    print()
    print(char * 60)
    print(title)
    print(char * 60)


def run_task1_text() -> None:
    """Print Task (a) in readable text form."""
    print_section("COMP5123M — Task (a): Selection of VNF(s)", "=")
    print("\nConstraint:")
    print(f"  Max RAM: {CONSTRAINT['max_ram_gb']} GB  |  Multi-CPU: {CONSTRAINT['multi_cpu']}")
    print(f"  Relevance: {CONSTRAINT['relevance']}")

    print_section("Selected VNF (primary): " + VNF_PRIMARY["name"], "-")
    print(VNF_PRIMARY["description"])
    print("\nResource requirements (outline):")
    print(f"  Memory:  {VNF_PRIMARY['resources']['memory_note']}  (constraint < 2 GB ✓)")
    print(f"  CPU:     {VNF_PRIMARY['resources']['cpu_note']}  (single CPU ok ✓)")
    print(f"  Storage: {VNF_PRIMARY['resources']['storage']}")
    print("\nJustification:")
    for j in VNF_PRIMARY["justification"]:
        print(f"  • {j}")
    print("\nReferences:")
    for k, v in VNF_PRIMARY["references"].items():
        print(f"  {k}: {v}")

    print_section("Optional second VNF", "-")
    print(f"  {VNF_OPTIONAL['name']}")
    print(f"  Memory: {VNF_OPTIONAL['resources']['memory_mib'][0]}–{VNF_OPTIONAL['resources']['memory_mib'][1]} Mi  |  CPU: {VNF_OPTIONAL['resources']['cpu_note']}")
    print(f"  Relevance: {VNF_OPTIONAL['relevance']}")

    print_section("Why not full 5G cores (Free5GC / Open5GS)?", "-")
    for line in WHY_NOT_FULL_5G:
        print(f"  • {line}")

    print()
    print("Summary: LoxiLB selected; justification and resource outline above.")
    print("Use this output in your Gradescope report for Task (a).")
    print()


def run_task1_json() -> None:
    """Print Task (a) as JSON (machine-readable)."""
    out = {
        "task": "a",
        "constraint": CONSTRAINT,
        "primary_vnf": {
            **VNF_PRIMARY,
            "resources": VNF_PRIMARY["resources"],
        },
        "optional_vnf": VNF_OPTIONAL,
        "why_not_full_5g": WHY_NOT_FULL_5G,
    }
    print(json.dumps(out, indent=2))


if __name__ == "__main__":
    import sys
    if "--json" in sys.argv:
        run_task1_json()
    else:
        run_task1_text()
