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

set(version        1.3.0)
set(download_hash  SHA256=8892439e5570091965aaffe30b08631fdf7ca7f81f6495b4648f0950d7ea7963)
set(patch_version  ${version}-9)
set(patch_hash     SHA256=595b5c7f2de4c73a784c0cdf5014a2321739a4f3f53437eb31e3fe7509e0f1d5)
set(base_url       https://snapshot.debian.org/archive/debian/20201111T205648Z/pool/main/libk/libkml/)

option(USE_SYSTEM_LIBKML "Use the system LibKML if possible" ON)

set(test_system_libkml [[
	if(${USE_SYSTEM_LIBKML})
		enable_language(C)
		find_package(LibKML CONFIG QUIET)
		find_package(LibKML MODULE QUIET)
		string(FIND "${LIBKML_LIBRARIES}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(LibKML_FOUND AND LIBKML_LIBRARIES AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} LibKML: ${LIBKML_LIBRARY}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
	
	if(CMAKE_C_COMPILER_ID MATCHES "Clang")
		set(extra_flags "-Wno-dangling-else -Wno-parentheses-equality" PARENT_SCOPE)
	else()
		set(extra_flags "" PARENT_SCOPE)
	endif()
]])

set(strptime_c_sed [[
/^if.WIN32./a \
  list(APPEND SRCS "${CMAKE_CURRENT_SOURCE_DIR}/contrib/netbsd-strptime.c")
]])

set(strptime_c_copyright [[
Files: src/kml/base/contrib/netbsd-strptime.c
Copyright: 1997, 1998, 2005, 2008 The NetBSD Foundation, Inc.
Comment: Copyright (c) 1997, 1998, 2005, 2008 The NetBSD Foundation, Inc.
 All rights reserved.
 .
 This code was contributed to The NetBSD Foundation by Klaus Klein.
 Heavily optimised by David Laight
License:
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
 .
 THIS SOFTWARE IS PROVIDED BY THE NETBSD FOUNDATION, INC. AND CONTRIBUTORS
 ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE FOUNDATION OR CONTRIBUTORS
 BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 ]])

superbuild_package(
  NAME           libkml-patches
  VERSION        ${patch_version}
  
  SOURCE_WRITE
    strptime_c-copyright  strptime_c_copyright
  SOURCE
    URL            ${base_url}libkml_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
    PATCH_COMMAND
      sed -e "/^python3.patch/d" -i -- patches/series
    COMMAND
      sed -e "/strptime/,$ d" -i -- copyright
    COMMAND
      sed -e "$ r strptime_c-copyright" -i -- copyright
)

superbuild_package(
  NAME           libkml-mingw-patch
  VERSION        ${version}
  
  SOURCE
    URL            https://raw.githubusercontent.com/msys2/MINGW-packages/d5535441b7435a0e7a7d7dee83b175eae7b48475/mingw-w64-libkml/001-libkml-1.3.0.patch
    URL_HASH       SHA256=3692ee34904bbc2ba9a186df80e8d870162abf973151cb16715f26b752020875
    DOWNLOAD_NAME  libkml-${version}-mingw.patch
    DOWNLOAD_NO_EXTRACT 1
)

superbuild_package(
  NAME           libkml-strptime-c
  VERSION        ${version}
  
  SOURCE
    URL            https://raw.githubusercontent.com/msys2/MINGW-packages/d5535441b7435a0e7a7d7dee83b175eae7b48475/mingw-w64-libkml/strptime.c
    URL_HASH       SHA256=49433be91643aaccef032ded7d413782a6ed62f545883165814e13c0e1f4182c
    DOWNLOAD_NAME  libkml-${version}-strptime.c
    DOWNLOAD_NO_EXTRACT 1
)

superbuild_package(
  NAME           libkml
  VERSION        ${patch_version}
  DEPENDS
    source:libkml-patches-${patch_version}
    source:libkml-mingw-patch-${version}
    source:libkml-strptime-c-${version}
    boost-smart_ptr
    expat
#    googletest
    minizip
    uriparser
    zlib
  
  SOURCE_WRITE
    strptime_c.sed   strptime_c_sed
  SOURCE
    URL            ${base_url}libkml_${version}.orig.tar.gz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=libkml-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
    COMMAND
      sed -e "s/ZLIB 1.2.8/ZLIB 1.2.7/" -i -- CMakeLists.txt
    COMMAND
      patch -p1 < "<DOWNLOAD_DIR>/libkml-${version}-mingw.patch"
    COMMAND
      cmake -E copy "<DOWNLOAD_DIR>/libkml-${version}-strptime.c" "src/kml/base/contrib/netbsd-strptime.c"
    COMMAND
      sed -f strptime_c.sed -i -- src/kml/base/CMakeLists.txt
    COMMAND
      "${CMAKE_COMMAND}" -E remove -f
        cmake/External_boost.cmake
        cmake/External_expat.cmake
        cmake/External_minizip.cmake
        cmake/External_uriparser.cmake
        cmake/External_zlib.cmake
  
  USING            USE_SYSTEM_LIBKML patch_version extra_flags
  BUILD_CONDITION  ${test_system_libkml}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DCMAKE_BUILD_TYPE:STRING=$<CONFIG>"
      "-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS} ${extra_flags}"
      -DBUILD_SHARED_LIBS=ON
      -DBoost_FOUND=ON
#      $<$<NOT:$<BOOL:@CMAKE_CROSSCOMPILING@>>:
#        -DBUILD_TESTING=ON
#        "-DGTEST_INCLUDE_DIR=${DESTDIR}${CMAKE_STAGING_PREFIX}/include"
#      >
   INSTALL_COMMAND
     "${CMAKE_COMMAND}" --build . --target install/strip/fast -- DESTDIR=${DESTDIR}${INSTALL_DIR}
   COMMAND
     "${CMAKE_COMMAND}" -E copy
       "<SOURCE_DIR>/../libkml-patches-${patch_version}/copyright"
       "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/libkml-${patch_version}.txt"
  ]]
)
