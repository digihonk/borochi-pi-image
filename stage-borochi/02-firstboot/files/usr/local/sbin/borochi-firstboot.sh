#!/bin/bash
# borochi-firstboot.sh — läuft EINMAL beim ersten Boot des Pi.
# Generiert Secrets, schreibt .env, aktiviert UFW, startet Docker-Compose.
# Markiert sich danach als "done" über /var/lib/borochi-firstboot.done.

set -e

FLAG=/var/lib/borochi-firstboot.done
ENV_FILE=/opt/borochi/.env
ENV_TEMPLATE=/opt/borochi/.env.template

if [ -f "$FLAG" ]; then
    echo "[$(date -Is)] First-Boot bereits gelaufen — Skip"
    exit 0
fi

echo "[$(date -Is)] ═══ Borochi First-Boot ═══"

# --- 1. Secrets generieren ---
echo "[$(date -Is)] Generiere Secrets..."
JWT=$(openssl rand -hex 32)
MASTER=$(openssl rand -hex 32)
AGENT=$(openssl rand -hex 32)

# --- 2. .env aus Template bauen ---
echo "[$(date -Is)] Schreibe $ENV_FILE..."
if [ ! -f "$ENV_TEMPLATE" ]; then
    echo "FEHLER: $ENV_TEMPLATE fehlt!"
    exit 1
fi

sed \
    -e "s|__GENERATED_AT_FIRSTBOOT__|REPLACEME|" \
    "$ENV_TEMPLATE" > "$ENV_FILE"

# Sicher: nicht in History
sed -i \
    -e "0,/REPLACEME/s||$JWT|" \
    -e "0,/REPLACEME/s||$MASTER|" \
    -e "0,/REPLACEME/s||$AGENT|" \
    "$ENV_FILE"

chown root:docker "$ENV_FILE"
chmod 0640 "$ENV_FILE"

# --- 3. Data-Verzeichnis Permissions ---
echo "[$(date -Is)] Setze Verzeichnis-Permissions..."
mkdir -p /opt/borochi/data
chown -R 1500:1500 /opt/borochi/data
chmod 0700 /opt/borochi/data

# --- 4. UFW aktivieren ---
echo "[$(date -Is)] Aktiviere Firewall..."
ufw --force enable

# --- 5. Docker-Compose hochziehen ---
echo "[$(date -Is)] Starte Borochi-Container..."
cd /opt/borochi
if docker compose up -d; then
    echo "[$(date -Is)] ✓ Container gestartet"
else
    echo "[$(date -Is)] FEHLER beim docker compose up — Logs prüfen"
    exit 1
fi

# --- 6. Health-Check (max 60 Sek warten) ---
echo "[$(date -Is)] Warte auf Bridge-Health..."
for i in $(seq 1 30); do
    if curl -sf --max-time 2 http://127.0.0.1/api/health >/dev/null 2>&1; then
        echo "[$(date -Is)] ✓ Bridge antwortet"
        break
    fi
    sleep 2
done

# --- 7. Done-Flag setzen ---
touch "$FLAG"
echo "[$(date -Is)] ═══ First-Boot fertig ═══"
echo "[$(date -Is)] Browser auf http://borochi.local — First-Run-Wizard öffnet sich"
echo "[$(date -Is)] Für Waveshare-IPs: sudo borochi-setup"

# Service disablen (läuft nie wieder)
systemctl disable borochi-firstboot.service
