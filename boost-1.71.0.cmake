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

set(version        1.71.0)
set(download_hash  SHA256=e30fb3f666df75fc2ba23403ccbd8bcb0ee5595dc099412b4abde7a9fdde3918)
set(patch_version  ${version}-7)
set(patch_hash     SHA256=5dd716c499d68bdb977061e9540df641a0c88d4546c74f7a578ff51369839cba)
set(base_url       https://snapshot.debian.org/archive/debian/20201012T150222Z/pool/main/b/boost1.71/)

option(USE_SYSTEM_BOOST "Use the system Boost Libraries if possible" ON)

set(test_system_boost [[
	if(${USE_SYSTEM_BOOST})
		enable_language(C)
		find_package(Boost QUIET)
		if(Boost_FOUND)
			string(FIND "${BOOST_INCLUDE_DIR}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
			if(BOOST_INCLUDE_DIR AND NOT staging_prefix_start EQUAL 0)
				message(STATUS "Found ${SYSTEM_NAME} Boost Libraries: ${BOOST_INCLUDE_DIR}")
				set(BUILD_CONDITION 0)
			endif()
		endif()
	endif()
]])

superbuild_package(
  NAME           boost1.71-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}boost1.71_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           boost1.71-bootstrap
  VERSION        ${patch_version}
  DEPENDS
    source:boost1.71-patches-${patch_version}
    host:bison
  
  SOURCE
    URL            ${base_url}boost1.71_${version}.orig.tar.xz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=boost1.71-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING            USE_SYSTEM_BOOST patch_version
  BUILD_CONDITION  ${test_system_boost}
  BUILD [[
    # Cannot do out-of-source build of boost
    CONFIGURE_COMMAND
      "${CMAKE_COMMAND}" -E make_directory "${BINARY_DIR}"
    COMMAND
      "${CMAKE_COMMAND}" -E copy_directory "${SOURCE_DIR}" "${BINARY_DIR}"
    BUILD_COMMAND
      "${CMAKE_COMMAND}" -E chdir tools/build bison -y -d -o src/engine/jamgram.cpp src/engine/jamgram.y
    COMMAND
      sh ./bootstrap.sh --without-icu --prefix=${DESTDIR}${CMAKE_STAGING_PREFIX}
    COMMAND
      ./b2 tools/bcp
    COMMAND
      ./b2 --with-headers
    INSTALL_COMMAND
      ""
  ]]
)

superbuild_package(
  NAME           boost-smart_ptr
  VERSION        ${patch_version}
  DEPENDS
    host:boost1.71-bootstrap
  
  SOURCE           boost1.71-bootstrap-${patch_version}
  
  USING            USE_SYSTEM_BOOST patch_version
  BUILD_CONDITION  ${test_system_boost}
  BUILD [[
    CONFIGURE_COMMAND
      ""
    BUILD_COMMAND
      ""
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" -E make_directory "${DESTDIR}${CMAKE_STAGING_PREFIX}/include"
    COMMAND
      "${CMAKE_COMMAND}" -E chdir "<BINARY_DIR>/../../default/boost1.71-bootstrap-${patch_version}"
        ./dist/bin/bcp boost/scoped_ptr.hpp "${DESTDIR}${CMAKE_STAGING_PREFIX}/include"
    COMMAND
      "${CMAKE_COMMAND}" -E chdir "<BINARY_DIR>/../../default/boost1.71-bootstrap-${patch_version}"
        ./dist/bin/bcp boost/intrusive_ptr.hpp "${DESTDIR}${CMAKE_STAGING_PREFIX}/include"
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<BINARY_DIR>/../../source/boost1.71-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/boost-${patch_version}.txt"
  ]]
)
