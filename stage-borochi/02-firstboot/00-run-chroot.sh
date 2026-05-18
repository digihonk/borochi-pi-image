#!/bin/bash -e
# Aktiviert den First-Boot-Service. Wird in chroot zur Build-Zeit ausgeführt.

# Service-Ownership + Permissions
chmod 0644 /etc/systemd/system/borochi-firstboot.service
chmod 0750 /usr/local/sbin/borochi-firstboot.sh

# Beim Pi-Boot starten lassen
systemctl enable borochi-firstboot.service

# Log-Verzeichnis vorbereiten
touch /var/log/borochi-firstboot.log
chmod 0640 /var/log/borochi-firstboot.log

echo "borochi-firstboot service enabled."
