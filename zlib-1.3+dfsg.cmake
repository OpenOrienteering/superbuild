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

# https://tracker.debian.org/pkg/zlib

# As long as zlib Debian sources and coypright are insufficient,
# we use libz-mingw-w64 instead:
# https://tracker.debian.org/pkg/libz-mingw-w64

set(version        1.3+dfsg)   # libz-mingw-w64
set(download_hash  SHA256=f3cea40eed0a5146439ab948a197e6541a5884a33e287c12a5795e90b5f70dd4)
set(patch_version  ${version}-1)  # libz-mingw-w64
set(patch_hash     SHA256=703f79924684ea675aafd1368dc02951cdd2eebbfb38efa0ee1a8aaf81b5e041  )
set(base_url       https://snapshot.debian.org/archive/debian/20230823T090443Z/pool/main/libz/libz-mingw-w64)

option(USE_SYSTEM_ZLIB "Use the system zlib if possible" ON)

set(test_system_zlib [[
	if(USE_SYSTEM_ZLIB)
		enable_language(C)
		find_package(ZLIB CONFIG QUIET)
		find_package(ZLIB MODULE QUIET)
		if(TARGET ZLIB::ZLIB)
			get_target_property(configurations ZLIB::ZLIB IMPORTED_CONFIGURATIONS)
			if(configurations)
				list(GET configurations 0 config)
				get_target_property(zlib_location ZLIB::ZLIB "IMPORTED_LOCATION_${config}")
			else()
				get_target_property(zlib_location ZLIB::ZLIB "IMPORTED_LOCATION")
			endif()
			string(FIND "${zlib_location}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
			if(NOT staging_prefix_start EQUAL 0)
				message(STATUS "Found ${SYSTEM_NAME} zlib: ${zlib_location}")
				set(BUILD_CONDITION 0)
			endif()
		elseif(NOT WIN32)
			message(FATAL_ERROR "Missing system zlib on ${SYSTEM_NAME}")
		endif()
	endif()
]])

superbuild_package(
  NAME           zlib-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}/libz-mingw-w64_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)

superbuild_package(
  NAME           zlib
  VERSION        ${patch_version}
  DEPENDS
    source:zlib-patches-${patch_version}
  
  SOURCE
    URL            ${base_url}/libz-mingw-w64_${version}.orig.tar.xz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=zlib-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
    COMMAND
      ${CMAKE_COMMAND} -E
        echo "set_target_properties(zlib zlibstatic PROPERTIES OUTPUT_NAME z)"
          >> "<SOURCE_DIR>/CMakeLists.txt"
  
  USING            USE_SYSTEM_ZLIB patch_version
  BUILD_CONDITION  ${test_system_zlib}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      -UCMAKE_STAGING_PREFIX # Has quirks with zlib sources
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast -- DESTDIR=${DESTDIR}${INSTALL_DIR}
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../zlib-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/zlib-${patch_version}.txt"
  ]]
)



option(USE_SYSTEM_MINIZIP "Use the system Minizip if possible" ON)

set(test_system_minizip [[
	if(${USE_SYSTEM_MINIZIP})
		enable_language(C)
		find_library(MINIZIP_LIBRARY NAMES minizip QUIET)
		find_path(MINIZIP_INCLUDE_DIR NAMES minizip/mztools.h QUIET)
		string(FIND "${MINIZIP_LIBRARY}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(MINIZIP_LIBRARY AND MINIZIP_INCLUDE_DIR AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} Minizip: ${MINIZIP_LIBRARY}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
	
	if(CMAKE_C_COMPILER_ID MATCHES "Clang")
		set(extra_flags "-Wno-parentheses-equality -Wno-unused-value" PARENT_SCOPE)
	else()
		set(extra_flags "" PARENT_SCOPE)
	endif()
]])

string(CONCAT CMakeLists_txt [[

cmake_minimum_required(VERSION 3.1)

project(minizip C)

find_package(ZLIB CONFIG QUIET)
find_package(ZLIB MODULE QUIET)
include(GNUInstallDirs)

set(MINIZIP_SOURCE_DIR "" CACHE PATH "Path to minizip sources")

set(MINIZIP_SOURCES
  "${MINIZIP_SOURCE_DIR}/ioapi.c"
  "${MINIZIP_SOURCE_DIR}/mztools.c"
  "${MINIZIP_SOURCE_DIR}/unzip.c"
  "${MINIZIP_SOURCE_DIR}/zip.c"
)
if(WIN32)
	list(APPEND MINIZIP_SOURCES "${MINIZIP_SOURCE_DIR}/iowin32.c")
endif()

set(MINIZIP_HEADERS
  "${MINIZIP_SOURCE_DIR}/crypt.h"
  "${MINIZIP_SOURCE_DIR}/ioapi.h"
  "${MINIZIP_SOURCE_DIR}/mztools.h"
  "${MINIZIP_SOURCE_DIR}/unzip.h"
  "${MINIZIP_SOURCE_DIR}/zip.h"
)
if(WIN32)
	list(APPEND MINIZIP_HEADERS "${MINIZIP_SOURCE_DIR}/iowin32.h")
endif()

add_library(minizip ${MINIZIP_SOURCES})
target_compile_definitions(minizip PUBLIC NOCRYPT USE_FILE32API)
target_link_libraries(minizip PUBLIC ZLIB::ZLIB)

install(TARGETS minizip
  RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
  ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
  LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
)
install(FILES ${MINIZIP_HEADERS}
  DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/minizip"
)
]])

superbuild_package(
  NAME           minizip
  VERSION        zlib-${patch_version}
  DEPENDS
    source:zlib-${patch_version}
    zlib
  
  SOURCE_WRITE
    CMakeLists.txt CMakeLists_txt
  
  USING            USE_SYSTEM_MINIZIP patch_version extra_flags
  BUILD_CONDITION  ${test_system_minizip}
  BUILD [[
    CMAKE_ARGS
      "-DMINIZIP_SOURCE_DIR=<SOURCE_DIR>/../zlib-${patch_version}/contrib/minizip"
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS} ${extra_flags}"
      "-DCMAKE_BUILD_TYPE:STRING=$<CONFIG>"
      -DBUILD_SHARED_LIBS=ON
   INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../zlib-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/minizip-zlib-${patch_version}.txt"
  ]]
)
