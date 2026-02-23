DESCRIPTION = "Systemd network configuration for eno2 interface"
LICENSE = "Apache-2.0"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://10-eno2.network"

# Add preset file conditionally based on DISTRO_FEATURES
## Will only work if feature is enabled in `kas` yaml
SRC_URI += "${@bb.utils.contains('DISTRO_FEATURES', 'disable-networkd-wait', 'file://90-networkd-wait-online.preset', '', d)}"

do_install:append() {
    install -d ${D}${sysconfdir}/systemd/network
    install -m 0644 ${WORKDIR}/10-eno2.network ${D}${sysconfdir}/systemd/network/10-eno2.network
    
    # Install preset if feature is enabled
    if ${@bb.utils.contains('DISTRO_FEATURES', 'disable-networkd-wait', 'true', 'false', d)}; then
        install -d ${D}${sysconfdir}/systemd/system-preset
        install -m 0644 ${WORKDIR}/90-networkd-wait-online.preset ${D}${sysconfdir}/systemd/system-preset/
    fi
}

FILES:${PN} += "${sysconfdir}/systemd/network/10-eno2.network"
FILES:${PN} += "${@bb.utils.contains('DISTRO_FEATURES', 'disable-networkd-wait', '${sysconfdir}/systemd/system-preset/90-networkd-wait-online.preset', '', d)}"
