# This file is part of OpenOrienteering.

# Copyright 2016-2019 Kai Pastor
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

set(version        0.8.4)
set(download_hash  SHA256=d39c05a84ad222ed278231c89c353174f35682c79f92467cb08d8f101debd8fd)
set(qt_version     5.6.2)

set(Mapper_LICENSING_PROVIDER "superbuild" CACHE STRING "Mapper: Provider for 3rd-party licensing information")

superbuild_package(
  NAME           openorienteering-mapper
  VERSION        ${version}
  DEPENDS
    gdal-2.2.3+dfsg-2
    libpolyclipping-6.4.2-3
    proj-4.9.3-1
    qtandroidextras-${qt_version}
    qtbase-${qt_version}
    qtimageformats-${qt_version}
    qtlocation-${qt_version}
    qtsensors-${qt_version}
    qttools-${qt_version}
    qttranslations-${qt_version}
    zlib-1.2.8.dfsg-5
    host:doxygen-1.8.13
    host:qttools-${qt_version}
  
  SOURCE
    DOWNLOAD_NAME  openorienteering-mapper_${version}.tar.gz
    URL            https://github.com/OpenOrienteering/mapper/archive/v${version}.tar.gz
    URL_HASH       ${download_hash}
  
  USING            Mapper_LICENSING_PROVIDER
  BUILD_CONDITION [[
    if(NOT CMAKE_BUILD_TYPE MATCHES "Rel")
        message(FATAL_ERROR "Not building a release configuration")
    endif()
  ]]
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-UCMAKE_STAGING_PREFIX"
      "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
      "-DBUILD_SHARED_LIBS=0"
      "-DMapper_AUTORUN_SYSTEM_TESTS=0"
      "-DLICENSING_PROVIDER=superbuild"
      "-DMapper_BUILD_PACKAGE=1"
    $<$<BOOL:@ANDROID@>:
      "-DCMAKE_DISABLE_FIND_PACKAGE_Qt5PrintSupport=TRUE"
      "-DKEYSTORE_URL=${KEYSTORE_URL}"
      "-DKEYSTORE_ALIAS=${KEYSTORE_ALIAS}"
    >
    $<$<NOT:$<BOOL:@ANDROID@>>:
      "-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Positioning=TRUE"
      "-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Sensors=TRUE"
    >
    $<$<BOOL:@CMAKE_CROSSCOMPILING@>:
      "-DCMAKE_PROGRAM_PATH=@HOST_DIR@/bin"
    >
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/fast -- VERBOSE=1
        # Mapper Windows installation layout is weird
        "DESTDIR=${DESTDIR}${INSTALL_DIR}$<$<BOOL:@WIN32@>:/OpenOrienteering>"
  $<$<NOT:$<BOOL:@CMAKE_CROSSCOMPILING@>>:
    TEST_BEFORE_INSTALL 1
  >
  ]]
  
  EXECUTABLES src/Mapper
  
  PACKAGE [[
    COMMAND "${CMAKE_COMMAND}" --build . --target package/fast
  ]]
)
