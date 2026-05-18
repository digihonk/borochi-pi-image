#!/bin/bash -e
# Stage-Init für Docs.
#
# Die Doku-HTML-Site wurde VOR pi-gen außerhalb des chroot gebaut
# (durch build-docker.sh bzw. den GitHub Workflow) und liegt jetzt
# unter /opt/borochi/docs-site/ im Image.
#
# Hier setzen wir nur die Permissions + stellen sicher dass das
# Verzeichnis exisitiert, falls der Pre-Build geskippt wurde.

mkdir -p /opt/borochi/docs-site
chmod -R 0755 /opt/borochi/docs-site

# Fallback: wenn keine Site gebaut wurde, eine Placeholder-index.html
if [ ! -f /opt/borochi/docs-site/index.html ]; then
    cat > /opt/borochi/docs-site/index.html <<'EOF'
<!DOCTYPE html>
<html>
<head><title>Borochi-Doku</title>
<meta charset="utf-8">
<style>
  body { font-family: -apple-system, sans-serif; max-width: 700px; margin: 4rem auto; padding: 2rem; line-height: 1.6; color: #ddd; background: #0a0a0a; }
  h1 { color: #ffb52e; } a { color: #66e3ff; }
  code { background: #1a1a1a; padding: 2px 6px; border-radius: 3px; }
</style></head>
<body>
<h1>Borochi-Anleitung</h1>
<p>Die statische Doku-Site wurde beim Image-Build nicht erzeugt
(<code>mkdocs build</code>-Step war nicht aktiv).</p>
<p>Online verfügbar unter:
<a href="https://digihonk.github.io/borochi-docs/">digihonk.github.io/borochi-docs</a>.</p>
<p>Bei Fragen: <code>ssh borochi@borochi.local</code> → <code>borochi-doctor</code>.</p>
</body></html>
EOF
fi

echo "borochi-docs stage processed."
