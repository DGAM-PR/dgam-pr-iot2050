DESCRIPTION = "Configure /dev/ttyUSB0 (IOT2050 X30 onboard UART) to 230400 8N1 at boot via a oneshot systemd service"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit dpkg-raw

SRC_URI = " \
    file://ttyUSB0-setup.service \
    file://postinst \
"

do_install() {
    install -d ${D}/etc/systemd/system
    install -m 0644 ${WORKDIR}/ttyUSB0-setup.service \
        ${D}/etc/systemd/system/ttyUSB0-setup.service
}

FILES:${PN} = " \
    /etc/systemd/system/ttyUSB0-setup.service \
"
