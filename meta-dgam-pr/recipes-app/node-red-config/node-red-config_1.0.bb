DESCRIPTION = "Node-RED configuration for PLC-facing IOT2050: adds root to dialout group for /dev/ttyUSB0 access"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit dpkg-raw

SRC_URI = " \
    file://postinst \
"

DEBIAN_DEPENDS = "node-red"

do_install() {
    # Nothing to install — all work is done in postinst
    :
}
