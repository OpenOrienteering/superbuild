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

set(version        master)
set(qt_version     5.6.2)

set(Mapper_VERSION_DISPLAY 0 CACHE STRING "Mapper: Custom version display string")
set(Mapper_LICENSING_PROVIDER "superbuild" CACHE STRING "Mapper: Provider for 3rd-party licensing information")
option(Mapper_ENABLE_POSITIONING "Mapper: Enable positioning" OFF)
option(Mapper_MANUAL_PDF "Mapper: Provide the manual as PDF file (needs pdflatex)" OFF)

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
  
  USING            Mapper_VERSION_DISPLAY
                   Mapper_LICENSING_PROVIDER
                   Mapper_ENABLE_POSITIONING
                   Mapper_MANUAL_PDF
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-UCMAKE_STAGING_PREFIX"
      "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
      "-DBUILD_SHARED_LIBS=0"
      "-DMapper_AUTORUN_SYSTEM_TESTS=0"
      "-DLICENSING_PROVIDER=${Mapper_LICENSING_PROVIDER}"
      "-DMapper_BUILD_PACKAGE=1"
      "-DMapper_VERSION_DISPLAY=${Mapper_VERSION_DISPLAY}"
      "-DMapper_MANUAL_PDF=$<BOOL:${Mapper_MANUAL_PDF}>"
    $<$<BOOL:@ANDROID@>:
      "-DCMAKE_DISABLE_FIND_PACKAGE_Qt5PrintSupport=TRUE"
      "-DKEYSTORE_URL=${KEYSTORE_URL}"
      "-DKEYSTORE_ALIAS=${KEYSTORE_ALIAS}"
    >
    $<$<NOT:$<OR:$<BOOL:@ANDROID@>,$<BOOL:@Mapper_ENABLE_POSITIONING@>>>:
      "-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Positioning:BOOL=TRUE"
      "-UQt5Positioning_DIR"
      "-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Sensors:BOOL=TRUE"
      "-UQt5Sensors_DIR"
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
