# This file is part of OpenOrienteering.

# Copyright 2020 Kai Pastor
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

set(version        3.7.2+dfsg)
set(download_hash  SHA256=7d9dfcb129e4004915d1099c034184027b21e95ef18bda8adb65457ada217c45)
set(patch_version  ${version}-1)
set(patch_hash     SHA256=fd0514a4effe94864aa3a51bbb47ed36bc597cbebac83b27722632c0bbb0dc2a)
set(base_url       https://snapshot.debian.org/archive/debian/20200907T204912Z/pool/main/b/bison/)

option(USE_SYSTEM_BISON "Use the system Bison if possible" ON)

set(test_system_bison [[
	if(${USE_SYSTEM_BISON})
		enable_language(C)
		# Doxygen 1.8.x needs at least Bison 2.7
		find_package(BISON 2.7 QUIET)
		string(FIND "${BISON_EXECUTABLE}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(BISON_EXECUTABLE AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} Bison: ${BISON_EXECUTABLE} (${BISON_VERSION})")
			set(BUILD_CONDITION 0)
		endif()
		if(BISON_VERSION AND BISON_VERSION VERSION_LESS 2.7)
			message(WARNING "Ignoring ${SYSTEM_NAME} Bison (< 2.7)")
			set(BUILD_CONDITION 1)
		endif()
	endif()
]])

set(bison_texi [[
@setfilename bison.info
]])

superbuild_package(
  NAME           bison-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}bison_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)

superbuild_package(
  NAME           bison
  VERSION        ${patch_version}
  DEPENDS
    source:bison-patches-${patch_version}
  
  SOURCE_WRITE
    bison.texi     bison_texi
  SOURCE
    URL            ${base_url}bison_${version}.orig.tar.xz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=bison-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
    # Fix the issues resulting from Debian DFSG tarball and patching
    COMMAND
      "${CMAKE_COMMAND}"
        -E copy bison.texi doc/bison.texi
    COMMAND
      touch -r doc/local.mk doc/bison.texi
    COMMAND
      touch -r doc/local.mk examples/c/lexcalc/local.mk
    COMMAND
      touch -r doc/local.mk examples/local.mk
  
  USING            USE_SYSTEM_BISON patch_version
  BUILD_CONDITION  ${test_system_bison}
  BUILD [[
    CONFIGURE_COMMAND
      "${SOURCE_DIR}/configure"
        "--prefix=${CMAKE_INSTALL_PREFIX}"
        $<$<BOOL:@CMAKE_CROSSCOMPILING@>:
        --host=${SUPERBUILD_TOOLCHAIN_TRIPLET}
        >
        --enable-relocatable
        --disable-nls
        --disable-silent-rules
        "CC=${SUPERBUILD_CC}"
        "CXX=${SUPERBUILD_CXX}"
        "CPPFLAGS=${SUPERBUILD_CPPFLAGS}"
        "CFLAGS=${SUPERBUILD_CFLAGS}"
        "CXXFLAGS=${SUPERBUILD_CXXFLAGS}"
        "LDFLAGS=${SUPERBUILD_LDFLAGS}"
    INSTALL_COMMAND
      "$(MAKE)" install "DESTDIR=${DESTDIR}${INSTALL_DIR}"
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../bison-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/bison-${patch_version}.txt"
  ]]
)
