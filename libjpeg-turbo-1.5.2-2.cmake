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

set(version        1.5.2)
set(download_hash  SHA256=9098943b270388727ae61de82adec73cf9f0dbb240b3bc8b172595ebf405b528)
set(patch_version  ${version}-2)
set(patch_hash     SHA256=964a2d747f8e74cbd558f343afd11b7dfe37212a611eeca863f1908eba66f728)

option(USE_SYSTEM_LIBJPEG "Use the system libjpeg if possible" ON)

set(test_system_jpeg [[
	if(USE_SYSTEM_LIBJPEG)
		enable_language(C)
		find_package(JPEG CONFIG QUIET)
		find_package(JPEG MODULE QUIET)
		string(FIND "${JPEG_INCLUDE_DIR}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(JPEG_FOUND AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} libjpeg: ${JPEG_LIBRARIES}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

find_program(NASM_EXECUTABLE NAMES nasm)
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

superbuild_package(
  NAME           libjpeg-turbo-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${SUPERBUILD_DEBIAN_BASE_URL_2017_11}/pool/main/libj/libjpeg-turbo/libjpeg-turbo_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           libjpeg-turbo
  VERSION        ${patch_version}
  DEPENDS
    source:libjpeg-turbo-patches-${patch_version}
  
  SOURCE
    DOWNLOAD_NAME  libjpeg-turbo_${version}.orig.tar.gz
    URL            ${SUPERBUILD_DEBIAN_BASE_URL_2017_11}/pool/main/libj/libjpeg-turbo/libjpeg-turbo_${version}.orig.tar.gz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=libjpeg-turbo-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  
  USING            USE_SYSTEM_LIBJPEG NASM_EXECUTABLE patch_version
  BUILD_CONDITION  ${test_system_jpeg}
  BUILD [[
    CONFIGURE_COMMAND
      "${CMAKE_COMMAND}" -E env
      "${SOURCE_DIR}/configure"
        "--prefix=${CMAKE_INSTALL_PREFIX}"
        $<$<BOOL:@CMAKE_CROSSCOMPILING@>:
          --host=${SUPERBUILD_TOOLCHAIN_TRIPLET}
        >
        $<$<NOT:$<BOOL:@ANDROID@>>:
        --disable-static
        --enable-shared
        >$<$<BOOL:@ANDROID@>:
        # Static only. There may be an interfering libjeg.so on the device.
        --enable-static
        --disable-shared
        --with-pic
        >
        --disable-silent-rules
        --without-12bit
        $<$<NOT:$<STREQUAL:@NASM_EXECUTABLE@,NASM_EXECUTABLE-NOTFOUND>>:
        "NASM=${NASM_EXECUTABLE}"
        >$<$<STREQUAL:@NASM_EXECUTABLE@,NASM_EXECUTABLE-NOTFOUND>:
        --without-simd
        >
        "CPPFLAGS=-I${CMAKE_FIND_ROOT_PATH}${CMAKE_INSTALL_PREFIX}/include"
        "CFLAGS=${CMAKE_C_FLAGS} ${CMAKE_C_FLAGS_$<UPPER_CASE:$<CONFIG>>}"
        "LDFLAGS=-L${CMAKE_FIND_ROOT_PATH}${CMAKE_INSTALL_PREFIX}/lib"
    INSTALL_COMMAND
      "$(MAKE)" install "DESTDIR=${DESTDIR}${INSTALL_DIR}"
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../libjpeg-turbo-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/libjpeg-turbo-${patch_version}.txt"
  ]]
)

superbuild_package(
  NAME           libjpeg
  VERSION        99-${patch_version}-turbo
  DEPENDS
    libjpeg-turbo-${patch_version}
)
