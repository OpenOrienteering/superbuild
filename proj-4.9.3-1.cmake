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

set(version        4.9.3)
set(download_hash  SHA256=6984542fea333488de5c82eea58d699e4aff4b359200a9971537cd7e047185f7)
set(patch_version  ${version}-1)
set(patch_hash     SHA256=8adf9c8172ef73aa6a437e56ebf8246c52e081f23390cd157b77d7c4f3c3347a)

option(USE_SYSTEM_PROJ "Use the system PROJ4 if possible" ON)

set(test_system_proj [[
	if(${USE_SYSTEM_PROJ})
		enable_language(C)
		find_library(PROJ4_LIBRARY NAMES proj QUIET)
		find_path(PROJ4_INCLUDE_DIR NAMES proj_api.h QUIET)
		string(FIND "${PROJ4_LIBRARY}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(PROJ4_LIBRARY AND PROJ4_INCLUDE_DIR AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} PROJ4: ${PROJ4_LIBRARY}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           proj-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${SUPERBUILD_DEBIAN_BASE_URL_2017_06}/pool/main/p/proj/proj_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           proj
  VERSION        ${patch_version}
  DEPENDS
    source:proj-patches-${patch_version}
  
  SOURCE
    URL            ${SUPERBUILD_DEBIAN_BASE_URL_2017_06}/pool/main/p/proj/proj_${version}.orig.tar.gz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=proj-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
    #COMMAND
    #  unshar -c -d "<SOURCE_DIR>/nad" "<SOURCE_DIR>/../proj-patches-${patch_version}/datumgrids.shar"
    #COMMAND
    #  unshar -c -d "<SOURCE_DIR>/nad" "<SOURCE_DIR>/../proj-patches-${patch_version}/datumgrids.shar"
  
  USING            USE_SYSTEM_PROJ patch_version
  BUILD_CONDITION  ${test_system_proj}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      -DBUILD_LIBPROJ_SHARED=ON
      -DUSE_THREAD=OFF
      -DJNI_SUPPORT=OFF
      -DPROJ_BIN_SUBDIR=bin
      -DPROJ_LIB_SUBDIR=lib
      -DPROJ_DATA_SUBDIR=share/proj
      -DPROJ_DOC_SUBDIR=share/doc/proj
      -DPROJ_INCLUDE_SUBDIR=include
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../proj-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/proj-${patch_version}.txt"
  ]]
)
