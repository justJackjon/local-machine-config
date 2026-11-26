"""Print the installed and bucket versions of Scoop apps as JSON.

Usage: python3 scoop_versions.py <scoop root (POSIX path)> <app> [<app> ...]

Prints a list of {"name", "installed", "available", "outdated"} objects. A version is "" when it can't be
read (app not installed, bucket or manifest missing), and then `outdated` is false. Used by
install_base_packages to update apps only when their (age-gated) bucket offers a newer version than the one
installed, never an older one.
"""

import json
import os
import re
import sys


def version_key(version):
    """Compare versions part by part: numbers numerically, anything else as text (e.g. 2.10 > 2.9)."""
    return [(0, int(p), "") if p.isdigit() else (1, 0, p) for p in re.split(r"[^0-9A-Za-z]+", version) if p]


def is_older(installed, available):
    return bool(installed and available) and version_key(installed) < version_key(available)


def read_json(*candidates):
    for path in candidates:
        try:
            with open(path, encoding="utf-8-sig") as f:
                return json.load(f)
        except (OSError, ValueError):
            continue
    return {}


def main():
    root, apps = sys.argv[1], sys.argv[2:]
    result = []
    for name in apps:
        current = os.path.join(root, "apps", name, "current")
        # NOTE: Newer Scoop writes scoop-install.json/scoop-manifest.json; older releases install.json/manifest.json.
        install = read_json(os.path.join(current, "scoop-install.json"), os.path.join(current, "install.json"))
        manifest = read_json(os.path.join(current, "scoop-manifest.json"), os.path.join(current, "manifest.json"))
        bucket = install.get("bucket", "")
        available = ""
        if bucket:
            bucket_dir = os.path.join(root, "buckets", bucket)
            available = read_json(
                os.path.join(bucket_dir, "bucket", name + ".json"), os.path.join(bucket_dir, name + ".json")
            ).get("version", "")
        installed = manifest.get("version", "")
        result.append(
            {"name": name, "installed": installed, "available": available, "outdated": is_older(installed, available)}
        )
    json.dump(result, sys.stdout)


if __name__ == "__main__":
    main()
