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

set(version        5.1.9)
set(download_hash  SHA256=292b10b86a87cb05f9dcbe1b6c7b99f3187a106132dd14f1ba79c90f561c3295)
set(patch_version  ${version}-1)
set(patch_hash     SHA256=fa7d879571e40ecbea6934f0fa3100a7cba0f7313c2de8ff61d62294970ad86d)
set(base_url       https://snapshot.debian.org/archive/debian/20191213T092546Z/pool/main/g/giflib/)

option(USE_SYSTEM_LIBGIF "Use the system giflib if possible" ON)

set(test_system_gif [[
	if(USE_SYSTEM_LIBGIF)
		enable_language(C)
		find_package(GIF 4 CONFIG QUIET)
		find_package(GIF 4 MODULE QUIET)
		string(FIND "${GIF_INCLUDE_DIR}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(GIF_FOUND AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found giflib: ${GIF_LIBRARIES}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           giflib-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}giflib_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)

superbuild_package(
  NAME           giflib
  VERSION        ${patch_version}
  DEPENDS
    source:giflib-patches-${patch_version}
  
  SOURCE
    URL            ${base_url}giflib_${version}.orig.tar.bz2
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=giflib-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING            USE_SYSTEM_LIBGIF patch_version
  BUILD_CONDITION  ${test_system_gif}
  BUILD [[
    # Cannot do out-of-source build of giflib
    CONFIGURE_COMMAND
      "${CMAKE_COMMAND}" -E make_directory "${BINARY_DIR}"
    COMMAND
      "${CMAKE_COMMAND}" -E copy_directory "${SOURCE_DIR}" "${BINARY_DIR}"
    BUILD_COMMAND
      # The doc files exist, don't regenerate them here
      "$(MAKE)" -C doc --touch
    COMMAND
      "$(MAKE)"
        "PREFIX=${CMAKE_INSTALL_PREFIX}"
        "CC=${SUPERBUILD_CC}"
        "CPPFLAGS=${SUPERBUILD_CPPFLAGS}$<$<BOOL:@ANDROID@>: -DS_IREAD=S_IRUSR -DS_IWRITE=S_IWUSR>"
        "CFLAGS=${SUPERBUILD_CFLAGS} -fPIC"
        "LDFLAGS=${SUPERBUILD_LDFLAGS}"
    INSTALL_COMMAND
      "$(MAKE)" install "DESTDIR=${DESTDIR}${INSTALL_DIR}"
        "PREFIX=${CMAKE_INSTALL_PREFIX}"
    COMMAND
      "${CMAKE_COMMAND}" -E copy_if_different
        "<SOURCE_DIR>/../giflib-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/giflib-${patch_version}.txt"
  ]]
)

superbuild_package(
  NAME           libgif
  VERSION        ${patch_version}
  DEPENDS        giflib-${patch_version}
)
