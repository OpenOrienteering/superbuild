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

set(download_version  autoconf-3200100)
set(version           3.20.1-${download_version})
set(download_hash     SHA1=48593dcd19473f25fe6fcd08048e13ddbff4c983)
set(patch_version     3.20.1-1)
set(patch_hash        SHA256=8c205983e0f7baf75419123093a42aac97c94e8454c0adf540838264604e04b3)

option(USE_SYSTEM_SQLITE3 "Use the system sqlite if possible" ON)

set(test_system_sqlite3 [[
	if(USE_SYSTEM_SQLITE3)
		enable_language(C)
		find_library(SQLITE3_LIBRARY NAMES sqlite3 QUIET)
		if(SQLITE3_LIBRARY
		   AND NOT SQLITE3_LIBRARY MATCHES "${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}")
			message(STATUS "Found ${SYSTEM_NAME} sqlite3: ${SQLITE3_LIBRARY}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           sqlite3-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            http://http.debian.net/debian/pool/main/s/sqlite3/sqlite3_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           sqlite3
  VERSION        ${version}
  DEPENDS
    source:sqlite3-patches-${patch_version}
    common-licenses
  
  SOURCE
    URL            https://www.sqlite.org/2017/sqlite-${download_version}.tar.gz
    URL_HASH       ${download_hash}
  
  USING            USE_SYSTEM_SQLITE3 version patch_version
  BUILD_CONDITION  ${test_system_sqlite3}
  BUILD [[
    CONFIGURE_COMMAND
      "${SOURCE_DIR}/configure"
        "--prefix=${CMAKE_INSTALL_PREFIX}"
        $<$<BOOL:${CMAKE_CROSSCOMPILING}>:
        --host=${SUPERBUILD_TOOLCHAIN_TRIPLET}
        >
        --disable-static
        --enable-shared
        --enable-threadsafe
    INSTALL_COMMAND
      "$(MAKE)" install "DESTDIR=${INSTALL_DIR}"
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../sqlite3-patches-${patch_version}/copyright"
        "${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}/share/doc/copyright/sqlite3-${version}.txt"
  ]]
)
