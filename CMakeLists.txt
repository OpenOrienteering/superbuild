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

cmake_minimum_required(VERSION 3.2)
cmake_policy(SET CMP0001 NEW)
cmake_policy(SET CMP0053 NEW)

project(Superbuild C)

set(documentation
  COPYING
  README.md
)

set(SUPERBUILD_HANDLE_ENV "" CACHE STRING
  "Additional environment variables to be passed to packages."
)
list(APPEND SUPERBUILD_HANDLE_ENV
  CPP
  CPPFLAGS
  CC
  CFLAGS
  CXX
  CXXFLAGS
  LDFLAGS
  LIBS
  LD_LIBRARY_PATH
  PATH
  PKG_CONFIG_PATH
)
list(REMOVE_DUPLICATES SUPERBUILD_HANDLE_ENV)

set(SUPERBUILD_STEP_TARGETS "" CACHE STRING
  "CMake ExternalProject step targets to be created")

if(DEFINED DISABLE_DEPENDENCIES)
	message(WARNING "DISABLE_DEPENDENCIES is deprecated, use SUPERBUILD_DISABLE_DEPENDENCIES instead")
	set(SUPERBUILD_DISABLE_DEPENDENCIES "${DISABLE_DEPENDENCIES}" CACHE BOOL
	  "Disable dependencies between binary packages")
	unset(DISABLE_DEPENDENCIES CACHE)
endif()
set(SUPERBUILD_DISABLE_DEPENDENCIES FALSE CACHE BOOL
  "Disable dependencies between binary packages")
mark_as_advanced(SUPERBUILD_DISABLE_DEPENDENCIES)

# Base URLs for source and patch tarballs
set(SUPERBUILD_RELEASE_BASE_URL_2017_06 "https://github.com/OpenOrienteering/superbuild/releases/download/2017.06")
set(SUPERBUILD_RELEASE_BASE_URL_2017_11 "https://github.com/OpenOrienteering/superbuild/releases/download/2017.11")
set(SUPERBUILD_DEBIAN_BASE_URL_2017_03 "http://snapshot.debian.org/archive/debian/20170325T152634Z")
set(SUPERBUILD_DEBIAN_BASE_URL_2017_06 "http://snapshot.debian.org/archive/debian/20170604T033458Z")
set(SUPERBUILD_DEBIAN_BASE_URL_2017_11 "http://snapshot.debian.org/archive/debian/20171110T094433Z")
set(SUPERBUILD_DEBIAN_BASE_URL_2018_02 "http://snapshot.debian.org/archive/debian/20180209T230438Z")
set(SUPERBUILD_DEBIAN_SECURITY_URL_2017_11 "http://snapshot.debian.org/archive/debian-security/20171027T200949Z")
set(SUPERBUILD_DEBIAN_SECURITY_URL_2018_02 "http://snapshot.debian.org/archive/debian-security/20180210T023041Z")

include(CMakeParseArguments)
include(ExternalProject)


# Silence warnings about unused variables (Qt Creator)
set(no_warn_unused
  ${CMAKE_CXX_COMPILER}
  ${SUPERBUILD_DISABLE_DEPENDENCIES}
)


# Global utilities
function(sb_install_dir var system_name)
	if(DEFINED ${system_name}_INSTALL_DIR)
		set(${var} "${${system_name}_INSTALL_DIR}" PARENT_SCOPE)
	else()
		set(${var} "${PROJECT_BINARY_DIR}/${system_name}/install" PARENT_SCOPE)
	endif()
endfunction()



function(sb_install_stamp_dir var system_name)
	set(${var} "${PROJECT_BINARY_DIR}/${system_name}/install/tmp" PARENT_SCOPE)
endfunction()



function(sb_toolchain_dir var system_name)
	if(DEFINED ${system_name}_TOOLCHAIN_DIR)
		set(${var} "${${system_name}_TOOLCHAIN_DIR}" PARENT_SCOPE)
	else()
		set(${var} "${PROJECT_BINARY_DIR}/${system_name}/toolchain" PARENT_SCOPE)
	endif()
endfunction()



function(sb_toolchain_stamp_dir var system_name)
	if(NOT DEFINED ${system_name}_TOOLCHAIN_DIR)
		set(${var} "${PROJECT_BINARY_DIR}/${system_name}/toolchain/tmp" PARENT_SCOPE)
	else()
		set(${var} "" PARENT_SCOPE)
	endif()
endfunction()



function(sb_install_prefix var system_name)
	if(DEFINED ${system_name}_INSTALL_PREFIX)
		set(${var} "${${system_name}_INSTALL_PREFIX}" PARENT_SCOPE)
	else()
		set(${var} "" PARENT_SCOPE)
	endif()
endfunction()



function(_sb_write_if_different filepath)
	string(CONCAT output ${ARGN})
	file(WRITE "${filepath}.raw" "${output}")
	# Create a proper build rule for Ninja et al.
	configure_file("${filepath}.raw" "${filepath}" COPYONLY)
	file(REMOVE "${filepath}.raw")
endfunction()



function(_sb_get_build_command var)
	if(ARGC GREATER 1)
		_sb_get_build_command_2(result "${ARGV1}")
		set(${var} ${result} PARENT_SCOPE)
	elseif(CMAKE_GENERATOR MATCHES "Make")
		set(${var} "$(MAKE)" PARENT_SCOPE)
	else()
		set(${var} "${CMAKE_COMMAND}" --build . PARENT_SCOPE)
	endif()
endfunction()



function(_sb_get_build_command_2 var target)
	if(CMAKE_GENERATOR MATCHES "Make")
		set(${var} "$(MAKE)" "${target}" PARENT_SCOPE)
	else()
		set(${var} "${CMAKE_COMMAND}" --build . --target "${target}" PARENT_SCOPE)
	endif()
endfunction()



