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

cmake_minimum_required(VERSION 3.2)
cmake_policy(SET CMP0001 NEW)
cmake_policy(SET CMP0053 NEW)

project(Superbuild C)

set(documentation
  COPYING
  README.md
)


include(CMakeParseArguments)
include(ExternalProject)


# Global utilities
function(sb_install_dir var system_name)
	if(DEFINED ${SYSTEM_NAME}_INSTALL_DIR)
		set(${var} "${SYSTEM_NAME}_INSTALL_DIR" PARENT_SCOPE)
	else()
		set(${var} "${PROJECT_BINARY_DIR}/${system_name}/install" PARENT_SCOPE)
	endif()
endfunction()



function(sb_toolchain_dir var system_name)
	if(DEFINED ${SYSTEM_NAME}_TOOLCHAIN_DIR)
		set(${var} "${SYSTEM_NAME}_TOOLCHAIN_DIR" PARENT_SCOPE)
	else()
		set(${var} "${PROJECT_BINARY_DIR}/${system_name}/toolchain" PARENT_SCOPE)
	endif()
endfunction()



function(_sb_write_if_different filepath)
	string(CONCAT output ${ARGN})
	if(EXISTS "${filepath}")
		file(READ "${filepath}" content)
		if(content STREQUAL output)
			return()
		endif()
	endif()
	file(WRITE "${filepath}" "${output}")
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
	file(STRINGS "${dir}/patches/series" series)
	foreach(line ${series})
		string(STRIP "${line}" line)
		if(line MATCHES "^#")
			continue()
		endif()
		message(STATUS "Applying ${line}")
		execute_process(
		  COMMAND patch -p1 
		  INPUT_FILE "${dir}/patches/${line}"
		  RESULT_VARIABLE exit_code
		)
		if(NOT exit_code EQUAL 0)
			message(FATAL_ERROR)
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
		foreach(item ${${name}})
			list(APPEND output " \"${item}\"")
		endforeach()
		list(APPEND output ")\n")
	endforeach()
	list(APPEND output
"
function(sb_test_build_condition)
	set(BUILD_CONDITION 1)
	# Protect the package from inadvertently finding it is own install results.
	set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER)
	set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER)
	set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE NEVER)
	set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
${SB_PACKAGE_BUILD_CONDITION}
	set(BUILD_CONDITION \${BUILD_CONDITION} PARENT_SCOPE)
endfunction()
")
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

