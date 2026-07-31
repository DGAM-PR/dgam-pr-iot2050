#!/usr/bin/env bash
# ci-cleanup.sh
#
# Runs after every build job (success OR failure) via `if: always()`.
# - Removes stopped Docker containers and dangling images (not named volumes —
#   those hold the BitBake sstate/download caches and must survive between runs)
# - Wipes the ISAR build output directory so / doesn't fill up.
#
# ponytail: named volumes (isar-sstate-cache, isar-downloads) are intentionally
# preserved to speed up incremental builds. Run `docker volume rm isar-sstate-cache
# isar-downloads` manually if you need a completely clean build.

set -euo pipefail

echo "=== Docker cleanup (stopped containers + dangling images) ==="
docker container prune --force
docker image prune --force
# Do NOT prune volumes — sstate/download caches live there.

echo "=== Wiping ISAR build output ==="
# The 'build/' directory is created by kas inside the workspace.
# It can be several GB; remove it to free space on /.
if [ -d "build" ]; then
  # ponytail: ISAR sbuild creates root-owned files inside chroot rootfs dirs.
  # The runner user cannot delete them directly; delegate to a throw-away
  # Docker container (runs as root) which has the necessary privilege.
  # Ceiling: requires Docker to be available on the runner (it always is here).
  docker run --rm \
    -v "$(pwd)/build:/mnt/build" \
    --entrypoint "" \
    debian:stable-slim \
    sh -c "rm -rf /mnt/build/*"
  rm -rf build/   # safe now — directory is runner-owned, contents are gone
  echo "Removed build/"
else
  echo "No build/ directory found — nothing to remove."
fi

echo "=== Cleanup complete ==="
