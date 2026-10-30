# Node-RED 5.x needs Node.js >= 22.9, which Debian trixie does not ship (it has 20).
# Node 24 comes from NodeSource, enabled in kas/plc-facing-dgam-pr.yml only.
# Overrides meta-node-red's node-red_4.0.9.bb (highest version wins).
# To update npm-shrinkwrap.json follow meta-node-red/classes/npm.bbclass.

PR = "1"

inherit npm
require recipes-app/node-red/node-red-home.inc

DESCRIPTION = "A visual tool for wiring the Internet of Things"

PRESERVE_PERMS = "usr/lib/node_modules/node-red/red.js"
DEBIAN_DEPENDS = "nodejs (>= 22.9)"

SRC_URI += "file://node-red.service.tmpl \
            file://99-node-red.preset"

TEMPLATE_FILES = "node-red.service.tmpl"
TEMPLATE_VARS  = "NODE_RED_HOME_DIR"

do_prepare_build:append() {
    cat <<EOF >> ${S}/debian/rules

override_dh_installsystemd:
	dh_installsystemd --no-start
EOF
}

do_install:append() {
    install -v -d ${D}/usr/lib/systemd/system/
    install -v -m 644 ${WORKDIR}/node-red.service ${D}/usr/lib/systemd/system/

    install -v -d ${D}/usr/lib/systemd/system-preset/
    install -v -m 644 ${WORKDIR}/99-node-red.preset ${D}/usr/lib/systemd/system-preset/
}
