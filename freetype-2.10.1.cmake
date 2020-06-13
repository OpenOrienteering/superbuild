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

set(version        2.10.1)
set(download_hash  SHA256=3a60d391fd579440561bf0e7f31af2222bc610ad6ce4d9d7bd2165bca8669110)
set(patch_version  ${version}-2)
set(patch_hash     SHA256=3d1405fe90e17ee290e06f4fd65a16ff38d9f9604aff12c40a0574edb3dbbe62)
set(base_url       https://snapshot.debian.org/archive/debian/20191015T150039Z/pool/main/f/freetype/)

option(USE_SYSTEM_FREETYPE "Use the system Freetype if possible" ON)

set(test_system_freetype [[
	if(${USE_SYSTEM_FREETYPE})
		enable_language(C)
		find_package(Freetype)
		string(FIND "${FREETYPE_LIBRARIES}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(FREETYPE_FOUND AND FREETYPE_INCLUDE_DIRS AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} FreeType: ${FREETYPE_LIBRARY} (${FREETYPE_VERSION_STRING})")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           freetype-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}freetype_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           freetype
  VERSION        ${patch_version}
  DEPENDS
    source:freetype-patches-${patch_version}
    libpng
    zlib
  
  SOURCE
    URL            ${base_url}freetype_${version}.orig.tar.gz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      sed -e [[ /^fix-js-doc\|^ft2demos\|^hide-donations\|^no-web-fonts/d ]] -i --
        "<SOURCE_DIR>/../freetype-patches-${patch_version}/patches/series"
    COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=freetype-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING            USE_SYSTEM_FREETYPE patch_version
  BUILD_CONDITION  ${test_system_freetype}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      -DBUILD_SHARED_LIBS=ON
      -DFT_WITH_PNG=ON
      -DFT_WITH_ZLIB=ON
      -DENABLE_QT5=OFF
      -DCMAKE_DISABLE_FIND_PACKAGE_HarfBuzz=ON
      -DCMAKE_DISABLE_FIND_PACKAGE_BZip2=ON
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../freetype-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/freetype-${patch_version}.txt"
  ]]
)
