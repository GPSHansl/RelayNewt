#!/bin/bash
#
# Postfix Relay
# Version 1.0
#

set -euo pipefail

CONFIG_DIR="/config"
POSTFIX_DIR="/etc/postfix"

IDENTITIES_DIR="${CONFIG_DIR}/identities"

SENDER_RELAY="${POSTFIX_DIR}/sender_relay"
SENDER_ACCESS="${POSTFIX_DIR}/sender_access"
SASL_PASSWD="${POSTFIX_DIR}/sasl_passwd"

#
# Start with empty files
#

> "${SENDER_RELAY}"
> "${SENDER_ACCESS}"
> "${SASL_PASSWD}"

#
# Detect duplicate sender definitions
#

declare -A SEEN_SENDERS

#
# Process all identity files
#

for file in "${IDENTITIES_DIR}"/*.conf
do

    FROM=""
    RELAY=""
    PORT=""
    USERNAME=""
    PASSWORD_FILE=""

    while IFS='=' read -r key value
    do

        key="$(echo "$key" | xargs)"
        value="$(echo "$value" | xargs)"

        [[ -z "$key" ]] && continue
        [[ "$key" =~ ^# ]] && continue

        case "$key" in

            FROM)
                FROM="$value"
                ;;

            RELAY)
                RELAY="$value"
                ;;

            PORT)
                PORT="$value"
                ;;

            USERNAME)
                USERNAME="$value"
                ;;

            PASSWORD_FILE)
                PASSWORD_FILE="$value"
                ;;

        esac

    done < "$file"

    #
    # Validate configuration
    #

    [[ -n "$FROM" ]] || { echo "Missing FROM in $file"; exit 1; }
    [[ -n "$RELAY" ]] || { echo "Missing RELAY in $file"; exit 1; }
    [[ -n "$PORT" ]] || { echo "Missing PORT in $file"; exit 1; }
    [[ -n "$USERNAME" ]] || { echo "Missing USERNAME in $file"; exit 1; }
    [[ -n "$PASSWORD_FILE" ]] || { echo "Missing PASSWORD_FILE in $file"; exit 1; }

    [[ -f "$PASSWORD_FILE" ]] || {
        echo "Password file not found: $PASSWORD_FILE"
        exit 1
    }

    PASSWORD="$(<"$PASSWORD_FILE")"

    #
    # One SASL entry per relay
    #

    RELAY_KEY="[${RELAY}]:${PORT}"

    if ! grep -qF "${RELAY_KEY}" "${SASL_PASSWD}" 2>/dev/null
    then
        echo "${RELAY_KEY} ${USERNAME}:${PASSWORD}" \
            >> "${SASL_PASSWD}"
    fi

    #
    # Process sender list
    #

    IFS=',' read -ra SENDERS <<< "$FROM"

    for sender in "${SENDERS[@]}"
    do

        sender="$(echo "$sender" | xargs)"

        #
        # Duplicate detection
        #

        if [[ -n "${SEEN_SENDERS[$sender]:-}" ]]
        then
            echo
            echo "Duplicate sender detected:"
            echo "  $sender"
            echo
            exit 1
        fi

        SEEN_SENDERS["$sender"]=1

        #
        # Allow sender
        #

        echo "${sender} OK" \
            >> "${SENDER_ACCESS}"

        #
        # Route sender
        #

        echo "${sender} ${RELAY_KEY}" \
            >> "${SENDER_RELAY}"

    done

done

#
# Build lookup databases
#

postmap "${SENDER_RELAY}"
postmap "${SENDER_ACCESS}"
postmap "${SASL_PASSWD}"

chmod 600 "${SASL_PASSWD}"
chmod 600 "${SASL_PASSWD}.db"

echo
echo "Generated:"
echo "  sender_relay"
echo "  sender_access"
echo "  sasl_passwd"
echo