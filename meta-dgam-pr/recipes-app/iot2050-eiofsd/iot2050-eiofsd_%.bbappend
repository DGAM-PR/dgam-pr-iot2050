# Redirect BitBake's file search path so the proprietary EIO binaries are
# sourced from meta-dgam-pr (which persists across kas re-clones of
# meta-iot2050) rather than from meta-sm's own files/bin/ directory.
#
# The EIO binaries are proprietary Siemens software and must NOT be
# committed to git. Download them from SIOS and place them in:
#
#   meta-dgam-pr/recipes-app/iot2050-eiofsd/files/bin/
#
# See README.md in this directory for download instructions.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
