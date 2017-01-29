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

set(version        2.2.0)
set(download_hash  MD5=2f47841c829facb346eb6e3fab5212e2)
set(patch_version  ${version}-2)
set(patch_hash     MD5=f7b4b7d3d2b172ea40c2cac54733fe3e)

option(USE_SYSTEM_EXPAT "Use the system Expat if possible" ON)

set(test_system_expat [[
	if(${USE_SYSTEM_EXPAT})
		enable_language(C)
		find_package(EXPAT NO_CMAKE_FIND_ROOT_PATH QUIET)
		if(EXPAT_LIBRARIES)
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           expat-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            http://http.debian.net/debian/pool/main/e/expat/expat_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           expat
  VERSION        ${patch_version}
  DEPENDS
    source:expat-patches-${patch_version}
  
  SOURCE
    URL            http://http.debian.net/debian/pool/main/e/expat/expat_${version}.orig.tar.bz2
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=expat-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING            USE_SYSTEM_EXPAT
  BUILD_CONDITION  ${test_system_expat}
  BUILD [[
    CONFIGURE_COMMAND
      "${SOURCE_DIR}/configure"
        "--prefix=${CMAKE_INSTALL_PREFIX}"
        $<$<BOOL:${CMAKE_CROSSCOMPILING}>:
        --host=${SUPERBUILD_TOOLCHAIN_TRIPLET}
        >
        --enable-shared
        --disable-static
    INSTALL_COMMAND
      "$(MAKE)" install "DESTDIR=${INSTALL_DIR}"
  ]]
)
