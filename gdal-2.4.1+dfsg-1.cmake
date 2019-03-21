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

# https://tracker.debian.org/pkg/gdal

set(version        2.4.1+dfsg)
set(download_hash  SHA256=9c3c3a4b6940e78f65a52e0aa31a8e0e3b2c1cacd209e9397d74a262ad969909)
set(patch_version  ${version}-1)
set(patch_hash     SHA256=152477e4ad03d0483414bb55fa5c0cb0e314456426275acedf18745092eab56e)
set(base_url       https://snapshot.debian.org/archive/debian/20190322T212047Z/pool/main/g/gdal)

option(USE_SYSTEM_GDAL "Use the system GDAL if possible" ON)

set(test_system_gdal [[
	if(USE_SYSTEM_GDAL)
		enable_language(C)
		find_package(GDAL 2 QUIET)
		string(FIND "${GDAL_INCLUDE_DIR}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(GDAL_FOUND AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} gdal: ${GDAL_LIBRARY}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
	
	if(BUILD_CONDITION)
		find_program(CURL_CONFIG NAMES curl-config QUIET CMAKE_FIND_ROOT_PATH_BOTH)
		if(NOT CURL_CONFIG)
			message(FATAL_ERROR "Could not find curl-config")
		endif()
		
		find_path(EXPAT_INCLUDE_DIR NAMES expat.h QUIET)
		if(NOT EXPAT_INCLUDE_DIR)
			message(FATAL_ERROR "Could not find expat.h")
		endif()
		get_filename_component(EXPAT_DIR "${EXPAT_INCLUDE_DIR}" DIRECTORY CACHE)
		
		find_path(LIBZ_INCLUDE_DIR NAMES zlib.h QUIET)
		if(NOT LIBZ_INCLUDE_DIR)
			message(FATAL_ERROR "Could not find zlib.h")
		endif()
		get_filename_component(LIBZ_DIR "${LIBZ_INCLUDE_DIR}" DIRECTORY CACHE)
		
		find_path(SQLITE3_INCLUDE_DIR NAMES sqlite3.h QUIET)
		if(NOT SQLITE3_INCLUDE_DIR)
			message(FATAL_ERROR "Could not find sqlite3.h")
		endif()
		get_filename_component(SQLITE3_DIR "${SQLITE3_INCLUDE_DIR}" DIRECTORY CACHE)
	endif(BUILD_CONDITION)
]])


superbuild_package(
  NAME           gdal-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}/gdal_${patch_version}~exp1.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           gdal
  VERSION        ${patch_version}
  DEPENDS
    source:gdal-patches-${patch_version}
    common-licenses
    curl
    expat
    libjpeg
    liblzma
    libpng
    pcre3
    proj
    sqlite3
    tiff
    zlib
  
  SOURCE
    URL            ${base_url}/gdal_${version}.orig.tar.xz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=gdal-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING            USE_SYSTEM_GDAL patch_version
  BUILD_CONDITION  ${test_system_gdal}
  BUILD [[
    # Cannot do out-of-source build of gdal
    UPDATE_COMMAND
      "${CMAKE_COMMAND}" -E make_directory "${BINARY_DIR}"
    COMMAND
      "${CMAKE_COMMAND}" -E copy_directory "${SOURCE_DIR}" "${BINARY_DIR}"
    CONFIGURE_COMMAND
      "${BINARY_DIR}/configure"
        "--prefix=${CMAKE_INSTALL_PREFIX}"
        $<$<BOOL:@CMAKE_CROSSCOMPILING@>:
          --host=${SUPERBUILD_TOOLCHAIN_TRIPLET}
        >
        --disable-static
        --enable-shared
        --with-hide-internal-symbols
        --with-rename-internal-libtiff-symbols
        --without-threads
        --with-liblzma
        --with-pcre
        "--with-curl=${CURL_CONFIG}"
        "--with-expat=${EXPAT_DIR}"
        "--with-jpeg=${CMAKE_STAGING_PREFIX}"
        "--with-libtiff=${CMAKE_STAGING_PREFIX}"
        $<$<NOT:$<BOOL:@ANDROID@>>:
          "--with-libz=${LIBZ_DIR}"
        >
        "--with-png=${CMAKE_STAGING_PREFIX}"
        "--with-proj=${CMAKE_STAGING_PREFIX}"
        "--with-sqlite3=${SQLITE3_DIR}"
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
        --without-python
        --without-xerces
        --without-xml2
        "CPPFLAGS=${SUPERBUILD_CPPFLAGS}"
        "CFLAGS=${SUPERBUILD_CFLAGS}"
        "CXXFLAGS=${SUPERBUILD_CXXFLAGS}"
        "LDFLAGS=${SUPERBUILD_LDFLAGS}"
        "PKG_CONFIG="
        $<$<BOOL:@ANDROID@>:
          "CC=${STANDALONE_C_COMPILER}"
          "CXX=${STANDALONE_CXX_COMPILER}"
        >
    BUILD_COMMAND
      "$(MAKE)"
    INSTALL_COMMAND
      "$(MAKE)" install "DESTDIR=${DESTDIR}${INSTALL_DIR}"
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../gdal-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/gdal-${patch_version}.txt"
  ]]
)
