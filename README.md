# DEBIAN_KVM_ON-OFF

Kleine Flask-Webanwendung für Debian, um zwischen Docker/KVM und VirtualBox umzuschalten.

Zielplattform: Debian 13 mit Python 3.13 (oder neuer).

## Dateien

- `app.py`
- `templates/index.html`
- `static/style.css`
- `static/script.js`
- `requirements.txt`

## Download

Option A (empfohlen, per Git):

```bash
sudo apt update
sudo apt install git
git clone https://github.com/Artorius-Lex/DEBIAN_KVM_ON-OFF.git
cd DEBIAN_KVM_ON-OFF
```

Hinweis: Der korrekte Befehl ist `git clone …` (nicht `git ssh …`).
Option B (ZIP-Download):

1. Öffne die GitHub-Seite: https://github.com/Artorius-Lex/DEBIAN_KVM_ON-OFF
2. Klicke auf **Code** → **Download ZIP**
3. Entpacke die ZIP-Datei
4. Wechsle in den Ordner:

```bash
unzip DEBIAN_KVM_ON-OFF-main.zip
cd DEBIAN_KVM_ON-OFF-main
```

## Installation

Voraussetzungen (Debian/Ubuntu):

```bash
sudo apt update
sudo apt install python3-venv python3-pip
```

```bash
cd /pfad/zum/DEBIAN_KVM_ON-OFF
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt
```

Hinweis für Debian 13 (PEP 668): Systemweite `pip`-Installationen sind blockiert. Verwende immer eine virtuelle Umgebung (`python3 -m venv`).

Empfehlung: Installiere Abhängigkeiten immer in einer eigenen venv oder via Installer, niemals global via `pip`.

## Installer (Desktop-Icon)

Der Installer erstellt ein Desktop-Icon, zeigt vorab eine Zustimmung an (Zenity falls vorhanden, sonst Terminal) und kopiert die App nach `~/.local/share/debian-kvm-on-off`.

```bash
chmod +x install.sh
./install.sh
```

Hinweise:
- Der Installer erstellt eine eigene virtuelle Umgebung unter `~/.local/share/debian-kvm-on-off/.venv`.
- Fehlende Pakete (`python3-venv`, `python3-pip`) werden automatisch per `sudo apt` installiert.
- Das Skript sollte **nicht** in einer aktivierten `.venv` laufen.
- Das Desktop-Icon liegt unter `~/.local/share/applications/debian-kvm-on-off.desktop`.
- Das Icon wird nach `~/.local/share/icons/debian-kvm-on-off.svg` kopiert.

Deinstallieren:
```bash
rm -rf ~/.local/share/debian-kvm-on-off
rm -f ~/.local/share/applications/debian-kvm-on-off.desktop
rm -f ~/.local/share/icons/debian-kvm-on-off.svg
```

## Fehlerbehebung (Debian 13)

- `externally-managed-environment`: Nutze den Installer oder eine venv (kein `pip --user`).
- `ensurepip is not available`: Installiere `python3-venv` (der Installer erledigt das automatisch).

## Start

```bash
python3 app.py
```

Danach öffnet sich die Anwendung automatisch im lokalen Browser unter `http://127.0.0.1:5000`.

## Konsolenbefehle

Docker/KVM einschalten:

```bash
sudo modprobe -r vboxdrv vboxnetflt vboxnetadp && sudo modprobe kvm_amd && docker-desktop
```

Docker/KVM ausschalten (VirtualBox):

```bash
sudo modprobe -r kvm_amd kvm && sudo modprobe vboxdrv && virtualbox
```

## Hinweise

- Die Buttons führen `modprobe`, `docker-desktop` und `virtualbox` über das Flask-Backend per `subprocess` aus.
- Für `sudo`-Befehle sind passende Rechte erforderlich.
