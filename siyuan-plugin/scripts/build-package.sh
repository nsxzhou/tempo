#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
STAGE="$DIST/package"
PLUGIN_NAME="$(node -p "require('$ROOT/plugin.json').name")"
PKG="$STAGE/$PLUGIN_NAME"
ZIP="$DIST/${PLUGIN_NAME}.zip"
LEGACY_ZIP="$DIST/tempo-sync.zip"

cd "$ROOT"

npm run build

rm -rf "$STAGE"
mkdir -p "$PKG"

cp "$ROOT/dist/index.js" "$PKG/index.js"
cp "$ROOT/plugin.json" "$PKG/plugin.json"
cp "$ROOT/README.zh-CN.md" "$PKG/README.zh-CN.md"
if [[ -d "$ROOT/i18n" ]]; then
  cp -R "$ROOT/i18n" "$PKG/i18n"
fi

if [[ ! -f "$ROOT/icon.png" ]]; then
  python3 - <<'PY'
from pathlib import Path
try:
    from PIL import Image
    img = Image.new("RGB", (160, 160), color=(15, 15, 15))
    img.save(Path("icon.png"))
except ImportError:
    # 最小合法 1x1 PNG（160x160 占位由思源缩放）
    import struct, zlib
    w, h = 160, 160
    row = b"\x00" + bytes([24, 24, 24]) * w
    raw = row * h
    png = b"\x89PNG\r\n\x1a\n" + struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)
    png += struct.pack(">I", 13) + b"IHDR" + struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)
    png += struct.pack(">I", zlib.crc32(b"IHDR" + struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)) & 0xffffffff)
    comp = zlib.compress(raw, 9)
    png += struct.pack(">I", len(comp)) + b"IDAT" + comp
    png += struct.pack(">I", zlib.crc32(b"IDAT" + comp) & 0xffffffff)
    png += struct.pack(">I", 0) + b"IEND"
    png += struct.pack(">I", zlib.crc32(b"IEND") & 0xffffffff)
    Path("icon.png").write_bytes(png)
PY
fi

cp "$ROOT/icon.png" "$PKG/icon.png"

rm -f "$ZIP" "$LEGACY_ZIP"
(cd "$STAGE" && zip -r "$ZIP" "$PLUGIN_NAME")
cp "$ZIP" "$LEGACY_ZIP"

if ! unzip -Z1 "$ZIP" | grep -qx "${PLUGIN_NAME}/plugin.json"; then
  echo "ERROR: zip must contain ${PLUGIN_NAME}/plugin.json (folder name must match plugin.json name)"
  exit 1
fi

echo "Package ready: $ZIP (also copied to $LEGACY_ZIP)"
echo "Install folder must be: data/plugins/${PLUGIN_NAME}/"
SIZE_KB=$(( $(stat -f%z "$PKG/index.js" 2>/dev/null || stat -c%s "$PKG/index.js") / 1024 ))
echo "index.js size: ${SIZE_KB} KB"
if [ "$SIZE_KB" -gt 500 ]; then
  echo "WARNING: index.js exceeds 500KB; SiYuan may fail to load the plugin."
fi
