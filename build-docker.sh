#!/bin/bash
# Lokaler Build via Docker Desktop auf macOS.
# Identisch zu dem, was GitHub Actions tut — nur dass du das auf deinem
# Rechner laufen lassen kannst, bevor du einen Tag pushst.

set -euo pipefail

cd "$(dirname "$0")"

# === Schritt 0: borochi-docs lokalisieren ===
# Wir suchen es in folgender Reihenfolge:
# 1. ./borochi-docs (git submodule oder direkter Subordner)
# 2. ../borochi-docs (Geschwister-Ordner, Marcels lokales Setup)
DOCS_SRC=""
if [ -f "borochi-docs/mkdocs.yml" ]; then
    DOCS_SRC="$(pwd)/borochi-docs"
elif [ -f "../borochi-docs/mkdocs.yml" ]; then
    DOCS_SRC="$(cd .. && pwd)/borochi-docs"
fi

if [ -z "$DOCS_SRC" ]; then
    echo "⚠  borochi-docs nicht gefunden — Image wird ohne Offline-Doku gebaut."
    echo "   Tipp: git submodule add https://github.com/digihonk/borochi-docs.git borochi-docs"
else
    echo "→ Baue Doku aus $DOCS_SRC..."
    DOCS_OUT="$(pwd)/stage-borochi/03-docs/files/opt/borochi/docs-site"
    rm -rf "$DOCS_OUT"
    mkdir -p "$DOCS_OUT"

    docker run --rm \
        -v "$DOCS_SRC:/docs:ro" \
        -v "$DOCS_OUT:/out" \
        python:3.11-slim \
        sh -c "set -e; \
               pip install --quiet --no-cache-dir mkdocs mkdocs-material pymdown-extensions && \
               cp -r /docs /tmp/docs && \
               cd /tmp/docs && \
               mkdocs build --strict -d /out"

    if [ -f "$DOCS_OUT/index.html" ]; then
        SITE_SIZE=$(du -sh "$DOCS_OUT" | awk '{print $1}')
        echo "✓ Doku gebaut: $SITE_SIZE in $DOCS_OUT"
    else
        echo "✗ Doku-Build fehlgeschlagen — index.html fehlt im Output!"
        exit 1
    fi
fi

# === Schritt 1: pi-gen-Submodule sicherstellen ===
if [ ! -f pi-gen/build.sh ]; then
    echo "→ pi-gen-Submodule holen..."
    git submodule update --init --recursive
fi

# === Schritt 2: Custom-Stage in pi-gen kopieren ===
echo "→ Kopiere stage-borochi nach pi-gen/..."
rm -rf pi-gen/stage-borochi
cp -r stage-borochi pi-gen/

# === Schritt 3: Config in pi-gen platzieren ===
echo "→ Kopiere config nach pi-gen/..."
cp config pi-gen/config

# === Schritt 4: Output-Dir vorbereiten ===
mkdir -p deploy

# === Schritt 5: Build via Docker (pi-gen liefert build-docker.sh) ===
echo "→ Starte Pi-gen-Build (~30-60 Min, ~6 GB RAM nötig)..."
cd pi-gen
CONTINUE=${CONTINUE:-0} ./build-docker.sh -c config

# === Schritt 6: Output kopieren ===
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
echo "  Doku auf dem Pi: http://borochi.local:81"
