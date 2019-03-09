# This file is part of OpenOrienteering.

# Copyright 2017-2019 Kai Pastor
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

set(version  9.9)
set(download_hash  SHA256=c941e091eea9d2949b6ed3b8d37ea1d086b50b10d564103d52fafcd129ac1931)

set(cmakelists_txt [[
cmake_minimum_required(VERSION 3.0)
project(base-files NONE)
file(GLOB files "${PROJECT_SOURCE_DIR}/licenses/*")
foreach(file ${files})
    get_filename_component(filename "${file}" NAME)
    install(FILES "${file}"
      RENAME "${filename}.txt"
      DESTINATION share/doc/copyright/common-licenses
      COMPONENT common-licenses
    )
endforeach()
  ]])

superbuild_package(
  NAME           base-files
  VERSION        ${version}
  SOURCE
    URL            ${SUPERBUILD_DEBIAN_BASE_URL_2017_06}/pool/main/b/base-files/base-files_${version}.tar.xz
    URL_HASH       ${download_hash}
  SOURCE_WRITE
    CMakeLists.txt cmakelists_txt
)

superbuild_package(
  NAME           common-licenses
  VERSION        ${version}
  SOURCE         base-files-${version}
  
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
    BUILD_COMMAND ""
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" -DCOMPONENT=common-licenses -P cmake_install.cmake
  ]]
)
