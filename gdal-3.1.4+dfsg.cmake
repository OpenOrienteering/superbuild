# This file is part of OpenOrienteering.

# Copyright 2016-2024 Kai Pastor
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

# https://tracker.debian.org/pkg/gdal

set(version        3.1.4+dfsg)
set(download_hash  SHA256=4e7de7eb64189fef6555f450c781e1b264386fce1846ff29cb63def458add67d)
set(patch_version  ${version}-1)
set(patch_hash     SHA256=da1f77fd2f491d847b4e8e9a0e3177c4a21c120916392e3abcfef31f7fbe0bb1)
set(base_url       https://snapshot.debian.org/archive/debian/20201024T083840Z/pool/main/g/gdal/)

option(USE_SYSTEM_GDAL "Use the system GDAL if possible" ON)

set(test_system_gdal [[
	if(USE_SYSTEM_GDAL)
		enable_language(C)
		find_package(GDAL 2 QUIET)
		string(FIND "${GDAL_INCLUDE_DIR}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(GDAL_FOUND AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} gdal: ${GDAL_LIBRARY}")
			set(BUILD_CONDITION 0)
		endif()
	endif()
	
	if(BUILD_CONDITION)
		find_program(CURL_CONFIG NAMES curl-config QUIET CMAKE_FIND_ROOT_PATH_BOTH)
		if(NOT CURL_CONFIG)
			message(FATAL_ERROR "Could not find curl-config")
		endif()
		
		find_path(EXPAT_INCLUDE_DIR NAMES expat.h QUIET)
		if(NOT EXPAT_INCLUDE_DIR)
			message(FATAL_ERROR "Could not find expat.h")
		endif()
		get_filename_component(EXPAT_DIR "${EXPAT_INCLUDE_DIR}" DIRECTORY CACHE)
		
		find_path(LIBKML_INCLUDE_DIR NAMES kml/engine.h QUIET)
		if(NOT LIBKML_INCLUDE_DIR)
			message(FATAL_ERROR "Could not find kml/engine.h")
		endif()
		get_filename_component(LIBKML_DIR "${LIBKML_INCLUDE_DIR}" DIRECTORY CACHE)
		
		find_path(SQLITE3_INCLUDE_DIR NAMES sqlite3.h QUIET)
		if(NOT SQLITE3_INCLUDE_DIR)
			message(FATAL_ERROR "Could not find sqlite3.h")
		endif()
		get_filename_component(SQLITE3_DIR "${SQLITE3_INCLUDE_DIR}" DIRECTORY CACHE)
	endif(BUILD_CONDITION)
	
	set(extra_cflags   "-Wno-strict-overflow -Wno-null-dereference" PARENT_SCOPE)
	set(extra_cxxflags "-Wno-strict-overflow -Wno-null-dereference -Wno-old-style-cast" PARENT_SCOPE)
	set(extra_ldflags  "-lminizip")
]])

set(gcc-13_patch [[
diff --git a/ogr/ogrsf_frmts/cad/libopencad/dwg/r2000.cpp b/ogr/ogrsf_frmts/cad/libopencad/dwg/r2000.cpp
index b500df8..51666e3 100644
--- a/ogr/ogrsf_frmts/cad/libopencad/dwg/r2000.cpp
+++ b/ogr/ogrsf_frmts/cad/libopencad/dwg/r2000.cpp
@@ -36,6 +36,7 @@
 #include <cassert>
 #include <cstring>
 #include <iostream>
+#include <limits>
 #include <memory>
 #include <string>
 
]])

set(libjpeg_patch [[
--- a/configure
+++ b/configure
@@ -1247,6 +1247,7 @@
 CXXCPP
 PKG_CONFIG
 bashcompdir
+LIBJPEG_SUFFIX
 PQ_CFLAGS
 PQ_LIBS
 OGDI_CFLAGS
@@ -30093,13 +30093,13 @@
 
 elif test "$with_jpeg" = "yes" -o "$with_jpeg" = "" ; then
 
-  { $as_echo "$as_me:${as_lineno-$LINENO}: checking for jpeg_read_scanlines in -ljpeg" >&5
-$as_echo_n "checking for jpeg_read_scanlines in -ljpeg... " >&6; }
+  { $as_echo "$as_me:${as_lineno-$LINENO}: checking for jpeg_read_scanlines in -ljpeg${LIBJPEG_SUFFIX}" >&5
+$as_echo_n "checking for jpeg_read_scanlines in -ljpeg${LIBJPEG_SUFFIX}... " >&6; }
 if ${ac_cv_lib_jpeg_jpeg_read_scanlines+:} false; then :
   $as_echo_n "(cached) " >&6
 else
   ac_check_lib_save_LIBS=$LIBS
-LIBS="-ljpeg  $LIBS"
+LIBS="-ljpeg${LIBJPEG_SUFFIX} $LIBS"
 cat confdefs.h - <<_ACEOF >conftest.$ac_ext
 /* end confdefs.h.  */
 
@@ -30172,7 +30172,7 @@
   fi
 
   if test "$JPEG_SETTING" = "external" ; then
-    LIBS="-ljpeg $LIBS"
+    LIBS="-ljpeg${LIBJPEG_SUFFIX} $LIBS"
     echo "using pre-installed libjpeg."
   else
     echo "using internal jpeg code."
@@ -30187,7 +30187,7 @@
 else
 
   JPEG_SETTING=external
-  LIBS="-L$with_jpeg -L$with_jpeg/lib -ljpeg $LIBS"
+  LIBS="-L$with_jpeg -L$with_jpeg/lib -ljpeg${LIBJPEG_SUFFIX} $LIBS"
   EXTRA_INCLUDES="-I$with_jpeg -I$with_jpeg/include $EXTRA_INCLUDES"
 
   echo "using libjpeg from $with_jpeg."
@@ -31550,7 +31550,7 @@
   $as_echo_n "(cached) " >&6
 else
   ac_check_lib_save_LIBS=$LIBS
-LIBS="-lmfhdfalt -ldfalt -ljpeg -lz $LIBS"
+LIBS="-lmfhdfalt -ldfalt -ljpeg${LIBJPEG_SUFFIX} -lz $LIBS"
 cat confdefs.h - <<_ACEOF >conftest.$ac_ext
 /* end confdefs.h.  */
 
@@ -31596,7 +31596,7 @@
   $as_echo_n "(cached) " >&6
 else
   ac_check_lib_save_LIBS=$LIBS
-LIBS="-lmfhdfalt -ldfalt -lsz -ljpeg -lz $LIBS"
+LIBS="-lmfhdfalt -ldfalt -lsz -ljpeg${LIBJPEG_SUFFIX} -lz $LIBS"
 cat confdefs.h - <<_ACEOF >conftest.$ac_ext
 /* end confdefs.h.  */
 
@@ -40801,7 +40801,7 @@
         PDFIUM_LIB="-L$with_pdfium/lib -lpdfium"
     fi
 
-    PDFIUM_LIB="$PDFIUM_LIB -ljpeg -lpng -lz -llcms2 -lpthread -lm -lstdc++"
+    PDFIUM_LIB="$PDFIUM_LIB -ljpeg${LIBJPEG_SUFFIX} -lpng -lz -llcms2 -lpthread -lm -lstdc++"
 
     if test ! -z "`uname | grep Darwin`" ; then
         PDFIUM_LIB="-stdlib=libstdc++ $PDFIUM_LIB"
]])

superbuild_package(
  NAME           gdal-patches
  VERSION        ${patch_version}
  
  SOURCE
    URL            ${base_url}gdal_${patch_version}.debian.tar.xz
    URL_HASH       ${patch_hash}
)
  
superbuild_package(
  NAME           gdal
  VERSION        ${patch_version}+openorienteering1
  DEPENDS
    source:gdal-patches-${patch_version}
    common-licenses
    curl
    expat
    giflib
    libiconv
    libjpeg
    libkml
    liblzma
    libpng
    libwebp
    openjpeg2
    pcre3
    pkg-config
    poppler
    proj
    sqlite3
    tiff
    zlib
  
  SOURCE_WRITE
    libjpeg.patch  libjpeg_patch
    gcc-13.patch   gcc-13_patch
  SOURCE
    URL            ${base_url}gdal_${version}.orig.tar.xz
    URL_HASH       ${download_hash}
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=gdal-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
    COMMAND
      patch -p1 < libjpeg.patch
    COMMAND
      patch -p1 < gcc-13.patch
  
  USING            USE_SYSTEM_GDAL patch_version extra_cflags extra_cxxflags extra_ldflags
  BUILD_CONDITION  ${test_system_gdal}
  BUILD [[
    # Cannot do out-of-source build of gdal
    CONFIGURE_COMMAND
      "${CMAKE_COMMAND}" -E make_directory "${BINARY_DIR}"
    COMMAND
      "${CMAKE_COMMAND}" -E copy_directory "${SOURCE_DIR}" "${BINARY_DIR}"
    COMMAND
      $<$<BOOL:@ANDROID@>:
        "${CMAKE_COMMAND}" -E env LIBJPEG_SUFFIX=-turbo  # needs libjpeg patch
      >
      "${BINARY_DIR}/configure"
        "--prefix=${CMAKE_INSTALL_PREFIX}"
        $<$<BOOL:@CMAKE_CROSSCOMPILING@>:
          --host=${SUPERBUILD_TOOLCHAIN_TRIPLET}
        >
        --disable-static
        --enable-shared
        --with-hide-internal-symbols
        --with-rename-internal-libtiff-symbols
        --with-threads
        "--with-curl=${CURL_CONFIG}"
        "--with-expat=${EXPAT_DIR}"
        --with-gif
        --with-jpeg
        "--with-libkml=${LIBKML_DIR}"
        --with-liblzma
        --with-libtiff
        --with-libz
        --with-openjpeg
        --with-pcre
        --with-png
        --with-poppler
        --with-proj
        "--with-sqlite3=${SQLITE3_DIR}"
        --with-webp
        --without-geos
        --without-java
        --without-jpeg12
        --without-netcdf
        --without-odbc
        --without-ogdi
        --without-pcraster
        --without-perl
        --without-pg
        --without-python
        --without-xerces
        --without-xml2
        --without-zstd
      $<$<STREQUAL:@CMAKE_SYSTEM_NAME@,Windows>:
        --without-crypto
      > # Windows
        "CC=${SUPERBUILD_CC}"
        "CXX=${SUPERBUILD_CXX}"
        "CPPFLAGS=${SUPERBUILD_CPPFLAGS}"
        "CFLAGS=${SUPERBUILD_CFLAGS} ${extra_cflags}"
        "CXXFLAGS=${SUPERBUILD_CXXFLAGS} ${extra_cxxflags}"
        "LDFLAGS=${SUPERBUILD_LDFLAGS} ${extra_ldflags}"
    BUILD_COMMAND
      "$(MAKE)"
    INSTALL_COMMAND
      "$(MAKE)" install "DESTDIR=${DESTDIR}${INSTALL_DIR}"
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../gdal-patches-${patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/gdal-${patch_version}.txt"
  ]]
)
