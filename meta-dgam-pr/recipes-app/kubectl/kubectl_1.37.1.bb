DESCRIPTION = "kubectl - Kubernetes command-line tool"
HOMEPAGE = "https://kubernetes.io/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

# Inherit dpkg-raw for binary packages in Isar
inherit dpkg-raw

# Set proper architecture for binary package
DPKG_ARCH = "arm64"

# ARM64 release KubeCTL
## More info: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
SRC_URI = "https://dl.k8s.io/release/v${PV}/bin/linux/arm64/kubectl;sha256sum=ff749f4b78d9c4f1ec87307df9b50119ed819e2094aa9810cb9acffc3286c8c7 \
           file://kubectl-alias.sh \
"

S = "${WORKDIR}/src"

prefix = "/usr"
bindir = "${prefix}/bin"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/kubectl ${D}${bindir}/kubectl

    # Install alias for all login shells
    install -d ${D}/etc/profile.d
    install -m 0644 ${WORKDIR}/kubectl-alias.sh ${D}/etc/profile.d/kubectl-alias.sh
}

FILES:${PN} = "${bindir}/kubectl \
               /etc/profile.d/kubectl-alias.sh"
