DESCRIPTION = "Systemd network configuration for eno2 interface"
LICENSE = "Apache-2.0"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://10-eno2.network"

do_install:append() {
    install -d ${D}${sysconfdir}/systemd/network
    install -m 0644 ${WORKDIR}/10-eno2.network ${D}${sysconfdir}/systemd/network/10-eno2.network
}

FILES:${PN} += "${sysconfdir}/systemd/network/10-eno2.network"
