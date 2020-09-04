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

set(version        2.15.02)
set(download_hash  SHA256=f4fd1329b1713e1ccd34b2fc121c4bcd278c9f91cc4cb205ae8fcd2e4728dd14)
set(patch_version  ${version}-1)
set(patch_hash     SHA256=730bc65e099138e6d00c3270d6fec34a5ff63c132258d0c23b51aefbc0b2da99)
set(base_url       https://snapshot.debian.org/archive/debian/20200704T025342Z/pool/main/n/nasm/)

option(USE_SYSTEM_NASM "Use the system nasm if possible" ON)

set(test_system_nasm [[
	if(USE_SYSTEM_NASM)
		find_program(NASM_EXECUTABLE NAMES nasm ONLY_CMAKE_FIND_ROOT_PATH QUIET)
		if(NASM_EXECUTABLE)
			execute_process(
			  COMMAND "${NASM_EXECUTABLE}" -v
			  OUTPUT_VARIABLE NASM_VERSION
			)
			if(NOT NASM_VERSION MATCHES "version"
			   OR NASM_VERSION MATCHES "version [01]\.")
				unset(NASM_EXECUTABLE CACHE)
				set(NASM_EXECUTABLE NASM_EXECUTABLE-NOTFOUND)
			endif()
		endif()
		string(FIND "${NASM_EXECUTABLE}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(NASM_EXECUTABLE AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} nasm: ${NASM_EXECUTABLE}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           nasm-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}nasm_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           nasm
  VERSION        ${patch_version}
  DEPENDS
    source:nasm-patches-${patch_version}
  
  SOURCE
    DOWNLOAD_NAME  nasm_${version}.orig.tar.gz
    URL            ${base_url}nasm_${version}.orig.tar.xz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=nasm-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING            USE_SYSTEM_NASM patch_version
  BUILD_CONDITION  ${test_system_nasm}
  BUILD [[
    CONFIGURE_COMMAND
      "${SOURCE_DIR}/configure"
        "--prefix=${CMAKE_INSTALL_PREFIX}"
        $<$<BOOL:@CMAKE_CROSSCOMPILING@>:
          --host=${SUPERBUILD_TOOLCHAIN_TRIPLET}
        >
        "CC=${SUPERBUILD_CC}"
        "CPPFLAGS=${SUPERBUILD_CPPFLAGS}"
        "CFLAGS=${SUPERBUILD_CFLAGS} -Wno-format"
        "LDFLAGS=${SUPERBUILD_LDFLAGS}"
    INSTALL_COMMAND
      "$(MAKE)" install "DESTDIR=${DESTDIR}${INSTALL_DIR}"
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../nasm-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/nasm-${patch_version}.txt"
  ]]
)
