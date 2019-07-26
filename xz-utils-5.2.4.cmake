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

set(version        5.2.4)
set(download_hash  SHA256=9717ae363760dedf573dad241420c5fea86256b65bc21d2cf71b2b12f0544f4b)

# Note: None of the patches from 5.2.2-1.2 are actually used.
# They are Debian specific and require autotools for reconfiguration.
set(patch_version  ${version}-1)
set(patch_hash     SHA256=d37b558444b76e88a69601df008cf1c0343c58cb7765b7bbb2099b0a19619361)
set(base_url       https://snapshot.debian.org/archive/debian/20190128T030507Z/pool/main/x/xz-utils)

option(USE_SYSTEM_LZMA "Use the system XZ-Utils/LZMA library if possible" ON)

set(test_system_lzma [[
	if(USE_SYSTEM_LZMA)
		enable_language(C)
		find_package(LibLZMA CONFIG QUIET)
		find_package(LibLZMA MODULE QUIET)
		string(FIND "${LIBLZMA_INCLUDE_DIRS}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(LIBLZMA_FOUND AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} LibLZMA (xz-utils): ${LIBLZMA_LIBRARIES}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           xz-utils-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}/xz-utils_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           xz-utils
  VERSION        ${patch_version}
  DEPENDS
    source:xz-utils-patches-${patch_version}
    common-licenses
    libiconv
  
  SOURCE
    URL            ${base_url}/xz-utils_${version}.orig.tar.xz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=xz-utils-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING            USE_SYSTEM_LZMA patch_version
  BUILD_CONDITION  ${test_system_lzma}
  BUILD [[
    CONFIGURE_COMMAND
      "${SOURCE_DIR}/configure"
        "--prefix=${CMAKE_INSTALL_PREFIX}"
        $<$<BOOL:@CMAKE_CROSSCOMPILING@>:
          --host=${SUPERBUILD_TOOLCHAIN_TRIPLET}
        >
        --disable-static
        --enable-shared
        --disable-lzma-links
        "CPPFLAGS=${SUPERBUILD_CPPFLAGS}"
        "CFLAGS=${SUPERBUILD_CFLAGS}"
        "LDFLAGS=${SUPERBUILD_LDFLAGS}"
        $<$<BOOL:@ANDROID@>:
          "CC=${STANDALONE_C_COMPILER}"
        >
    INSTALL_COMMAND
      "$(MAKE)" install "DESTDIR=${DESTDIR}${INSTALL_DIR}"
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../xz-utils-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/xz-utils-${patch_version}.txt"
  ]]
)

superbuild_package(
  NAME           liblzma
  VERSION        ${patch_version}
  DEPENDS
    xz-utils-${patch_version}
  SOURCE
    xz-utils-${patch_version}
    
  USING            USE_SYSTEM_LZMA patch_version
  BUILD_CONDITION  ${test_system_lzma}
  BUILD [[
    CONFIGURE_COMMAND ""
    BUILD_COMMAND     ""
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../xz-utils-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/liblzma-${patch_version}.txt"
  ]]
)
