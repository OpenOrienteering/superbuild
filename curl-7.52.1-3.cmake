# This file is part of OpenOrienteering.

# Copyright 2017 Kai Pastor
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

set(version        7.52.1)
set(download_hash  SHA256=a8984e8b20880b621f61a62d95ff3c0763a3152093a9f9ce4287cfd614add6ae)
set(patch_version  ${version}-3)
set(patch_hash     SHA256=e5a04a18e7728f3898da50845537123d3a500da7f959119eb36f1f73daee8cf7)

option(USE_SYSTEM_CURL "Use the system curl if possible" ON)

set(test_system_curl [[
	if(USE_SYSTEM_CURL)
		enable_language(C)
		find_package(CURL CONFIG QUIET)
		find_package(CURL MODULE QUIET)
		if(CURL_FOUND
		   AND NOT CURL_INCLUDE_DIRS MATCHES "${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}")
			message(STATUS "Found ${SYSTEM_NAME} curl: ${CURL_LIBRARIES}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           curl-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            http://http.debian.net/debian/pool/main/c/curl/curl_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           curl
  VERSION        ${patch_version}
  DEPENDS
    source:curl-patches-${patch_version}
    zlib
  
  SOURCE
    URL            http://http.debian.net/debian/pool/main/c/curl/curl_${version}.orig.tar.gz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=curl-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING            USE_SYSTEM_CURL
  BUILD_CONDITION  ${test_system_curl}
  BUILD [[
    CONFIGURE_COMMAND
      "${SOURCE_DIR}/configure"
        "--prefix=${CMAKE_INSTALL_PREFIX}"
        $<$<BOOL:${CMAKE_CROSSCOMPILING}>:
        --host=${SUPERBUILD_TOOLCHAIN_TRIPLET}
        >
        --disable-silent-rules
        --enable-symbol-hiding
        --disable-largefile
        --enable-shared
        --disable-static
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
      $<$<STREQUAL:${CMAKE_SYSTEM_NAME},Windows>:
        --with-winssl
      > # Windows
      $<$<STREQUAL:${CMAKE_SYSTEM_NAME},Darwin>:
        --with-darwinssl
      > # Darwin
    INSTALL_COMMAND
      "$(MAKE)" install "DESTDIR=${INSTALL_DIR}"
  ]]
)
