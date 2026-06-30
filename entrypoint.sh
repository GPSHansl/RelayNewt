#!/bin/bash
#
# Postfix Relay
# Version 1.0
#

set -euo pipefail

CONFIG_DIR="/config"
POSTFIX_DIR="/etc/postfix"

echo "=== Postfix Relay ==="
echo

#
# Check configuration
#

[[ -f "${CONFIG_DIR}/main.cf" ]] || {
    echo "ERROR: ${CONFIG_DIR}/main.cf not found."
    exit 1
}

[[ -f "${CONFIG_DIR}/build_maps.sh" ]] || {
    echo "ERROR: ${CONFIG_DIR}/build_maps.sh not found."
    exit 1
}

[[ -d "${CONFIG_DIR}/identities" ]] || {
    echo "ERROR: ${CONFIG_DIR}/identities not found."
    exit 1
}

[[ -d "${CONFIG_DIR}/secrets" ]] || {
    echo "ERROR: ${CONFIG_DIR}/secrets not found."
    exit 1
}

#
# Install configuration
#

echo "Installing configuration..."

cp "${CONFIG_DIR}/main.cf" "${POSTFIX_DIR}/main.cf"

chmod 644 "${POSTFIX_DIR}/main.cf"

#
# Generate lookup tables
#

echo "Generating lookup tables..."

bash "${CONFIG_DIR}/build_maps.sh"

#
# Validate configuration
#

echo "Running postfix check..."

postfix check

echo
echo "Configuration OK."
echo

#
# Start Postfix
#

exec postfix start-fg