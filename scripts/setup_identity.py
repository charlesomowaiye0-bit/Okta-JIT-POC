#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["pyyaml>=6"]
# ///
"""Interactive bootstrap for infra/identity.yaml. No-op if the file exists."""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import yaml


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--path", default="infra/identity.yaml")
    args = parser.parse_args(argv[1:])

    target = Path(args.path)
    if target.exists():
        print(f"{target} already exists; skipping interactive bootstrap.", file=sys.stderr)
        return 0

    print(f"No {target} found. Let's seed one user.", file=sys.stderr)
    try:
        email = input("Email: ").strip()
        first_name = input("First name: ").strip()
        last_name = input("Last name: ").strip()
    except EOFError as e:
        print(f"setup-identity aborted: {e}", file=sys.stderr)
        return 2

    user = {
        "email": email,
        "first_name": first_name,
        "last_name": last_name,
        "groups": ["jit-requesters"],
    }
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(yaml.safe_dump({"users": [user]}, sort_keys=False))
    print(f"Wrote {target} (1 user). Edit the file directly to add more.", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
