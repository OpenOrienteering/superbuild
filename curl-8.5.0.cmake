# This file is part of OpenOrienteering.

# Copyright 2017-2020 Kai Pastor
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

set(version        8.5.0)
set(download_hash  SHA256=05fc17ff25b793a437a0906e0484b82172a9f4de02be5ed447e0cab8c3475add)
set(patch_version  ${version}-2)
set(patch_hash     SHA256=5e398fc2d420bfc3fedc4d3cdedfad8bc4eadf5445bf59905af0e6f2602fcb66)
set(base_url       https://snapshot.debian.org/archive/debian/20231230T090509Z/pool/main/c/curl)

option(USE_SYSTEM_CURL "Use the system curl if possible" ON)

set(test_system_curl [[
	if(USE_SYSTEM_CURL)
		enable_language(C)
		find_package(CURL CONFIG QUIET)
		find_package(CURL MODULE QUIET)
		string(FIND "${CURL_INCLUDE_DIRS}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(CURL_FOUND AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} curl: ${CURL_LIBRARIES}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
	set(extra_flags "-Wno-old-style-cast" PARENT_SCOPE)
]])

superbuild_package(
  NAME           curl-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}/curl_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           curl
  VERSION        ${patch_version}
  DEPENDS
    source:curl-patches-${patch_version}
    zlib
  
  SOURCE
    URL            ${base_url}/curl_${version}.orig.tar.gz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=curl-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING            USE_SYSTEM_CURL patch_version extra_flags
  BUILD_CONDITION  ${test_system_curl}
  BUILD [[
    CONFIGURE_COMMAND
      "${SOURCE_DIR}/configure"
        "--prefix=${CMAKE_INSTALL_PREFIX}"
        $<$<BOOL:@CMAKE_CROSSCOMPILING@>:
        --host=${SUPERBUILD_TOOLCHAIN_TRIPLET}
        >
        --disable-silent-rules
        --enable-symbol-hiding
        --disable-largefile
        --enable-shared
        --disable-static
        --enable-pthreads
        --enable-threadsafe
        --disable-ldap
        --disable-ldaps
        --disable-rtsp
        --disable-dict
        --disable-telnet
        --disable-tftp
        --disable-pop3
        --disable-imap
        --disable-smb
        --disable-smtp
        --disable-gopher
        --disable-manual
        --enable-ipv6
      $<$<STREQUAL:@CMAKE_SYSTEM_NAME@,Windows>:
        --without-brotli
        --without-libpsl
        --without-libidn2
        --without-nghttp2
        --without-ssl
        --with-winssl
      > # Windows
      $<$<STREQUAL:@CMAKE_SYSTEM_NAME@,Darwin>:
        --with-darwinssl
      > # Darwin
      $<$<NOT:$<OR:$<STREQUAL:@CMAKE_SYSTEM_NAME@,Windows>,$<STREQUAL:@CMAKE_SYSTEM_NAME@,Darwin>>>:
        --without-ssl
      > # System without native SSL
        "CC=${SUPERBUILD_CC}"
        "CPPFLAGS=${SUPERBUILD_CPPFLAGS}"
        "CFLAGS=${SUPERBUILD_CFLAGS} ${extra_flags}"
        "CXXFLAGS=${SUPERBUILD_CXXFLAGS} ${extra_flags}"
        "LDFLAGS=${SUPERBUILD_LDFLAGS}"
    INSTALL_COMMAND
      "$(MAKE)" install "DESTDIR=${DESTDIR}${INSTALL_DIR}"
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../curl-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/curl-${patch_version}.txt"
  ]]
)
