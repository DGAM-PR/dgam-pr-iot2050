#!/usr/bin/env bash
# ci-copy-artifacts.sh
#
# Copies build artifacts (.wic.xz, .swu) from the ISAR output directory to
# /data/artifacts/<branch-slug>/<run-number>-<target>/ and prunes old builds,
# keeping only the last $KEEP successful builds per branch+target combo.
#
# Called by the GitHub Actions workflow with these env vars set:
#   BRANCH      - git branch name (e.g. stable/v01.06-locked)
#   RUN_NUMBER  - GitHub Actions run number (monotonically increasing)
#   TARGET      - build target (plc-facing or vpn-facing)
#   KEEP        - number of builds to retain (default: 3)
#
# ponytail: retention is O(n) over build count per target; n stays tiny (<100).

set -euo pipefail

KEEP="${KEEP:-3}"
ARTIFACTS_ROOT="/data/artifacts"

# Sanitise branch name for use as a directory name (replace / with -)
BRANCH_SLUG="${BRANCH//\//-}"

DEST_DIR="${ARTIFACTS_ROOT}/${BRANCH_SLUG}/${RUN_NUMBER}-${TARGET}"
mkdir -p "$DEST_DIR"

# ISAR/kas puts images in build/tmp/deploy/images/<machine>/
# The machine name for IOT2050 is iot2050-advanced (or iot2050-advanced-sm).
# We grab every .wic.xz and .swu we find — covers both machine variants.
DEPLOY_DIR="build/tmp/deploy/images"

if [ ! -d "$DEPLOY_DIR" ]; then
  echo "::error::Deploy directory not found: $DEPLOY_DIR"
  exit 1
fi

found=0
while IFS= read -r -d '' f; do
  name="$(basename "$f")"
  # Skip ebg SWU files (bootloader update packages, not needed)
  [[ "$name" == *-ebg.swu ]] && continue
  cp "$f" "$DEST_DIR/"
  echo "Copied: $name → $DEST_DIR/"
  (( found++ )) || true
done < <(find "$DEPLOY_DIR" \( -name "*.wic" -o -name "*.swu" \) -print0)

if [ "$found" -eq 0 ]; then
  echo "::warning::No .wic.xz or .swu files found in $DEPLOY_DIR — nothing copied."
  rmdir "$DEST_DIR" 2>/dev/null || true
  exit 0
fi

echo "Copied $found artifact(s) to $DEST_DIR"

# ── Retention: keep last $KEEP builds per branch+target ──────────────────────
# Build dirs are named "<run-number>-<target>"; sort numerically by run-number.
PARENT="${ARTIFACTS_ROOT}/${BRANCH_SLUG}"

# List dirs matching *-<TARGET>, extract run numbers, sort, drop all but last N
mapfile -t OLD_BUILDS < <(
  find "$PARENT" -maxdepth 1 -type d -name "*-${TARGET}" \
  | awk -F'/' '{print $NF}' \
  | sort -t'-' -k1 -n \
  | head -n "-${KEEP}"   # everything except the last $KEEP entries
)

if [ "${#OLD_BUILDS[@]}" -gt 0 ]; then
  for dir in "${OLD_BUILDS[@]}"; do
    TARGET_PATH="${PARENT}/${dir}"
    echo "Pruning old build: $TARGET_PATH"
    rm -rf "$TARGET_PATH"
  done
fi

echo "Retention: kept last ${KEEP} builds for ${BRANCH_SLUG}/${TARGET}"
