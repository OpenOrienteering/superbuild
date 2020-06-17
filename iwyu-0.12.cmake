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

set(version        0.12)
set(debian_version 8.0)
set(download_hash  SHA256=2df080a3e657ebf40386c94a327d1aeeb9ff8d4569bfb860df398629b7f0fdb6)
set(patch_version  ${debian_version}-1)
set(patch_hash     SHA256=31125566ce6752710bf37b2202933729382c78ae73c575f23c2bed1f98a79016)
set(base_url       https://snapshot.debian.org/archive/debian/20190707T150059Z/pool/main/i/iwyu)

set(IWYU_LLVM_ROOT "/usr/lib/llvm-8" CACHE PATH
  "The LLVM root to be prefered by iwyu"
)


superbuild_package(
  NAME           iwyu-patches
  VERSION        ${version}+debian${patch_version}
  
  SOURCE
    URL            ${base_url}/iwyu_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           iwyu
  VERSION        ${version}+debian${patch_version}
  DEPENDS
    source:iwyu-patches-${version}+debian${patch_version}
  
  SOURCE
    URL            ${base_url}/iwyu_${debian_version}.orig.tar.gz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=iwyu-patches-${version}+debian${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING            version patch_version IWYU_LLVM_ROOT
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DCMAKE_BUILD_TYPE:STRING=$<CONFIG>"
      "-DCMAKE_PREFIX_PATH=${IWYU_LLVM_ROOT}"
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../iwyu-patches-${version}+debian${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/iwyu-${version}+debian${patch_version}.txt"
  ]]
)
