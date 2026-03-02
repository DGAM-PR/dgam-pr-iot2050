DESCRIPTION = "Systemd network configuration for eno2 interface"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit dpkg-raw

SRC_URI = "file://10-eno2.network"

DEBIAN_DEPENDS = "systemd"

do_install() {
    install -d ${D}${sysconfdir}/systemd/network
    install -m 0644 ${WORKDIR}/10-eno2.network ${D}${sysconfdir}/systemd/network/10-eno2.network
}

FILES:${PN} = "${sysconfdir}/systemd/network/10-eno2.network"
