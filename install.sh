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

confirm_install() {
  local text="Diese Installation kopiert die App nach ${INSTALL_DIR}, erstellt ein Desktop-Icon und installiert Python-Abhängigkeiten mit pip --user.\n\nDie App nutzt sudo-Befehle (modprobe, docker-desktop, virtualbox). Möchtest du fortfahren?"
  if command -v zenity >/dev/null 2>&1; then
    zenity --question --title="${APP_NAME} Installation" --text="${text}"
    return $?
  fi

  echo -e "${text}"
  read -r -p "Installation fortsetzen? [j/N]: " reply
  [[ "${reply}" =~ ^([jJyY])$ ]]
}

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 wurde nicht gefunden. Bitte installiere Python 3."
  exit 1
fi

if ! python3 -m pip --version >/dev/null 2>&1; then
  echo "pip wurde nicht gefunden. Bitte installiere pip für Python 3."
  exit 1
fi

if [[ ! -f "${ICON_SOURCE}" ]]; then
  echo "Icon-Datei fehlt: ${ICON_SOURCE}"
  exit 1
fi

if ! confirm_install; then
  echo "Installation abgebrochen."
  exit 0
fi

rm -rf "${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}" "${DESKTOP_DIR}" "${ICON_DIR}"

cp -R "${SCRIPT_DIR}/app.py" "${SCRIPT_DIR}/templates" "${SCRIPT_DIR}/static" "${SCRIPT_DIR}/requirements.txt" "${INSTALL_DIR}/"

python3 -m pip install --user -r "${INSTALL_DIR}/requirements.txt"

cat > "${INSTALL_DIR}/run.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
python3 "${SCRIPT_DIR}/app.py"
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
  update-desktop-database "${DESKTOP_DIR}" >/dev/null 2>&1 || true
fi

if command -v zenity >/dev/null 2>&1; then
  zenity --info --title="${APP_NAME} Installation" --text="Installation abgeschlossen. Das Desktop-Icon ist nun verfügbar."
else
  echo "Installation abgeschlossen. Das Desktop-Icon ist nun verfügbar."
fi
