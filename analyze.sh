#!/usr/bin/env bash
set -euo pipefail
APK="${1:?APK path required}"
OUT="out"
rm -rf "$OUT" work
mkdir -p "$OUT" work

cp "$APK" "$OUT/input.apk"
sha256sum "$APK" > "$OUT/SHA256.txt"
ls -lh "$APK" > "$OUT/file-info.txt"

# Decode resources/manifest.
java -jar tools/apktool.jar d -f "$APK" -o work/apktool >/dev/null 2>&1 || true

# Extract all ZIP entries without executing anything.
unzip -q -o "$APK" -d work/unzip || true

# Decompile DEX when JADX was downloaded successfully.
JADX_BIN=$(find tools -type f -path '*/bin/jadx' -print -quit || true)
if [ -n "$JADX_BIN" ]; then
  "$JADX_BIN" --show-bad-code --no-res -d work/jadx "$APK" >/dev/null 2>&1 || true
fi

# Collect manifest, package metadata and likely network/config indicators.
if [ -f work/apktool/AndroidManifest.xml ]; then
  cp work/apktool/AndroidManifest.xml "$OUT/AndroidManifest.xml"
fi

# Search broadly for URLs/domains/Firebase/Cloud Config/network strings.
SEARCH_ROOTS="work/apktool work/jadx work/unzip"
{
  echo '=== URL/domain-like strings ==='
  rg -a -o -N 'https?://[^"'"'"'<>[:space:]]+' $SEARCH_ROOTS 2>/dev/null | sort -u || true
  echo
  echo '=== EHI/Evozi/Firebase/cloud related strings ==='
  rg -a -n -i 'ehi|evozi|firebase|cloud.?config|mycloudclient|ehiapp|http-injector|injector|update|api|endpoint|base.?url|server.?url' $SEARCH_ROOTS 2>/dev/null | head -n 5000 || true
} > "$OUT/network-indicators.txt"

# Search raw APK strings too; useful when code is obfuscated/protected.
strings -a "$APK" | rg -i 'https?://|firebase|ehiapp|mycloudclient|http-injector|evozi|cloud.?config|base.?url|api' | sort -u > "$OUT/raw-strings-network.txt" || true

# List native libraries and DEX files; helpful for protected apps.
find work/unzip -type f \( -name '*.dex' -o -name '*.so' \) -printf '%P\n' | sort > "$OUT/code-files.txt" || true

# Copy decoded resources if present.
if [ -d work/apktool/res ]; then
  cp -a work/apktool/res "$OUT/res"
fi

cat > "$OUT/README.txt" <<'TXT'
This artifact contains static APK analysis only.
It does not execute the APK or contact any service from the APK.
Check network-indicators.txt first.
If an exact API path is not present, the app may construct it at runtime or load protected code dynamically; static extraction cannot guarantee the runtime endpoint.
TXT

echo "Analysis complete: $OUT"
