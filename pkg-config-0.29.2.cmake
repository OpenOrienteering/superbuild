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

set(version        0.29.2)
set(download_hash  SHA256=6fc69c01688c9458a57eb9a1664c9aba372ccda420a02bf4429fe610e7e7d591)
set(patch_version  ${version}-1)
set(patch_hash     SHA256=6ecdd3463718e8922b53fca8d2fd37db4ba178f078b5e3ccd38c1a6efffb94ad)
set(base_url       https://snapshot.debian.org/archive/debian/20200421T214331Z/pool/main/p/pkg-config/)

option(USE_SYSTEM_PKG_CONFIG "Use the system pkg-config" OFF)

set(build_condition [[
	if (USE_SYSTEM_PKG_CONFIG)
		set(BUILD_CONDITION 0)
	else()
		set(BUILD_CONDITION 1)
	endif()
]])

set(download_pkg-config_diff_cmake "${PROJECT_BINARY_DIR}/download-pkg-config_${patch_version}.diff.cmake")
file(WRITE "${download_pkg-config_diff_cmake}" "
file(DOWNLOAD
  \"${base_url}/pkg-config_${patch_version}.diff.gz\"
  \"${SUPERBUILD_DOWNLOAD_DIR}/pkg-config_${patch_version}.diff.gz\"
  EXPECTED_HASH ${patch_hash}
)")


superbuild_package(
  NAME           pkg-config
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}pkg-config_${version}.orig.tar.gz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      # Save unchanged m4 files.
      ${CMAKE_COMMAND} -E tar cf unpatched.tar "glib/m4macros"
    COMMAND
      "${CMAKE_COMMAND}" -P "${download_pkg-config_diff_cmake}"
    COMMAND
      gunzip -c "${SUPERBUILD_DOWNLOAD_DIR}/pkg-config_${patch_version}.diff.gz" > "pkg-config_${patch_version}.diff"
    COMMAND
      patch -N -p1 < "pkg-config_${patch_version}.diff"
    COMMAND
      # Restore unchanged m4 files, or we will need aclocal.
      ${CMAKE_COMMAND} -E tar xf unpatched.tar
  
  USING            USE_SYSTEM_PKG_CONFIG patch_version
  BUILD_CONDITION  ${build_condition}
  BUILD [[
    CONFIGURE_COMMAND
      "${SOURCE_DIR}/configure"
        "--prefix=${TOOLCHAIN_DIR}"
        "--with-pc-path=${CMAKE_STAGING_PREFIX}/lib/pkgconfig:${CMAKE_STAGING_PREFIX}/share/pkgconfig"
        "--with-internal-glib"
        "--disable-host-tool"
        $<$<NOT:$<STREQUAL:@SUPERBUILD_TOOLCHAIN_TRIPLET@,>>:
        "--program-prefix=${SUPERBUILD_TOOLCHAIN_TRIPLET}-"
        >
    INSTALL_COMMAND
      "$(MAKE)" install "DESTDIR=${DESTDIR}"
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/debian/copyright"
        "${DESTDIR}${TOOLCHAIN_DIR}/share/doc/pkg-config/copyright"
  ]]
)
