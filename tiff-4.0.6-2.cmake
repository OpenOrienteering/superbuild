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

set(version        4.0.6)
set(download_hash  SHA256=4d57a50907b510e3049a4bba0d7888930fdfc16ce49f1bf693e5b6247370d68c)
set(patch_version  ${version}-2)
set(patch_hash     SHA256=82a0ef3f713d2a22d40b9be71fd121b9136657d313ae6b76b51430302a7b9f8b)

option(USE_SYSTEM_LIBTIFF "Use the system libtiff if possible" ON)

set(test_system_tiff [[
	if(${USE_SYSTEM_LIBTIFF})
		enable_language(C)
		find_package(TIFF CONFIG NO_CMAKE_FIND_ROOT_PATH QUIET)
		find_package(TIFF MODULE)
		if(TARGET TIFF::TIFF)
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           tiff-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            http://http.debian.net/debian/pool/main/t/tiff/tiff_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           tiff
  VERSION        ${patch_version}
  DEPENDS
    source:tiff-patches-${patch_version}
    libjpeg
    liblzma
    zlib
  
  SOURCE
    URL            http://http.debian.net/debian/pool/main/t/tiff/tiff_${version}.orig.tar.gz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=tiff-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING            USE_SYSTEM_LIBTIFF version patch
  BUILD_CONDITION  ${test_system_tiff}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}"
      "-DCMAKE_STAGING_PREFIX=${CMAKE_STAGING_PREFIX}"
      # This cache entry is a fallback, needed for MinGW
      "-DFILE_OFFSET_BITS=32"
      # USE_WIN32_FILEIO causes build problems and doesn't seem to be the
      # default for autoconf/configure controlled builds. In addition, more
      # trouble is pending, http://bugzilla.maptools.org/show_bug.cgi?id=1941.
      "-DUSE_WIN32_FILEIO:BOOL=OFF"
    # tiff uses CMAKE_INSTALL_PREFIX incorrectly
    INSTALL_COMMAND
      "$(MAKE)" -j1 install/strip "DESTDIR=${INSTALL_DIR}"
  ]]
)
