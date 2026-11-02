# Quick Install: New IOT2050 Device

Quick reference for installing a **brand-new IOT2050 straight from the factory**.

Order of work:

1. [Firmware update](#1-firmware-update)
2. [Deployment (flash the dgam-pr Debian OS to eMMC)](#2-deployment)

> ⚠️ Always do the firmware update **before** flashing the OS, so U-Boot is compatible with our self-built image.

## Prerequisites

| Item | Contents |
|---|---|
| **SD card** | Siemens Troubleshooting OS (service stick / example image) |
| **USB stick** | Firmware files (`iot2050-firmware-update_<version>_arm64.deb` and `IOT2050-FW-Update-PKG-V01.xx.xx-<hash>.tar.xz`, in a `firmware/` directory) **plus** the dgam-pr `.wic` file (`iot2050-image-swu-example-iot2050-debian-iot2050.wic`) |

Firmware version must match the branch version (e.g. `v01.06.XX`; the last part matters less).

How to prepare both: see the main [README.md](README.md) (sections [Build Output](README.md#build-output) and [Firmware Updates](README.md#firmware-updates)).

> The USB stick must be `ext4` formatted (it is mounted with `-t ext4` below).

---

## 0. Boot the Troubleshooting OS

1. Insert the SD card and the USB stick, power on.
2. Login: `root` / `root` (you may be forced to change the password on first login).
3. If it does not boot from the SD card, at the U-Boot prompt:
   - **Option A**
     ```
     printenv boot_targets
     setenv boot_targets mmc0 mmc1 usb0 usb1 usb2
     boot
     ```
   - **Option B** (if A fails)
     ```
     load mmc 0:2 ${kernel_addr_r} linux.efi
     bootefi ${kernel_addr_r} ${fdtcontroladdr}
     ```

> Advanced SM devices only: if a message says *"EIO firmware need update via cli iot2050-eio fwu controller!"*, connect the top port to the internet and run `iot2050-eio fwu controller`.

---

## 1. Firmware Update

### 1.1 Ensure `BUILD_ID` exists in `/etc/os-release`

The Siemens update script fails with a Python `KeyError` if it is missing.

```bash
grep BUILD_ID /etc/os-release || {
  CURRENT_VER=$(fw_printenv fw_version | cut -d'-' -f2)
  echo "BUILD_ID=$CURRENT_VER" >> /etc/os-release
}
```

### 1.2 Copy firmware from USB stick

```bash
mkdir -p /tmp/usb
mount -t ext4 /dev/sda1 /tmp/usb      # could be sdb1 if more sticks are plugged in
cp -R /tmp/usb/firmware ~/
cd ~/firmware/V01.XX/XX               # latest version matching the branch
```

### 1.3 Install the update tool (only if `iot2050-firmware-update` is missing)

```bash
dpkg -r iot2050-firmware-update || true
dpkg -i iot2050-firmware-update-1.1.0_arm64.deb   # or similar
apt -f install                                    # may need `apt update` first
```

### 1.4 Run the update

```bash
iot2050-firmware-update IOT2050-FW-Update-PKG-<Your Version>.tar.xz
```

Prompts:

1. Device may become unbootable → `Y`
2. Keep current boot order (`Y`) or reset to defaults (`n`), per your setup
3. Let the device reboot

### 1.5 Verify

After the reboot, boot the SD card again (step 0) and check:

```bash
fw_printenv fw_version
```

It must match the package you installed.

---

## 2. Deployment

Run from the Troubleshooting OS booted from the SD card.

1. **Wipe the eMMC**
   ```bash
   sudo wipefs -a /dev/mmcblk1
   ```
2. **Mount the USB stick**
   ```bash
   sudo mkdir -p /tmp/usb
   sudo mount -t ext4 /dev/sda1 /tmp/usb
   cd /tmp/usb/vpnfacing #or /plcfacing
   ```
3. **Flash the `.wic` to eMMC** (takes several minutes)
   ```bash
   sudo dd if=./iot2050-image-swu-example-iot2050-debian-iot2050.wic \
           of=/dev/mmcblk1 \
           bs=4M \
           status=progress \
           conv=fsync
   ```
   > First `dd` to this eMMC? Zero it first: `dd if=/dev/zero of=/dev/mmcblk1 bs=4M status=progress`
4. **Reboot**
   ```bash
   cd ~ && sudo umount /tmp/usb
   init 0
   ```
   - Wait a few seconds until it stops, then **pull the power**
   - Remove the SD card and the USB stick
   - Plug the power back in: the dgam-pr Debian OS boots from eMMC

---

## 3. First Boot Configuration

Login on the new OS (laptop on `eno1`, `192.168.200.1/24`, or serial/console).

### 3.1 Device identity (both device types)

```bash
vi /var/lib/device-identity/env
```

Replace the placeholders (`VPN_OR_PLC_FACING` is pre-filled at build time, leave it):

```bash
LOCATION= # amsterdam-zuid
GROUP= #spoorbrug or tunnel
EDGEDEVICENAME= #edge-***
```

> Restart the device first before moving on to Kubesolo to make sure the devce-identity is up to date
Restart the edge device: `reboot`


### 3.2 KubeSolo (VPN-facing device only)

```bash
vi /var/lib/kubesolo/config
```

Uncomment and set (both are required):

```bash
KUBESOLO_PORTAINER_EDGE_ID=device-001
KUBESOLO_PORTAINER_EDGE_KEY=<base64 key>
```

The service polls the file every 60 s and starts by itself; to start it right away:

```bash
systemctl start kubesolo
systemctl status kubesolo
```

> KubeSolo needs internet (`registry-1.docker.io`) through `eno2` before it starts. Optional variables: see [KubeSolo Configuration](README.md#kubesolo-configuration).

### 3.3 Network check

| Device | `eno2` IP | Extra |
|---|---|---|
| PLC-facing | `192.168.1.4/24` | `eno1` serves DHCP (`192.168.200.5`–`254`) |
| VPN-facing | `192.168.1.3/24` | |

```bash
ip addr show eno2
nmcli connection show eno2-static
ping -c 2 1.1.1.1       # connectivity
ping -c 2 google.com    # DNS
```

Details and changing settings: [Network Configuration](README.md#network-configuration).
