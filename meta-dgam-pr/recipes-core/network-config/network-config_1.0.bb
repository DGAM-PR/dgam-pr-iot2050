DESCRIPTION = "NetworkManager connection profile for eno2 static IP (192.168.1.3/24)"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit dpkg-raw

SRC_URI = " \
    file://eno2-static.nmconnection \
    file://postinst \
"

DEBIAN_DEPENDS = "network-manager"

do_install() {
    install -d ${D}/etc/NetworkManager/system-connections
    # NM requires 600 permissions on connection files — it silently ignores files
    # with looser permissions. The postinst script re-enforces this at dpkg
    # install time because dpkg-raw can override permissions set here.
    install -m 0600 ${WORKDIR}/eno2-static.nmconnection \
        ${D}/etc/NetworkManager/system-connections/eno2-static.nmconnection
}

FILES:${PN} = "/etc/NetworkManager/system-connections/eno2-static.nmconnection"
