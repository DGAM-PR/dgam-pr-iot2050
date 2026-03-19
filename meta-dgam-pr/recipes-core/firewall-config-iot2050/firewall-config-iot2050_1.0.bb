DESCRIPTION = "Firewalld configuration for IOT2050: opens MQTT (1883/tcp) and Node-RED (1880/tcp) in the public zone for management access via eno1/eno2"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit dpkg-raw

SRC_URI = " \
    file://mqtt.xml \
    file://node-red.xml \
    file://public.xml \
    file://firewalld.conf \
    file://postinst \
"
###
# Root cause recap: firewalld's default nftables backend calls python-nftables via a 
# JSON/netlink API on every cold start. The IOT2050 kernel's nftables subsystem ABI 
# is older than the libnftables userspace library in Debian Bookworm, so every call 
# fails with COMMAND_FAILED and firewalld crashes before it can load any zone. Setting 
# FirewallBackend=iptables routes all firewalld operations through the stable xt_* 
# kernel modules the IOT2050 kernel fully supports.
# nftables backend is incompatible with the IOT2050 kernel ABI; use iptables instead.
###

DEBIAN_DEPENDS = "firewalld, iptables"

do_install() {
    # Custom service definitions
    install -d ${D}/etc/firewalld/services
    install -m 0644 ${WORKDIR}/mqtt.xml     ${D}/etc/firewalld/services/mqtt.xml
    install -m 0644 ${WORKDIR}/node-red.xml ${D}/etc/firewalld/services/node-red.xml

    # Zone override — activates the custom services in the public zone
    install -d ${D}/etc/firewalld/zones
    install -m 0644 ${WORKDIR}/public.xml   ${D}/etc/firewalld/zones/public.xml

    # Backend override — force iptables; IOT2050 kernel nftables ABI is too old
    # for the libnftables version in Debian Bookworm (causes crash on cold boot).
    install -d ${D}/etc/firewalld
    install -m 0644 ${WORKDIR}/firewalld.conf ${D}/etc/firewalld/firewalld.conf
}

FILES:${PN} = " \
    /etc/firewalld/firewalld.conf \
    /etc/firewalld/services/mqtt.xml \
    /etc/firewalld/services/node-red.xml \
    /etc/firewalld/zones/public.xml \
"
