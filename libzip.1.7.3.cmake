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

set(version        1.7.3)
set(download_hash  SHA256=c0a086901dfc8bda0fb8695f2d3c8050ed140b7899536b9348bcc72b47b2f307)
set(patch_version  ${version})
set(base_url       https://github.com/nih-at/libzip/archive/)

superbuild_package(
  NAME           libzip
  VERSION        ${patch_version}
  DEPENDS
    common-licenses
  
  SOURCE
    URL            ${base_url}v${version}.tar.gz
    URL_HASH       ${download_hash}
  
  USING            patch_version extra_cflags extra_cxxflags
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DCMAKE_BUILD_TYPE:STRING=$<CONFIG>"
      "-DBUILD_SHARED_LIBS=ON"
      "-DCMAKE_C_STANDARD_LIBRARIES:STRING=-latomic -lm -lc"
    $<$<NOT:$<OR:$<BOOL:@CMAKE_CROSSCOMPILING@>,$<BOOL:@MSYS@>>>:
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast
  ]]
)
