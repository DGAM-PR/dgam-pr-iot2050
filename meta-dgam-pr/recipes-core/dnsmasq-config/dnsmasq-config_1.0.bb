DESCRIPTION = "PLC-facing dnsmasq DHCP configuration for the IOT2050 X1 P1 port"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit dpkg-raw

SRC_URI = " \
    file://plc-facing.conf \
    file://direct.xml \
    file://postinst \
"

DEBIAN_DEPENDS = "dnsmasq, firewalld"

do_install() {
    install -d ${D}/etc/dnsmasq.d
    install -m 0644 ${WORKDIR}/plc-facing.conf \
        ${D}/etc/dnsmasq.d/plc-facing.conf

    install -d ${D}/etc/firewalld
    install -m 0644 ${WORKDIR}/direct.xml ${D}/etc/firewalld/direct.xml
}

FILES:${PN} = " \
    /etc/dnsmasq.d/plc-facing.conf \
    /etc/firewalld/direct.xml \
"
