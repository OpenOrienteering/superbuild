# This file is part of OpenOrienteering.

# Copyright 2017-2020 Kai Pastor
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

set(version        3.16.3)
set(download_hash  SHA256=e54f16df9b53dac30fd626415833a6e75b0e47915393843da1825b096ee60668)
set(patch_version  ${version}-3)
set(patch_hash     SHA256=c377b41d9a03325fdb000efff639442da7a4f6cfeb5654403676fdd241416299)
set(base_url       https://snapshot.debian.org/archive/debian/20200509T144303Z/pool/main/c/cmake/)

option(USE_SYSTEM_CMAKE "Use the system CMake if possible" ON)

set(test_system_cmake [[
	if(USE_SYSTEM_CMAKE)
		if(NOT CMAKE_VERSION VERSION_LESS "${version}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           cmake-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}/cmake_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           cmake
  VERSION        ${patch_version}
  DEPENDS        source:cmake-patches-${patch_version}
                 curl
                 expat
                 xz-utils
                 zlib
  
  SOURCE
    URL            ${base_url}cmake_${version}.orig.tar.gz
    URL_HASH       ${download_hash}
  
  USING            USE_SYSTEM_CMAKE
                   patch_version
  BUILD_CONDITION  ${test_system_cmake}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../cmake-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/cmake-${patch_version}.txt"
  ]]
)
