from flask import Flask, jsonify, render_template
import subprocess
import webbrowser
from threading import Timer

app = Flask(__name__)


def run_command(command, suppress_stderr=False):
    try:
        result = subprocess.run(
            command,
            text=True,
            capture_output=True,
        )
    except FileNotFoundError:
        return False, f"Befehl nicht gefunden: {command[0]}"

    if result.returncode != 0:
        stderr = "" if suppress_stderr else (result.stderr or "")
        message = stderr.strip()
        if not message:
            message = f"Befehl fehlgeschlagen: {' '.join(command)}"
        return False, message

    return True, (result.stdout or "").strip()


def launch_app(command):
    try:
        subprocess.Popen(
            command,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except FileNotFoundError:
        return False, f"Befehl nicht gefunden: {command[0]}"
    except Exception:
        return False, "Unerwarteter Fehler beim Starten der Anwendung."

    return True, ""


def detect_status():
    try:
        result = subprocess.run(
            ["lsmod"],
            check=True,
            text=True,
            capture_output=True,
        )
    except Exception:
        return "Status unbekannt"

    modules = {
        line.split()[0]
        for line in result.stdout.splitlines()
        if line and not line.startswith("Module")
    }

    if "vboxdrv" in modules:
        return "VirtualBox aktiv"
    if {"kvm_amd", "kvm_intel", "kvm"}.intersection(modules):
        return "Docker/KVM aktiv"
    return "Status unbekannt"


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/status")
def status():
    return jsonify({"status": detect_status()})


@app.route("/launch/docker", methods=["POST"])
def launch_docker():
    ok, message = run_command(
        ["sudo", "modprobe", "-r", "vboxdrv", "vboxnetflt", "vboxnetadp"],
        suppress_stderr=True,
    )
    if not ok:
        return jsonify(success=False, error=message, status=detect_status()), 400

    ok, message = run_command(["sudo", "modprobe", "kvm_amd"])
    if not ok:
        return jsonify(success=False, error=message, status=detect_status()), 400

    ok, message = launch_app(["docker-desktop"])
    if not ok:
        return jsonify(success=False, error=message, status=detect_status()), 400

    return jsonify(success=True, status=detect_status())


@app.route("/launch/virtualbox", methods=["POST"])
def launch_virtualbox():
    ok, message = run_command(
        ["sudo", "modprobe", "-r", "kvm_amd", "kvm"],
        suppress_stderr=True,
    )
    if not ok:
        return jsonify(success=False, error=message, status=detect_status()), 400

    ok, message = run_command(["sudo", "modprobe", "vboxdrv"])
    if not ok:
        return jsonify(success=False, error=message, status=detect_status()), 400

    ok, message = launch_app(["virtualbox"])
    if not ok:
        return jsonify(success=False, error=message, status=detect_status()), 400

    return jsonify(success=True, status=detect_status())


def open_browser():
    webbrowser.open("http://127.0.0.1:5000/", new=2)


if __name__ == "__main__":
    Timer(1, open_browser).start()
    app.run(host="127.0.0.1", port=5000, debug=False, use_reloader=False)
