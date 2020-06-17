# This file is part of OpenOrienteering.

# Copyright 2020 Kai Pastor
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

set(version        1.1.0)
set(download_hash  SHA256=98a052268cc4d5ece27f76572a7f50293f439c17a98e67c4ea0c7ed6f50ef043)
set(patch_version  ${version})

option(USE_SYSTEM_LIBWEBP "Use the system LIBWEBP if possible" ON)

set(test_system_libwebp [[
	if(${USE_SYSTEM_LIBWEBP})
		enable_language(C)
		find_library(LIBWEBP_LIBRARY NAMES webp QUIET)
		string(FIND "${LIBWEBP_LIBRARY}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(LIBWEBP_LIBRARY AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} LIBWEBP: ${LIBWEBP_LIBRARY}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           libwebp
  VERSION        ${patch_version}
  DEPENDS
    giflib
    libjpeg-turbo
    libpng
    zlib
  
  SOURCE
    URL            https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${version}.tar.gz
    URL_HASH       ${download_hash}
  
  USING            USE_SYSTEM_LIBWEBP patch_version
  BUILD_CONDITION  ${test_system_libwebp}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      -DBUILD_SHARED_LIBS=ON
      -DWEBP_BUILD_ANIM_UTILS=OFF
      -DWEBP_BUILD_CWEBP=OFF
      -DWEBP_BUILD_DWEBP=OFF
      -DWEBP_BUILD_GIF2WEBP=OFF
      -DWEBP_BUILD_IMG2WEBP=OFF
      -DWEBP_BUILD_VWEBP=OFF
      -DWEBP_BUILD_WEBPINFO=OFF
      -DWEBP_BUILD_WEBPMUX=OFF
      -DWEBP_BUILD_EXTRAS=OFF
      -DWEBP_BUILD_WEBP_JS=OFF
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/COPYING"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/libwebp-${patch_version}.txt"
  ]]
)
