# DEBIAN_KVM_ON-OFF

Kleine Flask-Webanwendung für Debian, um zwischen Docker/KVM und VirtualBox umzuschalten. Die App lädt die passenden Kernel-Module und startet Docker Desktop bzw. VirtualBox.

## Funktionen

- Statusanzeige (erkennt geladene KVM- oder VirtualBox-Module)
- „Docker Desktop starten“: entfernt VirtualBox-Module, lädt KVM und startet `docker-desktop`
- „VirtualBox starten“: entfernt KVM-Module, lädt `vboxdrv` und startet `virtualbox`
- Öffnet die UI automatisch im lokalen Browser unter `http://127.0.0.1:5000`

## Voraussetzungen

- Debian mit Python 3 und `pip`
- Docker Desktop (`docker-desktop` im PATH)
- VirtualBox (`virtualbox` im PATH)
- `sudo`-Rechte für `modprobe`
- **AMD-CPU**: es wird `kvm_amd` geladen. Für Intel-Systeme bitte `kvm_intel` in `app.py` anpassen.
- Optional: `zenity` (grafische Installer-Abfrage), `update-desktop-database`

## Dateien

- `app.py`
- `templates/index.html`
- `static/style.css`
- `static/script.js`
- `requirements.txt`
- `install.sh`
- `assets/icon.svg`

## Installation (lokal)

```bash
cd /pfad/zum/DEBIAN_KVM_ON-OFF
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Start

```bash
python3 app.py
```

Danach öffnet sich die Anwendung automatisch im lokalen Browser unter `http://127.0.0.1:5000`.

## Installer (Desktop-Icon)

Der Installer erstellt ein Desktop-Icon, zeigt vorab eine Zustimmung an (Zenity falls vorhanden, sonst Terminal) und kopiert die App nach `~/.local/share/debian-kvm-on-off`.

```bash
chmod +x install.sh
./install.sh
```

Hinweise:
- Abhängigkeiten werden mit `pip --user` installiert.
- Startskript: `~/.local/share/debian-kvm-on-off/run.sh`
- Desktop-Icon: `~/.local/share/applications/debian-kvm-on-off.desktop`
- Icon-Datei: `~/.local/share/icons/debian-kvm-on-off.svg`

Deinstallieren:
```bash
rm -rf ~/.local/share/debian-kvm-on-off
rm -f ~/.local/share/applications/debian-kvm-on-off.desktop
rm -f ~/.local/share/icons/debian-kvm-on-off.svg
```

## Hinweise

- Die Buttons führen `modprobe`, `docker-desktop` und `virtualbox` über das Flask-Backend per `subprocess` aus.
- Für `sudo`-Befehle sind passende Rechte erforderlich.
- Die Anwendung läuft lokal auf `127.0.0.1:5000` und ist nicht für den externen Zugriff gedacht.
