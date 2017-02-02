# This file is part of OpenOrienteering.

# Copyright 2016, 2017 Kai Pastor
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
	
	if(NOT DEFINED ${system_name}_INSTALL_PREFIX)
		set(${system_name}_INSTALL_PREFIX "/ProgramFiles")
	endif()
	
	if(NOT DEFINED ${system_name}_FIND_ROOT_PATH)
		set(${system_name}_FIND_ROOT_PATH "${install_dir}")
	endif()
	
	set(toolchain [[
# Generated by ]] "${CMAKE_CURRENT_LIST_FILE}\n" [[

set(SYSTEM_NAME            "]] ${system_name} [[")
set(CMAKE_SYSTEM_NAME      "Windows")
set(SUPERBUILD_TOOLCHAIN_TRIPLET "]] ${system_name} [[")
set(CMAKE_C_COMPILER       "]] "${${system_name}-gcc_EXECUTABLE}" [[")
set(CMAKE_CXX_COMPILER     "]] "${${system_name}-g++_EXECUTABLE}" [[")
set(CMAKE_RC_COMPILER      "]] "${${system_name}-windres_EXECUTABLE}" [[")

set(TOOLCHAIN_DIR          "]] "${toolchain_dir}" [[")
set(INSTALL_DIR            "]] "${install_dir}" [[")
# Some packages don't build well with spaces in the path ("Program Files").
set(CMAKE_INSTALL_PREFIX   "]] "${${system_name}_INSTALL_PREFIX}" [["
    CACHE PATH             "Install path prefix, prepended onto install directories")

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
    
    superbuild_package(
      NAME         ${system_name}-toolchain
      VERSION      ${version}
      SYSTEM_NAME  ${system_name}
      
      SOURCE_WRITE
        toolchain.cmake toolchain
      
      BUILD [[
        CONFIGURE_COMMAND ""
        BUILD_COMMAND     ""
        INSTALL_COMMAND   "${CMAKE_COMMAND}" -E copy_if_different
          "${SOURCE_DIR}/toolchain.cmake" "${INSTALL_DIR}/toolchain.cmake"
      ]]
    )
endforeach(system_name)
