# Borochi Pi-Image

Builder für `borochi-pi-vX.Y.Z.img.xz` — ein flashbares Raspberry-Pi-Image mit
Borochi vorinstalliert.

**Zielgruppe:** Solinteg-Nutzer, die kein Linux-Wissen haben. Sie flashen das
Image mit dem **Raspberry Pi Imager**, der Pi bootet, das Borochi-Dashboard
ist auf `http://borochi.local` erreichbar.

## Was im Image drin ist

- **Raspberry Pi OS Lite (Bookworm, arm64)** als Basis
- **Docker + Docker-Compose**
- **borochi-bridge** (FastAPI Container)
- **borochi-agent** (pymodbus Container, läuft per `localhost`-Verbindung zur Bridge)
- **Borochi-Frontend** unter Nginx auf Port 80
- **avahi-daemon** für `borochi.local` (mDNS)
- **ufw** mit Default-Deny + Port 22/80/443 offen
- **borochi-setup**, **borochi-update**, **borochi-doctor** CLI-Tools
- **First-Boot-Service** — generiert Secrets, startet alles automatisch

## Unterstützte Hardware

- Raspberry Pi 4 (2GB+)
- Raspberry Pi 5
- Raspberry Pi Zero 2 W
- Raspberry Pi 3B+ (mit Geduld — Builds dauern länger)

## Image bauen — lokal auf dem Mac

Du brauchst **Docker Desktop** mit Linux-Container-Support.

```bash
# Pi-gen-Submodule holen
git submodule update --init --recursive

# Image bauen (dauert ~30-60 Min, ~6 GB RAM-Bedarf)
./build-docker.sh

# Output:
#   deploy/borochi-pi-<date>-<sha>.img.xz   (~1.5-2 GB komprimiert)
#   deploy/borochi-pi-<date>-<sha>.info     (Build-Manifest)
```

## Image bauen — via GitHub Actions

```bash
# Tag pushen
git tag v2.27.0
git push --tags

# GitHub Actions baut automatisch, attached .img.xz an GitHub Release
```

## Flashen — User-Experience

1. **Raspberry Pi Imager** öffnen ([raspberrypi.com/software](https://www.raspberrypi.com/software/))
2. **Choose Device:** Pi 4 / Pi 5 (passend wählen)
3. **Choose OS** → ganz unten: **Use Custom** → `borochi-pi-vX.Y.Z.img.xz` wählen
4. **Choose Storage** → deine SD-Karte oder USB-SSD
5. **Settings (⚙)**:
   - Hostname: `borochi` (bleibt mDNS-resolvbar)
   - SSH aktivieren mit Passwort `borochi` (musst du beim ersten Login ändern)
   - WLAN-Daten falls kein LAN
   - Locale: `Europe/Berlin`
6. **Write** drücken — dauert je nach SD-Karte 3–10 Min
7. Karte in den Pi, Strom dran, ~2 Min warten
8. Browser auf **`http://borochi.local`** → First-Run-Wizard öffnet sich

## Architektur des Image-Builds

```
borochi-pi-image/
├── pi-gen/                    # Submodule: github.com/RPi-Distro/pi-gen
├── config                     # Pi-gen-Config (HOSTNAME, IMG_NAME, LOCALE, ...)
├── stage-borochi/             # Unsere Custom-Stage (zwischen stage2 und stage3)
│   ├── prerun.sh              # Stage-Init
│   ├── 00-packages/
│   │   └── 00-packages        # apt-Packages-Liste
│   ├── 01-borochi-app/
│   │   ├── 00-run-chroot.sh   # docker-compose.yml + Borochi-Files installieren
│   │   └── files/             # → wird nach / kopiert
│   │       └── opt/borochi/   # Compose-Files + .env-template
│   └── 02-firstboot/
│       ├── 00-run-chroot.sh   # systemd-Service enablen
│       └── files/
│           ├── etc/systemd/system/borochi-firstboot.service
│           └── usr/local/sbin/borochi-firstboot.sh
├── .github/workflows/build-image.yml
├── build-docker.sh            # Lokaler Build-Wrapper
└── README.md                  # diese Datei
```

## Update-Strategie für laufende Pis

User mit installiertem Image können updaten ohne neu zu flashen:

```bash
ssh borochi@borochi.local
sudo borochi-update      # zieht neue Docker-Images, hot-restart
```

Größere Image-Releases (OS-Updates, neue Pakete) brauchen ein Re-Flash, weil
das pi-gen-Image die Basis ist.

## Sicherheit

- Default-Login `borochi/borochi` muss beim ersten Login geändert werden
  (PAM-erzwungen)
- UFW blockt alle Ports außer 22/80/443
- Docker-Container laufen als non-root (UID 1500/1501)
- HA-Tokens und KI-API-Keys werden AES-verschlüsselt mit dem
  `MASTER_SECRET` aus `.env` gespeichert
- `MASTER_SECRET` wird beim First-Boot per `openssl rand -hex 32` generiert

## Troubleshooting Image-Build

| Problem | Lösung |
|---|---|
| `qemu-user-static not found` | macOS: Docker Desktop liefert das selbst mit. Linux: `apt install qemu-user-static binfmt-support` |
| Build hängt bei "Mounting boot partition" | Loop-Devices belegt: `losetup -D` als root |
| Out-of-Space | pi-gen Build-Cache mit ~15 GB einplanen, `--rm` an Docker-Run |
| Image bootet nicht | First-Boot-Logs in `/var/log/borochi-firstboot.log` |

## Copyright

© 2026 Marcel Ebbert — privates Reverse-Engineering, kein offizielles Borochi-Produkt.
