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
    # Default KUBESOLO_LOCAL_STORAGE to false if not explicitly set in config
    # The binary reads this env var directly and supports --[no-]local-storage flags
    export KUBESOLO_LOCAL_STORAGE="${KUBESOLO_LOCAL_STORAGE:-false}"

    # Translate KUBESOLO_LOCAL_STORAGE env var to the correct CLI flag
    if [ "$KUBESOLO_LOCAL_STORAGE" = "true" ]; then
        LOCAL_STORAGE_FLAG="--local-storage"
    else
        LOCAL_STORAGE_FLAG="--no-local-storage"
    fi

    echo "Configuration validated successfully | edge-id: $KUBESOLO_PORTAINER_EDGE_ID | key: ${KUBESOLO_PORTAINER_EDGE_KEY:0:5}... | local-storage: $LOCAL_STORAGE_FLAG"
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
        --portainer-edge-key "$KUBESOLO_PORTAINER_EDGE_KEY" \
        "$LOCAL_STORAGE_FLAG"

    EXIT_CODE=$?
    echo "kubesolo exited with code $EXIT_CODE, retrying in ${KUBESOLO_RETRY_SEC}s..."
    sleep "$KUBESOLO_RETRY_SEC"
done
