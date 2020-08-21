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

set(system_name_32 i686-w64-mingw32)
set(system_name_64 x86_64-w64-mingw32)
set(version     1)

option(ENABLE_${system_name_32} "Enable the ${system_name_32} toolchain" 0)
option(ENABLE_${system_name_64} "Enable the ${system_name_64} toolchain" 0)
option(mingw-w64_FIX_HEADERS    "Install missing mingw-w64 headers"      0)

set(i686-w64-mingw32_SYSTEM_PROCESSOR   x86)
set(x86_64-w64-mingw32_SYSTEM_PROCESSOR AMD64)

# Debian/Ubuntu package providing gnustl copyright files
set(i686-w64-mingw32_g++_deb   "g++-mingw-w64-i686")
set(x86_64-w64-mingw32_g++_deb "g++-mingw-w64-x86-64")

foreach(system_name ${system_name_32} ${system_name_64})
	if(NOT ENABLE_${system_name})
		continue()
	endif()
	
	foreach(tool gcc g++ windres)
		find_program(${system_name}-${tool}_EXECUTABLE ${system_name}-${tool})
		if(${${system_name}-${tool}_EXECUTABLE} MATCHES "NOTFOUND")
			message(FATAL_ERROR "${system_name}-${tool} must be available")
		endif()
		mark_as_advanced(${system_name}-${tool}_EXECUTABLE)
	endforeach()
	
	sb_toolchain_dir(toolchain_dir ${system_name})
	sb_install_dir(install_dir ${system_name})
	
	# Absolute paths may help with some packages, or with debugging.
	option(${system_name}_ABSOLUTE_INSTALL_PREFIX "Use an absolute host path for CMAKE_INSTALL_PREFIX" 0)
	if(${system_name}_ABSOLUTE_INSTALL_PREFIX)
		set(${system_name}_INSTALL_PREFIX "${install_dir}${${system_name}_INSTALL_PREFIX}")
		set(install_dir "")
	endif()
	
	if(NOT DEFINED ${system_name}_FIND_ROOT_PATH)
		set(${system_name}_FIND_ROOT_PATH [[${INSTALL_DIR}]])
	endif()
	
	get_filename_component(compiler_dir "${${system_name}-g++_EXECUTABLE}" DIRECTORY)
	find_file(${system_name}-gnustl-copyright-file
	  NAMES copyright
	  HINTS "${compiler_dir}/.."
	  PATHS "/usr"
	  PATH_SUFFIXES "/share/doc/${${system_name}_g++_deb}"
	  NO_DEFAULT_PATH
	  DOC "The copyright file for ${system_name} gcc libstdc++ etc."
	)
	if(${system_name}-gnustl-copyright-file)
		set(${system_name}-gnustl-copyright [["gnustl.txt" "]] "${${system_name}-gnustl-copyright-file}" [[" "3rd-party"]])
	else()
		set(${system_name}-gnustl-copyright OFF)
		message(WARNING "Unable to find a copyright file for ${system_name} gcc libstdc++ etc.")
		message(WARNING "Please set '${system_name}-gnustl-copyright-file' to the absolute path of such a text file.")
	endif()
	
	string(CONCAT toolchain [[
# Generated by ]] "${CMAKE_CURRENT_LIST_FILE}\n" [[

# Superbuild configuration
set(SYSTEM_NAME            "]] ${system_name} [[")
set(SUPERBUILD_TOOLCHAIN_TRIPLET "]] ${system_name} [[")
set(TOOLCHAIN_DIR          "]] "${toolchain_dir}" [[")
set(INSTALL_DIR            "]] "${install_dir}" [[")
set(explicit_copyright_gnustl ]] "${${system_name}-gnustl-copyright}" [[)

# CMake configuration
set(CMAKE_SYSTEM_NAME      "Windows")
set(CMAKE_SYSTEM_PROCESSOR "]] "${${system_name}_SYSTEM_PROCESSOR}" [[")
set(CMAKE_C_COMPILER       "]] "${${system_name}-gcc_EXECUTABLE}" [[")
set(CMAKE_CXX_COMPILER     "]] "${${system_name}-g++_EXECUTABLE}" [[")
set(CMAKE_RC_COMPILER      "]] "${${system_name}-windres_EXECUTABLE}" [[")
set(CMAKE_INSTALL_PREFIX   "]] "${${system_name}_INSTALL_PREFIX}" [["
    CACHE PATH             "Run-time install path prefix, prepended onto install directories")
set(CMAKE_STAGING_PREFIX   "${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}"
    CACHE PATH             "Build-time install path prefix, prepended onto install directories")

set(CMAKE_FIND_ROOT_PATH   "]] "${${system_name}_FIND_ROOT_PATH}" [[")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(CMAKE_RULE_MESSAGES    OFF CACHE BOOL "Whether to report a message for each make rule")
set(CMAKE_TARGET_MESSAGES  OFF CACHE BOOL "Whether to report a message for each target")
set(CMAKE_VERBOSE_MAKEFILE ON  CACHE BOOL "Enable verbose output from Makefile builds")
]]
)
    #string(MD5 md5 "${toolchain}")
    
    set(missing_headers_source)
    set(configure_command CONFIGURE_COMMAND [[${CMAKE_COMMAND}]] -E echo_append)
    set(build_command     BUILD_COMMAND     [[${CMAKE_COMMAND}]] -E echo_append)
    if(mingw-w64_FIX_HEADERS)
        set(missing_headers_source
          SOURCE
            URL            https://github.com/OpenOrienteering/superbuild/archive/mingw-missing-headers_2018.12.tar.gz
            URL_HASH       SHA256=60228b01060ac8b0ba8e4d264968a50b895fb8ef10e65b62ced8d6b1eeb7cc1c
        )
        set(configure_command CMAKE_ARGS
          [[-DCMAKE_TOOLCHAIN_FILE=${SOURCE_DIR}/toolchain.cmake]])
        set(build_command     BUILD_COMMAND
          [[${CMAKE_COMMAND}]] -E env [[DESTDIR=${${system_name}_INSTALL_DIR}]]
            [[${CMAKE_COMMAND}]] -P cmake_install.cmake)
    endif()
    superbuild_package(
      NAME         ${system_name}-toolchain
      VERSION      ${version}
      SYSTEM_NAME  ${system_name}
      
      ${missing_headers_source}
  
      SOURCE_WRITE
        toolchain.cmake toolchain
      
      USING
        configure_command
        build_command
        system_name
        ${system_name}_INSTALL_DIR
      BUILD [[
        ${configure_command}
        ${build_command}
        INSTALL_COMMAND   "${CMAKE_COMMAND}" -E copy_if_different
          "${SOURCE_DIR}/toolchain.cmake" "${INSTALL_DIR}/toolchain.cmake"
      ]]
    )
endforeach(system_name)
