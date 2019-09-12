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

set(version        2.2.7)
set(download_hash  SHA256=cbc9102f4a31a8dafd42d642e9a3aa31e79a0aedaa1f6efd2795ebc83174ec18)
set(patch_version  ${version}-2)
set(patch_hash     SHA256=9f427b1f23a95ded54f347d67dd527cb130b686bc190428dc95ed67a0100bc0a)
set(base_url       https://snapshot.debian.org/archive/debian/20190908T172415Z/pool/main/e/expat)

option(USE_SYSTEM_EXPAT "Use the system Expat if possible" ON)

set(test_system_expat [[
	if(USE_SYSTEM_EXPAT)
		enable_language(C)
		find_package(EXPAT QUIET)
		string(FIND "${EXPAT_INCLUDE_DIRS}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(EXPAT_FOUND AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} expat: ${EXPAT_LIBRARIES}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           expat-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}/expat_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
    PATCH_COMMAND
      # This patch would not apply with -p1
      sed -e "s, [ab]/expat/, expat/,g" -i --
        patches/CVE-2019-15903_Deny_internal_entities_closing_the_doctype.patch
)
  
superbuild_package(
  NAME           expat
  VERSION        ${patch_version}
  DEPENDS
    source:expat-patches-${patch_version}
  
  SOURCE
    URL            https://downloads.sourceforge.net/expat/expat-${version}.tar.bz2
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=expat-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING            USE_SYSTEM_EXPAT patch_version
  BUILD_CONDITION  ${test_system_expat}
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
        "<SOURCE_DIR>/../expat-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/expat-${patch_version}.txt"
  ]]
)
