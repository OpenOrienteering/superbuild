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

set(version        1.6.34)
set(download_hash  SHA256=2f1e960d92ce3b3abd03d06dfec9637dfbd22febf107a536b44f7a47c60659f6)
set(patch_version  ${version}-1)
set(patch_hash     SHA256=8ca33d2930b340412f04d76cac3159f6b3b823cff33b35b72426a75f3f02a8a0)
set(patch_base_url ${SUPERBUILD_DEBIAN_BASE_URL_2018_02})

option(USE_SYSTEM_LIBPNG "Use the system libpng if possible" ON)

set(test_system_png [[
	if(USE_SYSTEM_LIBPNG)
		enable_language(C)
		find_package(PNG CONFIG QUIET)
		find_package(PNG MODULE QUIET)
		if(TARGET PNG::PNG)
			get_target_property(configurations PNG::PNG IMPORTED_CONFIGURATIONS)
			if(configurations)
				list(GET configurations 0 config)
				get_target_property(png_location PNG::PNG "IMPORTED_LOCATION_${config}")
			else()
				get_target_property(png_location PNG::PNG "IMPORTED_LOCATION")
			endif()
			string(FIND "${png_location}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
			if(NOT staging_prefix_start EQUAL 0)
				message(STATUS "Found ${SYSTEM_NAME} libpng: ${png_location}")
				set(BUILD_CONDITION 0)
			endif()
		endif()
	endif()
]])

superbuild_package(
  NAME           libpng1.6-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${patch_base_url}/pool/main/libp/libpng1.6/libpng1.6_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)

superbuild_package(
  NAME           libpng1.6
  VERSION        ${patch_version}
  DEPENDS
    source:libpng1.6-patches-${patch_version}
    common-licenses
    zlib
  
  SOURCE
    URL            ${SUPERBUILD_DEBIAN_BASE_URL_2018_02}/pool/main/libp/libpng1.6/libpng1.6_${version}.orig.tar.xz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=libpng1.6-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
    COMMAND
      # Enable determining CMAKE_ASM_COMPILER from CMAKE_C_COMPILER.
      # Fixed in libpng > 1.6.34.
      sed -i -e "s,project(libpng ASM C),project(libpng C ASM)," CMakeLists.txt
    COMMAND
      # AWK is not used for ANDROID builds.
      sed -i -e "s,if(UNIX AND AWK),if(UNIX AND AWK AND NOT ANDROID)," CMakeLists.txt
  
  USING            USE_SYSTEM_LIBPNG patch_version
  BUILD_CONDITION  ${test_system_png}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DPNG_STATIC=0"
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../libpng1.6-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/libpng1.6-${patch_version}.txt"
  ]]
)

superbuild_package(
  NAME           libpng
  VERSION        ${patch_version}
  DEPENDS        libpng1.6
)
