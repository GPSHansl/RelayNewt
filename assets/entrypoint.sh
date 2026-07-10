#!/bin/bash
#
# relaynewt Postfix Relay
# Version 1.0
#

set -euo pipefail

CONFIG_DIR="/config"

echo "=== relaynewt Postfix Relay ==="
echo

#
# Required files (list-based validation)
#

REQUIRED_DIRS=(
    "${CONFIG_DIR}/identities"
)

echo "Checking configuration..."

for dir in "${REQUIRED_DIRS[@]}"; do
    [[ -d "$dir" ]] || {
        echo "ERROR: required directory missing: $dir"
        exit 1
    }
done

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

bash "/build_maps.sh"

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
