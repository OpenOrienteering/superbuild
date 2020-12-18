# This file is part of OpenOrienteering.

# Copyright 2016-2020 Kai Pastor
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

set(version           3.34.0)
set(download_version  2020/sqlite-autoconf-3340000)
set(download_hash     SHA3_256=b7479a5b163f1ba0dd5208e247c1ea677373a2b6bf9ef8ed87c8414f58c61de3)
set(patch_version     ${version}-1)
set(patch_hash        SHA256=cdce039f7cf5bbde36855ff70864655cc2e514fcb6e2d8d89bfa58484bb75da6)
set(base_url          https://snapshot.debian.org/archive/debian/20201205T034710Z/pool/main/s/sqlite3/)

option(USE_SYSTEM_SQLITE3 "Use the system sqlite if possible" ON)

set(test_system_sqlite3 [[
	if(APPLE AND USE_SYSTEM_SQLITE3)
		# System sqlite doesn't provide all required features for GDAL
		message(WARNING "Ignoring system sqlite for macOS")
		set(BUILD_CONDITION 1)
	elseif(USE_SYSTEM_SQLITE3)
		enable_language(C)
		find_library(SQLITE3_LIBRARY NAMES sqlite3 QUIET)
		find_path(SQLITE3_INCLUDE_DIR NAMES sqlite3.h QUIET)
		string(FIND "${SQLITE3_LIBRARY}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(SQLITE3_LIBRARY AND SQLITE3_INCLUDE_DIR AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} sqlite3: ${SQLITE3_LIBRARY}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           sqlite3-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}sqlite3_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           sqlite3
  VERSION        ${patch_version}
  DEPENDS
    source:sqlite3-patches-${patch_version}
    common-licenses
  
  SOURCE
    URL            https://www.sqlite.org/${download_version}.tar.gz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      # __USE_GNU is defined on Android, but compiling and linking find only the
      # POSIX version of strerror_r, issueing a warning.
      # Just rely on configure's feature detection.
      sed -e "/STRERROR_R_CHAR_P/ s/ .. defined.__USE_GNU.//" -i -- sqlite3.c
  
  USING            USE_SYSTEM_SQLITE3 version patch_version
  BUILD_CONDITION  ${test_system_sqlite3}
  BUILD [[
    CONFIGURE_COMMAND
      "${SOURCE_DIR}/configure"
        "--prefix=${CMAKE_INSTALL_PREFIX}"
        $<$<BOOL:@CMAKE_CROSSCOMPILING@>:
        --host=${SUPERBUILD_TOOLCHAIN_TRIPLET}
        >
        --disable-static
        --enable-shared
        --enable-threadsafe
        "CC=${SUPERBUILD_CC}"
        "CPPFLAGS=${SUPERBUILD_CPPFLAGS} -DSQLITE_ENABLE_COLUMN_METADATA"
        "CFLAGS=${SUPERBUILD_CFLAGS}"
        "LDFLAGS=${SUPERBUILD_LDFLAGS}"
    INSTALL_COMMAND
      "$(MAKE)" install "DESTDIR=${DESTDIR}${INSTALL_DIR}"
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../sqlite3-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/sqlite3-${version}.txt"
  ]]
)
