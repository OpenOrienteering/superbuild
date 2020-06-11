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

set(version        10.32)
set(download_hash  SHA256=9ca9be72e1a04f22be308323caa8c06ebd0c51efe99ee11278186cafbc4fe3af)
set(patch_version  ${version}-5)
set(patch_hash     SHA256=bfe23d2661bf5727a10a1c1e49660c35afc0a4ad1c151bdcefb7c5a52e71e685)
set(base_url       https://snapshot.debian.org/archive/debian/20190326T041411Z/pool/main/p/pcre2)

option(USE_SYSTEM_PCRE2 "Use the system pcre2 if possible" ON)

set(test_system_pcre2 [[
	if(USE_SYSTEM_PCRE2)
		enable_language(C)
		find_library(PCRE2_LIBRARY NAMES pcre QUIET)
		find_path(PCRE2_INCLUDE_DIR NAMES pcre2.h QUIET)
		string(FIND "${PCRE2_INCLUDE_DIR}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(PCRE2_LIBRARY AND PCRE2_INCLUDE_DIR AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} pcre2: ${PCRE2_LIBRARY}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])


set(download_pcre2_diff_cmake "${PROJECT_BINARY_DIR}/download-pcre2_${patch_version}.diff.cmake")
file(WRITE "${download_pcre2_diff_cmake}" "
file(DOWNLOAD
  \"${base_url}/pcre2_${patch_version}.diff.gz\"
  \"${SUPERBUILD_DOWNLOAD_DIR}/pcre2_${patch_version}.diff.gz\"
  EXPECTED_HASH ${patch_hash}
)")


superbuild_package(
  NAME           pcre2
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}/pcre2_${version}.orig.tar.gz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}" -P "${download_pcre2_diff_cmake}"
    COMMAND
      gunzip -c "${SUPERBUILD_DOWNLOAD_DIR}/pcre2_${patch_version}.diff.gz" > "pcre2_${patch_version}.diff"
    COMMAND
      patch -N -p1 < "pcre2_${patch_version}.diff"
    COMMAND
      sed -i -e "/INSTALL/ s,DESTINATION man,DESTINATION share/man," CMakeLists.txt
  
  USING            USE_SYSTEM_PCRE2 patch_version
  BUILD_CONDITION  ${test_system_pcre2}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DCMAKE_BUILD_TYPE:STRING=$<CONFIG>"
      "-DBUILD_SHARED_LIBS:BOOL=ON"
      "-DPCRE2_BUILD_PCRE2_16:BOOL=ON"
      "-DPCRE2_BUILD_PCRE2_32:BOOL=ON"
      "-DPCRE2_BUILD_PCRE2GREP:BOOL=OFF"
      "-DPCRE_SUPPORT_UTF:BOOL=ON"
      "-DPCRE_SUPPORT_UNICODE_PROPERTIES:BOOL=ON"
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/debian/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/pcre2-${patch_version}.txt"
  ]]
)
