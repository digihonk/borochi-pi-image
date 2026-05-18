#!/bin/bash
# Lokaler Build via Docker Desktop auf macOS.
# Identisch zu dem, was GitHub Actions tut — nur dass du das auf deinem
# Rechner laufen lassen kannst, bevor du einen Tag pushst.

set -euo pipefail

cd "$(dirname "$0")"

# 1. pi-gen-Submodule sicherstellen
if [ ! -f pi-gen/build.sh ]; then
    echo "→ pi-gen-Submodule holen..."
    git submodule update --init --recursive
fi

# 2. Custom-Stage in pi-gen kopieren
echo "→ Kopiere stage-borochi nach pi-gen/..."
rm -rf pi-gen/stage-borochi
cp -r stage-borochi pi-gen/

# 3. Config in pi-gen platzieren
echo "→ Kopiere config nach pi-gen/..."
cp config pi-gen/config

# 4. Output-Dir vorbereiten
mkdir -p deploy

# 5. Build via Docker (pi-gen liefert build-docker.sh)
echo "→ Starte Build (~30-60 Min, ~6 GB RAM nötig)..."
cd pi-gen
CONTINUE=${CONTINUE:-0} ./build-docker.sh -c config

# 6. Output kopieren
cd ..
IMG=$(ls -t pi-gen/deploy/*.img.xz 2>/dev/null | head -1)
if [ -z "$IMG" ]; then
    echo "✗ Kein Image im Output-Verzeichnis gefunden!"
    echo "  pi-gen/deploy/ Inhalt:"
    ls -la pi-gen/deploy/ || true
    exit 1
fi

BASENAME=$(basename "$IMG")
cp "$IMG" "deploy/$BASENAME"
sha256sum "deploy/$BASENAME" > "deploy/$BASENAME.sha256"

echo
echo "╔══════════════════════════════════════════════╗"
echo "║   Image gebaut                               ║"
echo "╚══════════════════════════════════════════════╝"
printf "  Datei:    deploy/%s\n" "$BASENAME"
printf "  Größe:    %s\n" "$(stat -f%z "deploy/$BASENAME" 2>/dev/null || stat -c%s "deploy/$BASENAME" | numfmt --to=iec)"
printf "  SHA-256:  deploy/%s.sha256\n" "$BASENAME"
echo
echo "  Flashen: Raspberry Pi Imager → 'Use Custom' → diese Datei"
