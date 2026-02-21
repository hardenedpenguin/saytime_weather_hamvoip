#!/bin/sh
# POSIX-compliant install script for saytime_weather_hamvoip
# Fetches saytime.rb, weather.rb, weather.ini.default from GitHub and installs
# to /usr/sbin (scripts) and /etc/asterisk/local (config). Replaces existing
# weather.ini with a fresh default (old one backed up as weather.ini.bak).

set -e

BASE_URL="https://raw.githubusercontent.com/hardenedpenguin/saytime_weather_hamvoip/main"
SBIN_DIR="/usr/sbin"
CONFIG_DIR="/etc/asterisk/local"
CONFIG_FILE="/etc/asterisk/local/weather.ini"

# Require root
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: This script must be run as root (e.g. sudo)." >&2
  exit 1
fi

# Detect fetch command (curl preferred, then wget)
fetch_file() {
  _url="$1"
  _dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -sL -o "${_dest}" "${_url}"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "${_dest}" "${_url}"
  else
    echo "Error: Need curl or wget to fetch files." >&2
    exit 1
  fi
}

# Create temp dir for downloads
TMPDIR="${TMPDIR:-/tmp}"
INSTALL_TMP="${TMPDIR}/saytime_weather_hamvoip_install.$$"
mkdir -p "${INSTALL_TMP}"
trap 'rm -rf "${INSTALL_TMP}"' EXIT

echo "Fetching saytime.rb..."
fetch_file "${BASE_URL}/saytime.rb" "${INSTALL_TMP}/saytime.rb"
echo "Fetching weather.rb..."
fetch_file "${BASE_URL}/weather.rb" "${INSTALL_TMP}/weather.rb"
echo "Fetching weather.ini.default..."
fetch_file "${BASE_URL}/weather.ini.default" "${INSTALL_TMP}/weather.ini.default"

# Install scripts to /usr/sbin
install -m 755 "${INSTALL_TMP}/saytime.rb" "${SBIN_DIR}/saytime.rb"
install -m 755 "${INSTALL_TMP}/weather.rb" "${SBIN_DIR}/weather.rb"
chown root:root "${SBIN_DIR}/saytime.rb" "${SBIN_DIR}/weather.rb"
echo "Installed ${SBIN_DIR}/saytime.rb and ${SBIN_DIR}/weather.rb (root:root, 755)."

# Config: backup existing weather.ini and install fresh default
mkdir -p "${CONFIG_DIR}"
if [ -f "${CONFIG_FILE}" ]; then
  mv "${CONFIG_FILE}" "${CONFIG_FILE}.bak"
  echo "Backed up existing config to ${CONFIG_FILE}.bak"
fi
install -m 644 "${INSTALL_TMP}/weather.ini.default" "${CONFIG_FILE}"
chown root:root "${CONFIG_FILE}"
echo "Installed default config: ${CONFIG_FILE}"

echo ""
echo "Install complete."
echo "  Scripts: ${SBIN_DIR}/saytime.rb, ${SBIN_DIR}/weather.rb"
echo "  Config:  ${CONFIG_FILE}"
echo "  Edit ${CONFIG_FILE} to change temperature mode, location, etc."
echo ""
echo "Usage:"
echo "  ${SBIN_DIR}/weather.rb <location> [v]"
echo "  ${SBIN_DIR}/saytime.rb -l <location> -n <node_number>"
