# CI Build Runner Setup

This document describes how to set up a GitHub Actions self-hosted runner on an ARM Ubuntu server to build IOT2050 images using this repository.

## Table of Contents

- [Overview](#overview)
- [Server Requirements](#server-requirements)
- [Directory Layout on the Build Server](#directory-layout-on-the-build-server)
- [1. Prepare the Server](#1-prepare-the-server)
- [2. Install and Register the GitHub Actions Runner](#2-install-and-register-the-github-actions-runner)
- [3. Place EIO Binaries (VPN-facing build only)](#3-place-eio-binaries-vpn-facing-build-only)
- [4. Verify the Setup](#4-verify-the-setup)
- [How Builds Work](#how-builds-work)
- [Artifact Retention Policy](#artifact-retention-policy)
- [Disk Space Reference](#disk-space-reference)
- [Adding Nightly / Scheduled Builds](#adding-nightly--scheduled-builds)
- [Troubleshooting](#troubleshooting)

---

## Overview

```
GitHub push / workflow_dispatch
        │
        ▼
GitHub Actions → self-hosted runner (ARM Ubuntu)
        │
        ├── Job: build plc-facing   ──┐
        └── Job: build vpn-facing   ──┤  (parallel)
                                      │
                    ISAR build (kas-container + Docker)
                                      │
                    on success ───────▶  /data/artifacts/<branch>/<run>-<target>/
                                      │     *.wic  *.swu  (no *-ebg.swu)
                    always ───────────▶  workspace cleanup + docker prune
```

**What lives where:**

| Path | Purpose | Cleaned by CI? |
|------|---------|----------------|
| `~/actions-runner/_work/` | Runner workspace (checkout, build `tmp/`) | Yes — after every run |
| `/data/artifacts/` | Final `.wic` + `.swu` files (excluding `*-ebg.swu`) | Partially — oldest builds pruned, last 3 kept |
| `/data/eio-binaries/` | Siemens EIO firmware (placed once by admin) | Never |
| Docker named volumes (`isar-sstate-cache`, `isar-downloads`) | BitBake cache — speeds up incremental builds | Never (remove manually for a clean build) |

---

## Server Requirements

| Item | Minimum |
|------|---------|
| Architecture | `arm64` (AArch64) |
| OS | Ubuntu 22.04 LTS or later |
| RAM | 8 GB (16 GB recommended — ISAR is memory-hungry) |
| `/` free space | 40 GB (ISAR build temp + Docker images) |
| `/data` free space | 1 TB (ext4 mounted, for artifact storage) |
| Docker | ≥ 24.x |
| Internet access | Required — kas fetches `meta-iot2050` and Debian packages |

---

## Directory Layout on the Build Server

```
/
├── home/
│   └── github-runner/
│       └── actions-runner/        ← runner binary + _work/
└── data/
    ├── artifacts/
    │   └── stable-v01.06-locked/  ← branch slug (/ replaced with -)
    │       ├── 42-plc-facing/
    │       │   ├── iot2050-image-swu-example-iot2050-advanced.wic
    │       │   └── iot2050-image-swu-example-iot2050-advanced.swu
    │       └── 42-vpn-facing/
    │           ├── iot2050-image-swu-example-iot2050-advanced-sm.wic
    │           └── iot2050-image-swu-example-iot2050-advanced-sm.swu
    └── eio-binaries/              ← Siemens proprietary binaries, placed once
        └── <firmware files>
```

---

## 1. Prepare the Server

### 1a. Create the runner user

```bash
sudo useradd --system --create-home --shell /bin/bash github-runner
```

### 1b. Install Docker

```bash
# Add Docker's official repository (Ubuntu)
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Allow github-runner to use Docker without sudo
sudo usermod -aG docker github-runner

```
> If you want to build locally on the server (outside CI), add your personal user to the `docker` group too:
> ```bash
> sudo usermod -aG docker <your-username>
> # Log out and back in for the group change to take effect.
> ```

> ⚠️ The `docker` group grants root-equivalent access to the Docker daemon. This is acceptable for a dedicated CI build server. If your security policy requires rootless Docker, additional configuration is needed (see [Docker rootless docs](https://docs.docker.com/engine/security/rootless/)).

### 1c. Create storage directories

```bash
sudo mkdir -p /data/artifacts /data/eio-binaries
sudo chown -R github-runner:github-runner /data/artifacts /data/eio-binaries
```

### 1d. Verify `/data` is the ext4 volume

```bash
df -hT /data
# Expected output: /dev/sdX  ext4  1.0T  ...  /data
```

---

## 2. Install and Register the GitHub Actions Runner

### 2a. Download the runner binary

Switch to the runner user:

```bash
sudo -u github-runner -i
cd ~
mkdir actions-runner && cd actions-runner
```

Download the latest ARM64 runner from GitHub. Replace `<VERSION>` with the latest release from [github.com/actions/runner/releases](https://github.com/actions/runner/releases):

```bash
curl -o actions-runner-linux-arm64-<VERSION>.tar.gz -L \
  https://github.com/actions/runner/releases/download/v<VERSION>/actions-runner-linux-arm64-<VERSION>.tar.gz

tar xzf actions-runner-linux-arm64-<VERSION>.tar.gz
```

Example:

```
curl -o actions-runner-linux-arm64-2.336.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.336.0/actions-runner-linux-arm64-2.336.0.tar.gz

tar xzf actions-runner-linux-arm64-2.336.0.tar.gz
```

### 2b. Register the runner with the DGAM-PR organisation

An **organisation-level** runner can serve any repository in the org, so you only need to set it up once even as more repos are added.

> ℹ️ You need **Owner** access to the `DGAM-PR` GitHub organisation to do this.

1. Go to **github.com/organizations/DGAM-PR/settings/actions/runners**
2. Click **New self-hosted runner**
3. Select **Linux / ARM64**
4. GitHub shows a unique registration token valid for ~1 hour. Use it below:

```bash
./config.sh \
  --url https://github.com/DGAM-PR \
  --token <REGISTRATION-TOKEN> \
  --name arm-build-server \
  --labels self-hosted,Linux,ARM64 \
  --work _work \
  --unattended
```

**Labels explained:**

| Label | Purpose |
|-------|---------|
| `self-hosted` | Required — marks this as a self-hosted runner |
| `Linux` | OS type (capital L — must match exactly what the runner reports) |
| `ARM64` | Architecture (capital — must match exactly what the runner reports) |

> ⚠️ **Runner access policy**: By default, organisation runners are available to **all** repositories in the org. If you want to restrict it to specific repos only, go to **github.com/organizations/DGAM-PR/settings/actions/runners**, click the runner, and under **Repository access** select the repos that should use it.

### 2c. Install and start as a systemd service

`svc.sh` creates a systemd unit and needs root — run it as your **admin user** (the one with sudo), not as `github-runner`. Exit the `github-runner` shell first, then `cd` into the runner directory before calling `svc.sh` (it checks `$PWD` and fails if run from elsewhere):

```bash
# Exit back to your admin user
exit

# cd into the runner directory — svc.sh requires this
cd /home/github-runner/actions-runner

# Install the service (tells systemd to run the runner as github-runner)
sudo ./svc.sh install github-runner

# Start it
sudo ./svc.sh start

# Verify it's running
sudo ./svc.sh status
```

The runner will now appear as **Idle** in the organisation's Runners list at **github.com/organizations/DGAM-PR/settings/actions/runners**.

### 2d. Verify runner labels in GitHub

Go to **github.com/organizations/DGAM-PR/settings/actions/runners** and confirm the runner shows labels: `self-hosted`, `Linux`, `ARM64`.

> ⚠️ Label matching in GitHub Actions is **case-sensitive**. The labels in `runs-on` in the workflow must match the runner's labels exactly, including capitalisation.

---

## 3. Place EIO Binaries (VPN-facing build only)

The VPN-facing image requires proprietary EIO firmware from Siemens that cannot be distributed in the repository. This is a **one-time manual step** per build server.

### 3a. Download the binaries

Download the **EIO firmware & binaries** package from [Siemens Industry Online Support (SIOS)](https://support.industry.siemens.com/cs/document/109741799/).

### 3b. Extract and place on the server

```bash
# As your admin user (not github-runner)
sudo cp -r /path/to/extracted/eio-binaries/. /data/eio-binaries/
sudo chown -R github-runner:github-runner /data/eio-binaries/
```

### 3c. Verify

```bash
ls -lh /data/eio-binaries/
# Should list the firmware files — must not be empty
```

The CI workflow checks for this and fails fast with a clear error if the directory is empty.

---

## 4. Verify the Setup

Trigger a manual build from the GitHub Actions tab (**Actions → Build IOT2050 Images → Run workflow**) and watch the logs.

Expected run sequence per target:

```
✓ Checkout
✓ Copy EIO binaries into workspace (vpn-facing only)
✓ Build (plc-facing / vpn-facing)
✓ Copy artifacts to /data
✓ Cleanup workspace and Docker
```

After a successful run, check the artifacts:

```bash
ls -lh /data/artifacts/stable-v01.06-locked/
```

---

## How Builds Work

### Trigger

Builds run automatically on:
- **Push** to `stable/v01.06-locked`
- **Manual trigger** via `workflow_dispatch` (Actions tab → Run workflow)

### Concurrency

Only one build runs at a time per branch. A new push while a build is running will wait (not cancel) to avoid race conditions on the shared Docker volumes.

### Parallel targets

Both `plc-facing` and `vpn-facing` build jobs run in parallel on the same server. Each job gets its own workspace directory inside `_work/`. `fail-fast: false` means one failing target does not cancel the other.

### BitBake cache persistence

ISAR's sstate and download caches are stored in named Docker volumes:
- `isar-sstate-cache`
- `isar-downloads`

These persist across builds and dramatically speed up incremental builds (unchanged packages are not rebuilt). They are **never** cleaned automatically.

To force a completely clean build, remove them manually:

```bash
docker volume rm isar-sstate-cache isar-downloads
```

---

## Artifact Retention Policy

Only **successful** builds write artifacts to `/data`. Failed builds write nothing.

After each successful build, the retention script (`scripts/ci-copy-artifacts.sh`) automatically deletes old builds, keeping the **last 3 successful builds per branch per target**.

Example after 5 successful builds:

```
/data/artifacts/stable-v01.06-locked/
├── 3-plc-facing/   ← kept
├── 4-plc-facing/   ← kept
├── 5-plc-facing/   ← kept (newest)
├── 3-vpn-facing/   ← kept
├── 4-vpn-facing/   ← kept
└── 5-vpn-facing/   ← kept (newest)

# builds 1 and 2 were automatically deleted
```

To change the retention count, edit the `KEEP` environment variable in [`.github/workflows/build.yml`](../.github/workflows/build.yml):

```yaml
env:
  KEEP: "3"   # change this to 2 or 5 etc.
```

---

## Disk Space Reference

| Item | Approximate size |
|------|-----------------|
| ISAR build `tmp/` (per build) | 15–25 GB |
| `isar-sstate-cache` Docker volume | 5–15 GB (grows then stabilises) |
| `isar-downloads` Docker volume | 2–5 GB |
| One `.wic` artifact | ~300–600 MB |
| One `.swu` artifact | ~200–400 MB |
| 3 builds × 2 targets × 2 files (`.wic` + `.swu`, no `*-ebg.swu`) | ~3–6 GB on `/data` |

The `/` partition needs ~40 GB free during a build. After the cleanup step runs, most of that is reclaimed.

---

## Adding Nightly / Scheduled Builds

To add a nightly build for a branch (e.g. `main`), add a `schedule` trigger to the workflow:

```yaml
on:
  push:
    branches:
      - "stable/v01.06-locked"
  schedule:
    # Every night at 02:00 Amsterdam time (00:00 UTC in winter, adjust for DST)
    - cron: "0 0 * * *"
  workflow_dispatch:
```

> Note: GitHub Actions scheduled triggers only run on the **default branch** by default. To run nightly builds on non-default branches, use a separate workflow file per branch or use `workflow_dispatch` with branch selection.

---

## Troubleshooting

### Runner shows as Offline

```bash
sudo -u github-runner -i
cd ~/actions-runner
./svc.sh status
# If stopped:
./svc.sh start
```

### Build fails: "EIO binaries not found"

The `/data/eio-binaries/` directory is empty. See [Step 3](#3-place-eio-binaries-vpn-facing-build-only).

### Disk full on `/`

The cleanup step (`scripts/ci-cleanup.sh`) removes `build/` and prunes dangling Docker images. If `/` is still full:

```bash
# Check what's large
df -hT /
du -sh ~/actions-runner/_work/*

# Manually remove the build output if a previous run's cleanup failed
rm -rf ~/actions-runner/_work/<repo-name>/<repo-name>/build/

# Prune Docker
docker system prune -f
```

If you need the build temp to live on `/data` instead of `/`:

```bash
# In the runner config, set --work to a path on /data:
./config.sh --work /data/runner-work ...
# Then re-register the runner.
```

### Artifacts not appearing in `/data`

Check the "Copy artifacts to /data" step in the GitHub Actions log. Common causes:
- The build step failed (copy is skipped on failure — intentional)
- The ISAR deploy directory path changed — look for the actual path in the build log and update `DEPLOY_DIR` in `scripts/ci-copy-artifacts.sh`

### Force a clean build (no cache)

```bash
docker volume rm isar-sstate-cache isar-downloads
```

Then trigger a new build. The first clean build will take significantly longer.
