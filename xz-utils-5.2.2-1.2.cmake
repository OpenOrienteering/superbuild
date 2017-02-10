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

set(version        5.2.2)
set(download_hash  MD5=e26772b69940085c0632589ab1d52e64)

# Note: None of the patches from 5.2.2-1.2 are actually used.
# They are Debian specific and require autotools for reconfiguration.
set(patch_version  ${version}-1.2)
set(patch_hash     MD5=0862985af8480d65a5d0836feaa4b70e)

option(USE_SYSTEM_LZMA "Use the system XZ-Utils/LZMA library if possible" ON)

set(test_system_lzma [[
	if(USE_SYSTEM_LZMA)
		enable_language(C)
		find_package(LibLZMA CONFIG QUIET)
		find_package(LibLZMA MODULE QUIET)
		if(LIBLZMA_FOUND)
			message(STATUS "Found xz-utils: ${LIBLZMA_LIBRARIES}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           xz-utils-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            http://http.debian.net/debian/pool/main/x/xz-utils/xz-utils_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
    PATCH_COMMAND
      sed -i -e "/liblzma-skip-ABI-incompatible-check-when-liblzma.so.patch/d" patches/series
    COMMAND
      sed -i -e "/liblzma-make-dlopen-based-liblzma2-compatibility-opt.patch/d" patches/series
    COMMAND
      sed -i -e "/kfreebsd-link-against-libfreebsd-glue.patch/d" patches/series
)
  
superbuild_package(
  NAME           xz-utils
  VERSION        ${patch_version}
  DEPENDS
    source:xz-utils-patches-${patch_version}
  
  SOURCE
    URL            http://http.debian.net/debian/pool/main/x/xz-utils/xz-utils_${version}.orig.tar.xz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=xz-utils-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING            USE_SYSTEM_LZMA
  BUILD_CONDITION  ${test_system_lzma}
  BUILD [[
    CONFIGURE_COMMAND
      "${SOURCE_DIR}/configure"
        "--prefix=${CMAKE_INSTALL_PREFIX}"
        $<$<BOOL:${CMAKE_CROSSCOMPILING}>:
          --host=${SUPERBUILD_TOOLCHAIN_TRIPLET}
        >
        --disable-static
        --enable-shared
        --disable-lzma-links
    INSTALL_COMMAND
      "$(MAKE)" install "DESTDIR=${INSTALL_DIR}"
  ]]
)

superbuild_package(
  NAME           liblzma
  VERSION        ${patch_version}
  DEPENDS
    xz-utils-${patch_version}
)
