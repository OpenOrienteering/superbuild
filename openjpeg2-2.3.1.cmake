# This file is part of OpenOrienteering.

# Copyright 2019 Kai Pastor
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

set(version        2.3.1)
set(download_hash  SHA256=69d39843a25f1a482e1b568fd042eb34837ffc0d708ab7717edeb52e592ecbeb)
set(patch_version  ${version}-1)
set(patch_hash     SHA256=ae77564e1fb581fbed5a6bc09e6948de018f0c457f6b7c9d34721985d236c9fe)
set(base_url       https://snapshot.debian.org/archive/debian/20191008T150147Z/pool/main/o/openjpeg2/)

option(USE_SYSTEM_OPENJPEG "Use the system OpenJPEG if possible" ON)

set(test_system_openjpeg2 [[
	if(${USE_SYSTEM_OPENJPEG})
		enable_language(C)
		find_package(OpenJPEG CONFIG QUIET)
		string(FIND "${OPENJPEG_CMAKE_DIR}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(OPENJPEG_LIBRARIES AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} OpenJPEG: ${OPENJPEG_LIBRARIES}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           openjpeg2-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}openjpeg2_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)

superbuild_package(
  NAME           openjpeg2
  VERSION        ${patch_version}
  DEPENDS
    source:openjpeg2-patches-${patch_version}
    curl
    libpng
    tiff
    zlib
  SOURCE
    URL            ${base_url}openjpeg2_${version}.orig.tar.xz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=openjpeg2-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING            USE_SYSTEM_OPENJPEG patch_version version
  BUILD_CONDITION  ${test_system_openjpeg2}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DOPENJPEG_INSTALL_DATA_DIR=share/openjpeg2"
      "-DOPENJPEG_INSTALL_INCLUDE_DIR=include/openjpeg2"
      "-DOPENJPEG_INSTALL_DOC_DIR=share/doc/openjpeg2"
      "-DOPENJPEG_INSTALL_PACKAGE_DIR=lib/cmake/OpenJPEG-${version}"
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../openjpeg2-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/openjpeg2-${patch_version}.txt"
  ]]
)
