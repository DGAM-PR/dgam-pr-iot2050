DESCRIPTION = "NetworkManager connection profile for eno2 static IP \
(192.168.1.4/24 on PLC-facing device, 192.168.1.3/24 on VPN-facing device)"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit dpkg-raw

# ENO2_PROFILE selects which nmconnection file to deploy.
# Set to "plc" in plc-facing-dgam-pr.yml  → 192.168.1.4/24
# Set to "vpn" in vpn-facing-dgam-pr.yml  → 192.168.1.3/24
ENO2_PROFILE ??= "vpn"

SRC_URI = " \
    file://eno2-static-plc.nmconnection \
    file://eno2-static-vpn.nmconnection \
    file://postinst \
"

DEBIAN_DEPENDS = "network-manager"

do_install() {
    install -d ${D}/etc/NetworkManager/system-connections
    # NM requires 600 permissions on connection files — it silently ignores files
    # with looser permissions. The postinst script re-enforces this at dpkg
    # install time because dpkg-raw can override permissions set here.
    install -m 0600 ${WORKDIR}/eno2-static-${ENO2_PROFILE}.nmconnection \
        ${D}/etc/NetworkManager/system-connections/eno2-static.nmconnection

    # Mask systemd-networkd-wait-online — not needed since we use NetworkManager.
    # A symlink to /dev/null is exactly what `systemctl mask` writes to disk;
    # shipping it in the package makes the masking declarative and permanent.
    install -d ${D}/etc/systemd/system
    ln -sf /dev/null \
        ${D}/etc/systemd/system/systemd-networkd-wait-online.service
}

FILES:${PN} = " \
    /etc/NetworkManager/system-connections/eno2-static.nmconnection \
    /etc/systemd/system/systemd-networkd-wait-online.service \
"
