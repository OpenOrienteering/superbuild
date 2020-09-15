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

# https://tracker.debian.org/pkg/gdal

set(version        3.6.1)
set(download_hash  SHA256=3d4e589d81b2006ca603c1ab712c9715a76227293032d05b26fca603f90b3f5b)
set(patch_version  ${version})
set(base_url       https://github.com/protocolbuffers/protobuf/archive/)

superbuild_package(
  NAME           protobuf
  VERSION        ${patch_version}
  DEPENDS
    common-licenses
    zlib
  
  SOURCE
    URL            ${base_url}v${version}/protobuf-cpp-${version}.tar.gz
    URL_HASH       ${download_hash}
  
  USING            patch_version extra_cflags extra_cxxflags
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DCMAKE_BUILD_TYPE:STRING=$<CONFIG>"
      -DBUILD_SHARED_LIBS=ON
      -Dprotobuf_BUILD_TESTS=OFF
      "-DANDROID_LINKER_FLAGS=-landroid -llog"
      ${SOURCE_DIR}/cmake

    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast
  ]]
)
