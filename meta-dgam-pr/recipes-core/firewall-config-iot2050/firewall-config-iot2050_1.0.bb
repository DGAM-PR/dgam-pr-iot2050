DESCRIPTION = "Firewalld configuration for IOT2050: opens MQTT (1883/tcp) and Node-RED (1880/tcp) in the public zone for management access via eno1/eno2"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit dpkg-raw

SRC_URI = " \
    file://mqtt.xml \
    file://node-red.xml \
    file://public.xml \
    file://postinst \
"

DEBIAN_DEPENDS = "firewalld, nftables"

do_install() {
    # Custom service definitions
    install -d ${D}/etc/firewalld/services
    install -m 0644 ${WORKDIR}/mqtt.xml     ${D}/etc/firewalld/services/mqtt.xml
    install -m 0644 ${WORKDIR}/node-red.xml ${D}/etc/firewalld/services/node-red.xml

    # Zone override — activates the custom services in the public zone
    install -d ${D}/etc/firewalld/zones
    install -m 0644 ${WORKDIR}/public.xml   ${D}/etc/firewalld/zones/public.xml
}

FILES:${PN} = " \
    /etc/firewalld/services/mqtt.xml \
    /etc/firewalld/services/node-red.xml \
    /etc/firewalld/zones/public.xml \
"