function(_sb_write_debian_patch_script)
	option(IGNORE_REVERSED_PATCHES
	  "Ignore patches which appear to be reversed or already applied." OFF)
	set (APPLY_PATCHES_SERIES "${PROJECT_BINARY_DIR}/source/apply-debian-patches.cmake")
	_sb_write_if_different("${APPLY_PATCHES_SERIES}" [[
# Created by ]] ${CMAKE_CURRENT_LIST_FILE} [[
#
# Synopsis:
#  "${CMAKE_COMMAND}" -Dpackage=foo-patches-1.3.2 -P "${APPLY_PATCHES_SERIES}"

if(NOT package)
	message(FATAL_ERROR "Variable 'package' must specify an existing package.")
endif()

set(dir "]] "${PROJECT_BINARY_DIR}" [[/source/${package}")
if(EXISTS "${dir}/patches/series")
	set(IGNORE_REVERSED_PATCHES "]] ${IGNORE_REVERSED_PATCHES} [[")
	file(STRINGS "${dir}/patches/series" series)
	foreach(line ${series})
		string(STRIP "${line}" line)
		if(line MATCHES "^#")
			continue()
		endif()
		message(STATUS "Applying ${line}")
		execute_process(
		  COMMAND patch -N -p1
		  INPUT_FILE "${dir}/patches/${line}"
		  RESULT_VARIABLE exit_code
		  OUTPUT_VARIABLE output
		)
		if(IGNORE_REVERSED_PATCHES
		   AND output MATCHES "Reversed.* patch detected")
			continue()
		endif()
		if(NOT exit_code EQUAL 0)
			message(FATAL_ERROR "Could not apply patch ${line}")
		endif()
	endforeach()
else()
	message(STATUS "No patches series in ${package}.")
	if(NOT EXISTS "${dir}/control")
		message(FATAL_ERROR "No control file - maybe wrong package?")
	endif()
endif()


]]	)
	set (APPLY_PATCHES_SERIES "${APPLY_PATCHES_SERIES}" PARENT_SCOPE)
endfunction()



