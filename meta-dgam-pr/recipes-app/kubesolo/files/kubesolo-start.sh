#!/bin/bash

# Wrapper start script for kubesolo service
# Polls until required environment variables are set, then launches kubesolo

ENV_FILE="/var/lib/kubesolo/config"

while true; do
    if [ ! -f "$ENV_FILE" ]; then
        echo "Configuration file $ENV_FILE does not exist, retrying in 60s..."
        sleep 60
        continue
    fi

    # Source the environment file fresh each iteration
    unset KUBESOLO_PORTAINER_EDGE_ID
    unset KUBESOLO_PORTAINER_EDGE_KEY
    unset KUBESOLO_LOCAL_STORAGE
    source "$ENV_FILE"

    if [ -z "$KUBESOLO_PORTAINER_EDGE_ID" ]; then
        echo "ERROR: KUBESOLO_PORTAINER_EDGE_ID is not set in $ENV_FILE, retrying in 60s..."
        sleep 60
        continue
    fi

    if [ -z "$KUBESOLO_PORTAINER_EDGE_KEY" ]; then
        echo "ERROR: KUBESOLO_PORTAINER_EDGE_KEY is not set in $ENV_FILE, retrying in 60s..."
        sleep 60
        continue
    fi

    # Export all variables so they are inherited by the exec'd kubesolo process
    export KUBESOLO_PORTAINER_EDGE_ID
    export KUBESOLO_PORTAINER_EDGE_KEY
    # Default KUBESOLO_LOCAL_STORAGE to false if not explicitly set in config.
    # The binary reads this env var directly and supports --[no-]local-storage flags.
    export KUBESOLO_LOCAL_STORAGE="${KUBESOLO_LOCAL_STORAGE:-false}"

    # Translate KUBESOLO_LOCAL_STORAGE env var to the correct CLI flag
    if [ "$KUBESOLO_LOCAL_STORAGE" = "true" ]; then
        LOCAL_STORAGE_FLAG="--local-storage"
    else
        LOCAL_STORAGE_FLAG="--no-local-storage"
    fi

    echo "Configuration validated successfully | edge-id: $KUBESOLO_PORTAINER_EDGE_ID | key: ${KUBESOLO_PORTAINER_EDGE_KEY:0:5}... | local-storage: $LOCAL_STORAGE_FLAG | starting kubesolo..."
    break
done

exec /usr/bin/kubesolo \
    --portainer-edge-id "$KUBESOLO_PORTAINER_EDGE_ID" \
    --portainer-edge-key "$KUBESOLO_PORTAINER_EDGE_KEY" \
    "$LOCAL_STORAGE_FLAG"
