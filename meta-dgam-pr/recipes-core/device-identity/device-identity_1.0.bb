DESCRIPTION = "Device identity environment variables (LOCATION, GROUP, NAME, EDGEDEVICENAME). \
Installs /var/lib/device-identity/env with placeholder values that must be \
filled in before the device is deployed to the field. Variables are exported \
host-wide via /etc/profile.d/device-env.sh for login shells, and are available \
to systemd services via EnvironmentFile=/var/lib/device-identity/env."
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit dpkg-raw

SRC_URI = " \
    file://device-identity.env \
    file://device-env.sh \
    file://postinst \
"

do_install() {
    # Ship the template to /usr/share so postinst can copy it to /var/lib.
    # /usr/share is part of the read-only OS image; /var/lib is the writable
    # data partition where the operator edits the live config.
    install -d ${D}/usr/share/device-identity
    install -m 0644 ${WORKDIR}/device-identity.env \
        ${D}/usr/share/device-identity/device-identity.env

    # profile.d shim — sources the live env file for every login shell.
    install -d ${D}/etc/profile.d
    install -m 0644 ${WORKDIR}/device-env.sh ${D}/etc/profile.d/device-env.sh
}

FILES:${PN} = " \
    /usr/share/device-identity/device-identity.env \
    /etc/profile.d/device-env.sh \
"
