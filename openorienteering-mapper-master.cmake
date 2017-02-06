# This file is part of OpenOrienteering.

# Copyright 2016, 2017 Kai Pastor
#
# Redistribution and use is allowed according to the terms of the BSD license:
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 
# 1. Redistributions of source code must retain the copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products 
#    derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

set(version        master)
set(qt_version     5.6.2)

superbuild_package(
  NAME           openorienteering-mapper
  VERSION        ${version}
  DEPENDS
    gdal
    libpolyclipping
    proj
    qtandroidextras-${qt_version}
    qtbase-${qt_version}
    qtimageformats-${qt_version}
    qtlocation-${qt_version}
    qtsensors-${qt_version}
    qttools-${qt_version}
    qttranslations-${qt_version}
    zlib
    host:doxygen
    host:qttools-${qt_version}
  
  SOURCE
    DOWNLOAD_NAME  openorienteering-mapper_${version}.tar.gz
    URL            https://github.com/OpenOrienteering/mapper/archive/${version}.tar.gz
    PATCH_COMMAND
      sed -i -e [[ s/\/usr\//${CMAKE_INSTALL_PREFIX}\// ]] CMakeLists.txt
    COMMAND
      sed -i -e [[ /DESTDIR/d ]] packaging/CMakeLists.txt
    COMMAND
      sed -i -e [[ /libqjp2.so/d ]] src/src.pro
  
  BUILD [[
  $<$<NOT:$<BOOL:${ANDROID}>>:
    CONFIGURE_COMMAND
      $<$<AND:$<BOOL:${UNIX}>,$<NOT:$<BOOL:${APPLE}>>>:
      "${CMAKE_COMMAND}" -E env
        "LDFLAGS=-Wl,--as-needed"
      > # UNIX AND NOT APPLE
      "${CMAKE_COMMAND}" "${SOURCE_DIR}"
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DBUILD_SHARED_LIBS=0"
      "-DMapper_AUTORUN_SYSTEM_TESTS=0"
      "-DBIN_INSTALL_DIR=bin"
      "-DLIB_INSTALL_DIR=bin"
      "-DSHARE_INSTALL_DIR=share"
      "-DMapper_BUILD_PACKAGE=1"
      "-DMapper_BUILD_CLIPPER=0"
      "-DMapper_BUILD_PROJ=0"
        "-DMapper_PACKAGE_PROJ=1"
      "-DMapper_USE_GDAL=1"
        "-DMapper_BUILD_GDAL=0"
        "-DMapper_PACKAGE_GDAL=1"
      "-DMapper_BUILD_DOXYGEN=0"
      "-DMapper_PACKAGE_QT=1"
        "-DMapper_BUILD_QT=0"
        "-DMapper_PACKAGE_ASSISTANT=1"
      $<$<STREQUAL:${SYSTEM_NAME},default>:
        # Cf. https://cmake.org/Wiki/CMake_RPATH_handling#Always_full_RPATH
        "-DCMAKE_INSTALL_RPATH=${CMAKE_STAGING_PREFIX}/lib"
        "-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=1"
      >
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip
    $<$<NOT:$<BOOL:${CMAKE_CROSSCOMPILING}>>:
      TEST_BEFORE_INSTALL 1
    >
  >
  $<$<BOOL:${ANDROID}>:
    CONFIGURE_COMMAND
      qmake "${SOURCE_DIR}"
        $<$<CONFIG:Debug>:"CONFIG += debug">
        $<$<CONFIG:Release>:"CONFIG += release">
    INSTALL_COMMAND
      make install INSTALL_ROOT="${BINARY_DIR}/PKG"
  >
  ]]
  
  PACKAGE [[
  $<$<NOT:$<BOOL:${ANDROID}>>:
    COMMAND "${CMAKE_COMMAND}" --build . --target package/fast
  >
  $<$<BOOL:${ANDROID}>:
    COMMAND sh -c
      "tty $<ANGLE-R>/dev/null | echo Cannot build signed package: `tty` $<ANGLE-R>&2 && tty $<ANGLE-R>/dev/null"
    COMMAND androiddeployqt
      --output "${BINARY_DIR}/PKG"
      --input "src/android-libMapper.so-deployment-settings.json"
      --deployment "bundled"
      --gradle
      --verbose
      $<$<OR:$<CONFIG:Release>,$<CONFIG:RelWithDebInfo>>:--release>
      $<${EXPRESSION_BOOL_SIGN}:--sign "${KEYSTORE_URL}" "${KEYSTORE_ALIAS}">
  >
  ]]
)
