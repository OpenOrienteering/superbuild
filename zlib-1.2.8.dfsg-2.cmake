# This file is part of OpenOrienteering.

# Copyright 2016 Kai Pastor
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
set(download_hash  MD5=b752e88a9717131354bd07aa1e1c505d)
set(patch_version  ${version}-2)
set(patch_hash     MD5=33acd96a3311d6fe60d94b64427a296e)

option(USE_SYSTEM_ZLIB "Use the system zlib if possible" ON)

set(test_system_zlib [[
	if(${USE_SYSTEM_ZLIB})
		enable_language(C)
		find_package(ZLIB CONFIG NO_CMAKE_FIND_ROOT_PATH QUIET)
		find_package(ZLIB MODULE)
		if(TARGET ZLIB::ZLIB)
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           zlib-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            http://http.debian.net/debian/pool/main/z/zlib/zlib_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)

superbuild_package(
  NAME           zlib
  VERSION        ${patch_version}
  DEPENDS
    source:zlib-patches-${patch_version}
  
  SOURCE
    URL            http://http.debian.net/debian/pool/main/z/zlib/zlib_${version}.orig.tar.gz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=zlib-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
    COMMAND
      ${CMAKE_COMMAND} -E
        echo "set_target_properties(zlib zlibstatic PROPERTIES OUTPUT_NAME z)"
          >> "<SOURCE_DIR>/CMakeLists.txt"
  
  USING            USE_SYSTEM_ZLIB
  BUILD_CONDITION  ${test_system_zlib}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}"
      "-DCMAKE_STAGING_PREFIX=${CMAKE_STAGING_PREFIX}"
    # zlib uses CMAKE_INSTALL_PREFIX incorrectly
    INSTALL_COMMAND
      "$(MAKE)" install "DESTDIR=${INSTALL_DIR}"
  ]]
)