function(_sb_write_config dir)
	set(output [[
# Created by ]] ${CMAKE_CURRENT_LIST_FILE} [[


if (NOT DEFINED SYSTEM_NAME)
	message(FATAL_ERROR "SYSTEM_NAME must be defined when using ${CMAKE_CURRENT_LIST_FILE}")
endif()

]])
	foreach(name ${ARGN})
		list(APPEND output "set(${name}")
		foreach(item IN LISTS ${name})
			string(REPLACE [["]] [[\"]] escaped "${item}")
			list(APPEND output " \"${escaped}\"")
		endforeach()
		list(APPEND output ")\n")
	endforeach()
	list(APPEND output [[

function(sb_test_build_condition)
	set(BUILD_CONDITION 1)
]] "${SB_PACKAGE_BUILD_CONDITION}" [[
	set(BUILD_CONDITION ${BUILD_CONDITION} PARENT_SCOPE)
endfunction()
]])
	_sb_write_if_different("${dir}/${package}-config.cmake" ${output})
endfunction()



function(_sb_write_generator)
	set(output
"# Created by ${CMAKE_CURRENT_LIST_FILE}

cmake_minimum_required(VERSION 3.1)
cmake_policy(SET CMP0053 NEW)

if(NOT SYSTEM_NAME OR NOT PACKAGE)
	message(FATAL_ERROR \"SYSTEM_NAME and PACKAGE must be given\")
else()
	message(STATUS \"Generating \${PACKAGE} for system \${SYSTEM_NAME}\")
endif()

project(\${PACKAGE}-\${SYSTEM_NAME}-generator NONE)

set_property(GLOBAL PROPERTY RULE_MESSAGES 0)
set_property(GLOBAL PROPERTY TARGET_MESSAGES 0)

include(\"${PROJECT_BINARY_DIR}/config/\${PACKAGE}-config.cmake\")

if(PACKAGE STREQUAL \"toolchain-info\")
	set(LANGUAGES      \"C CXX\")
	set(TOOLCHAIN_INFO \"
include(\\\"${PROJECT_BINARY_DIR}/source/toolchain-info.cmake\\\")
print_toolchain_info()
write_toolchain_info(\\\"\\\${BINARY_DIR}/info.txt\\\")
\")
else()
	set(LANGUAGES      NONE)
	set(TOOLCHAIN_INFO )
endif()

file(READ \"${PROJECT_BINARY_DIR}/config/\${PACKAGE}-CMakeLists.txt.in\" config)
string(CONFIGURE \"\${config}\" config @ONLY)
file(GENERATE OUTPUT \"\${TMP_DIR}/CMakeLists.txt\"
  CONTENT \"\${config}\"
)

# Silence warnings in case these variables are not used.
set(no_warn_unused
  ${SYSTEM_NAME}_INSTALL_DIR
)

")
	_sb_write_if_different("${PROJECT_BINARY_DIR}/config/CMakeLists.txt" ${output})
endfunction()



function(_sb_write_build dir)
	if(NOT SB_PACKAGE_BUILD)
		set(SB_PACKAGE_BUILD [[
  CONFIGURE_COMMAND ""
  BUILD_COMMAND     ""
  INSTALL_COMMAND   ""
]]		)
	endif()
	set(output
"# Template created by ${CMAKE_CURRENT_LIST_FILE}
# Instance created by @CMAKE_CURRENT_LIST_FILE@
#   for system @SYSTEM_NAME@

cmake_minimum_required(VERSION 3.1)
cmake_policy(SET CMP0053 NEW)

message(STATUS \"Configuring @PACKAGE@ for system @SYSTEM_NAME@\")

project(${package}-@SYSTEM_NAME@ @LANGUAGES@)

set_property(GLOBAL PROPERTY RULE_MESSAGES 0)
set_property(GLOBAL PROPERTY TARGET_MESSAGES 0)

set(SYSTEM_NAME      \"@SYSTEM_NAME@\")
set(INSTALL_DIR      \"@INSTALL_DIR@\")
set(TOOLCHAIN_DIR    \"@TOOLCHAIN_DIR@\")
set(CMAKE_BUILD_TYPE \"@CMAKE_BUILD_TYPE@\")
include(\"${dir}/${package}-config.cmake\")

if(CMAKE_GENERATOR MATCHES \"Make\")
	set(DESTDIR \"\$(DESTDIR)\")
else()
	set(DESTDIR \"\")
endif()

@TOOLCHAIN_INFO@

sb_test_build_condition()
if(NOT BUILD_CONDITION)
	message(STATUS \"Not building ${SB_PACKAGE_NAME} for @SYSTEM_NAME@ toolchain\")
	add_custom_target(${package}-@SYSTEM_NAME@-system
	  ALL
	  COMMAND \${CMAKE_COMMAND} -E make_directory \"\${TMP_DIR}/stamp\"
	  COMMAND \${CMAKE_COMMAND} -E echo \"Not building ${SB_PACKAGE_NAME} for @SYSTEM_NAME@ toolchain\"
	)
	add_custom_target(${package}-@SYSTEM_NAME@-package)
	return()
endif()

include(ExternalProject)

ExternalProject_Add(${package}-@SYSTEM_NAME@
  DOWNLOAD_DIR \"\${DOWNLOAD_DIR}\"
  SOURCE_DIR   \"\${SOURCE_DIR}\"
  BINARY_DIR   \"\${BINARY_DIR}\"
  TMP_DIR      \"\${TMP_DIR}\"
  STAMP_DIR    \"\${TMP_DIR}/stamp\"
  INSTALL_DIR  \"\${INSTALL_DIR}\"
  DOWNLOAD_COMMAND \"${CMAKE_COMMAND}\" -E touch_nocreate \"<SOURCE_DIR>/placeholder/@STAMP@\"
${SB_PACKAGE_BUILD})
ExternalProject_Add_StepDependencies(${package}-@SYSTEM_NAME@ configure
  \"" [[${CMAKE_CURRENT_LIST_FILE}]] "\"
  \"${CMAKE_CURRENT_LIST_FILE}\"
)
if(CMAKE_TOOLCHAIN_FILE)
  ExternalProject_Add_StepDependencies(${package}-@SYSTEM_NAME@ configure
    \"" [[${CMAKE_TOOLCHAIN_FILE}]] "\"
  )
endif()

set(stamp_dir \"@INSTALL_STAMP_DIR@\")
if(stamp_dir)
    set(stamp     \"\${stamp_dir}/${package}.stamp\")
    add_custom_command(OUTPUT \"\${stamp}\"
      COMMAND \"${CMAKE_COMMAND}\" -E make_directory \"\${stamp_dir}\"
      COMMAND \"${CMAKE_COMMAND}\" -E touch \"\${stamp}\"
    )
    ExternalProject_Add_StepDependencies(${package}-@SYSTEM_NAME@ install
      \"\${stamp}\"
    )
endif()

")
	if(SUPERBUILD_STEP_TARGETS)
		string(REPLACE ";" " " step_targets "${SUPERBUILD_STEP_TARGETS}")
		list(APPEND output "
ExternalProject_Add_StepTargets(${package}-@SYSTEM_NAME@ ${step_targets})

")
	endif()
	if(SB_PACKAGE_PACKAGE)
		list(APPEND output "
ExternalProject_Add_Step(${package}-@SYSTEM_NAME@ package
  EXCLUDE_FROM_MAIN 1
  ALWAYS 1
  WORKING_DIRECTORY <BINARY_DIR>
  ${SB_PACKAGE_PACKAGE}
)
ExternalProject_Add_StepTargets(${package}-@SYSTEM_NAME@ package)

")
	endif()
	_sb_write_if_different("${dir}/${package}-CMakeLists.txt.in" ${output})
endfunction()



function(_sb_source_write list_name dir rel_path var)
	if(NOT var MATCHES "^[-_.+A-Za-z0-9]")
		message(FATAL_ERROR "Invalid variable name '${var}'")
	endif()
	get_filename_component(out_path "${dir}/${rel_path}" ABSOLUTE)
	_sb_write_if_different("${out_path}" ${${var}})
	list(APPEND ${list_name} "${out_path}")
	if(ARGC GREATER 4)
		_sb_source_write(${list_name} "${dir}" ${ARGN})
	endif()
	set(${list_name} ${${list_name}} PARENT_SCOPE)
endfunction()



function(_sb_create_main_c)
	_sb_write_if_different("${PROJECT_BINARY_DIR}/source/main.c"
	  "// Placeholder file\n"
	  "int main(int argc, char** argv) { return 0\; }\n"
	)
endfunction()



function(_sb_create_toolchain_info)
	string(REPLACE ";" " " env_vars "${SUPERBUILD_HANDLE_ENV}")
	_sb_write_if_different("${PROJECT_BINARY_DIR}/source/toolchain-info.cmake" [[
# Created by ]] "${CMAKE_CURRENT_LIST_FILE}\n" [[

function(toolchain_info_helper out_var headline)
	set(output "${headline}\n\n")
	foreach(var ${ARGN})
		if(var MATCHES "^ENV{")
			string(REPLACE "ENV{" "" var "${var}")
			string(REPLACE "}" "" var "${var}")
			if(DEFINED ENV{${var}})
				set(output "${output}ENV{${var}}=\"$ENV{${var}}\"\n")
			else()
				set(output "${output}ENV{${var}} - not set\n")
			endif()
		elseif(DEFINED ${var})
			set(output "${output}${var}=\"${${var}}\"\n")
		else()
			set(output "${output}${var} - not set\n")
		endif()
	endforeach()
	set(${out_var} "${output}\n" PARENT_SCOPE)
endfunction()

set(toolchain_info_groups )

list(APPEND toolchain_info_groups toolchain_info_var_information)
set(toolchain_info_var_information  "Variables that provide information"
  CMAKE_COMMAND
  CMAKE_CROSSCOMPILING
  CMAKE_GENERATOR
  CMAKE_MAKE_PROGRAM
  CMAKE_SIZEOF_VOID_P
  CMAKE_TOOLCHAIN_FILE
  CMAKE_VERSION
  CMAKE_XCODE_PLATFORM_TOOLSET
  PROJECT_BINARY_DIR
  PROJECT_SOURCE_DIR
)

list(APPEND toolchain_info_groups toolchain_info_var_behavior)
set(toolchain_info_var_behavior  "Variables that change behavior"
  BUILD_SHARED_LIBS
  CMAKE_BUILD_TYPE
  CMAKE_SYSROOT
  CMAKE_FIND_ROOT_PATH
    CMAKE_FIND_ROOT_PATH_MODE_INCLUDE
    CMAKE_FIND_ROOT_PATH_MODE_LIBRARY
    CMAKE_FIND_ROOT_PATH_MODE_PACKAGE
    CMAKE_FIND_ROOT_PATH_MODE_PROGRAM
  CMAKE_INSTALL_PREFIX
  CMAKE_STAGING_PREFIX
  CMAKE_SYSTEM_PREFIX_PATH
    CMAKE_SYSTEM_APPBUNDLE_PATH
    CMAKE_SYSTEM_FRAMEWORK_PATH
    CMAKE_SYSTEM_IGNORE_PATH
    CMAKE_SYSTEM_INCLUDE_PATH
    CMAKE_SYSTEM_LIBRARY_PATH
    CMAKE_SYSTEM_PROGRAM_PATH
)

list(APPEND toolchain_info_groups toolchain_info_var_system)
set(toolchain_info_var_system  "Variables that describe the system"
  CMAKE_HOST_SYSTEM_NAME
  CMAKE_HOST_SYSTEM_VERSION
  CMAKE_HOST_SYSTEM_PROCESSOR
  CMAKE_HOST_APPLE
  CMAKE_HOST_UNIX
  CMAKE_HOST_WIN32
  CMAKE_SYSTEM_NAME
  CMAKE_SYSTEM_VERSION
  CMAKE_SYSTEM_PROCESSOR
  CMAKE_LIBRARY_ARCHITECTURE
  ANDROID
  APPLE
  MINGW
  UNIX
  WIN32
)
if(ANDROID)
    list(APPEND toolchain_info_var_system
      ANDROID_SDK_ROOT
      ANDROID_NDK_ROOT
      ANDROID_ABI
      ANDROID_NATIVE_API_LEVEL
      ANDROID_STL
      ANDROID_TOOLCHAIN
      ANDROID_TOOLCHAIN_NAME
      ANDROID_KEYSTORE_URL
      ANDROID_KEYSTORE_ALIAS
    )
elseif(APPLE)
    list(APPEND toolchain_info_var_system
      XCODE_VERSION
    )
endif()

list(APPEND toolchain_info_groups toolchain_info_var_build)
set(toolchain_info_var_build  "Variables that control the build"
  CMAKE_EXE_LINKER_FLAGS
  CMAKE_EXE_LINKER_FLAGS_DEBUG
  CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO
  CMAKE_EXE_LINKER_FLAGS_RELEASE
  CMAKE_EXE_LINKER_FLAGS_MINSIZEREL
  CMAKE_INSTALL_NAME_DIR
  CMAKE_OSX_DEPLOYMENT_TARGET
  CMAKE_POSITION_INDEPENDENT_CODE
)

list(APPEND toolchain_info_groups toolchain_info_var_languages)
set(toolchain_info_var_languages  "Variables for languages"
  CMAKE_C_COMPILER
  CMAKE_C_COMPILER_VERSION
  CMAKE_C_FLAGS
  CMAKE_C_FLAGS_DEBUG
  CMAKE_C_FLAGS_RELWITHDEBINFO
  CMAKE_C_FLAGS_RELEASE
  CMAKE_C_FLAGS_MINSIZEREL
  CMAKE_C_IMPLICIT_LINK_DIRECTORIES
  CMAKE_CXX_COMPILER
  CMAKE_CXX_COMPILER_VERSION
  CMAKE_CXX_FLAGS
  CMAKE_CXX_FLAGS_DEBUG
  CMAKE_CXX_FLAGS_RELWITHDEBINFO
  CMAKE_CXX_FLAGS_RELEASE
  CMAKE_CXX_FLAGS_MINSIZEREL
  CMAKE_CXX_IMPLICIT_LINK_DIRECTORIES
  CMAKE_INTERNAL_PLATFORM_ABI
  CMAKE_RC_COMPILER
)

list(APPEND toolchain_info_groups toolchain_info_var_superbuild)
set(toolchain_info_var_superbuild  "Variables provided by superbuild"
  HOST_DIR
  INSTALL_DIR
  PACKAGE_NAME
  SOURCE_DIR
  SYSTEM_NAME
  TOOLCHAIN_DIR
)

list(APPEND toolchain_info_groups toolchain_info_var_env)
set(toolchain_info_var_env "Environment variables")
foreach(var ]] "${env_vars}" [[)
	list(APPEND toolchain_info_var_env "ENV{${var}}")
endforeach()

function(print_toolchain_info)
	foreach(group ${toolchain_info_groups})
		toolchain_info_helper(info ${${group}})
		string(REPLACE "toolchain-info" "<PACKAGE_NAME>-<VERSION>" info "${info}")
		message(STATUS "${info}");
	endforeach()
endfunction()

function(write_toolchain_info file)
	set(out "")
	foreach(group ${toolchain_info_groups})
		toolchain_info_helper(info ${${group}})
		string(REPLACE "toolchain-info" "<PACKAGE_NAME>-<VERSION>" info "${info}")
		string(REPLACE "\;" "\\\;" info "${info}")
		list(APPEND out "${info}\n");
	endforeach()
	file(WRITE "${file}" ${out})
endfunction()

]])
	superbuild_package(
	  NAME           toolchain
	  VERSION        info
	)
endfunction()



# Provide default toolchain settings, if not existing
function(_sb_create_default_toolchain)
	set(local_build FALSE)
	if(NOT DEFINED default_INSTALL_DIR)
		sb_install_dir(default_INSTALL_DIR "default")
		set(default_INSTALL_DIR "${default_INSTALL_DIR}" PARENT_SCOPE)
		set(local_build TRUE)
	endif()
	if(NOT DEFINED default_PREFIX_PATH)
		set(default_PREFIX_PATH "${CMAKE_PREFIX_PATH}")
		set(default_PREFIX_PATH "${default_PREFIX_PATH}" PARENT_SCOPE)
	endif()
	if(NOT DEFINED default_INSTALL_PREFIX)
		if(local_build)
			set(default_INSTALL_PREFIX "${default_INSTALL_DIR}")
			set(default_INSTALL_PREFIX "${default_INSTALL_PREFIX}" PARENT_SCOPE)
			set(default_INSTALL_DIR "")
			set(default_INSTALL_DIR "${default_INSTALL_DIR}" PARENT_SCOPE)
		else()
			sb_install_prefix(default_INSTALL_PREFIX "default")
			set(default_INSTALL_PREFIX "${default_INSTALL_PREFIX}" PARENT_SCOPE)
		endif()
	endif()
	if(NOT DEFINED default_TOOLCHAIN_DIR)
		sb_toolchain_dir(default_TOOLCHAIN_DIR "default")
		set(default_TOOLCHAIN_DIR "${default_TOOLCHAIN_DIR}" PARENT_SCOPE)
	endif()
	set(toolchain_content [[
# Generated by ]] "${CMAKE_CURRENT_LIST_FILE}\n" [[

set(SYSTEM_NAME            "default")

# TOOLCHAIN_DIR will be changed for building toolchains,
# so it must be cached for the default toolchain
set(TOOLCHAIN_DIR          "]] "${default_TOOLCHAIN_DIR}" [["
    CACHE PATH             "The install root for this toolchain")
# INSTALL_DIR will be changed for building toolchains,
# so it must be cached for the default toolchain
set(INSTALL_DIR            "]] "${default_INSTALL_DIR}" [["
    CACHE PATH             "The Superbuild install root for the output of this toolchain")
set(CMAKE_PREFIX_PATH      "]] "${default_PREFIX_PATH}" [["
    CACHE PATH             "Path used for searching by FIND_XXX()")
set(CMAKE_INSTALL_PREFIX   "]] "${default_INSTALL_PREFIX}" [["
    CACHE PATH             "Run-time install path prefix, prepended onto install directories")
set(CMAKE_STAGING_PREFIX   "${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}"
    CACHE PATH             "Build-time install path prefix, prepended onto install directories")
if(APPLE AND NOT CMAKE_INSTALL_NAME_DIR)
	set(CMAKE_INSTALL_NAME_DIR "${CMAKE_INSTALL_PREFIX}/lib")
endif()

set(CMAKE_RULE_MESSAGES    OFF CACHE BOOL "Whether to report a message for each make rule")
set(CMAKE_TARGET_MESSAGES  OFF CACHE BOOL "Whether to report a message for each target")
set(CMAKE_VERBOSE_MAKEFILE ON  CACHE BOOL "Enable verbose output from Makefile builds")
]])
	if(CMAKE_TOOLCHAIN_FILE)
		set(toolchain_content "include(\"${CMAKE_TOOLCHAIN_FILE}\")\n")
	endif()
	set(toolchain_file "${default_TOOLCHAIN_DIR}/toolchain.cmake")
	_sb_write_if_different("${toolchain_file}" "${toolchain_content}")
	add_custom_command(OUTPUT "${toolchain_file}"
	  COMMAND "${CMAKE_COMMAND}" .
	)
	add_custom_target(default-toolchain
	  DEPENDS "${toolchain_file}"
	)
	set_property(TARGET default-toolchain PROPERTY SB_PACKAGE_SYSTEM_NAME default)
endfunction()


# Provide host toolchain settings, if not existing
function(_sb_create_host_toolchain)
	# TODO This is just a stub
	set(local_build FALSE)
	if(NOT DEFINED host_INSTALL_DIR)
		sb_install_dir(host_INSTALL_DIR "default")
		set(host_INSTALL_DIR "${host_INSTALL_DIR}" PARENT_SCOPE)
		set(local_build TRUE)
	endif()
	if(NOT DEFINED host_INSTALL_PREFIX)
		if(local_build AND NOT "${host_INSTALL_DIR}" STREQUAL "")
			set(host_INSTALL_PREFIX "${host_INSTALL_DIR}")
			set(host_INSTALL_PREFIX "${host_INSTALL_PREFIX}" PARENT_SCOPE)
			set(host_INSTALL_DIR "")
			set(host_INSTALL_DIR "${host_INSTALL_DIR}" PARENT_SCOPE)
		else()
			sb_install_prefix(host_INSTALL_PREFIX "default")
			set(host_INSTALL_PREFIX "${host_INSTALL_PREFIX}" PARENT_SCOPE)
		endif()
	endif()
	set(HOST_DIR "${host_INSTALL_DIR}${host_INSTALL_PREFIX}" PARENT_SCOPE)
endfunction()


# Read all definitions
function(_sb_read_packages)
	file(GLOB sb_definitions RELATIVE ${PROJECT_SOURCE_DIR} *.cmake)
	foreach(sb_definition ${sb_definitions})
		if(sb_definition STREQUAL "cmake_install.cmake")
			continue()
		endif()
		include(${sb_definition})
	endforeach()
endfunction()


# Setup package dependencies
function(_sb_resolve_dependencies)
	set(suffix "${ARGV0}")
	get_property(packages GLOBAL PROPERTY SB_PACKAGES)
	foreach(package ${packages})
		if(NOT TARGET ${package}${suffix})
			continue()
		endif()
		
		# Source dependencies
		if(TARGET ${package}-source)
			add_dependencies(${package}${suffix} ${package}-source)
		endif()
		
		# Build dependencies
		get_property(dependencies TARGET ${package} PROPERTY SB_PACKAGE_DEPENDS)
		foreach(dependency ${dependencies})
			if(dependency MATCHES "^host:")
				if(SUPERBUILD_DISABLE_DEPENDENCIES)
					continue()
				endif()
				string(REGEX REPLACE "^host:" "" real_dependency ${dependency})
				set(real_suffix "")
				set(real_package ${package}${suffix})
			elseif(dependency MATCHES "^source:")
				# We add source dependencies to the source package,
				# so they can be used for download, patch and update steps.
				string(REGEX REPLACE "^source:" "" real_dependency ${dependency})
				set(real_suffix "-source")
				set(real_package ${package}-source)
			else()
				if(SUPERBUILD_DISABLE_DEPENDENCIES)
					continue()
				endif()
				set(real_dependency ${dependency})
				set(real_suffix     ${suffix})
				set(real_package ${package}${suffix})
			endif()
			get_property(default_version GLOBAL PROPERTY SB_DEFAULT_${real_dependency})
			if(TARGET ${real_dependency}${real_suffix})
				add_dependencies(${real_package} ${real_dependency}${real_suffix})
			elseif(TARGET ${real_dependency}-${default_version}${real_suffix})
				add_dependencies(${real_package} ${real_dependency}-${default_version}${real_suffix})
			elseif(NOT suffix)
				message(SEND_ERROR "No rule to satisfy dependency '${dependency}' for package '${package}'")
			endif()
		endforeach()
	endforeach()
endfunction()


# Toolchain handling
function(_sb_handle_toolchains)
	set(regular_packages)
	set(virtual_packages)
	set(toolchains)
	get_property(packages GLOBAL PROPERTY SB_PACKAGES)
	foreach(package ${packages})
		get_property(SYSTEM_NAME TARGET ${package} PROPERTY SB_PACKAGE_SYSTEM_NAME)
		get_property(build_ TARGET ${package} PROPERTY SB_PACKAGE_BUILD)
		get_property(depends_ TARGET ${package} PROPERTY SB_PACKAGE_DEPENDS)
		if(SYSTEM_NAME)
			list(APPEND toolchains ${package})
		elseif(build_ OR package MATCHES "toolchain-info")
			list(APPEND regular_packages ${package})
		elseif(depends_)
			list(APPEND virtual_packages ${package})
		endif()
	endforeach()
	foreach(toolchain ${toolchains})
		foreach(package ${regular_packages})
			_sb_make_toolchained_build(${package} ${toolchain})
		endforeach()
		foreach(package ${virtual_packages})
 			_sb_make_toolchained_virtual(${package} ${toolchain})
		endforeach()
		get_property(SYSTEM_NAME TARGET ${toolchain} PROPERTY SB_PACKAGE_SYSTEM_NAME)
		_sb_resolve_dependencies("-${SYSTEM_NAME}")
	endforeach()
endfunction()


# Create ExternalProject for handling the source
function(_sb_make_source package)
	set(TMP_DIR "${PROJECT_BINARY_DIR}/tmp/${package}")
	
	list(LENGTH SB_PACKAGE_SOURCE length)
	if(length EQUAL 1)
		# SB_PACKAGE_SOURCE contains name of another package.
		# Use that package's source.
		set(SOURCE_DIR "${PROJECT_BINARY_DIR}/source/${SB_PACKAGE_SOURCE}")
	else()
		set(SOURCE_DIR "${PROJECT_BINARY_DIR}/source/${package}")
	endif()
	file(MAKE_DIRECTORY "${SOURCE_DIR}")
	
	set(source_files)
	if(SB_PACKAGE_SOURCE_WRITE)
		set(source_write_files )
		set(source_write_commands )
		_sb_source_write(source_files "${TMP_DIR}/extra" ${SB_PACKAGE_SOURCE_WRITE})
		foreach(file ${source_files})
			list(APPEND source_write_files "${file}")
			list(APPEND source_write_commands
			  COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${file}" "${SOURCE_DIR}"
			)
		endforeach()
		if(length EQUAL 0)
			# No external source
			set(SB_PACKAGE_SOURCE
			  DOWNLOAD_COMMAND "${CMAKE_COMMAND}" -E make_directory <SOURCE_DIR>
			)
			list(LENGTH SB_PACKAGE_SOURCE length)
		endif()
	endif()
	
	set(source_stamp "${TMP_DIR}/${package}-SOURCE")
	_sb_write_if_different("${source_stamp}"
	  ${SB_PACKAGE_SOURCE}
	  ${SB_PACKAGE_SOURCE_WRITE} # catch list changes
	)
	list(APPEND source_files "${source_stamp}")
	
	if(length EQUAL 0)
		# No external source
		return() 
	elseif(length EQUAL 1)
		# Use another package's source.
		add_custom_target(${package}-source)
		add_dependencies(${package}-source "${SB_PACKAGE_SOURCE}-source")
	else()
		# SB_PACKAGE_SOURCE contains options for ExternalProject source steps.
		ExternalProject_Add(${package}-source
		  DOWNLOAD_DIR "${PROJECT_SOURCE_DIR}"
		  SOURCE_DIR   "${SOURCE_DIR}"
		  TMP_DIR      "${TMP_DIR}"
		  STAMP_DIR    "${TMP_DIR}/stamp"
		  BINARY_DIR   "${TMP_DIR}/unused"
		  INSTALL_DIR  "${TMP_DIR}/unused"
		  ${SB_PACKAGE_SOURCE}
		  CONFIGURE_COMMAND ""
		  BUILD_COMMAND     ""
		  INSTALL_COMMAND   ""
		  EXCLUDE_FROM_ALL  1
		)
		if(source_write_commands)
			ExternalProject_Add_Step(${package}-source write
			  ${source_write_commands}
			  DEPENDS   "${source_write_files}"
			  DEPENDEES download
			  DEPENDERS patch update
			)
		endif()
		# There must be no stamp files when the source dir is missing.
		# We do the cleanup here, at configuration time.
		if(NOT EXISTS "${SOURCE_DIR}" AND EXISTS "${TMP_DIR}")
			file(REMOVE_RECURSE "${TMP_DIR}")
		endif()
	endif()
	set_property(TARGET ${package}-source PROPERTY SB_SOURCE_DIR "${SOURCE_DIR}")
	set_property(TARGET ${package}-source PROPERTY SB_SOURCE_FILES "${source_files}")
endfunction()


# Create virtual packages
function(_sb_make_toolchained_virtual package toolchain)
	get_property(system_name TARGET ${toolchain} PROPERTY SB_PACKAGE_SYSTEM_NAME)
	add_custom_target(${package}-${system_name})
endfunction()

# Create actual build projects
function(_sb_make_toolchained_build package toolchain)
	get_property(SYSTEM_NAME TARGET ${toolchain} PROPERTY SB_PACKAGE_SYSTEM_NAME)
	sb_toolchain_dir(toolchain_dir "${SYSTEM_NAME}")
	sb_install_dir(install_dir "${SYSTEM_NAME}")
	sb_install_stamp_dir(install_stamp_dir "${SYSTEM_NAME}")
	set(tmp_dir "${PROJECT_BINARY_DIR}/${SYSTEM_NAME}/${package}/tmp.superbuild")
	set(target_install_dir_option "")
	if(SB_PACKAGE_SYSTEM_NAME)
		# This is a toolchain
		set(suffix "")
		_sb_get_build_command(build_command ${package})
		add_custom_command(OUTPUT "${INSTALL_DIR}/toolchain.cmake"
		  COMMAND ${build_command}
		)
		sb_toolchain_dir(install_dir "${SB_PACKAGE_SYSTEM_NAME}")
		sb_toolchain_stamp_dir(install_stamp_dir "${SB_PACKAGE_SYSTEM_NAME}")
		set(tmp_dir "${install_dir}/build/tmp.superbuild")
		sb_install_dir(${SB_PACKAGE_SYSTEM_NAME}_INSTALL_DIR "${SB_PACKAGE_SYSTEM_NAME}")
		set(target_install_dir_option "-D${SB_PACKAGE_SYSTEM_NAME}_INSTALL_DIR=${${SB_PACKAGE_SYSTEM_NAME}_INSTALL_DIR}")
	elseif(SYSTEM_NAME STREQUAL "default")
		set(suffix "")
	else()
		set(suffix "-${SYSTEM_NAME}")
	endif()
	
	if(DEFINED ${SYSTEM_NAME}_CMAKE_COMMAND)
		# Scoped to the current function.
		set(CMAKE_COMMAND "${${SYSTEM_NAME}_CMAKE_COMMAND}")
	endif()
	
	if(DEFINED ${SYSTEM_NAME}_BUILD_TYPE)
		set(defined_build_type "-DCMAKE_BUILD_TYPE=${${SYSTEM_NAME}_BUILD_TYPE}")
	elseif(DEFINED CMAKE_BUILD_TYPE)
		set(defined_build_type "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}")
	else()
		set(defined_build_type )
	endif()
	
	if(NOT DEFINED ${SYSTEM_NAME}_ENV_PATH)
		# Don't add ${HOST_DIR}/bin,
		# or find_package may pick host packages when cross compiling.
		set(${SYSTEM_NAME}_ENV_PATH "${toolchain_dir}/bin:$ENV{PATH}")
	endif()
	
	set(define_env )
	foreach(var ${SUPERBUILD_HANDLE_ENV})
		if(DEFINED ${SYSTEM_NAME}_ENV_${var})
			list(APPEND define_env "${var}=${${SYSTEM_NAME}_ENV_${var}}")
		elseif(SYSTEM_NAME STREQUAL "default" AND DEFINED ENV{${var}})
			list(APPEND define_env "${var}=$ENV{${var}}")
		endif()
	endforeach()
	string(MD5 env_stamp "${define_env}")
	
	set(toolchain_file "${toolchain_dir}/toolchain.cmake")
	add_custom_command(OUTPUT "${tmp_dir}/CMakeLists.txt"
	  DEPENDS "${PROJECT_BINARY_DIR}/config/CMakeLists.txt"
	          "${PROJECT_BINARY_DIR}/config/${package}-config.cmake"
	          "${PROJECT_BINARY_DIR}/config/${package}-CMakeLists.txt.in"
	          "${toolchain_file}"
	  COMMAND ${CMAKE_COMMAND} -E make_directory "${tmp_dir}/config/generator"
	  COMMAND ${CMAKE_COMMAND} -E chdir "${tmp_dir}/config/generator"
	    ${CMAKE_COMMAND} -E env ${define_env}
	    ${CMAKE_COMMAND} "${PROJECT_BINARY_DIR}/config"
	      "-DCMAKE_TOOLCHAIN_FILE:FILEPATH=${toolchain_file}"
	      "-DSYSTEM_NAME:STRING=${SYSTEM_NAME}"
	      "-DPACKAGE:STRING=${package}"
	      ${defined_build_type}
	      "-DINSTALL_DIR=${install_dir}"
	      "-DTOOLCHAIN_DIR=${toolchain_dir}"
	      "-DINSTALL_STAMP_DIR=${install_stamp_dir}"
	      "${target_install_dir_option}"
	      "-DSTAMP=${env_stamp}"
	  COMMAND ${CMAKE_COMMAND} -E touch_nocreate "${tmp_dir}/CMakeLists.txt"
	  COMMAND ${CMAKE_COMMAND} -E chdir "${tmp_dir}/config"
	    ${CMAKE_COMMAND} -E env ${define_env}
	    ${CMAKE_COMMAND} "${tmp_dir}"
	      "-DCMAKE_TOOLCHAIN_FILE:FILEPATH=${toolchain_file}"
	  WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
	  COMMENT "Generating configuration for ${package}${suffix}"
	)
	
	if(TARGET ${package}-source)
		get_property(source_files TARGET ${package}-source PROPERTY SB_SOURCE_FILES)
	else()
		set(source_files )
	endif()
	_sb_get_build_command(build_command)
	add_custom_target(${package}${suffix}
	  DEPENDS "${tmp_dir}/CMakeLists.txt"
	          ${source_files}
	  COMMAND ${CMAKE_COMMAND} -E env ${define_env}
	    ${build_command}
	  WORKING_DIRECTORY "${tmp_dir}/config"
	  COMMENT "Building ${package}${suffix}"
	)
	if(SB_PACKAGE_SYSTEM_NAME OR package STREQUAL "toolchain-info")
		# Toolchains and toolchain-info may depend directly on the toolchain
		add_dependencies(${package}${suffix} ${toolchain})
	else()
		# Normal packages depend on toolchain via toolchain-info
		add_dependencies(${package}${suffix} "toolchain-info${suffix}")
	endif()
	
	foreach(step ${SUPERBUILD_STEP_TARGETS})
		_sb_get_build_command(build_command ${package}-${SYSTEM_NAME}-${step})
		add_custom_target(${package}${suffix}-${step}
		  DEPENDS "${tmp_dir}/CMakeLists.txt"
				  ${source_files}
		  COMMAND ${CMAKE_COMMAND} -E env ${define_env}
			${build_command}
		  WORKING_DIRECTORY "${tmp_dir}/config"
		  COMMENT "Building ${package}${suffix}"
		)
		if(TARGET ${package}-source)
			add_dependencies(${package}${suffix}-${step} ${package}-source)
		endif()
	endforeach()
	
	get_property(build_package TARGET ${package} PROPERTY SB_PACKAGE_PACKAGE SET)
	if(build_package OR SB_PACKAGE_PACKAGE)
		_sb_get_build_command(build_command ${package}-${SYSTEM_NAME}-package)
		add_custom_target(${package}${suffix}-package
		  DEPENDS ${package}${suffix}
		  COMMAND ${CMAKE_COMMAND} -E env ${define_env}
		    ${build_command}
		  WORKING_DIRECTORY "${tmp_dir}/config"
		  COMMENT "Building ${package}${suffix}-package"
		)
	endif()
endfunction()


# Package registration
#
# This is the only public function
function(superbuild_package)
	set(sb_options
	  NO_DEFAULT
	)
	set(sb_one_value_args
	  BUILD_CONDITION
	  CHANGES
	  CHANGES_MD5
	  NAME
	  VERSION
	  SYSTEM_NAME
	)
	set(sb_multi_value_args
	  DEPENDS
	  EXTERNAL_PROJECT
	  EXTERNAL_STEPS
	  SOURCE_WRITE
	  SOURCE
	  BUILD
	  PACKAGE
	  USING
	  EXECUTABLES
	)
	cmake_parse_arguments(SB_PACKAGE "${sb_options}" "${sb_one_value_args}" "${sb_multi_value_args}" ${ARGN})
	
	if(NOT SB_PACKAGE_NAME)
		message(FATAL_ERROR "Missing package name")
	endif()
	if(NOT SB_PACKAGE_VERSION)
		message(FATAL_ERROR "Missing package version")
	endif()
	if(SB_PACKAGE_UNPARSED_ARGUMENTS)
		message(FATAL_ERROR "Invalid arguments: ${SB_PACKAGE_UNPARSED_ARGUMENTS}")
	endif()
	
	set(package ${SB_PACKAGE_NAME}-${SB_PACKAGE_VERSION})
	set(config_dir "${PROJECT_BINARY_DIR}/config")
	file(MAKE_DIRECTORY "${config_dir}")
	
	if(SB_PACKAGE_SYSTEM_NAME)
		# toolchain
		set(TOOLCHAIN_DIR "${HOST_DIR}")
		set(BINARY_DIR    "${PROJECT_BINARY_DIR}/${SB_PACKAGE_SYSTEM_NAME}/toolchain/build")
		set(TMP_DIR       "${PROJECT_BINARY_DIR}/${SB_PACKAGE_SYSTEM_NAME}/toolchain/build/tmp.superbuild")
		set(INSTALL_DIR   "${PROJECT_BINARY_DIR}/${SB_PACKAGE_SYSTEM_NAME}/toolchain")
		if(NOT DEFINED ${SB_PACKAGE_SYSTEM_NAME}_INSTALL_DIR)
			sb_install_dir(${SB_PACKAGE_SYSTEM_NAME}_INSTALL_DIR "${SB_PACKAGE_SYSTEM_NAME}")
		endif()
	else()
		# regular package
		set(TOOLCHAIN_DIR [[${${SYSTEM_NAME}_TOOLCHAIN_DIR}]])
		set(BINARY_DIR    "${PROJECT_BINARY_DIR}/\${SYSTEM_NAME}/${package}")
		set(TMP_DIR       "${PROJECT_BINARY_DIR}/\${SYSTEM_NAME}/${package}/tmp.superbuild")
		set(INSTALL_DIR   [[${${SYSTEM_NAME}_INSTALL_DIR}]])
	endif()
	_sb_make_source(${package})
	
	if(DEFINED SB_PACKAGE_BUILD
	       OR "${package}" STREQUAL "toolchain-info")
		if(TARGET ${package}-source)
			get_property(SOURCE_DIR TARGET ${package}-source PROPERTY SB_SOURCE_DIR)
		else()
			set(SOURCE_DIR "${TMP_DIR}/source")
		endif()
		set(DOWNLOAD_DIR     "${PROJECT_SOURCE_DIR}")
		_sb_write_config("${config_dir}"
		  HOST_DIR
		  DOWNLOAD_DIR
		  SOURCE_DIR
		  BINARY_DIR
		  TMP_DIR
		  ${SB_PACKAGE_USING} # May use the previous variables
		)
		_sb_write_build("${config_dir}")
		_sb_make_toolchained_build(${package} default-toolchain)
	
		# Export executables from default toolchain
		if (SB_PACKAGE_EXECUTABLES)
			# Bring keywords in front of executables
			list(REVERSE SB_PACKAGE_EXECUTABLES)
		endif()
		set(keyword "")
		foreach(executable_path ${SB_PACKAGE_EXECUTABLES})
			if("${executable_path}" STREQUAL "MACOSX_BUNDLE")
				if(APPLE)
					set(keyword "${executable_path}")
				endif()
				continue()
			endif()
	
			set(project_file "${PROJECT_BINARY_DIR}/source/${package}/CMakeLists.txt")
			if(NOT EXISTS "${project_file}")
				set(project_file )
			endif()
			get_filename_component(executable "${executable_path}" NAME)
			add_executable(${executable}-${SB_PACKAGE_VERSION}
			  ${keyword}
			  EXCLUDE_FROM_ALL
			  "${PROJECT_BINARY_DIR}/source/main.c"
			  "${project_file}"
			)
			if("${keyword}" STREQUAL "MACOSX_BUNDLE")
				# Copy the whole bundle, to avoid trouble with rebuilds
				add_custom_command(TARGET ${executable}-${SB_PACKAGE_VERSION}
				  POST_BUILD
				  COMMAND "${CMAKE_COMMAND}" -E
					remove_directory
					  "${executable}-${SB_PACKAGE_VERSION}.app"
				  COMMAND "${CMAKE_COMMAND}" -E
					copy_directory
					  "default/${package}/${executable_path}.app"
					  "${executable}-${SB_PACKAGE_VERSION}.app"
				  COMMAND "${CMAKE_COMMAND}" -E
					create_symlink
					  "${executable}"
					  "${executable}-${SB_PACKAGE_VERSION}.app/Contents/MacOS/${executable}-${SB_PACKAGE_VERSION}"
				  VERBATIM
				)
			else()
				# Create a symlink to the actual executable
				add_custom_command(TARGET ${executable}-${SB_PACKAGE_VERSION}
				  POST_BUILD
				  COMMAND "${CMAKE_COMMAND}" -E
					create_symlink
					  "${PROJECT_BINARY_DIR}/default/${package}/${executable_path}"
					  "${executable}-${SB_PACKAGE_VERSION}"
				  VERBATIM
				)
			endif()
			add_dependencies(${executable}-${SB_PACKAGE_VERSION} ${package})
			set(keyword "")
		endforeach()
	elseif(DEFINED SB_PACKAGE_DEPENDS)
		add_custom_target(${package})
	else()
		return()
	endif()
	
	# Publish package properties
	set_property(TARGET ${package} PROPERTY SB_PACKAGE_FILE ${CMAKE_CURRENT_LIST_FILE})
	foreach(arg ${sb_options} ${sb_one_value_args} ${sb_multi_value_args})
		set_property(TARGET ${package} PROPERTY SB_PACKAGE_${arg} ${SB_PACKAGE_${arg}})
	endforeach()
	
	# Publish package via global properties
	set_property(GLOBAL APPEND PROPERTY SB_PACKAGES ${package})
	string(REPLACE "-" "." version ${SB_PACKAGE_VERSION})
	get_property(default_version GLOBAL PROPERTY SB_DEFAULT_${SB_PACKAGE_NAME})
	string(REPLACE "-" "." default_version "${default_version}")
	if(NOT SB_PACKAGE_NO_DEFAULT
	   AND version VERSION_GREATER default_version)
		set_property(GLOBAL PROPERTY SB_DEFAULT_${SB_PACKAGE_NAME} ${SB_PACKAGE_VERSION})
	endif()
endfunction()


# For convenience, make existing documentation visible to IDEs
foreach(file ${documentation})
	if(NOT EXISTS ${PROJECT_SOURCE_DIR}/${file})
		set_source_files_properties(${file} PROPERTIES GENERATED 1)
	endif()
endforeach()
add_custom_target(doc SOURCES ${documentation})

# ExternalPackage < 3.8.0 has bug with UPDATE_DISCONNECTED
if(NOT CMAKE_VERSION VERSION_LESS 3.8.0)
	option(SUPERBUILD_UPDATE_DISCONNECTED "Skip package update steps" ON)
	set_directory_properties(PROPERTIES EP_UPDATE_DISCONNECTED "${SUPERBUILD_UPDATE_DISCONNECTED}")
endif()

_sb_create_main_c()
_sb_create_default_toolchain()
_sb_create_host_toolchain()
_sb_write_generator()
_sb_write_debian_patch_script()
_sb_create_toolchain_info()
_sb_read_packages()
_sb_resolve_dependencies()
_sb_handle_toolchains()
