# Workaround: 0001-ARM32-Split-headers-and-code.patch is already incorporated
# into the upstream Debian gnu-efi source package, causing do_prepare_build to
# fail with "Patch can be reverse-applied" (all hunks rejected).
#
# The fix is present in isar-cip-core/next branch. Remove this file once
# meta-iot2050 updates its cip-core pin to a commit that includes the fix.
#
# Upstream issue: https://github.com/siemens/meta-iot2050/issues/653
SRC_URI:remove = "file://0001-ARM32-Split-headers-and-code.patch"
