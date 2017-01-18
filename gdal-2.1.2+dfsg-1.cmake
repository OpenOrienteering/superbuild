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

set(version        2.1.2+dfsg)
set(download_hash  MD5=b7b7387130c32a4a4e88e7b4145438bc)
set(patch_version  ${version}-1)
set(patch_hash     MD5=b99ef2e37273773fe8f6ea8234d2bfdb)

if(APPLE)
	set(copy_dir cp -aR)
else()
	set(copy_dir cp -auT)
endif()

option(USE_SYSTEM_GDAL "Use the system GDAL if possible" ON)

set(test_system_gdal [[
	if(${USE_SYSTEM_GDAL})
		enable_language(C)
		find_package(GDAL 2 NO_CMAKE_FIND_ROOT_PATH QUIET)
		if(GDAL_FOUND)
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           gdal-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            http://http.debian.net/debian/pool/main/g/gdal/gdal_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           gdal
  VERSION        ${patch_version}
  DEPENDS
    source:gdal-patches-${patch_version}
    curl
    libjpeg
    liblzma
    libpng
    pcre3
    proj
    sqlite3
    tiff
    zlib
  
  SOURCE
    URL            http://http.debian.net/debian/pool/main/g/gdal/gdal_${version}.orig.tar.gz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=gdal-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING            USE_SYSTEM_GDAL copy_dir
  BUILD_CONDITION  ${test_system_gdal}
  BUILD [[
    CONFIGURE_COMMAND
      "${CMAKE_COMMAND}" -E make_directory "${BINARY_DIR}"
    COMMAND
      ${copy_dir} "${SOURCE_DIR}/" "${BINARY_DIR}"
    COMMAND
      "${BINARY_DIR}/configure"
        "--prefix=${CMAKE_INSTALL_PREFIX}"
        $<$<BOOL:${CMAKE_CROSSCOMPILING}>:
          --host=${SUPERBUILD_TOOLCHAIN_TRIPLET}
        >
        --disable-static
        --enable-shared
        --with-hide-internal-symbols
        --with-rename-internal-libtiff-symbols
        --without-threads
        --with-liblzma
        --with-pcre
        "--with-curl=${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}/bin/curl-config"
        "--with-jpeg=${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}"
        "--with-libtiff=${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}"
        "--with-libz=${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}"
        "--with-png=${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}"
        "--with-sqlite3=${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}"
        --without-expat
        --without-geos
        --without-grib
        --without-java
        --without-jpeg12
        --without-netcdf
        --without-odbc
        --without-ogdi
        --without-pcraster
        --without-perl
        --without-pg
        --without-php
        --without-python
        --without-xerces
        --without-xml2
        "CPPFLAGS=-I${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}/include"
        "LDFLAGS=-L${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}/lib"
        "PKG_CONFIG="
    BUILD_COMMAND
      "$(MAKE)" USER_DEFS=-Wno-format   # no missing-sentinel warnings
    INSTALL_COMMAND
      "$(MAKE)" install "DESTDIR=${INSTALL_DIR}"
  ]]
)
