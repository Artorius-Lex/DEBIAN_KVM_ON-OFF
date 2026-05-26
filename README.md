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

## Start

```bash
python3 app.py
```

Danach öffnet sich die Anwendung automatisch im lokalen Browser unter `http://127.0.0.1:5000`.

## Hinweise

- Die Buttons führen `modprobe`, `docker-desktop` und `virtualbox` über das Flask-Backend per `subprocess` aus.
- Für `sudo`-Befehle sind passende Rechte erforderlich.
