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

set(version        1.8.13)
set(download_hash  SHA256=af667887bd7a87dc0dbf9ac8d86c96b552dfb8ca9c790ed1cbffaa6131573f6b)

option(USE_SYSTEM_DOXYGEN "Use the system DOXYGEN if possible" ON)

set(test_system_doxygen [[
	if(USE_SYSTEM_DOXYGEN)
		find_program(DOXYGEN_EXECUTABLE NAMES doxygen ONLY_CMAKE_FIND_ROOT_PATH QUIET)
		string(FIND "${DOXYGEN_EXECUTABLE}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(DOXYGEN_EXECUTABLE AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} doxygen: ${DOXYGEN_EXECUTABLE}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

superbuild_package(
  NAME           doxygen
  VERSION        ${version}
  DEPENDS        zlib
  
  SOURCE
    URL            ${SUPERBUILD_DEBIAN_BASE_URL_2017_06}/pool/main/d/doxygen/doxygen_${version}.orig.tar.gz
    URL_HASH       ${download_hash}
  
  USING            USE_SYSTEM_DOXYGEN
  BUILD_CONDITION  ${test_system_doxygen}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      -Denglish_only=1
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast
  ]]
)
