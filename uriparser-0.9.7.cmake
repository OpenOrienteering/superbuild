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

set(version        0.9.7+dfsg)
set(download_hash  SHA256=f7e51d6be4d7830d377433bc740e450cf0e9fea316ada0403f8080a02bfb1e38)
set(patch_version  ${version}-2)
set(patch_hash     SHA256=d013e86dfc0626978894f2d4bc41e8fd4d3dde26ca2aab4739cf4b3755bf3373)
set(base_url       https://snapshot.debian.org/archive/debian/20230202T212152Z/pool/main/u/uriparser/)

option(USE_SYSTEM_URIPARSER "Use the system uriparser if possible" ON)

set(test_system_uriparser [[
	if(${USE_SYSTEM_URIPARSER})
		enable_language(C)
		find_library(URIPARSER_LIBRARY NAMES uriparser QUIET)
		find_path(URIPARSER_INCLUDE_DIR NAMES uriparser/Uri.h QUIET)
		string(FIND "${URIPARSER_LIBRARY}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(URIPARSER_LIBRARY AND URIPARSER_INCLUDE_DIR AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} uriparser: ${URIPARSER_LIBRARY}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           uriparser-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}uriparser_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           uriparser
  VERSION        ${patch_version}
  DEPENDS
    source:uriparser-patches-${patch_version}
    googletest
    zlib
  
  SOURCE
    URL            ${base_url}uriparser_${version}.orig.tar.xz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=uriparser-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
    COMMAND
      sed -e "s/WSAAPI inet_ntop/WSAAPI inet_ntop_UNUSED/" -i -- tool/uriparse.c
  
  USING            USE_SYSTEM_URIPARSER patch_version
  BUILD_CONDITION  ${test_system_uriparser}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DCMAKE_BUILD_TYPE:STRING=$<CONFIG>"
      -DBUILD_SHARED_LIBS=ON
      -DURIPARSER_BUILD_DOCS=OFF
      $<$<BOOL:@CMAKE_CROSSCOMPILING@>:
        -DURIPARSER_BUILD_TESTS=OFF
        -DURIPARSER_BUILD_TOOLS=OFF
      >
   INSTALL_COMMAND
     "${CMAKE_COMMAND}" --build . --target install/strip/fast
   COMMAND
     "${CMAKE_COMMAND}" -E copy
       "<SOURCE_DIR>/../uriparser-patches-${patch_version}/copyright"
       "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/uriparser-${patch_version}.txt"
  ]]
)
