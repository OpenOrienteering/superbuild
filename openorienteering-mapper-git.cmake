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

find_package(Git QUIET)
if(NOT GIT_EXECUTABLE)
	message(STATUS "Disabling openorienteering-mapper-git due to missing git")
	return()
endif()

set(Mapper_GIT_TAGS "master;dev" CACHE STRING "Mapper (git): The git branch names, commit IDs and tags")
set(Mapper_GIT_LICENSING_PROVIDER "superbuild" CACHE STRING "Mapper (git): Provider for 3rd-party licensing information")
set(Mapper_GIT_QT_VERSION 5.12 CACHE STRING "Mapper (git): Qt version")
option(Mapper_GIT_ENABLE_POSITIONING "Mapper: Enable positioning" OFF)
option(Mapper_GIT_MANUAL_PDF "Mapper (git): Provide the manual as PDF file (needs pdflatex)" OFF)

foreach(git_tag ${Mapper_GIT_TAGS})
	string(MAKE_C_IDENTIFIER "git-${git_tag}" version)
	string(REGEX REPLACE "^git_" "git-" version "${version}")

	superbuild_package(
	  NAME           openorienteering-mapper
	  VERSION        ${version}
	  DEPENDS
	    gdal
	    libpolyclipping
	    proj
	    qtandroidextras-${Mapper_GIT_QT_VERSION}
	    qtbase-${Mapper_GIT_QT_VERSION}
	    qtimageformats-${Mapper_GIT_QT_VERSION}
	    qtlocation-${Mapper_GIT_QT_VERSION}
	    qtsensors-${Mapper_GIT_QT_VERSION}
	    qttools-${Mapper_GIT_QT_VERSION}
	    qttranslations-${Mapper_GIT_QT_VERSION}
	    zlib
	    host:doxygen
	    host:qttools-${Mapper_GIT_QT_VERSION}

	  SOURCE
	    GIT_REPOSITORY https://github.com/OpenOrienteering/mapper.git
	    GIT_TAG        ${git_tag}

	  USING            version
	                   Mapper_GIT_LICENSING_PROVIDER
	                   Mapper_GIT_ENABLE_POSITIONING
	                   Mapper_GIT_MANUAL_PDF
	  BUILD [[
	    CMAKE_ARGS
	      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
	      "-UCMAKE_STAGING_PREFIX"
	      "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
	      "-DBUILD_SHARED_LIBS=0"
	      "-DMapper_AUTORUN_SYSTEM_TESTS=0"
	      "-DLICENSING_PROVIDER=${Mapper_GIT_LICENSING_PROVIDER}"
	      "-DMapper_BUILD_PACKAGE=1"
	      "-DMapper_VERSION_DISPLAY=${version}"
	      "-DMapper_MANUAL_PDF=$<BOOL:@Mapper_GIT_MANUAL_PDF@>"
	    $<$<BOOL:@ANDROID@>:
	      "-DCMAKE_DISABLE_FIND_PACKAGE_Qt5PrintSupport=TRUE"
	      "-DKEYSTORE_URL=${KEYSTORE_URL}"
	      "-DKEYSTORE_ALIAS=${KEYSTORE_ALIAS}"
	    >
	    $<$<NOT:$<OR:$<BOOL:@ANDROID@>,$<BOOL:@Mapper_GIT_ENABLE_POSITIONING@>>>:
	      "-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Positioning:BOOL=TRUE"
	      "-UQt5Positioning_DIR"
	      "-DCMAKE_DISABLE_FIND_PACKAGE_Qt5Sensors:BOOL=TRUE"
	      "-UQt5Sensors_DIR"
	    >
	    INSTALL_COMMAND
	      "${CMAKE_COMMAND}" --build . --target install/fast -- VERBOSE=1
	        # Mapper Windows installation layout is weird
	        "DESTDIR=${DESTDIR}${INSTALL_DIR}$<$<BOOL:@WIN32@>:/OpenOrienteering>"
	  $<$<NOT:$<BOOL:@CMAKE_CROSSCOMPILING@>>:
	    TEST_BEFORE_INSTALL 1
	  >
	  ]]

	  EXECUTABLES src/Mapper MACOSX_BUNDLE

	  PACKAGE [[
	    COMMAND "${CMAKE_COMMAND}" --build . --target package/fast
	  ]]
	)
endforeach()
