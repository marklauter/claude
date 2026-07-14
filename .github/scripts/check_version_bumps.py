#!/usr/bin/env python3
"""Fail a PR when a plugin's files changed but its version wasn't bumped.

The plugin cache is keyed by version, so an in-place edit at the same version
number never reaches installs. This guard doesn't pick the bump — it just makes
"we forgot to bump" a red CI check instead of a silent stale install. The author
or agent decides the semver size.

Usage: check_version_bumps.py <base-sha> <head-sha>
"""

import json
import subprocess
import sys
from pathlib import Path


def git(*args: str) -> str:
    return subprocess.run(
        ["git", *args], capture_output=True, text=True, check=True
    ).stdout


def changed_plugins(base: str, head: str) -> set[str]:
    """Top-level plugin names with any changed file in base...head."""
    out = git("diff", "--name-only", f"{base}...{head}")
    names: set[str] = set()
    for line in out.splitlines():
        parts = Path(line.strip()).parts
        if len(parts) >= 2 and parts[0] == "plugins":
            names.add(parts[1])
    return names


def version_at(ref: str, plugin: str) -> str | None:
    """Plugin version at a git ref, or None if the manifest didn't exist there."""
    path = f"plugins/{plugin}/.claude-plugin/plugin.json"
    try:
        blob = git("show", f"{ref}:{path}")
    except subprocess.CalledProcessError:
        return None
    return json.loads(blob).get("version")


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: check_version_bumps.py <base-sha> <head-sha>", file=sys.stderr)
        return 2
    base, head = sys.argv[1], sys.argv[2]

    stale: list[tuple[str, str | None]] = []
    for plugin in sorted(changed_plugins(base, head)):
        old = version_at(base, plugin)
        new = version_at(head, plugin)
        if old is None:
            continue  # newly added plugin — nothing to bump against
        if old == new:
            stale.append((plugin, old))

    if stale:
        print("Plugin files changed without a version bump:\n")
        for plugin, version in stale:
            print(
                f"  - {plugin}: still {version} — "
                f"bump plugins/{plugin}/.claude-plugin/plugin.json"
            )
        print(
            "\nThe plugin cache is keyed by version; without a bump, installs keep "
            "the old files. Pick the semver size that fits the change and bump it."
        )
        return 1

    print("Version-bump check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
