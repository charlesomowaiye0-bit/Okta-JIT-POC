#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["pyyaml>=6"]
# ///
"""Validate infra/identity.yaml against the JIT POC schema."""
from __future__ import annotations

import sys
from pathlib import Path

import yaml


REQUIRED_FIELDS = ("email", "first_name", "last_name", "groups")


def validate(path: Path) -> list[str]:
    """Return a list of error messages. Empty list = valid."""
    errors: list[str] = []
    try:
        data = yaml.safe_load(path.read_text())
    except FileNotFoundError:
        return [f"{path} not found. Run scripts/setup_identity.py first."]
    except yaml.YAMLError as e:
        return [f"{path} is not valid YAML: {e}"]

    users = (data or {}).get("users")
    if not isinstance(users, list) or len(users) == 0:
        errors.append(f"{path}: `users` must be a non-empty list of at least one user.")
        return errors

    seen_emails: set[str] = set()
    for i, user in enumerate(users):
        if not isinstance(user, dict):
            errors.append(f"{path}: users[{i}] must be a mapping.")
            continue
        for field in REQUIRED_FIELDS:
            if field not in user:
                errors.append(f"{path}: users[{i}] missing required field `{field}`.")
        if not isinstance(user.get("groups"), list) or len(user.get("groups", [])) == 0:
            errors.append(f"{path}: users[{i}].groups must be a non-empty list.")
        email = user.get("email")
        if email in seen_emails:
            errors.append(f"{path}: duplicate email `{email}`.")
        if isinstance(email, str):
            seen_emails.add(email)

    return errors


def main(argv: list[str]) -> int:
    path = Path(argv[1]) if len(argv) > 1 else Path("infra/identity.yaml")
    errors = validate(path)
    if errors:
        for e in errors:
            print(e, file=sys.stderr)
        return 1
    print(f"{path} ✓", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
