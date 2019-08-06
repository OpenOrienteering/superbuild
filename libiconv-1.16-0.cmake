# This file is part of OpenOrienteering.

# Copyright 2019 Kai Pastor
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

set(version        1.16)
set(download_hash  SHA256=e6a1b1b589654277ee790cce3734f07876ac4ccfaecbee8afa0b649cf529cc04)
set(patch_version  ${version}-0)
set(base_url       https://ftp.gnu.org/pub/gnu/libiconv)

option(USE_SYSTEM_LIBICONV "Use the system libiconv if possible" ON)

set(test_system_libiconv [[
    if(NOT WIN32)
		set(BUILD_CONDITION 0)
	elseif(USE_SYSTEM_LIBICONV)
		enable_language(C)
		find_package(Iconv CONFIG QUIET)
		find_package(Iconv MODULE QUIET)
		string(FIND "${Iconv_INCLUDE_DIRS}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(Iconv_FOUND AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} Iconv: ${Iconv_LIBRARIES}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           libiconv
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}/libiconv-${version}.tar.gz
    URL_HASH       ${download_hash}
  
  USING
    USE_SYSTEM_LIBICONV
    patch_version
  
  BUILD_CONDITION  ${test_system_libiconv}
  BUILD [[
    CONFIGURE_COMMAND
      "${SOURCE_DIR}/configure"
        "--prefix=${CMAKE_INSTALL_PREFIX}"
        $<$<BOOL:@CMAKE_CROSSCOMPILING@>:
        --host=${SUPERBUILD_TOOLCHAIN_TRIPLET}
        >
        --enable-shared
        --disable-static
        "CC=${SUPERBUILD_CC}"
        "CPPFLAGS=${SUPERBUILD_CPPFLAGS}"
        "CFLAGS=${SUPERBUILD_CFLAGS}"
        "LDFLAGS=${SUPERBUILD_LDFLAGS}"
    INSTALL_COMMAND
      "$(MAKE)" install "DESTDIR=${DESTDIR}${INSTALL_DIR}"
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/COPYING.LIB"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/libiconv-${patch_version}.txt"
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/COPYING"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/iconv-${patch_version}.txt"
  ]]
)
