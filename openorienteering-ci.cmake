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


# Import the CI script for the named OpenOrientering project.
# This function sets up the ${project}_CI_SOURCE_DIR cache variable which
# defaults to a corresponding sibling directory of the Superbuild, and
# includes the CI cmake script from this directory if it is found.

function(OPENORIENTEERING_CI_ADD project)
    string(TOLOWER "${project}" project_lower)
    get_filename_component(base_dir "${CMAKE_CURRENT_LIST_DIR}" PATH)
    set(${project}_CI_SOURCE_DIR "${base_dir}/${project_lower}" CACHE STRING
      "The OpenOrienteering ${project} source directory"
    )
    set(${project}_CI_LIST_FILE
      "${${project}_CI_SOURCE_DIR}/ci/openorienteering-${project_lower}-ci.cmake"
    )
    if(EXISTS "${${project}_CI_LIST_FILE}")
        include("${${project}_CI_LIST_FILE}")
    endif()
endfunction()


# By editing the OPENORIENTEERING_CI_PROJECTS cache variable, it is possible
# to name additional (new) CI projects which follow the project files layout
# of the existing projects.
list(APPEND OPENORIENTEERING_CI_PROJECTS
  "CupCalculator"
  "Mapper"
)
list(REMOVE_DUPLICATES OPENORIENTEERING_CI_PROJECTS)
set(OPENORIENTEERING_CI_PROJECTS "${OPENORIENTEERING_CI_PROJECTS}" CACHE STRING
  "OpenOrienteering CI projects"
  FORCE
)
mark_as_advanced(OPENORIENTEERING_CI_PROJECTS)
foreach(project ${OPENORIENTEERING_CI_PROJECTS})
    openorienteering_ci_add("${project}")
endforeach()

