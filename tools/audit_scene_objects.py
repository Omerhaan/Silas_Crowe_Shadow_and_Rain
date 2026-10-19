#!/usr/bin/env python3
import os
import re
import json

with open("assets/asset_manifest.json", "r", encoding="utf-8") as f:
    manifest = json.load(f).get("assets", {})

manifest_keys = set(manifest.keys())

oids = []
for r, d, fs in os.walk("scenes"):
    for f in fs:
        if f.endswith(".tscn"):
            with open(os.path.join(r, f), "r", encoding="utf-8") as s:
                for line in s:
                    m = re.search(r'object_id = "([^"]+)"', line)
                    if m:
                        oids.append((m.group(1), f))

print(f"{'OBJECT ID':<32} {'SCENE':<24} {'IN MANIFEST?'}")
print("-" * 70)
for oid, fn in sorted(set(oids)):
    has_manifest = (oid in manifest_keys) or (f"prop_{oid}" in manifest_keys)
    print(f"{oid:<32} {fn:<24} {has_manifest}")
