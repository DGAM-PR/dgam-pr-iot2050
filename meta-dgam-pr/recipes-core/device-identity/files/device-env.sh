#!/bin/sh
# /etc/profile.d/device-env.sh
#
# Sources /var/lib/device-identity/env for every interactive login shell.
# set -a / set +a causes all variables defined in the sourced file to be
# automatically exported — no hardcoded export list needed. Any KEY=VALUE
# line added to the env file is picked up on the next login without any
# changes to this script.

ENV_FILE="/var/lib/device-identity/env"

if [ -f "$ENV_FILE" ]; then
    set -a
    # shellcheck source=/dev/null
    . "$ENV_FILE"
    set +a
fi
