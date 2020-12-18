# This file is part of OpenOrienteering.

# Copyright 2018-2020 Kai Pastor
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

project(qt-5.12-openorienteering VERSION 5.12.0 LANGUAGES NONE)

configure_file(init-copyright.cmake.in "${CMAKE_CURRENT_BINARY_DIR}/init-copyright.cmake" @ONLY)

set(qt_modules
  qtandroidextras
  qtbase
  qtimageformats
  qtlocation
  qtsensors
  qtserialport
  qttools
  qttranslations
)

add_custom_target(update-copyright)

foreach(module ${qt_modules})
    get_filename_component(module_source_dir "source/${module}" REALPATH)
    if(NOT EXISTS "${module_source_dir}")
       continue()
    endif()
    
    set(copyright_file "${CMAKE_CURRENT_LIST_DIR}/${module}/copyright")
    configure_file(copyright.in "${CMAKE_CURRENT_BINARY_DIR}/copyright.${module}" @ONLY)
    add_custom_target(update-copyright-${module}
      COMMAND
        "${CMAKE_COMMAND}" "-Dmodule=${module}" -P "${CMAKE_CURRENT_BINARY_DIR}/init-copyright.cmake"
      COMMAND
        "${CMAKE_COMMAND}" -E make_directory "${module_source_dir}/debian"
      COMMAND
        "${CMAKE_COMMAND}" -E copy "${copyright_file}" "${module_source_dir}/debian/copyright"
      COMMAND
        "${INSTALL_DIR}${CMAKE_INSTALL_PREFIX}/bin/qtattributionsscanner"
          --output-format json
          --output "${module_source_dir}/debian/attribution.json"
          --basedir "${module_source_dir}"
          "${module_source_dir}"
      COMMAND
        "${CMAKE_COMMAND}" -E chdir "${module_source_dir}"
          "${PYTHON_EXECUTABLE}" "${CMAKE_CURRENT_LIST_DIR}/update-copyright"
      COMMAND
        "${CMAKE_COMMAND}" -E copy_if_different "${module_source_dir}/debian/copyright" "${copyright_file}"
      VERBATIM
      COMMENT
        "Updating copyright for '${module}'"
    )
    add_dependencies(update-copyright update-copyright-${module})
    
    file(STRINGS "${module_source_dir}/.qmake.conf" module_version REGEX "MODULE_VERSION")
    string(REPLACE "MODULE_VERSION = " "" module_version "${module_version}")
    install(
      FILES "${copyright_file}"
      RENAME "${module}-${module_version}.txt"
      DESTINATION "share/doc/copyright"
    )
endforeach()

