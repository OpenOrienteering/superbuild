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

set(version        1.6.26)
set(download_hash  MD5=faed9bb495d2e12dd0c9ec561ca60cd8)
set(patch_version  ${version}-1)
set(patch_hash     MD5=2d1dda318fe4edee21afca4384fc5f5c)

option(USE_SYSTEM_LIBPNG "Use the system libpng if possible" ON)

set(test_system_png [[
	if(${USE_SYSTEM_LIBPNG})
		enable_language(C)
		find_package(PNG CONFIG NO_CMAKE_FIND_ROOT_PATH QUIET)
		find_package(PNG MODULE)
		if(TARGET PNG::PNG)
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           libpng1.6-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            http://http.debian.net/debian/pool/main/libp/libpng1.6/libpng1.6_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)

superbuild_package(
  NAME           libpng1.6
  VERSION        ${patch_version}
  DEPENDS
    source:libpng1.6-patches-${patch_version}
    zlib
  
  SOURCE
    URL            http://http.debian.net/debian/pool/main/libp/libpng1.6/libpng1.6_${version}.orig.tar.xz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=libpng1.6-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING            USE_SYSTEM_LIBPNG
  BUILD_CONDITION  ${test_system_png}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}"
      "-DCMAKE_STAGING_PREFIX=${CMAKE_STAGING_PREFIX}"
      "-DPNG_STATIC=0"
  ]]
)

superbuild_package(
  NAME           libpng
  VERSION        ${patch_version}
  DEPENDS        libpng1.6
)
