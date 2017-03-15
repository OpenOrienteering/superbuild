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
  
  BUILD [[
    CONFIGURE_COMMAND
    $<$<AND:$<BOOL:${UNIX}>,$<NOT:$<BOOL:${APPLE}>>,$<NOT:$<BOOL:${ANDROID}>>>:
      "${CMAKE_COMMAND}" -E env
        "LDFLAGS=-Wl,--as-needed"
    > # UNIX AND NOT APPLE AND NOT ANDROID
      "${CMAKE_COMMAND}" "${SOURCE_DIR}"
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
      "-DBUILD_SHARED_LIBS=0"
      "-DMapper_AUTORUN_SYSTEM_TESTS=0"
      "-DMapper_BUILD_CLIPPER=0"
      "-DMapper_BUILD_GDAL=0"
      "-DMapper_BUILD_PROJ=0"
      "-DMapper_BUILD_QT=0"
      "-DMapper_BUILD_DOXYGEN=0"
      "-DMapper_USE_GDAL=1"
      "-DMapper_BUILD_PACKAGE=1"
    $<$<OR:$<BOOL:${APPLE}>,$<BOOL:${WINDOWS}>>:
        "-DMapper_PACKAGE_ASSISTANT=1"
    >$<$<NOT:$<OR:$<BOOL:${APPLE}>,$<BOOL:${WINDOWS}>>>:
        "-DMapper_PACKAGE_ASSISTANT=0"
    >
        "-DMapper_PACKAGE_GDAL=1"
        "-DGDAL_DATA_DIR=${INSTALL_DIR}"
        "-DMapper_PACKAGE_PROJ=1"
        "-DMapper_PACKAGE_QT=1"
        "-DMAPPER_USE_QT_CONF_QRC=0"
    $<$<BOOL:ANDROID>:
      "-DKEYSTORE_URL=${KEYSTORE_URL}"
      "-DKEYSTORE_ALIAS=${KEYSTORE_ALIAS}"
    >
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip -- "DESTDIR=${INSTALL_DIR}/openorienteering"
  $<$<NOT:$<BOOL:${CMAKE_CROSSCOMPILING}>>:
    TEST_BEFORE_INSTALL 1
  >
  ]]
  
  EXECUTABLES src/Mapper
  
  PACKAGE [[
    COMMAND "${CMAKE_COMMAND}" --build . --target package/fast
  ]]
)
