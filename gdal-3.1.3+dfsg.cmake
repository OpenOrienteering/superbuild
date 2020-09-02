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

set(version        3.1.3~rc1+dfsg)
set(download_hash  SHA256=b8f1776183ab25e7e99c8aa36f1274b484bf3e51ec2de8786a2da0309e6fd774)
set(patch_version  3.1.3-rc1+dfsg-1+exp1)
set(patch_hash     SHA256=176d31d5e9a4a622f5a73949ac5edf77de4945fe4f9766df91650e5a7d6432a0)
set(base_url       https://snapshot.debian.org/archive/debian/20200901T150453Z/pool/main/g/gdal/)

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
		
		find_path(SQLITE3_INCLUDE_DIR NAMES sqlite3.h QUIET)
		if(NOT SQLITE3_INCLUDE_DIR)
			message(FATAL_ERROR "Could not find sqlite3.h")
		endif()
		get_filename_component(SQLITE3_DIR "${SQLITE3_INCLUDE_DIR}" DIRECTORY CACHE)
	endif(BUILD_CONDITION)
	
	set(extra_cflags   "-Wno-strict-overflow -Wno-null-dereference" PARENT_SCOPE)
	set(extra_cxxflags "-Wno-strict-overflow -Wno-null-dereference -Wno-old-style-cast" PARENT_SCOPE)
]])

superbuild_package(
  NAME           gdal-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}gdal_3.1.3~rc1+dfsg-1~exp1.debian.tar.xz
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
    giflib
    libiconv
    libjpeg
    liblzma
    libpng
    libwebp
    openjpeg2
    pcre3
    pkg-config
    poppler
    proj
    sqlite3
    tiff
    zlib
  
  SOURCE
    URL            ${base_url}gdal_${version}.orig.tar.xz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=gdal-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING            USE_SYSTEM_GDAL patch_version extra_cflags extra_cxxflags
  BUILD_CONDITION  ${test_system_gdal}
  BUILD [[
    # Cannot do out-of-source build of gdal
    CONFIGURE_COMMAND
      "${CMAKE_COMMAND}" -E make_directory "${BINARY_DIR}"
    COMMAND
      "${CMAKE_COMMAND}" -E copy_directory "${SOURCE_DIR}" "${BINARY_DIR}"
    COMMAND
      "${BINARY_DIR}/configure"
        "--prefix=${CMAKE_INSTALL_PREFIX}"
        $<$<BOOL:@CMAKE_CROSSCOMPILING@>:
          --host=${SUPERBUILD_TOOLCHAIN_TRIPLET}
        >
        --disable-static
        --enable-shared
        --with-hide-internal-symbols
        --with-rename-internal-libtiff-symbols
        --with-threads
        "--with-curl=${CURL_CONFIG}"
        "--with-expat=${EXPAT_DIR}"
        --with-gif
        --with-jpeg
        --with-liblzma
        --with-libtiff
        --with-poppler
        --with-webp
        --with-libz
        --with-openjpeg
        --with-pcre
        --with-png
        --with-proj
        "--with-sqlite3=${SQLITE3_DIR}"
        --without-geos
        --without-java
        --without-jpeg12
        --without-libkml
        --without-netcdf
        --without-odbc
        --without-ogdi
        --without-pcraster
        --without-perl
        --without-pg
        --without-python
        --without-xerces
        --without-xml2
        --without-zstd
      $<$<STREQUAL:@CMAKE_SYSTEM_NAME@,Windows>:
        --without-crypto
      > # Windows
        "CC=${SUPERBUILD_CC}"
        "CXX=${SUPERBUILD_CXX}"
        "CPPFLAGS=${SUPERBUILD_CPPFLAGS}"
        "CFLAGS=${SUPERBUILD_CFLAGS} ${extra_cflags}"
        "CXXFLAGS=${SUPERBUILD_CXXFLAGS} ${extra_cxxflags}"
        "LDFLAGS=${SUPERBUILD_LDFLAGS}"
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
