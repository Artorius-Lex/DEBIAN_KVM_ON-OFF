from __future__ import annotations

import os
import subprocess
import threading
import webbrowser
from typing import List, Tuple

from flask import Flask, jsonify, render_template

app = Flask(__name__)


def run_command(command: List[str], *, suppress_stderr: bool = False) -> Tuple[bool, str]:
    try:
        result = subprocess.run(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL if suppress_stderr else subprocess.PIPE,
            text=True,
            check=False,
        )
    except Exception:  # defensive fallback
        return False, "Interner Fehler beim Ausführen des Befehls."

    stdout = (result.stdout or "").strip()
    stderr = (result.stderr or "").strip()
    combined = "\n".join(part for part in [stdout, stderr] if part).strip()
    return result.returncode == 0, combined


def detect_mode() -> str:
    try:
        lsmod = subprocess.run(["lsmod"], capture_output=True, text=True, check=False)
        output = lsmod.stdout
    except Exception:
        return "Unbekannt"

    if "vboxdrv" in output:
        return "VirtualBox aktiv"
    if "kvm_amd" in output or "kvm " in output:
        return "Docker/KVM aktiv"
    return "Unbekannt"


@app.route("/")
def index() -> str:
    return render_template("index.html")


@app.post("/api/start/docker")
def start_docker():
    commands = [
        (["sudo", "modprobe", "-r", "vboxdrv", "vboxnetflt", "vboxnetadp"], True, True),
        (["sudo", "modprobe", "kvm_amd"], False, False),
        (["docker-desktop"], False, False),
    ]

    logs = []
    for command, ignore_error, suppress_stderr in commands:
        success, output = run_command(command, suppress_stderr=suppress_stderr)
        if output:
            logs.append(output)
        if not success and not ignore_error:
            return (
                jsonify({
                    "ok": False,
                    "status": detect_mode(),
                    "message": f"Befehl fehlgeschlagen: {' '.join(command)}",
                    "details": "\n".join(logs),
                }),
                500,
            )

    return jsonify({"ok": True, "status": "Docker/KVM aktiv", "message": "Docker Desktop gestartet."})


@app.post("/api/start/virtualbox")
def start_virtualbox():
    commands = [
        (["sudo", "modprobe", "-r", "kvm_amd", "kvm"], True, True),
        (["sudo", "modprobe", "vboxdrv"], False, False),
        (["virtualbox"], False, False),
    ]

    logs = []
    for command, ignore_error, suppress_stderr in commands:
        success, output = run_command(command, suppress_stderr=suppress_stderr)
        if output:
            logs.append(output)
        if not success and not ignore_error:
            return (
                jsonify({
                    "ok": False,
                    "status": detect_mode(),
                    "message": f"Befehl fehlgeschlagen: {' '.join(command)}",
                    "details": "\n".join(logs),
                }),
                500,
            )

    return jsonify({"ok": True, "status": "VirtualBox aktiv", "message": "VirtualBox gestartet."})


@app.get("/api/status")
def status():
    return jsonify({"status": detect_mode()})


def open_browser() -> None:
    webbrowser.open("http://127.0.0.1:5000")


if __name__ == "__main__":
    if not os.environ.get("WERKZEUG_RUN_MAIN"):
        threading.Timer(1.0, open_browser).start()
    app.run(host="127.0.0.1", port=5000, debug=False)
