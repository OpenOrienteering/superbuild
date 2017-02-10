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

set(version        8.35)
set(download_hash  MD5=ed58bcbe54d3b1d59e9f5415ef45ce1c)
set(patch_version  ${version}-3.3+deb8u4)
set(patch_hash     MD5=ea36f15f106f19cfad8ea0896606c11c)

option(USE_SYSTEM_PCRE3 "Use the system sqlite if possible" ON)

set(test_system_pcre3 [[
	if(USE_SYSTEM_PCRE3)
		enable_language(C)
		find_library(PCRE3_LIBRARY NAMES pcre QUIET)
		find_path(PCRE3_INCLUDE_DIR NAMES pcre.h QUIET)
		if(PCRE3_LIBRARY AND PCRE3_INCLUDE_DIR)
			message(STATUS "Found pcre3: ${PCRE3_LIBRARY}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           pcre3-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            http://http.debian.net/debian/pool/main/p/pcre3/pcre3_${patch_version}.debian.tar.gz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           pcre3
  VERSION        ${patch_version}
  DEPENDS
    source:pcre3-patches-${patch_version}
  
  SOURCE
    URL            http://http.debian.net/debian/pool/main/p/pcre3/pcre3_${version}.orig.tar.gz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=pcre3-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING            USE_SYSTEM_PCRE3
  BUILD_CONDITION  ${test_system_pcre3}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DCMAKE_BUILD_TYPE:STRING=$<CONFIG>"
      "-DBUILD_SHARED_LIBS:BOOL=ON"
      "-DPCRE_BUILD_PCRE16:BOOL=ON"
      "-DPCRE_BUILD_PCRE32:BOOL=ON"
      "-DPCRE_SUPPORT_UTF:BOOL=ON"
      "-DPCRE_SUPPORT_UNICODE_PROPERTIES:BOOL=ON"
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip -- "DESTDIR=${INSTALL_DIR}"
  ]]
)
