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

set(version        20.08.0)
set(download_hash  SHA256=ae65fef04bbf63259a6352e7b620719115d4fb97f5079b0b8b00a8eb0c86eca5)
set(patch_version  ${version}-1)
set(patch_hash     SHA256=f5447a3fafa65d0a4a448b06ab7ad0f771d0a3a565cbf2aeba6c3e9029d4af70)
set(base_url       https://snapshot.debian.org/archive/debian/20200902T144444Z/pool/main/p/poppler/)

option(USE_SYSTEM_POPPLER "Use the system Poppler if possible" ON)

set(test_system_poppler [[
	if(${USE_SYSTEM_POPPLER})
		enable_language(C)
		find_library(POPPLER_LIBRARY NAMES poppler QUIET)
		find_path(POPPLER_INCLUDE_DIR NAMES poppler-document.h QUIET)
		string(FIND "${POPPLER_LIBRARY}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(POPPLER_LIBRARY AND POPPLER_INCLUDE_DIR AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} Poppler: ${POPPLER_LIBRARY}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
	set(font_configuration )
	if(BUILD_CONDITION AND APPLE)
		find_package(Fontconfig QUIET)
		if(Fontconfig_FOUND)
			message(STATUS "${SYSTEM_NAME} Fontconfig: ${Fontconfig_VERSION}")
		else()
			message(STATUS "${SYSTEM_NAME} Fontconfig: not found")
			set(font_configuration "-DFONT_CONFIGURATION=generic")
		endif()
	endif()
	set(poppler_font_configuration "${font_configuration}" CACHE STRING
	  "Poppler font configuration" FORCE)
	
	if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
		set(extra_flags "-Wno-zero-as-null-pointer-constant -Wno-unused-private-field" PARENT_SCOPE)
	else()
		set(extra_flags "-Wno-zero-as-null-pointer-constant -Wno-unused-function" PARENT_SCOPE)
	endif()
]])

set(license_txt [[
   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 2 of the License or
   (at your option) version 3 of the License.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.

On Debian systems, the complete text of the GNU General
Public License version 2 can be found in "/usr/share/common-licenses/GPL-2".

On Debian systems, the complete text of the GNU General
Public License version 3 can be found in "/usr/share/common-licenses/GPL-3".


For cpp/tests/pdf_fuzzer.cc, the following license applies:
--cut--
]])

set(cpp_macros_diff [[
WITH_FONTCONFIGURATION_WIN32 is either undefined or 1.
--- a/poppler/GlobalParams.cc
+++ b/poppler/GlobalParams.cc
@@ -1002,7 +1002,7 @@
     return path;
 }
 
-#elif WITH_FONTCONFIGURATION_WIN32
+#elif defined(WITH_FONTCONFIGURATION_WIN32)
 #    include "GlobalParamsWin.cc"
 
 GooString *GlobalParams::findBase14FontFile(const GooString *base14Name, const GfxFont *font)]]
)

superbuild_package(
  NAME           poppler-patches
  VERSION        ${patch_version}
  
  SOURCE_WRITE
    license.txt    license_txt
  SOURCE
    URL            ${base_url}poppler_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
  PATCH_COMMAND
    sed -e "/^License:/r license.txt" -i -- copyright
  COMMAND
    sed -e "/--cut--/,/pdf_fuzzer/d" -i -- copyright
)
  
superbuild_package(
  NAME           poppler
  VERSION        ${patch_version}
  DEPENDS
    source:poppler-patches-${patch_version}
    freetype
    libiconv
    libjpeg
    libpng
    openjpeg2
    pkg-config
    tiff
    zlib
  
  SOURCE_WRITE
    cpp_macros.diff  cpp_macros_diff
  SOURCE
    URL            ${base_url}poppler_${version}.orig.tar.xz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=poppler-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
    COMMAND
      patch -N -p1 < cpp_macros.diff
  
  USING            version patch_version extra_flags
  BUILD_CONDITION  ${test_system_poppler}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS} ${extra_flags}"
      "-DCMAKE_BUILD_TYPE:STRING=$<CONFIG>"
      -DBUILD_SHARED_LIBS=ON
      -DENABLE_UNSTABLE_API_ABI_HEADERS=ON # needed by GDAL
      -DENABLE_SPLASH=ON
      -DENABLE_LIBOPENJPEG=openjpeg2
      -DENABLE_DCTDECODER=libjpeg
      -DENABLE_GLIB=OFF
      -DBUILD_GTK_TESTS=OFF
      -DENABLE_QT5=OFF
      -DBUILD_QT5_TESTS=OFF
      -DENABLE_LIBCURL=OFF
      -DRUN_GPERF_IF_PRESENT=OFF
      -DCMAKE_DISABLE_FIND_PACKAGE_NSS3=ON
      ${poppler_font_configuration}
      $<$<BOOL:@ANDROID@>:
        -D_FILE_OFFSET_BITS=
      >
   INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../poppler-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/poppler-${patch_version}.txt"
  ]]
)
