# DEBIAN_KVM_ON-OFF

Kleine Flask-Webanwendung für Debian, um zwischen Docker/KVM und VirtualBox umzuschalten.

## Dateien

- `app.py`
- `templates/index.html`
- `static/style.css`
- `static/script.js`
- `requirements.txt`

## Installation

```bash
cd /home/runner/work/DEBIAN_KVM_ON-OFF/DEBIAN_KVM_ON-OFF
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Alternativ nur Flask direkt installieren:

```bash
pip install Flask
```

## Installer (Desktop-Icon)

Der Installer erstellt ein Desktop-Icon, zeigt vorab eine Zustimmung an (Zenity falls vorhanden, sonst Terminal) und kopiert die App nach `~/.local/share/debian-kvm-on-off`.

```bash
chmod +x install.sh
./install.sh
```

Hinweise:
- Abhängigkeiten werden mit `pip --user` installiert.
- Das Desktop-Icon liegt unter `~/.local/share/applications/debian-kvm-on-off.desktop`.
- Das Icon wird nach `~/.local/share/icons/debian-kvm-on-off.svg` kopiert.

Deinstallieren:
```bash
rm -rf ~/.local/share/debian-kvm-on-off
rm -f ~/.local/share/applications/debian-kvm-on-off.desktop
rm -f ~/.local/share/icons/debian-kvm-on-off.svg
```

## Start

```bash
python3 app.py
```

Danach öffnet sich die Anwendung automatisch im lokalen Browser unter `http://127.0.0.1:5000`.

## Hinweise

- Die Buttons führen `modprobe`, `docker-desktop` und `virtualbox` über das Flask-Backend per `subprocess` aus.
- Für `sudo`-Befehle sind passende Rechte erforderlich.
