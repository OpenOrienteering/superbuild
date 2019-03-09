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

set(version        1.2.8.dfsg)
set(download_hash  SHA256=2caecc2c3f1ef8b87b8f72b128a03e61c307e8c14f5ec9b422ef7914ba75cf9f)
set(patch_version  ${version}-5)
set(patch_hash     SHA256=7b88f58d1bfe8e873b8362ede3d0bc569793decc60094189fad1a110599cdd95)

option(USE_SYSTEM_ZLIB "Use the system zlib if possible" ON)

set(test_system_zlib [[
	if(USE_SYSTEM_ZLIB)
		enable_language(C)
		find_package(ZLIB CONFIG QUIET)
		find_package(ZLIB MODULE QUIET)
		if(TARGET ZLIB::ZLIB)
			get_target_property(configurations ZLIB::ZLIB IMPORTED_CONFIGURATIONS)
			if(configurations)
				list(GET configurations 0 config)
				get_target_property(zlib_location ZLIB::ZLIB "IMPORTED_LOCATION_${config}")
			else()
				get_target_property(zlib_location ZLIB::ZLIB "IMPORTED_LOCATION")
			endif()
			string(FIND "${zlib_location}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
			if(NOT staging_prefix_start EQUAL 0)
				message(STATUS "Found ${SYSTEM_NAME} zlib: ${zlib_location}")
				set(BUILD_CONDITION 0)
			endif()
		elseif(NOT WIN32)
			message(FATAL_ERROR "Missing system zlib on ${SYSTEM_NAME}")
		endif()
	endif()
]])

superbuild_package(
  NAME           zlib-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${SUPERBUILD_DEBIAN_BASE_URL_2017_06}/pool/main/z/zlib/zlib_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)

superbuild_package(
  NAME           zlib
  VERSION        ${patch_version}
  DEPENDS
    source:zlib-patches-${patch_version}
  
  SOURCE
    URL            ${SUPERBUILD_DEBIAN_BASE_URL_2017_06}/pool/main/z/zlib/zlib_${version}.orig.tar.gz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=zlib-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
    COMMAND
      ${CMAKE_COMMAND} -E
        echo "set_target_properties(zlib zlibstatic PROPERTIES OUTPUT_NAME z)"
          >> "<SOURCE_DIR>/CMakeLists.txt"
  
  USING            USE_SYSTEM_ZLIB patch_version
  BUILD_CONDITION  ${test_system_zlib}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      -UCMAKE_STAGING_PREFIX # Has quirks with zlib sources
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast -- DESTDIR=${DESTDIR}${INSTALL_DIR}
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../zlib-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/zlib-${patch_version}.txt"
  ]]
)