file(READ \"${PROJECT_BINARY_DIR}/config/\${PACKAGE}-CMakeLists.txt.in\" config)
string(CONFIGURE \"\${config}\" config)
file(GENERATE OUTPUT \"\${TMP_DIR}/CMakeLists.txt\"
  CONTENT \"\${config}\"
)
")
	_sb_write_if_different("${PROJECT_BINARY_DIR}/config/CMakeLists.txt" ${output})
endfunction()



function(_sb_write_build dir)
	_sb_get_build_command(build_command_list "${package}-@SYSTEM_NAME@")
	set(build_command )
	foreach(item ${build_command_list})
		set(build_command "${build_command} \"${item}\"")
	endforeach()
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

project(${package}-@SYSTEM_NAME@ NONE)

set_property(GLOBAL PROPERTY RULE_MESSAGES 0)
set_property(GLOBAL PROPERTY TARGET_MESSAGES 0)

include(\"${dir}/${package}-config.cmake\")
set(INSTALL_DIR      \"@INSTALL_DIR@\")
set(TOOLCHAIN_DIR    \"@TOOLCHAIN_DIR@\")
set(CMAKE_BUILD_TYPE \"@CMAKE_BUILD_TYPE@\")

sb_test_build_condition()
if(NOT BUILD_CONDITION)
	message(STATUS \"Not building ${SB_PACKAGE_NAME} for @SYSTEM_NAME@ toolchain\")
	add_custom_target(${package}-@SYSTEM_NAME@-system
	  ALL
	  COMMAND \${CMAKE_COMMAND} -E make_directory \"\${TMP_DIR}/stamp\"
	  COMMAND \${CMAKE_COMMAND} -E echo \"Not building ${SB_PACKAGE_NAME} for @SYSTEM_NAME@ toolchain\"
	)
	add_custom_target(${package}-@SYSTEM_NAME@-env-package)
	return()
endif()

add_custom_target(${package}-@SYSTEM_NAME@-env
  ALL
  COMMAND \${CMAKE_COMMAND} -E env \"PATH=\${TOOLCHAIN_DIR}/bin:\${HOST_INSTALL_DIR}/bin:\$ENV{PATH}\"
    ${build_command}
)

include(ExternalProject)

ExternalProject_Add(${package}-@SYSTEM_NAME@
  DOWNLOAD_DIR \"\${DOWNLOAD_DIR}\"
  SOURCE_DIR   \"\${SOURCE_DIR}\"
  BINARY_DIR   \"\${BINARY_DIR}\"
  TMP_DIR      \"\${TMP_DIR}\"
  STAMP_DIR    \"\${TMP_DIR}/stamp\"
  INSTALL_DIR  \"\${INSTALL_DIR}\"
  EXCLUDE_FROM_ALL 1
  DOWNLOAD_COMMAND \"${CMAKE_COMMAND}\" -E touch_nocreate \"<SOURCE_DIR>/placeholder\"
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

add_custom_command(OUTPUT \"\${INSTALL_DIR}\${CMAKE_INSTALL_PREFIX}/tmp/${package}.stamp\"
  COMMAND \"${CMAKE_COMMAND}\" -E  make_directory \"\${INSTALL_DIR}\${CMAKE_INSTALL_PREFIX}/tmp\"
  COMMAND \"${CMAKE_COMMAND}\" -E  touch \"\${INSTALL_DIR}\${CMAKE_INSTALL_PREFIX}/tmp/${package}.stamp\"
)
ExternalProject_Add_StepDependencies(${package}-@SYSTEM_NAME@ install
  \"\${INSTALL_DIR}\${CMAKE_INSTALL_PREFIX}/tmp/${package}.stamp\"
)


")
if(SB_PACKAGE_PACKAGE)
	_sb_get_build_command(build_command_list "${package}-@SYSTEM_NAME@-package")
	set(build_command )
	foreach(item ${build_command_list})
		set(build_command "${build_command} \"${item}\"")
	endforeach()
	list(APPEND output "
add_custom_target(${package}-@SYSTEM_NAME@-env-package
  COMMAND \${CMAKE_COMMAND} -E env \"PATH=\${TOOLCHAIN_DIR}/bin:\${HOST_INSTALL_DIR}/bin:\$ENV{PATH}\"
	${build_command}
)
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



# Provide default toolchain settings, if not existing
function(_sb_create_default_toolchain)
	if(NOT DEFINED default_INSTALL_DIR)
		set(default_INSTALL_DIR "" )
		set(default_INSTALL_DIR "${default_INSTALL_DIR}" PARENT_SCOPE)
	endif()
	if(NOT DEFINED default_INSTALL_PREFIX)
		sb_install_dir(default_INSTALL_PREFIX "default")
		set(default_INSTALL_PREFIX "${default_INSTALL_PREFIX}" PARENT_SCOPE)
	endif()
	if(NOT DEFINED default_TOOLCHAIN_DIR)
		set(default_TOOLCHAIN_DIR "${default_INSTALL_DIR}${default_INSTALL_PREFIX}")
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
    CACHE PATH             "The install root for the output of this toolchain")
set(CMAKE_INSTALL_PREFIX   "]] "${default_INSTALL_PREFIX}" [["
    CACHE PATH             "Install path prefix, prepended onto install directories")
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
	set(toolchain_file "${PROJECT_BINARY_DIR}/default/toolchain/toolchain.cmake")
	_sb_write_if_different("${toolchain_file}" "${toolchain_content}")
	add_custom_command(OUTPUT "${toolchain_file}"
	  COMMAND "${CMAKE_COMMAND}" .
	)
	add_custom_target(default-toolchain
	  DEPENDS "${toolchain_file}"
	)
	set_property(TARGET default-toolchain PROPERTY SB_PACKAGE_SYSTEM_NAME default)
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
		add_dependencies(${package}${suffix} ${package}-source)
		
		# Build dependencies
		get_property(dependencies TARGET ${package} PROPERTY SB_PACKAGE_DEPENDS)
		foreach(dependency ${dependencies})
			if(dependency MATCHES "^host:")
				if(DISABLE_DEPENDENCIES)
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
				if(DISABLE_DEPENDENCIES)
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
	set(toolchains)
	get_property(packages GLOBAL PROPERTY SB_PACKAGES)
	foreach(package ${packages})
		get_property(SYSTEM_NAME TARGET ${package} PROPERTY SB_PACKAGE_SYSTEM_NAME)
		if(SYSTEM_NAME)
			list(APPEND toolchains ${package})
		else()
			list(APPEND regular_packages ${package})
		endif()
	endforeach()
	foreach(toolchain ${toolchains})
		foreach(package ${regular_packages})
			_sb_make_toolchained_project(${package} ${toolchain})
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
		add_custom_target(${package}-source)
	elseif(length EQUAL 1)
		# Use another package's source.
		add_custom_target(${package}-source)
		add_dependencies(${package}-source "${SB_PACKAGE_SOURCE}-source")
	else()
		# SB_PACKAGE_SOURCE contains options for ExternalPackage source steps.
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
	endif()
	set_property(TARGET ${package}-source PROPERTY SB_SOURCE_DIR "${SOURCE_DIR}")
	set_property(TARGET ${package}-source PROPERTY SB_SOURCE_FILES "${source_files}")
endfunction()


# Create actual build projects
function(_sb_make_toolchained_project package toolchain)
	get_property(SYSTEM_NAME TARGET ${toolchain} PROPERTY SB_PACKAGE_SYSTEM_NAME)
	set(tmp_dir "${PROJECT_BINARY_DIR}/${SYSTEM_NAME}/${package}/tmp.superbuild")
	if(SYSTEM_NAME STREQUAL "default")
		set(suffix "")
		if(SB_PACKAGE_SYSTEM_NAME)
			# This is a toolchain
			_sb_get_build_command(build_command ${package})
			add_custom_command(OUTPUT "${INSTALL_DIR}/toolchain.cmake"
			  COMMAND ${build_command}
			)
			set(tmp_dir "${PROJECT_BINARY_DIR}/${SB_PACKAGE_SYSTEM_NAME}/toolchain/build/tmp.superbuild")
		endif()	
	else()
		set(suffix "-${SYSTEM_NAME}")
	endif()
	
	set(target_install_dir_option "")
	if(SB_PACKAGE_SYSTEM_NAME)
		set(${SYSTEM_NAME}_INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/${SB_PACKAGE_SYSTEM_NAME}/toolchain/install")
		if(NOT DEFINED ${SB_PACKAGE_SYSTEM_NAME}_INSTALL_DIR)
			set(${SB_PACKAGE_SYSTEM_NAME}_INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/${SB_PACKAGE_SYSTEM_NAME}/install")
			set(target_install_dir_option "-D${SB_PACKAGE_SYSTEM_NAME}_INSTALL_DIR=${${SB_PACKAGE_SYSTEM_NAME}_INSTALL_DIR}")
		endif()
	elseif(NOT DEFINED ${SYSTEM_NAME}_INSTALL_DIR)
		set(${SYSTEM_NAME}_INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/${SYSTEM_NAME}/install")
	endif()
	
	if(NOT DEFINED ${SYSTEM_NAME}_TOOLCHAIN_DIR)
		set(${SYSTEM_NAME}_TOOLCHAIN_DIR "${CMAKE_CURRENT_BINARY_DIR}/${SYSTEM_NAME}/toolchain")
	endif()
	
	set(toolchain_file "${PROJECT_BINARY_DIR}/${SYSTEM_NAME}/toolchain/toolchain.cmake")
	add_custom_command(OUTPUT "${tmp_dir}/CMakeLists.txt"
	  DEPENDS "${PROJECT_BINARY_DIR}/config/CMakeLists.txt"
	          "${PROJECT_BINARY_DIR}/config/${package}-config.cmake"
	          "${PROJECT_BINARY_DIR}/config/${package}-CMakeLists.txt.in"
	          "${toolchain_file}"
	  COMMAND ${CMAKE_COMMAND} -E make_directory "${tmp_dir}/config/generator"
	  COMMAND ${CMAKE_COMMAND} -E chdir "${tmp_dir}/config/generator"
	    ${CMAKE_COMMAND} "${PROJECT_BINARY_DIR}/config"
	      "-DCMAKE_TOOLCHAIN_FILE:FILEPATH=${toolchain_file}"
	      "-DSYSTEM_NAME:STRING=${SYSTEM_NAME}"
	      "-DPACKAGE:STRING=${package}"
	      "-DCMAKE_BUILD_TYPE=$<CONFIG>"
	      "-D${SYSTEM_NAME}_INSTALL_DIR=${${SYSTEM_NAME}_INSTALL_DIR}"
	      "-D${SYSTEM_NAME}_TOOLCHAIN_DIR=${${SYSTEM_NAME}_TOOLCHAIN_DIR}"
	      "${target_install_dir_option}"
	  COMMAND ${CMAKE_COMMAND} -E touch_nocreate "${tmp_dir}/CMakeLists.txt"
	  COMMAND ${CMAKE_COMMAND} -E chdir "${tmp_dir}/config"
	    ${CMAKE_COMMAND} "${tmp_dir}"
	      "-DCMAKE_TOOLCHAIN_FILE:FILEPATH=${toolchain_file}"
	  WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
	  COMMENT "Generating configuration for ${package}${suffix}"
	)
	
	get_property(source_files TARGET ${package}-source PROPERTY SB_SOURCE_FILES)
	_sb_get_build_command(build_command)
	add_custom_target(${package}${suffix}
	  DEPENDS "${tmp_dir}/CMakeLists.txt"
	          ${source_files}
	  COMMAND ${build_command}
	  WORKING_DIRECTORY "${tmp_dir}/config"
	  COMMENT "Building ${package}${suffix}"
	)
	add_dependencies(${package}${suffix} ${toolchain})
	
	get_property(build_package TARGET ${package} PROPERTY SB_PACKAGE_PACKAGE SET)
	if(build_package OR SB_PACKAGE_PACKAGE)
		_sb_get_build_command(build_command ${package}-${SYSTEM_NAME}-env-package)
		add_custom_target(${package}${suffix}-package
		  DEPENDS ${package}${suffix}
		  COMMAND ${build_command}
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
	
	if(NOT DEFINED host_INSTALL_DIR)
		set(host_INSTALL_DIR "${default_INSTALL_DIR}")
	endif()
	set(HOST_INSTALL_DIR "${host_INSTALL_DIR}")
	if(SB_PACKAGE_SYSTEM_NAME)
		# toolchain
		set(TOOLCHAIN_DIR "${HOST_INSTALL_DIR}")
		set(BINARY_DIR    "${PROJECT_BINARY_DIR}/${SB_PACKAGE_SYSTEM_NAME}/toolchain/build")
		set(TMP_DIR       "${PROJECT_BINARY_DIR}/${SB_PACKAGE_SYSTEM_NAME}/toolchain/build/tmp.superbuild")
		set(INSTALL_DIR   "${PROJECT_BINARY_DIR}/${SB_PACKAGE_SYSTEM_NAME}/toolchain")
		if(NOT DEFINED ${SB_PACKAGE_SYSTEM_NAME}_INSTALL_DIR)
			set(${SB_PACKAGE_SYSTEM_NAME}_INSTALL_DIR "${PROJECT_BINARY_DIR}/${SB_PACKAGE_SYSTEM_NAME}/install")
		endif()
	else()
		# regular package
		set(TOOLCHAIN_DIR [[${${SYSTEM_NAME}_TOOLCHAIN_DIR}]])
		set(BINARY_DIR    "${PROJECT_BINARY_DIR}/\${SYSTEM_NAME}/${package}")
		set(TMP_DIR       "${PROJECT_BINARY_DIR}/\${SYSTEM_NAME}/${package}/tmp.superbuild")
		set(INSTALL_DIR   [[${${SYSTEM_NAME}_INSTALL_DIR}]])
	endif()
	_sb_make_source(${package})
	get_property(SOURCE_DIR TARGET ${package}-source PROPERTY SB_SOURCE_DIR)
	set(DOWNLOAD_DIR     "${PROJECT_SOURCE_DIR}")
	
	_sb_write_config("${config_dir}"
	  HOST_INSTALL_DIR
	  TOOLCHAIN_DIR
	  DOWNLOAD_DIR
	  SOURCE_DIR
	  BINARY_DIR
	  TMP_DIR
	  INSTALL_DIR
	  ${SB_PACKAGE_USING} # May use the previous variables
	)
	_sb_write_build("${config_dir}")
	_sb_make_toolchained_project(${package} default-toolchain)
	
	# Export executables from default toolchain
	foreach(executable_path ${SB_PACKAGE_EXECUTABLES})
		get_filename_component(executable "${executable_path}" NAME)
		add_executable(${executable}-${SB_PACKAGE_VERSION} 
		  EXCLUDE_FROM_ALL
		  "${PROJECT_BINARY_DIR}/source/main.c"
		)
		add_custom_command(TARGET ${executable}-${SB_PACKAGE_VERSION} POST_BUILD
		  COMMAND "${CMAKE_COMMAND}" -E create_symlink "${PROJECT_BINARY_DIR}/default/${package}/${executable_path}" ${executable}-${SB_PACKAGE_VERSION}
		)
		add_dependencies(${executable}-${SB_PACKAGE_VERSION} ${package})
	endforeach()
	
	# Publish package properties
	set_property(TARGET ${package} PROPERTY SB_PACKAGE_FILE ${CMAKE_CURRENT_LIST_FILE})
	foreach(arg ${sb_options} ${sb_one_value_args} ${sb_multi_value_args})
		set_property(TARGET ${package} PROPERTY SB_PACKAGE_${arg} ${SB_PACKAGE_${arg}})
	endforeach()
	
	# Publish package via global properties
	set_property(GLOBAL APPEND PROPERTY SB_PACKAGES ${package})
	string(REPLACE "-" "." version ${SB_PACKAGE_VERSION})
	string(REPLACE "-" "." default_version "${sb_default_${SB_PACKAGE_NAME}}")
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

_sb_create_main_c()
_sb_create_default_toolchain()
_sb_write_generator()
_sb_write_debian_patch_script()
_sb_read_packages()
_sb_resolve_dependencies()
_sb_handle_toolchains()
