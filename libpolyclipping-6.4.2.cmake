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

set(version        6.4.2)
set(download_hash  SHA256=69a2fadc3c0b6c06c3f77e92067b65e28e398a75d1260e9114c283a04e76c463)
set(patch_version  ${version}-7)
set(patch_hash     SHA256=eb5337f173e6b7a465fb81b4b1295b925e1711c9902c670dfee2679654537944)
set(base_url       https://snapshot.debian.org/archive/debian/20200731T211026Z/pool/main/libp/libpolyclipping/)

option(USE_SYSTEM_POLYCLIPPING "Use the system libpolyclipping if possible" ON)

set(test_system_libpolyclipping [[
	if(USE_SYSTEM_POLYCLIPPING)
		enable_language(C)
		find_library(POLYCLIPPING_LIBRARY NAMES polyclipping QUIET)
		find_path(POLYCLIPPING_INCLUDE_DIR NAMES clipper.hpp QUIET)
		string(FIND "${POLYCLIPPING_LIBRARY}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(POLYCLIPPING_LIBRARY AND POLYCLIPPING_INCLUDE_DIR AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} libpolyclipping: ${POLYCLIPPING_LIBRARY}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           libpolyclipping-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}libpolyclipping_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           libpolyclipping-multi
  VERSION        ${patch_version}
  DEPENDS
    source:libpolyclipping-patches-${patch_version}
  
  SOURCE
    URL            ${base_url}libpolyclipping_${version}.orig.tar.bz2
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=libpolyclipping-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
    # On Windows, import libraries count as ARCHIVE
    COMMAND
      sed -i -e [[ s/polyclipping LIBRARY DESTINATION/polyclipping ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}" LIBRARY DESTINATION/ ]] cpp/CMakeLists.txt
    # On Windows, shared libraries count as RUNTIME.
    COMMAND
      sed -i -e [[ s/polyclipping ARCHIVE DESTINATION/polyclipping RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}\/bin" ARCHIVE DESTINATION/ ]] cpp/CMakeLists.txt
)

# Build from a copy of the cpp directory
superbuild_package(
  NAME           libpolyclipping
  VERSION        ${patch_version}
  PROVIDES       libpolyclipping
  DEPENDS
    source:libpolyclipping-multi-${patch_version}
    common-licenses
  
  SOURCE
    DOWNLOAD_COMMAND
      ${CMAKE_COMMAND} -E copy_directory 
        <SOURCE_DIR>/../libpolyclipping-multi-${patch_version}/cpp
        <SOURCE_DIR>
  
  USING            USE_SYSTEM_POLYCLIPPING patch_version version
  BUILD_CONDITION  ${test_system_libpolyclipping}
  BUILD [[
    CMAKE_ARGS
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
      -DCMAKE_BUILD_TYPE:STRING=$<CONFIG>
      # VERSION is needed in the pkgconfig file
      -DVERSION=${version} --no-warn-unused-cli
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../libpolyclipping-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/libpolyclipping-${patch_version}.txt"
  ]]
)
