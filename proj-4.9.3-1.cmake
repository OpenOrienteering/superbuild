# This file is part of OpenOrienteering.

# Copyright 2016 Kai Pastor
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
set(download_hash  MD5=d598336ca834742735137c5674b214a1)
set(patch_version  ${version}-1)
set(patch_hash     MD5=766b9ebedbc282ce2996794c722dc43a)

option(USE_SYSTEM_PROJ "Use the system PROJ4 if possible" ON)

set(test_system_proj [[
	if(${USE_SYSTEM_PROJ})
		enable_language(C)
		find_library(PROJ_LIBRARY NAMES proj NO_CMAKE_FIND_ROOT_PATH QUIET)
		if(PROJ_LIBRARY)
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           proj-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            http://http.debian.net/debian/pool/main/p/proj/proj_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           proj
  VERSION        ${patch_version}
  DEPENDS
    source:proj-patches-${patch_version}
  
  SOURCE
    URL            http://http.debian.net/debian/pool/main/p/proj/proj_${version}.orig.tar.gz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=proj-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
    #COMMAND
    #  unshar -c -d "<SOURCE_DIR>/nad" "<SOURCE_DIR>/../proj-patches-${patch_version}/datumgrids.shar"
    #COMMAND
    #  unshar -c -d "<SOURCE_DIR>/nad" "<SOURCE_DIR>/../proj-patches-${patch_version}/datumgrids.shar"
  
  USING            USE_SYSTEM_PROJ
  BUILD_CONDITION  ${test_system_proj}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}"
      "-DCMAKE_STAGING_PREFIX=${CMAKE_STAGING_PREFIX}"
      -DBUILD_LIBPROJ_SHARED=ON
      -DUSE_THREAD=OFF
      -DJNI_SUPPORT=OFF
      -DPROJ_BIN_SUBDIR=bin
      -DPROJ_LIB_SUBDIR=lib
      -DPROJ_DATA_SUBDIR=share/proj
      -DPROJ_DOC_SUBDIR=share/doc/proj
      -DPROJ_INCLUDE_SUBDIR=include
  ]]
)
