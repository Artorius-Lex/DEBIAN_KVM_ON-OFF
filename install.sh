#!/usr/bin/env bash
set -euo pipefail

APP_NAME="KVM / VirtualBox Umschalter"
APP_ID="debian-kvm-on-off"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${HOME}/.local/share/${APP_ID}"
DESKTOP_DIR="${HOME}/.local/share/applications"
ICON_DIR="${HOME}/.local/share/icons"
ICON_SOURCE="${SCRIPT_DIR}/assets/icon.svg"
ICON_TARGET="${ICON_DIR}/${APP_ID}.svg"
DESKTOP_FILE="${DESKTOP_DIR}/${APP_ID}.desktop"
VENV_DIR="${INSTALL_DIR}/.venv"

on_error() {
  local line="$1"
  local command="$2"
  echo "Fehler: Befehl fehlgeschlagen (Zeile ${line}): ${command}" >&2
}

info() {
  echo -e "$*"
}

warn() {
  echo "Warnung: $*" >&2
}

die() {
  echo "Fehler: $*" >&2
  exit 1
}

trap 'on_error $LINENO "$BASH_COMMAND"' ERR

confirm_install() {
  local text="Diese Installation kopiert die App nach ${INSTALL_DIR}, richtet eine eigene virtuelle Umgebung ein und erstellt ein Desktop-Icon.\n\nFehlende Pakete (python3-venv, python3-pip) werden bei Bedarf per sudo apt installiert.\n\nDie App nutzt sudo-Befehle (modprobe, docker-desktop, virtualbox). Möchtest du fortfahren?"
  if command -v zenity >/dev/null 2>&1; then
    zenity --question --title="${APP_NAME} Installation" --text="${text}"
    return $?
  fi

  echo -e "${text}"
  read -r -p "Installation fortsetzen? [j/N]: " reply
  [[ "${reply}" =~ ^([jJyY])$ ]]
}

detect_debian() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ "${ID:-}" == "debian" ]]; then
      info "Debian erkannt (Version ${VERSION_ID:-unbekannt})."
      return 0
    fi
    warn "Dieses System ist kein Debian (${ID:-unbekannt})."
    return 1
  fi
  warn "/etc/os-release nicht gefunden. Debian-Version kann nicht erkannt werden."
  return 1
}

