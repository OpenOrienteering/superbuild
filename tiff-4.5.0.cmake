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

# https://tracker.debian.org/pkg/tiff

set(version        4.5.0)
set(download_hash  SHA256=638f43d7dea33948d5dee7f39572fc0194d9cc3c74195de9dd26a4388a1f880a)
set(patch_version  ${version}-6+deb12u1)
set(patch_hash     SHA256=d70ba897e15f135b7ed8cbc823490ca522c91ceff5e6a4c4274fc348219dcde0)
set(base_url       https://snapshot.debian.org/archive/debian/20231130T032551Z/pool/main/t/tiff/)

option(USE_SYSTEM_LIBTIFF "Use the system libtiff if possible" ON)

set(test_system_tiff [[
	if(USE_SYSTEM_LIBTIFF)
		enable_language(C)
		find_package(TIFF CONFIG QUIET)
		find_package(TIFF MODULE QUIET)
		if(TARGET TIFF::TIFF)
			get_target_property(configurations TIFF::TIFF IMPORTED_CONFIGURATIONS)
			if(configurations)
				list(GET configurations 0 config)
				get_target_property(tiff_location TIFF::TIFF "IMPORTED_LOCATION_${config}")
			else()
				get_target_property(tiff_location TIFF::TIFF "IMPORTED_LOCATION")
			endif()
			string(FIND "${tiff_location}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
			if(EXISTS "${tiff_location}" AND NOT staging_prefix_start EQUAL 0)
				message(STATUS "Found ${SYSTEM_NAME} libtiff: ${tiff_location}")
				set(BUILD_CONDITION 0)
			endif()
		endif()
	endif()
]])

set(extra_flags "-Wno-unused-parameter -Wno-unused-but-set-variable -Wno-tautological-constant-out-of-range-compare")

superbuild_package(
  NAME           tiff-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}tiff_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           tiff
  VERSION        ${patch_version}+openorienteering1
  DEPENDS
    source:tiff-patches-${patch_version}
    libjpeg
    liblzma
    libwebp
    zlib
  
  SOURCE
    URL            ${base_url}tiff_${version}.orig.tar.bz2
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=tiff-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
#[[
    COMMAND
      echo "\tTIFFReadRGBAStripExt" >> libtiff/libtiff.def
    COMMAND
      echo "\tTIFFReadRGBATileExt" >> libtiff/libtiff.def
    COMMAND
	  # Also on MinGW, rpcndr.h already defines `boolean`
      sed -e "s/ && !defined.__MINGW32__.//" -i -- test/raw_decode.c
    COMMAND
	  # Cannot silence warnings via CMAKE_C_FLAGS parameter
      sed -e "s/  -W$/-W ${extra_flags}/" -i -- CMakeLists.txt
]]
  
  USING            USE_SYSTEM_LIBTIFF patch_version
  BUILD_CONDITION  ${test_system_tiff}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DCMAKE_BUILD_TYPE:STRING=$<CONFIG>"
      # We don't provide all possible sources (yet)
      "-Djbig:BOOL=OFF"
      "-Dzstd:BOOL=OFF"
      $<$<BOOL:@ANDROID@>:
        -DJPEG_NAMES=jpeg-turbo
      >
      # GNUInstallDirs doesn't work with CMAKE_STAGING_PREFIX
      -UCMAKE_STAGING_PREFIX
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast -- "DESTDIR=${DESTDIR}${INSTALL_DIR}"
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../tiff-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/tiff-${patch_version}.txt"
  ]]
)
