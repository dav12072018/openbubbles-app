#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Separate test-engine processes avoid a Flutter 3.24 glyph-atlas capture bug
# where text painted by an earlier test can disappear from later PNG captures.
flutter_bin="${FLUTTER_BIN:-flutter}"
for height in 413 800; do
  for brightness in dark light; do
    for screen in inbox conversation; do
      "$flutter_bin" test --reporter expanded --dart-define=RENDER_PREVIEWS=true \
        --plain-name "render sample-data $screen $brightness component preview at 360x$height.0"
    done
  done
done
