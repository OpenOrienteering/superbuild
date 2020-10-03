# This file is part of OpenOrienteering.

# Copyright 2016-2020 Kai Pastor
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

set(version        2.0.5)
set(download_hash  SHA256=16f8f6f2715b3a38ab562a84357c793dd56ae9899ce130563c72cd93d8357b5d)
set(patch_version  ${version}-1.1)
set(patch_hash     SHA256=d4370be8fabaef3be0007a75df92f964986f03d648c5f97cbeb750067f53a493)
set(base_url       https://snapshot.debian.org/archive/debian/20200802T025122Z/pool/main/libj/libjpeg-turbo/)

option(USE_SYSTEM_LIBJPEG "Use the system libjpeg if possible" ON)

set(test_system_jpeg [[
	if(USE_SYSTEM_LIBJPEG)
		enable_language(C)
		find_package(JPEG CONFIG QUIET)
		find_package(JPEG MODULE QUIET)
		string(FIND "${JPEG_INCLUDE_DIR}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(JPEG_FOUND AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} libjpeg: ${JPEG_LIBRARIES}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
]])

set(suffix_patch [[
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -189,6 +189,13 @@
 report_option(ENABLE_SHARED "Shared libraries")
 report_option(ENABLE_STATIC "Static libraries")
 
+if(NOT MSVC)
+  set(LIBJPEG_SUFFIX "" CACHE STRING "Suffix to be added the library name")
+  report_option(LIBJPEG_SUFFIX "Library name suffix")
+else()
+  set(LIBJPEG_SUFFIX "")
+endif()
+
 if(WITH_12BIT)
   set(WITH_ARITH_DEC 0)
   set(WITH_ARITH_ENC 0)
@@ -566,7 +573,7 @@
   add_library(jpeg-static STATIC ${JPEG_SOURCES} $<TARGET_OBJECTS:simd>
     ${SIMD_OBJS})
   if(NOT MSVC)
-    set_target_properties(jpeg-static PROPERTIES OUTPUT_NAME jpeg)
+    set_target_properties(jpeg-static PROPERTIES OUTPUT_NAME jpeg${LIBJPEG_SUFFIX})
   endif()
 endif()
 
--- a/release/libjpeg.pc.in
+++ b/release/libjpeg.pc.in
@@ -6,5 +6,5 @@
 Name: libjpeg
 Description: A SIMD-accelerated JPEG codec that provides the libjpeg API
 Version: @VERSION@
-Libs: -L${libdir} -ljpeg
+Libs: -L${libdir} -ljpeg@LIBJPEG_SUFFIX@
 Cflags: -I${includedir}
--- a/sharedlib/CMakeLists.txt
+++ b/sharedlib/CMakeLists.txt
@@ -38,6 +38,9 @@
 add_library(jpeg SHARED ${JPEG_SRCS} ${DEFFILE} $<TARGET_OBJECTS:simd>
   ${SIMD_OBJS})
 
+if(NOT MSVC)
+  set_target_properties(jpeg PROPERTIES OUTPUT_NAME jpeg${LIBJPEG_SUFFIX})
+endif()
 set_target_properties(jpeg PROPERTIES SOVERSION ${SO_MAJOR_VERSION}
   VERSION ${SO_MAJOR_VERSION}.${SO_AGE}.${SO_MINOR_VERSION})
 if(APPLE AND (NOT CMAKE_OSX_DEPLOYMENT_TARGET OR
]])

superbuild_package(
  NAME           libjpeg-turbo-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}libjpeg-turbo_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           libjpeg-turbo
  VERSION        ${patch_version}
  DEPENDS
    source:libjpeg-turbo-patches-${patch_version}
    host:nasm
  
  SOURCE_WRITE
    suffix.patch   suffix_patch
  SOURCE
    DOWNLOAD_NAME  libjpeg-turbo_${version}.orig.tar.gz
    URL            ${base_url}libjpeg-turbo_${version}.orig.tar.gz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=libjpeg-turbo-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
    COMMAND
      patch -p1 < suffix.patch
  
  USING            USE_SYSTEM_LIBJPEG patch_version
  BUILD_CONDITION  ${test_system_jpeg}
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DCMAKE_BUILD_TYPE:STRING=$<CONFIG>"
      -DENABLE_SHARED=ON
      -DENABLE_STATIC=OFF
      $<$<BOOL:@ANDROID@>:
        -DLIBJPEG_SUFFIX=-turbo  # needs suffix patch
        -DCMAKE_ASM_FLAGS="--target=${SUPERBUILD_TOOLCHAIN_TRIPLET}${ANDROID_NATIVE_API_LEVEL}"
      >
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" --build . --target install/strip/fast
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../libjpeg-turbo-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/libjpeg-turbo-${patch_version}.txt"
  ]]
)

superbuild_package(
  NAME           libjpeg
  VERSION        99-${patch_version}-turbo
  DEPENDS
    libjpeg-turbo-${patch_version}
)
