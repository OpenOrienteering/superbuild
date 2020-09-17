# This file is part of OpenOrienteering.

# Copyright 2016-2020 Kai Pastor
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

set(version        1.8.20)
set(download_hash  SHA256=3dbdf8814d6e68233d5149239cb1f0b40b4e7b32eef2fd53de8828fedd7aca15)
set(patch_version  ${version}-1)
set(patch_hash     SHA256=16271cdae86fcda19f5078442e49148db48f087c046da517641230408b2702ae)
set(base_url       https://snapshot.debian.org/archive/debian/20200914T084139Z/pool/main/d/doxygen/)

option(USE_SYSTEM_DOXYGEN "Use the system DOXYGEN if possible" ON)

set(test_system_doxygen [[
	if(USE_SYSTEM_DOXYGEN)
		find_program(DOXYGEN_EXECUTABLE NAMES doxygen ONLY_CMAKE_FIND_ROOT_PATH QUIET)
		string(FIND "${DOXYGEN_EXECUTABLE}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(DOXYGEN_EXECUTABLE AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} doxygen: ${DOXYGEN_EXECUTABLE}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
	if(CMAKE_C_COMPILER_ID MATCHES "Clang")
		set(extra_flags "-Wno-return-type -Wno-tautological-constant-out-of-range-compare" PARENT_SCOPE)
	elseif(CMAKE_C_COMPILER_ID STREQUAL "GNU")
		set(extra_flags "-Wno-return-type -Wno-write-strings" PARENT_SCOPE)
	else()
		set(extra_flags "" PARENT_SCOPE)
	endif()
]])


superbuild_package(
  NAME           doxygen-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}/doxygen_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)

superbuild_package(
  NAME           doxygen
  VERSION        ${patch_version}
  DEPENDS
    source:doxygen-patches-${patch_version}
    host:bison
    libiconv
    zlib
  
  SOURCE
    URL            ${base_url}doxygen_${version}.orig.tar.gz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=doxygen-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
    COMMAND
      sed -e "/set.YACC_FLAGS/ s/set.*/set(YACC_FLAGS -Wno-deprecated)/" -i --
        CMakeLists.txt
    COMMAND
      sed -e "/BISON_EXECUTABLE/ s/ -o / -Wno-deprecated -o /" -i --
        CMakeLists.txt
    COMMAND
      sed -e "/set.PROJECT_WARNINGS/ s/set.*/set(PROJECT_WARNINGS )/" -i --
        cmake/CompilerWarnings.cmake
  
  USING            USE_SYSTEM_DOXYGEN patch_version extra_flags
  BUILD_CONDITION  ${test_system_doxygen}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DCMAKE_BUILD_TYPE=Release"
      "-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS} ${extra_flags}"
      "-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS} ${extra_flags}"
       -Denglish_only=1
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../doxygen-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/doxygen-${patch_version}.txt"
  ]]
)
