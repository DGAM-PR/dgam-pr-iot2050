# Node 24 (NodeSource) headers: V8 13 needs C++20, but meta-iot2050 patch 0006 only sets C++17.
# Headers come from NodeSource's nodejs (usr/include/node); Debian's libnode-dev is tied to
# Node 20 and would conflict, so it is dropped from the build dependencies.
DEBIAN_BUILD_DEPENDS = " \
    cmake, \
    swig, \
    libpython3-dev, \
    nodejs:native, \
    libjson-c-dev, \
    default-jdk:native"

do_prepare_build:append() {
    sed -i 's/CXX_STANDARD 17/CXX_STANDARD 20/' ${S}/src/javascript/CMakeLists.txt
    # fail the build if upstream patch 0006 changes shape and the sed silently misses
    grep -q 'CXX_STANDARD 20' ${S}/src/javascript/CMakeLists.txt
}