ensure_packages() {
  local missing=()
  if command -v dpkg >/dev/null 2>&1; then
    for pkg in python3-venv python3-pip; do
      dpkg -s "${pkg}" >/dev/null 2>&1 || missing+=("${pkg}")
    done
  else
    warn "dpkg nicht gefunden; Paketprüfung übersprungen."
    return 0
  fi

  if ((${#missing[@]})); then
    if ! command -v sudo >/dev/null 2>&1 || ! command -v apt >/dev/null 2>&1; then
      die "Fehlende Pakete: ${missing[*]}. Bitte installiere sie manuell."
    fi
    info "Installiere fehlende Pakete: ${missing[*]}"
    sudo apt update
    sudo apt install -y "${missing[@]}"
  fi
}

check_python_version() {
  if ! python3 - <<'PY'
import sys
if sys.version_info < (3, 10):
    raise SystemExit(1)
PY
  then
    die "Python 3.10 oder neuer ist erforderlich. Bitte aktualisiere Python."
  fi
  info "Python-Version: $(python3 - <<'PY'
import sys
print(f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")
PY
)"
}

check_pip() {
  if ! python3 -m pip --version >/dev/null 2>&1; then
    die "pip wurde nicht gefunden. Bitte installiere python3-pip."
  fi
  info "pip-Version: $(python3 -m pip --version | awk '{print $2}')"
}

validate_desktop_file() {
  if [[ ! -f "${DESKTOP_FILE}" ]]; then
    die "Desktop-Datei wurde nicht erstellt: ${DESKTOP_FILE}"
  fi
  if [[ ! -x "${DESKTOP_FILE}" ]]; then
    die "Desktop-Datei ist nicht ausführbar: ${DESKTOP_FILE}"
  fi
  grep -q "^Exec=${INSTALL_DIR}/run.sh$" "${DESKTOP_FILE}" || die "Exec-Pfad in Desktop-Datei stimmt nicht."
  grep -q "^Icon=${ICON_TARGET}$" "${DESKTOP_FILE}" || die "Icon-Pfad in Desktop-Datei stimmt nicht."
  if command -v desktop-file-validate >/dev/null 2>&1; then
    desktop-file-validate "${DESKTOP_FILE}"
  else
    warn "desktop-file-validate nicht verfügbar (Paket desktop-file-utils)."
  fi
}

if [[ -n "${VIRTUAL_ENV:-}" ]]; then
  warn "Eine virtuelle Umgebung ist aktiv (${VIRTUAL_ENV}). Bitte 'deactivate' ausführen und erneut starten."
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  die "python3 wurde nicht gefunden. Bitte installiere Python 3."
fi

detect_debian || true
ensure_packages
check_python_version
check_pip

if [[ ! -f "${ICON_SOURCE}" ]]; then
  die "Icon-Datei fehlt: ${ICON_SOURCE}"
fi

if ! confirm_install; then
  info "Installation abgebrochen."
  exit 0
fi

rm -rf "${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}" "${DESKTOP_DIR}" "${ICON_DIR}"

cp -R "${SCRIPT_DIR}/app.py" "${SCRIPT_DIR}/templates" "${SCRIPT_DIR}/static" "${SCRIPT_DIR}/requirements.txt" "${INSTALL_DIR}/"

info "Erstelle virtuelle Umgebung in ${VENV_DIR}"
if ! python3 -m venv "${VENV_DIR}"; then
  die "Virtuelle Umgebung konnte nicht erstellt werden. Prüfe python3-venv/ensurepip."
fi

info "Installiere Python-Abhängigkeiten"
if ! "${VENV_DIR}/bin/python" -m pip install --upgrade pip; then
  warn "pip-Update fehlgeschlagen, fahre mit vorhandener Version fort."
fi
"${VENV_DIR}/bin/python" -m pip install -r "${INSTALL_DIR}/requirements.txt"

cat > "${INSTALL_DIR}/run.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${SCRIPT_DIR}/.venv"
if [[ ! -x "${VENV_DIR}/bin/python" ]]; then
  echo "Fehler: Virtuelle Umgebung fehlt. Bitte install.sh erneut ausführen." >&2
  exit 1
fi
exec "${VENV_DIR}/bin/python" "${SCRIPT_DIR}/app.py"
EOF
chmod +x "${INSTALL_DIR}/run.sh"

cp "${ICON_SOURCE}" "${ICON_TARGET}"

cat > "${DESKTOP_FILE}" <<EOF
[Desktop Entry]
Type=Application
Name=${APP_NAME}
Comment=Umschalten zwischen Docker/KVM und VirtualBox
Exec=${INSTALL_DIR}/run.sh
Icon=${ICON_TARGET}
Terminal=false
Categories=Utility;System;
StartupNotify=true
EOF
chmod +x "${DESKTOP_FILE}"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "${DESKTOP_DIR}" >/dev/null 2>&1 || warn "update-desktop-database ist fehlgeschlagen."
else
  warn "update-desktop-database nicht verfügbar (Paket desktop-file-utils)."
fi

validate_desktop_file

info "Testlauf: Import der Anwendung"
(cd "${INSTALL_DIR}" && PYTHONPATH="${INSTALL_DIR}" "${VENV_DIR}/bin/python" - <<'PY'
import flask  # noqa: F401
import app  # noqa: F401
print("OK")
PY
)

if command -v zenity >/dev/null 2>&1; then
  zenity --info --title="${APP_NAME} Installation" --text="Installation abgeschlossen. Das Desktop-Icon ist nun verfügbar."
else
  info "Installation abgeschlossen. Das Desktop-Icon ist nun verfügbar."
fi
