# The npm build chroot gets Node 24 (with bundled npm) from NodeSource instead of
# Debian's Node 20 npm/libnode115, so npm packages are built for the runtime Node.
SBUILD_CHROOT_PREINSTALL_EXTRA:remove = "npm libnode115"
SBUILD_CHROOT_PREINSTALL_EXTRA:append = " nodejs"
