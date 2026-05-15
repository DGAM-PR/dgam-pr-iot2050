#!/bin/bash

# Wrapper start script for kubesolo service
# Polls until required environment variables are set and internet is reachable,
# then launches kubesolo. Retries every 5 minutes if kubesolo exits for any reason.

ENV_FILE="/var/lib/kubesolo/config"
CONFIG_RETRY_SEC=60
CONNECTIVITY_CHECK_URL="https://registry-1.docker.io"
CONNECTIVITY_RETRY_SEC=30
KUBESOLO_RETRY_SEC=300

# --- Phase 1: Wait for config file and required variables ---
while true; do
    if [ ! -f "$ENV_FILE" ]; then
        echo "Configuration file $ENV_FILE does not exist, retrying in ${CONFIG_RETRY_SEC}s..."
        sleep "$CONFIG_RETRY_SEC"
        continue
    fi

    # Source the environment file fresh each iteration
    unset KUBESOLO_PORTAINER_EDGE_ID
    unset KUBESOLO_PORTAINER_EDGE_KEY
    unset KUBESOLO_LOCAL_STORAGE
    unset KUBESOLO_DB_WAL_REPAIR
    unset KUBESOLO_DISABLE_IPV6
    unset KUBESOLO_STARTUP_TIMEOUT
    source "$ENV_FILE"

    if [ -z "$KUBESOLO_PORTAINER_EDGE_ID" ]; then
        echo "ERROR: KUBESOLO_PORTAINER_EDGE_ID is not set in $ENV_FILE, retrying in ${CONFIG_RETRY_SEC}s..."
        sleep "$CONFIG_RETRY_SEC"
        continue
    fi

    if [ -z "$KUBESOLO_PORTAINER_EDGE_KEY" ]; then
        echo "ERROR: KUBESOLO_PORTAINER_EDGE_KEY is not set in $ENV_FILE, retrying in ${CONFIG_RETRY_SEC}s..."
        sleep "$CONFIG_RETRY_SEC"
        continue
    fi

    # Export all variables so they are inherited by the kubesolo process
    export KUBESOLO_PORTAINER_EDGE_ID
    export KUBESOLO_PORTAINER_EDGE_KEY
    # The following vars match the upstream defaults from flags.go; set them here
    # so the effective value is always visible in logs and the binary never relies
    # on its own compiled-in default silently.
    export KUBESOLO_LOCAL_STORAGE="${KUBESOLO_LOCAL_STORAGE:-false}"
    export KUBESOLO_DB_WAL_REPAIR="${KUBESOLO_DB_WAL_REPAIR:-false}"
    export KUBESOLO_DISABLE_IPV6="${KUBESOLO_DISABLE_IPV6:-false}"
    export KUBESOLO_STARTUP_TIMEOUT="${KUBESOLO_STARTUP_TIMEOUT:-600}"

    echo "Configuration validated successfully | edge-id: $KUBESOLO_PORTAINER_EDGE_ID | key: ${KUBESOLO_PORTAINER_EDGE_KEY:0:5}... | local-storage: $KUBESOLO_LOCAL_STORAGE | db-wal-repair: $KUBESOLO_DB_WAL_REPAIR | disable-ipv6: $KUBESOLO_DISABLE_IPV6 | startup-timeout: $KUBESOLO_STARTUP_TIMEOUT"
    break
done

# --- Phase 2: Wait for internet connectivity, then run kubesolo ---
# Retry every 5 minutes if kubesolo exits for any reason (including clean exit 0)
# This handles the case where the 4G modem is not yet ready when systemd starts the service upon cold start of modem + IOT2050 Device
while true; do
    # Wait for actual internet connectivity before attempting to pull images
    echo "Checking internet connectivity to $CONNECTIVITY_CHECK_URL..."
    until curl --silent --max-time 10 --head "$CONNECTIVITY_CHECK_URL" > /dev/null 2>&1; do
        echo "Internet not reachable yet, retrying in ${CONNECTIVITY_RETRY_SEC}s..."
        sleep "$CONNECTIVITY_RETRY_SEC"
    done
    echo "Internet connectivity confirmed, starting kubesolo..."

    /usr/bin/kubesolo \
        --portainer-edge-id "$KUBESOLO_PORTAINER_EDGE_ID" \
        --portainer-edge-key "$KUBESOLO_PORTAINER_EDGE_KEY"

    EXIT_CODE=$?
    echo "kubesolo exited with code $EXIT_CODE, retrying in ${KUBESOLO_RETRY_SEC}s..."
    sleep "$KUBESOLO_RETRY_SEC"
done
