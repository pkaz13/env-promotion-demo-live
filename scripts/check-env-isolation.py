#!/usr/bin/env python3
"""Deterministic guardrail: config of one Environment must not reference resources owned by another.

Usage: python3 scripts/check-env-isolation.py [repo_root]
Exit code 0 = clean, 1 = violations. Same command for developers, AI agents and CI.
"""
import json
import os
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".")
ownership = json.loads((root / "policy/resource-ownership.json").read_text())["resources"]
violations = []

for env_dir in sorted(p for p in (root / "config").iterdir() if p.is_dir()):
    env = env_dir.name
    for f in sorted(env_dir.rglob("*")):
        if not f.is_file():
            continue
        for lineno, line in enumerate(f.read_text().splitlines(), 1):
            for resource, allowed in ownership.items():
                if re.search(re.escape(resource), line, re.IGNORECASE) and env not in allowed:
                    violations.append(
                        f"{f.relative_to(root)}:{lineno}: '{resource}' belongs to {allowed}, not to '{env}'"
                    )

for v in violations:
    print(f"::error::{v}" if os.environ.get("GITHUB_ACTIONS") else f"ERROR {v}")
print(f"{len(violations)} cross-environment reference(s) found." if violations else "OK: no cross-environment references.")
sys.exit(1 if violations else 0)
