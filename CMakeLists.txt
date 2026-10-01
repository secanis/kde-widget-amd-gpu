# Optional system-wide install:
#   cmake -B build-cmake -DCMAKE_INSTALL_PREFIX=/usr && sudo cmake --install build-cmake
# For a per-user install `make install` (kpackagetool6) is enough. Nothing is compiled,
# so this needs only CMake itself, not ECM or the Plasma development files.
cmake_minimum_required(VERSION 3.19)

file(READ package/metadata.json _metadata)
string(JSON _version GET "${_metadata}" KPlugin Version)
string(JSON _plugin_id GET "${_metadata}" KPlugin Id)

project(amdgpumonitor VERSION ${_version} LANGUAGES NONE)

# GNUInstallDirs needs a compiled language to pick a libdir; only the data dir is used here.
set(CMAKE_INSTALL_DATADIR "share" CACHE PATH "Read-only architecture-independent data root (share)")

install(DIRECTORY package/
        DESTINATION ${CMAKE_INSTALL_DATADIR}/plasma/plasmoids/${_plugin_id}
        PATTERN "*~" EXCLUDE)
