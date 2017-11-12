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

# https://tracker.debian.org/pkg/gdal

set(version        2.2.2+dfsg)
set(download_hash  SHA256=1a63e1ece046f3abf5490cdbe441a4889a7d2028709459d0154e04d60c7f1109)
set(patch_version  ${version}-2)
set(patch_hash     SHA256=d221d2bbdd3abb3f84dccb979be1420b97295a5bf1b372022226d584556bb714)

if(APPLE)
	set(copy_dir cp -aR)
else()
	set(copy_dir cp -auT)
endif()

option(USE_SYSTEM_GDAL "Use the system GDAL if possible" ON)

set(test_system_gdal [[
	if(USE_SYSTEM_GDAL)
		enable_language(C)
		find_package(GDAL 2 QUIET)
		if(GDAL_FOUND
		   AND NOT GDAL_INCLUDE_DIR MATCHES "${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}")
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
		
		if(WIN32)
			# The PROJ4 DLL from the superbuild is named like libproj_4_9.dll,
			# but GDAL expects a name like libproj-0.dll
			# (exactly this name when loading the lib at runtime).
			# Try hard to link the correct library, at build time.
			find_package(PROJ4 CONFIG QUIET)
			if(NOT TARGET proj)
				message(FATAL_ERROR "Could not find PROJ4")
			endif()
			get_target_property(proj4_configurations proj IMPORTED_CONFIGURATIONS)
			list(GET proj4_configurations 0 config)
			get_target_property(proj4_lib proj IMPORTED_IMPLIB_${config})
			get_filename_component(proj4_lib "${proj4_lib}" NAME)
			get_filename_component(proj4_lib "${proj4_lib}" NAME_WE)
			string(REPLACE "libproj" "proj" proj4_lib "${proj4_lib}")
		else()
			set(proj4_lib proj)
		endif()
		set(PROJ4_LIB "${proj4_lib}" CACHE STRING "internal" FORCE)
	endif(BUILD_CONDITION)
]])

superbuild_package(
  NAME           gdal-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${SUPERBUILD_DEBIAN_BASE_URL_2017_11}/pool/main/g/gdal/gdal_${patch_version}.debian.tar.xz
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
    URL            ${SUPERBUILD_DEBIAN_BASE_URL_2017_11}/pool/main/g/gdal/gdal_${version}.orig.tar.xz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=gdal-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING            USE_SYSTEM_GDAL copy_dir patch_version
  BUILD_CONDITION  ${test_system_gdal}
  BUILD [[
    CONFIGURE_COMMAND
      "${CMAKE_COMMAND}" -E make_directory "${BINARY_DIR}"
    COMMAND
      ${copy_dir} "${SOURCE_DIR}/" "${BINARY_DIR}"
    COMMAND
      # Insert another library name if needed (MinGW)
      sed -i -e "/ PROJ_LIB=/ s,-lproj[-_0-9]*,-l$${}{PROJ4_LIB}," "${BINARY_DIR}/configure"
    COMMAND
      # Remove duplicate -lproj
      sed -i -e "/LIBS=/ s,-lproj ,," "${BINARY_DIR}/configure"
    $<$<BOOL:${ANDROID}>:
    COMMAND
      # Fix .so versioning
      sed -i -e "/ -avoid-version/! s,^LD.*=.*LIBTOOL_LINK.*,& -avoid-version," "${BINARY_DIR}/GDALmake.opt.in"
    COMMAND
      # Android NDK STL quirk
      sed -i -e "/__sun__/ s,#if .*,#if 1," "${BINARY_DIR}/ogr/ogrsf_frmts/cad/libopencad/dwg/r2000.cpp"
                                            "${BINARY_DIR}/ogr/ogrsf_frmts/cad/libopencad/cadheader.cpp"
    >
    $<$<NOT:$<CONFIG:Debug>>:
    COMMAND
      # Strip library
      sed -i -e "/ -s/! s,^INSTALL_LIB.*=.*LIBTOOL_INSTALL.*,& -s," "${BINARY_DIR}/GDALmake.opt.in"
    >
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
        --with-static-proj4
        "--with-curl=$${}{CURL_CONFIG}"
        "--with-expat=$${}{EXPAT_DIR}"
        "--with-jpeg=${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}"
        "--with-libtiff=${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}"
        "--with-libz=$${}{LIBZ_DIR}"
        "--with-png=${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}"
        "--with-sqlite3=$${}{SQLITE3_DIR}"
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
        $<$<BOOL:${ANDROID}>:
          "LIBS=-lgnustl_shared"
        >
        "PKG_CONFIG="
    BUILD_COMMAND
      "$(MAKE)" USER_DEFS=-Wno-format   # no missing-sentinel warnings
    $<$<BOOL:${WIN32}>:
    COMMAND
      # Verify that libgdal is linked to libproj
      "$<$<BOOL:${CMAKE_CROSSCOMPILING}>:${SYSTEM_NAME}->objdump" -x .libs/libgdal-20.dll
        | grep "DLL Name: libproj"
    >
    INSTALL_COMMAND
      "$(MAKE)" install "DESTDIR=${INSTALL_DIR}"
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../gdal-patches-${patch_version}/copyright"
        "${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}/share/doc/copyright/gdal-${patch_version}.txt"
  ]]
)
