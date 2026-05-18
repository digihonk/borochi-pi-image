#!/bin/bash -e
# Läuft in chroot des Pi-Filesystem. Vor First-Boot.
# Setup: User-Gruppen, Docker-User, Verzeichnis-Permissions.

# borochi-User in docker-Gruppe (kann ohne sudo Container managen nach First-Boot)
usermod -aG docker borochi

# UID 1500 (bridge) und 1501 (agent) für die Container-User anlegen
groupadd -g 1500 borochi-bridge || true
useradd  -u 1500 -g 1500 -M -s /usr/sbin/nologin borochi-bridge || true
groupadd -g 1501 borochi-agent || true
useradd  -u 1501 -g 1501 -M -s /usr/sbin/nologin borochi-agent || true

# /opt/borochi vorbereiten — Files kommen aus 'files/'
mkdir -p /opt/borochi/{bridge,agent,frontend,data}
chown -R 1500:1500 /opt/borochi/data

# CLI-Tools ausführbar
chmod +x /usr/local/bin/borochi-setup
chmod +x /usr/local/bin/borochi-update
chmod +x /usr/local/bin/borochi-doctor

# UFW vorbereiten (aktiviert wird beim First-Boot)
ufw --force default deny incoming
ufw --force default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Docker beim Boot aktivieren
systemctl enable docker

# Avahi für borochi.local
systemctl enable avahi-daemon

# Fail2ban gegen SSH-Brute-Force
systemctl enable fail2ban

# Nginx ist installiert, aber wir nutzen den nicht direkt -- der Bridge-Container
# liefert auch Frontend aus. Default-Site disabled lassen.
systemctl disable nginx

echo "borochi-app stage installed."
