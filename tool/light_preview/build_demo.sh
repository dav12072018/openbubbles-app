#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

"${FLUTTER_BIN:-flutter}" build web --web-renderer html --pwa-strategy=none --target demo_main.dart

# Flutter subsets icon fonts on each build. Version font URLs by their contents
# so an open preview cannot reuse an older subset that lacks newly added icons.
python3 - <<'PY'
import hashlib
import json
from pathlib import Path

assets = Path("build/web/assets")
manifest_path = assets / "FontManifest.json"
manifest = json.loads(manifest_path.read_text())
for family in manifest:
    for font in family["fonts"]:
        asset = font["asset"].split("?", 1)[0]
        digest = hashlib.sha256((assets / asset).read_bytes()).hexdigest()[:12]
        font["asset"] = f"{asset}?v={digest}"
manifest_path.write_text(json.dumps(manifest, separators=(",", ":")))
PY
