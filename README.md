# DEBIAN_KVM_ON-OFF

Kleine Flask-Anwendung zum Umschalten zwischen Docker Desktop (KVM) und VirtualBox
auf Debian Linux.

## Voraussetzungen

- Debian Linux
- Python 3 + pip
- sudo-Rechte für `modprobe`
- Installiertes Docker Desktop und VirtualBox

## Flask installieren

```bash
pip install Flask
```

## Installation

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Anwendung starten

```bash
python app.py
```

Nach dem Start öffnet sich automatisch `http://127.0.0.1:5000/` im Browser.