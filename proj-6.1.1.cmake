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

set(version        6.1.1)
set(download_hash  SHA256=5cf0a2360a28b5d724c53edbb87f3f3b14fd96001265411ac4e56f369e2d503f)
set(patch_version  ${version}-1-exp1)
set(patch_hash     SHA256=3621c37f7b85173448f5c46ede37fddffdb0059d6e5bdd97101fa889d127dda1)
set(base_url       https://snapshot.debian.org/archive/debian/20190701T145228Z/pool/main/p/proj)

set(datumgrid_version  1.8)
set(datumgrid_hash SHA256=b9838ae7e5f27ee732fb0bfed618f85b36e8bb56d7afb287d506338e9f33861e)

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

if(NOT TARGET proj-datumgrid-${datumgrid_version}-source)
    # may be defined by multiple proj package files
    superbuild_package(
      NAME           proj-datumgrid
      VERSION        ${datumgrid_version}
    
      SOURCE
        URL            https://download.osgeo.org/proj/proj-datumgrid-${datumgrid_version}.zip
        URL_HASH       ${datumgrid_hash}
    )
endif()

superbuild_package(
  NAME           proj-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}/proj_${version}-1~exp1.debian.tar.xz
    URL_HASH       ${patch_hash}
)

superbuild_package(
  NAME           proj
  VERSION        ${patch_version}-0
  DEPENDS
    source:proj-datumgrid-${datumgrid_version}
    source:proj-patches-${patch_version}
    host:sqlite3
    googletest
    sqlite3
  
  SOURCE
    URL            ${base_url}/proj_${version}.orig.tar.gz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=proj-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING            USE_SYSTEM_PROJ patch_version datumgrid_version
  BUILD_CONDITION  ${test_system_proj}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      -DBUILD_LIBPROJ_SHARED=ON
      -DUSE_THREAD=ON
      -DJNI_SUPPORT=OFF
      -DPROJ_BIN_SUBDIR=bin
      -DPROJ_LIB_SUBDIR=lib
      -DPROJ_DATA_SUBDIR=share/proj
      -DPROJ_DOC_SUBDIR=share/doc/proj
      -DPROJ_INCLUDE_SUBDIR=include
      -DPROJ_CMAKE_SUBDIR=lib/cmake/proj4
    $<$<NOT:$<BOOL:@CMAKE_CROSSCOMPILING@>>:
      -DCONVERT_DATA=ON
      -DPROJ_TESTS=ON
      -DUSE_EXTERNAL_GTEST=ON
    >
    $<$<BOOL:@CMAKE_CROSSCOMPILING@>:
      -DCMAKE_PROGRAM_PATH=${HOST_DIR}/bin # for sqlite3
      -DPROJ_TESTS=OFF
    >
    $<$<NOT:$<OR:$<BOOL:@CMAKE_CROSSCOMPILING@>,$<BOOL:@MSYS@>>>:
    TEST_COMMAND
      "${CMAKE_COMMAND}" -E env
        "PROJ_LIB=${DESTDIR}${CMAKE_STAGING_PREFIX}/share/proj"
        "${CMAKE_COMMAND}" --build . --target test
    TEST_AFTER_INSTALL
    >
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast
    $<$<BOOL:@WIN32@>:
      COMMAND
        # GDAL tries to link -lproj. Proj4-config.cmake references libproj_6_1.dll.a.
        "${CMAKE_COMMAND}" -E copy
          "${DESTDIR}${CMAKE_STAGING_PREFIX}/lib/libproj_6_1.dll.a"
          "${DESTDIR}${CMAKE_STAGING_PREFIX}/lib/libproj.dll.a"
    >
    COMMAND
      "${CMAKE_COMMAND}" -E copy_directory
        "<SOURCE_DIR>/../proj-datumgrid-${datumgrid_version}"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/proj"
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../proj-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/proj-${patch_version}.txt"
  ]]
)
