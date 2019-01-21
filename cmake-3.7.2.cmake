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

set(version        3.7.2)
set(download_hash  SHA256=dc1246c4e6d168ea4d6e042cfba577c1acd65feea27e56f5ff37df920c30cae0)

option(USE_SYSTEM_CMAKE "Use the system CMake if possible" ON)

set(test_system_cmake [[
	if(USE_SYSTEM_CMAKE)
		if(NOT CMAKE_VERSION VERSION_LESS "${version}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           cmake
  VERSION        ${version}
  DEPENDS        curl
                 expat
                 xz-utils
                 zlib
  
  SOURCE
    URL            ${SUPERBUILD_DEBIAN_BASE_URL_2017_06}/pool/main/c/cmake/cmake_${version}.orig.tar.gz
    URL_HASH       ${download_hash}
  
  USING            USE_SYSTEM_CMAKE
                   version
  BUILD_CONDITION  ${test_system_cmake}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast"
  ]]
)
