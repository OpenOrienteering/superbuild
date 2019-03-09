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

set(version        6.4.2)
set(download_hash  SHA256=69a2fadc3c0b6c06c3f77e92067b65e28e398a75d1260e9114c283a04e76c463)
set(patch_version  ${version}-3)
set(patch_hash     SHA256=96b0a1bd0187f069cd3865e209b8f257da210ca541f9cb4f654173ae90fb3bec)

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
    URL            ${SUPERBUILD_DEBIAN_BASE_URL_2017_11}/pool/main/libp/libpolyclipping/libpolyclipping_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           libpolyclipping
  VERSION        ${patch_version}
  DEPENDS
    source:libpolyclipping-patches-${patch_version}
    common-licenses
  
  SOURCE
    URL            ${SUPERBUILD_DEBIAN_BASE_URL_2017_11}/pool/main/libp/libpolyclipping/libpolyclipping_${version}.orig.tar.bz2
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=libpolyclipping-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
    # On Windows, shared libraries count as RUNTIME, not LIBRARY.
    COMMAND
      sed -i -e [[ s/LIBRARY DESTINATION/RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}\/bin" LIBRARY DESTINATION/ ]] cpp/CMakeLists.txt
  
  USING            USE_SYSTEM_POLYCLIPPING patch_version version
  BUILD_CONDITION  ${test_system_libpolyclipping}
  BUILD [[
    CONFIGURE_COMMAND
      "${CMAKE_COMMAND}" "${SOURCE_DIR}/cpp"
        "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
        "-DCMAKE_BUILD_TYPE:STRING=$<CONFIG>"
        "-DBUILD_SHARED_LIBS:BOOL=ON" # install fails for static lib
        --no-warn-unused-cli
        # polyclipping uses CMAKE_{INSTALL,STAGING}_PREFIX incorrectly
        -UCMAKE_STAGING_PREFIX
        # VERSION is needed in the pkgconfig file
        "-DVERSION=${version}"
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast -- "DESTDIR=${DESTDIR}${INSTALL_DIR}"
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../libpolyclipping-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/libpolyclipping-${patch_version}.txt"
  ]]
)
