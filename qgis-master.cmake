# This file is part of OpenOrienteering.

# Copyright 2016-2020 Kai Pastor
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

# https://tracker.debian.org/pkg/gdal

set(version        master)
set(download_hash  SHA256=a06b47271827892f1897464c04a2a484f682f930d96b4d0329634512e973fe29)
set(patch_version  ${version})
set(patch_hash     SHA256=50314f747a4813566d0005b677f83eab50c5e2b32ce23e513830724d86ae5640)
set(base_url       https://github.com/qgis/QGIS/archive/)
set(QGIS_QT_VERSION 5.15)

superbuild_package(
  NAME           qgis
  VERSION        ${patch_version}
  DEPENDS
    common-licenses
    gdal
    geos
    libzip
    protobuf
    qtandroidextras-${QGIS_QT_VERSION}
    qtbase-${QGIS_QT_VERSION}
    qtimageformats-${QGIS_QT_VERSION}
    qtlocation-${QGIS_QT_VERSION}
    qtsensors-${QGIS_QT_VERSION}
    qttools-${QGIS_QT_VERSION}
    qttranslations-${QGIS_QT_VERSION}
  
  SOURCE
    URL            ${base_url}${version}.tar.gz
    URL_HASH       ${download_hash}
  
  USING            patch_version extra_cflags extra_cxxflags
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DCMAKE_BUILD_TYPE:STRING=$<CONFIG>"
      -DBUILD_SHARED_LIBS=ON
      -DUSE_THREAD=ON
      -DWITH_QTWEBKIT=OFF
    $<$<NOT:$<BOOL:@CMAKE_CROSSCOMPILING@>>:
      -DBUILD_TESTING=ON
    >
    $<$<BOOL:@CMAKE_CROSSCOMPILING@>:
      -DCMAKE_PROGRAM_PATH=${HOST_DIR}/bin # for sqlite3
      -DBUILD_TESTING=OFF
    >
    $<$<NOT:$<OR:$<BOOL:@CMAKE_CROSSCOMPILING@>,$<BOOL:@MSYS@>>>:
    TEST_COMMAND
      "${CMAKE_COMMAND}" -E env
        "PROJ_LIB=${DESTDIR}${CMAKE_STAGING_PREFIX}/share/proj"
        "${CMAKE_COMMAND}" --build . --target test
    TEST_AFTER_INSTALL
    >
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast
    COMMAND
      "${CMAKE_COMMAND}" -E copy_directory
        "<SOURCE_DIR>/../proj-patches-${patch_version}/data"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/proj"
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../proj-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/proj-${patch_version}.txt"
  ]]
)
