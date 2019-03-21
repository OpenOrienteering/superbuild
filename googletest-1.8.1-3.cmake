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

set(version        1.8.1)
set(download_hash  SHA256=9bf1fe5182a604b4135edc1a425ae356c9ad15e9b23f9f12a02e80184c3a249c)
set(patch_version  ${version}-3)
set(patch_hash     SHA256=960e7dd2cdbaa108707b93fc5b5681a4b123682dda05af103018761cba4e6280)
set(base_url       https://snapshot.debian.org/archive/debian/20190113T030047Z/pool/main/g/googletest)

option(USE_SYSTEM_GOOGLETEST "Use the system googletest if possible" ON)

set(test_system_googletest [[
	if(USE_SYSTEM_GOOGLETEST)
	    enable_language(C) # Required for FindThread in GTest package config
		find_package(GTest 1.8 CONFIG QUIET)
		find_package(GTest 1.8 MODULE QUIET)
		if(TARGET GTest::gtest)
			get_target_property(configurations GTest::gtest IMPORTED_CONFIGURATIONS)
			if(configurations)
				list(GET configurations 0 config)
				get_target_property(googletest_location GTest::gtest "IMPORTED_LOCATION_${config}")
			else()
				get_target_property(googletest_location GTest::gtest "IMPORTED_LOCATION")
			endif()
			string(FIND "${googletest_location}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
			if(NOT staging_prefix_start EQUAL 0)
				message(STATUS "Found ${SYSTEM_NAME} googletest: ${googletest_location}")
				set(BUILD_CONDITION 0)
			endif()
		elseif(TARGET GTest::GTest)
			get_target_property(configurations GTest::GTest IMPORTED_CONFIGURATIONS)
			if(configurations)
				list(GET configurations 0 config)
				get_target_property(googletest_location GTest::GTest "IMPORTED_LOCATION_${config}")
			else()
				get_target_property(googletest_location GTest::GTest "IMPORTED_LOCATION")
			endif()
			string(FIND "${googletest_location}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
			if(NOT staging_prefix_start EQUAL 0)
				message(STATUS "Found ${SYSTEM_NAME} googletest: ${googletest_location}")
				set(BUILD_CONDITION 0)
			endif()
		endif()
	endif()
]])

# legacy

superbuild_package(
  NAME           googletest-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}/googletest_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)

superbuild_package(
  NAME           googletest
  VERSION        ${patch_version}
  DEPENDS
    source:googletest-patches-${patch_version}
  
  SOURCE
    URL            ${base_url}/googletest_${version}.orig.tar.gz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=googletest-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING            USE_SYSTEM_GOOGLETEST patch_version
  BUILD_CONDITION  ${test_system_googletest}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../googletest-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/googletest-${patch_version}.txt"
  ]]
)
