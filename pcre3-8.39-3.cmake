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

set(version        8.39)
set(download_hash  SHA256=b858099f82483031ee02092711689e7245586ada49e534a06e678b8ea9549e8b)
set(patch_version  ${version}-3)
set(patch_hash     SHA256=a9f0e1a96b6a017965fe69233e267682c289f2cfeb33b46fb78aedcb8cf2c16a)

option(USE_SYSTEM_PCRE3 "Use the system pcre3 if possible" ON)

set(test_system_pcre3 [[
	if(USE_SYSTEM_PCRE3)
		enable_language(C)
		find_library(PCRE3_LIBRARY NAMES pcre QUIET)
		find_path(PCRE3_INCLUDE_DIR NAMES pcre.h QUIET)
		string(FIND "${PCRE3_INCLUDE_DIR}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(PCRE3_LIBRARY AND PCRE3_INCLUDE_DIR AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} pcre3: ${PCRE3_LIBRARY}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           pcre3-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${SUPERBUILD_DEBIAN_BASE_URL_2017_06}/pool/main/p/pcre3/pcre3_${patch_version}.debian.tar.gz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           pcre3
  VERSION        ${patch_version}
  DEPENDS
    source:pcre3-patches-${patch_version}
  
  SOURCE
    URL            ${SUPERBUILD_DEBIAN_BASE_URL_2017_06}/pool/main/p/pcre3/pcre3_${version}.orig.tar.bz2
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=pcre3-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
    COMMAND
      sed -i -e "/INSTALL/ s,DESTINATION man,DESTINATION share/man," CMakeLists.txt
  
  USING            USE_SYSTEM_PCRE3 patch_version
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
      "${CMAKE_COMMAND}" --build . --target install/strip/fast
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../pcre3-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/pcre3-${patch_version}.txt"
  ]]
)
