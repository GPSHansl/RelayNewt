#!/bin/bash
#
# relaynewt Postfix Relay
# Version 1.0
#

set -euo pipefail

CONFIG_DIR="/config"
POSTFIX_DIR="/etc/postfix"

echo "=== relaynewt Postfix Relay ==="
echo

#
# Required files (list-based validation)
#

REQUIRED_FILES=(
    "${CONFIG_DIR}/main.cf"
    "${CONFIG_DIR}/master.cf"
    "${CONFIG_DIR}/build_maps.sh"
)

REQUIRED_DIRS=(
    "${CONFIG_DIR}/identities"
)

echo "Checking configuration..."

for file in "${REQUIRED_FILES[@]}"; do
    [[ -f "$file" ]] || {
        echo "ERROR: required file missing: $file"
        exit 1
    }
done

for dir in "${REQUIRED_DIRS[@]}"; do
    [[ -d "$dir" ]] || {
        echo "ERROR: required directory missing: $dir"
        exit 1
    }
done

#
# Install configuration
#

echo "Installing configuration..."

cp "${CONFIG_DIR}/main.cf" "${POSTFIX_DIR}/main.cf"
cp "${CONFIG_DIR}/master.cf" "${POSTFIX_DIR}/master.cf"

chmod 644 "${POSTFIX_DIR}/main.cf"
chmod 644 "${POSTFIX_DIR}/master.cf"

#
# Prepare Postfix chroot environment
#

mkdir -p /var/spool/postfix/etc

POSTFIX_CHROOT_FILES=(
    /etc/resolv.conf
    /etc/hosts
    /etc/services
)

for file in "${POSTFIX_CHROOT_FILES[@]}"
do
    [[ -f "$file" ]] || continue
    cp -f "$file" "/var/spool/postfix${file}"
done

#
# Generate lookup tables
#

echo "Generating lookup tables..."

bash "${CONFIG_DIR}/build_maps.sh"

#
# Ensure Postfix runtime environment is valid
#

postfix set-permissions >/dev/null 2>&1 || true

#
# Validate configuration
#

echo "Running postfix check..."

if ! postfix check; then
    echo "ERROR: Postfix configuration invalid."
    exit 1
fi

echo
echo "Configuration OK."
echo

#
# Start Postfix in foreground (Docker-safe)
#

exec /usr/sbin/postfix start-fg
