#!/usr/bin/env python3
"""score.py — aggregate per-tier JSON fragments into the final scorecard.json.

Each --tierN argument is a JSON object string of the shape:
    {"score": <int>, "max": <int>, "details": {...}}
or:
    {"score": null, "max": null, "skipped": true}
"""

import argparse
import datetime
import json
import sys


def parse_tier(s: str) -> dict:
    s = s.strip()
    if not s:
        return {"score": 0, "max": 0, "skipped": True}
    try:
        return json.loads(s)
    except json.JSONDecodeError as e:
        return {"score": 0, "max": 0, "error": f"parse error: {e}", "raw": s[:500]}


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--tier0",  required=True)
    p.add_argument("--tier1",  required=True)
    p.add_argument("--tier2",  required=True)
    p.add_argument("--tier3a", required=True)
    p.add_argument("--tier3b", required=True)
    p.add_argument("--tier4",  required=True)
    p.add_argument("--task",   required=True)
    p.add_argument("--output", required=True)
    args = p.parse_args()

    tiers = {
        "tier0_build":      parse_tier(args.tier0),
        "tier1_lit":        parse_tier(args.tier1),
        "tier2_spike":      parse_tier(args.tier2),
        "tier3a_isel":      parse_tier(args.tier3a),
        "tier3b_noregress": parse_tier(args.tier3b),
        "tier4_e2e":        parse_tier(args.tier4),
    }

    total = sum(int(t.get("score") or 0) for t in tiers.values())
    max_total = sum(int(t.get("max") or 0) for t in tiers.values())

    scorecard = {
        "schema_version": "1.0",
        "task": args.task,
        "timestamp_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "oracle_sha256_ok": True,  # if we got this far, oracle check passed
        **tiers,
        "total":       total,
        "max_total":   max_total,
        "pass":        total >= 80,
        "strong_pass": total >= 95,
    }

    with open(args.output, "w") as f:
        json.dump(scorecard, f, indent=2, sort_keys=False)
        f.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
