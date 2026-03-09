DESCRIPTION = "Mosquitto configuration for PLC-facing IOT2050: listener on port 1883, anonymous access allowed"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit dpkg-raw

SRC_URI = " \
    file://listener.conf \
    file://postinst \
"

DEBIAN_DEPENDS = "mosquitto"

do_install() {
    install -d ${D}/etc/mosquitto/conf.d
    install -m 0644 ${WORKDIR}/listener.conf \
        ${D}/etc/mosquitto/conf.d/listener.conf
}

FILES:${PN} = " \
    /etc/mosquitto/conf.d/listener.conf \
"
