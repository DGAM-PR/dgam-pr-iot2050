# Build Locking

Reproducible builds require two separate locks: one for git layers, one for apt packages.

## 1. Git Layer Lock

Pins `meta-iot2050` to an exact commit instead of floating on `branch: master`.

```bash
# After a successful build, get the SHA that was checked out
git -C meta-iot2050 rev-parse HEAD
```

## 2. APT Snapshot Lock

Pins all Debian packages via [snapshot.debian.org](https://snapshot.debian.org) to a specific point in time.

```bash
# Get current Unix timestamp just before your build
date +%s
```

## Lock File

Create `kas/opt/package-lock.yml` combining both:

```yaml
header:
  version: 14

repos:
  meta-iot2050:
    commit: <SHA from git -C meta-iot2050 rev-parse HEAD>

local_conf_header:
  package-lock: |
    # YYYY-MM-DD HH:MM:SS UTC
    ISAR_APT_SNAPSHOT_TIMESTAMP = "<unix timestamp from date +%s>"
    ISAR_USE_APT_SNAPSHOT = "1"
```

## Usage

Chain the lock file onto your build command:

```bash
./kas-container build kas/plc-facing-dgam-pr.yml:kas/opt/package-lock.yml
```

## Updating the Lock

When you intentionally want to pull in upstream changes:
1. Build **without** the lock file, test the image
2. Re-capture the new SHA and timestamp
3. Update `kas/opt/package-lock.yml` and commit
