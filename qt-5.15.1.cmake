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

# Common defaults, modules may deviate.
set(short_version  5.15)
set(version        5.15.1)

option(USE_SYSTEM_QT "Use the system Qt if possible" ON)

string(CONFIGURE [[
	if("${module}" MATCHES "Android" AND NOT ANDROID)
		set(BUILD_CONDITION 0)
	elseif(ANDROID AND "${module}" STREQUAL "Qt5SerialPort")
		set(BUILD_CONDITION 0)
	elseif(USE_SYSTEM_QT)
		find_package(Qt5Core @version@ CONFIG QUIET
		  NO_CMAKE_FIND_ROOT_PATH
		  NO_CMAKE_SYSTEM_PATH
		  NO_SYSTEM_ENVIRONMENT_PATH
		)
		if(Qt5Core_VERSION)
			find_package(${module} ${Qt5Core_VERSION} CONFIG EXACT
			  NO_CMAKE_FIND_ROOT_PATH
			  NO_CMAKE_SYSTEM_PATH
			  NO_SYSTEM_ENVIRONMENT_PATH
			)
			find_package(${module} ${Qt5Core_VERSION_MAJOR}.${Qt5Core_VERSION_MINOR} CONFIG
			  NO_CMAKE_FIND_ROOT_PATH
			  NO_CMAKE_SYSTEM_PATH
			  NO_SYSTEM_ENVIRONMENT_PATH
			)
			string(FIND "${${module}_INCLUDE_DIRS}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
			if(${module}_VERSION AND NOT staging_prefix_start EQUAL 0)
				message(STATUS "Found ${SYSTEM_NAME} ${module}: ${${module}_VERSION}")
				set(BUILD_CONDITION 0)
			else()
				message(STATUS "Found ${SYSTEM_NAME} Qt5Core ${Qt5Core_VERSION}, but no matching ${module}")
			endif()
		endif()
	endif()
	if(DEFINED ENV{HOST_PREFIX})
		set(HOST_PREFIX "$ENV{HOST_PREFIX}" PARENT_SCOPE)
	else()
		set(HOST_PREFIX "${TOOLCHAIN_DIR}" PARENT_SCOPE)
	endif()
]] use_system_qt @ONLY)



# qtbase

set(module Qt5Core)
set(qtbase_version       ${version}+dfsg)
set(qtbase_download_hash SHA256=00f7d3c4d7fb8e8921020f8366f907b0fb2ac25ee5e1487ba61ac6cd2c98e36d)
set(qtbase_patch_version ${qtbase_version}-1)
set(qtbase_patch_hash    SHA256=dd93864111f57b1ffe23d3c62fd2a0d8aa5efdb47ae617ae5546be4bf3f07edd)
set(qtbase_base_url      https://snapshot.debian.org/archive/debian/20200910T144906Z/pool/main/q/qtbase-opensource-src/)

superbuild_package(
  NAME           qtbase
  VERSION        ${short_version}
  DEPENDS
    qtbase-opensource-src-${qtbase_patch_version}
)

superbuild_package(
  NAME           qtbase-opensource-src-patches
  VERSION        ${qtbase_patch_version}
  
  SOURCE
    URL            ${qtbase_base_url}qtbase-opensource-src_${qtbase_patch_version}.debian.tar.xz
    URL_HASH       ${qtbase_patch_hash}
)

superbuild_package(
  NAME         qtbase-opensource-src
  VERSION      ${qtbase_patch_version}
  DEPENDS
    source:qtbase-opensource-src-patches-${qtbase_patch_version}
    freetype
    libjpeg-turbo
    libpng
    pcre2
    sqlite3
    zlib
  
  SOURCE
    URL             ${qtbase_base_url}qtbase-opensource-src_${qtbase_version}.orig.tar.xz
    URL_HASH        ${qtbase_download_hash}
    
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=qtbase-opensource-src-patches-${qtbase_patch_version}
        -P "${APPLY_PATCHES_SERIES}"
    # Don't accidently used bundled copies
    COMMAND
      "${CMAKE_COMMAND}" -E remove_directory src/3rdparty/angle # excluded by -opengl desktop
    COMMAND
      "${CMAKE_COMMAND}" -E remove_directory src/3rdparty/dbus-ifaces # excluded by -no-dbus
    COMMAND
      "${CMAKE_COMMAND}" -E remove_directory src/3rdparty/libjpeg # excluded by -system-libjpeg
    COMMAND
      "${CMAKE_COMMAND}" -E remove_directory src/3rdparty/libpng # excluded by -system-libpng
    COMMAND
      "${CMAKE_COMMAND}" -E remove_directory src/3rdparty/pcre # excluded by -system-pcre
    COMMAND
      "${CMAKE_COMMAND}" -E remove_directory src/3rdparty/sqlite # excluded by -system-sqlite, -no-sql-sqlite
    COMMAND
      "${CMAKE_COMMAND}" -E remove_directory src/3rdparty/wasm # for WebAssembly platform
    COMMAND
      "${CMAKE_COMMAND}" -E remove_directory src/3rdparty/xcb # requires -qt-xcb
    # Without extra patching, zlib files are needed for Qt's bootstrapping
    #COMMAND
    #  "${CMAKE_COMMAND}" -E remove_directory src/3rdparty/zlib # excluded by -system-zlib
    COMMAND
      # Enforce make for MSYS. Needed for config.tests outside qtbase, e.g. libtiff in qtimageformats
      # Cf. https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-qt5/0025-qt-5.8.0-force-using-make-on-msys.patch
      sed -i -e "/MAKEFILE_GENERATOR, MINGW/,/mingw32-make/ s/.equals.QMAKE_HOST.os, Windows./\\!isEmpty(QMAKE_SH)|\\!equals(QMAKE_HOST.os, Windows)/"
        mkspecs/features/configure_base.prf
  
  USING default crosscompiling windows android macos USE_SYSTEM_QT module qtbase_patch_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND 
    $<@crosscompiling@:
      COMMAND
       # Cf. qtbase configure "SYSTEM_VARIABLES"
       "${CMAKE_COMMAND}" -E env 
         --unset=AR
         --unset=RANLIB
         --unset=STRIP
         --unset=OBJDUMP
         --unset=LD
         --unset=CC
         --unset=CXX
         --unset=CFLAGS
         --unset=CXXFLAGS
         --unset=LDFLAGS
         # fall through
    >
    "${SOURCE_DIR}/configure"
      -opensource
      -confirm-license
      $<$<CONFIG:Debug>:-debug>$<$<NOT:$<CONFIG:Debug>>:-release $<$<CONFIG:RelWithDebInfo>:-force-debug-info>>
      -shared
      -optimized-tools
      $<@macos@:-no-framework>
      -gui
      -widgets
      -system-libjpeg
      -system-libpng
      -system-pcre
      -system-sqlite
      -system-zlib
      -no-sql-db2
      -no-sql-ibase
      -no-sql-mysql
      -no-sql-oci
      -no-sql-odbc
      -no-sql-psql
      -sql-sqlite
      -no-sql-sqlite2
      -no-sql-tds
      -no-openssl
      -no-directfb
      -no-linuxfb
      $<$<OR:@android@,@macos@,@windows@>:
        -no-dbus
      >
      -nomake examples
      -nomake tests
      -nomake tools
      -system-proxies
      -no-glib
      -prefix         "${CMAKE_INSTALL_PREFIX}"
      -archdatadir    "${CMAKE_INSTALL_PREFIX}/lib/qt5"
      -datadir        "${CMAKE_INSTALL_PREFIX}/share/qt5"
      -examplesdir    "${CMAKE_INSTALL_PREFIX}/share/qt5/examples"
      -headerdir      "${CMAKE_INSTALL_PREFIX}/include/qt5"
      -libdir         "${CMAKE_INSTALL_PREFIX}/lib"
      -extprefix      "${CMAKE_STAGING_PREFIX}"
      $<$<BOOL:@MSYS@>:
        -no-pkg-config
        -platform  win32-g++
        -opengl desktop
      >
      $<@crosscompiling@:
        -no-pkg-config
        -hostprefix "${HOST_PREFIX}"
        #-hostdatadir "${HOST_PREFIX}/share/qt5"
        $<@windows@:
          -device-option CROSS_COMPILE=${SUPERBUILD_TOOLCHAIN_TRIPLET}-
          -xplatform     win32-g++
          -opengl desktop
          -no-feature-systemtrayicon # Workaround missing ChangeWindowMessageFilterEx symbol
          -no-feature-tabletevent # No wintab.h on some MinGW
        >
        $<@android@:
          $<$<STREQUAL:@CMAKE_CXX_COMPILER_ID@,GNU>:
            -xplatform     android-g++
          >$<$<STREQUAL:@CMAKE_CXX_COMPILER_ID@,Clang>:
            -xplatform     android-clang
            -disable-rpath
          >
          -android-ndk   "${ANDROID_NDK_ROOT}"
          -android-sdk   "${ANDROID_SDK_ROOT}"
          -android-arch  "${ANDROID_ABI}"
          -android-ndk-platform "${ANDROID_PLATFORM}"
        >
      >
      -I "${CMAKE_STAGING_PREFIX}/include"
      -L "${CMAKE_STAGING_PREFIX}/lib"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
    $<@android@:
      # androiddeployqt QTBUG-73141
    COMMAND
      "${CMAKE_COMMAND}" -E create_symlink
        "${CMAKE_STAGING_PREFIX}/lib/qt5/plugins"
        "${CMAKE_STAGING_PREFIX}/plugins"
    >
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../qtbase-opensource-src-patches-${qtbase_patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qtbase-${qtbase_patch_version}.txt"
  ]]
)



# qtandroidextras, directly from upstream (not in Debian)

set(module Qt5AndroidExtras)
set(qtandroidextras_version       ${version})
set(qtandroidextras_download_hash SHA256=c1e64d7278f38d99a672265feb8ba5f3edcc9377e816d055a4150f2c44dc58ed)
set(qtandroidextras_url           https://download.qt.io/archive/qt/${short_version}/${qtandroidextras_version}/submodules/qtandroidextras-everywhere-src-${qtandroidextras_version}.tar.xz)

superbuild_package(
  NAME           qtandroidextras
  VERSION        ${short_version}
  DEPENDS        qtandroidextras-everywhere-src-${qtandroidextras_version}
)

superbuild_package(
  NAME           qtandroidextras-everywhere-src
  VERSION        ${qtandroidextras_version}
  DEPENDS
    qtbase-${short_version}
  
  SOURCE
    URL             ${qtandroidextras_url}
    URL_HASH        ${qtandroidextras_download_hash}
  
  USING qmake USE_SYSTEM_QT module short_version qtandroidextras_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "@qmake@" "${SOURCE_DIR}"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
# TODO: Review copyright and credits
#    COMMAND
#      "${CMAKE_COMMAND}" -E copy
#        "<SOURCE_DIR>/../qt-${short_version}-openorienteering-${openorienteering_version}/qtandroidextras/copyright"
#        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qtandroidextras-${qtandroidextras_version}.txt"
  ]]
)



# qtimageformats

set(module Qt5Gui)
set(qtimageformats_version       5.15.1)
set(qtimageformats_download_hash SHA256=75e72b4c11df97af3ff64ed26df16864ce1220a1cc730e49074ab9d72f658568)
set(qtimageformats_patch_version ${qtimageformats_version}-1)
set(qtimageformats_patch_hash    SHA256=8c0d588299addf1e5f1c6af2c208881892530efd05058e9d8cb06d235934f64d)
set(qtimageformats_base_url      https://snapshot.debian.org/archive/debian/20200913T204208Z/pool/main/q/qtimageformats-opensource-src/)

superbuild_package(
  NAME           qtimageformats
  VERSION        ${short_version}
  DEPENDS        qtimageformats-opensource-src-${qtimageformats_version}
)

superbuild_package(
  NAME           qtimageformats-opensource-src-patches
  VERSION        ${qtimageformats_patch_version}
  
  SOURCE
    URL            ${qtimageformats_base_url}qtimageformats-opensource-src_${qtimageformats_patch_version}.debian.tar.xz
    URL_HASH       ${qtimageformats_patch_hash}
)

superbuild_package(
  NAME           qtimageformats-opensource-src
  VERSION        ${qtimageformats_version}
  DEPENDS        
    source:qtimageformats-opensource-src-patches-${qtimageformats_patch_version}
    qtbase-${short_version}
    libwebp
    tiff
  
  SOURCE
    URL             ${qtimageformats_base_url}qtimageformats-opensource-src_${qtimageformats_version}.orig.tar.xz
    URL_HASH        ${qtimageformats_download_hash}
    
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=qtimageformats-opensource-src-patches-${qtimageformats_patch_version}
        -P "${APPLY_PATCHES_SERIES}"
    # Don't accidently used bundled copies
    COMMAND
      "${CMAKE_COMMAND}" -E remove_directory src/3rdparty/libtiff
  
  USING qmake USE_SYSTEM_QT module short_version qtimageformats_patch_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "@qmake@" "${SOURCE_DIR}" --
        -no-jasper
        -no-mng
        -system-tiff
        -system-webp
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../qtimageformats-opensource-src-patches-${qtimageformats_patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qtimageformats-${qtimageformats_patch_version}.txt"
  ]]
)



# qtlocation

set(module Qt5Location)
set(qtlocation_version       ${version}+dfsg)
set(qtlocation_download_hash SHA256=afb8dc6b99a6f54152686df085ad8752b2c39d1e89d891af0b5f5eaeeb4d6987)
set(qtlocation_patch_version ${qtlocation_version}-1)
set(qtlocation_patch_hash    SHA256=26695c4d8097419669d6b495ca48676d84b50ae08c68fdc1ff8d4e48cacfc7a3)
set(qtlocation_base_url      https://snapshot.debian.org/archive/debian/20200911T205121Z/pool/main/q/qtlocation-opensource-src/)

superbuild_package(
  NAME           qtlocation
  VERSION        ${short_version}
  DEPENDS        qtlocation-opensource-src-${qtlocation_version}
)

superbuild_package(
  NAME           qtlocation-opensource-src-patches
  VERSION        ${qtlocation_patch_version}
  
  SOURCE
    URL            ${qtlocation_base_url}qtlocation-opensource-src_${qtlocation_patch_version}.debian.tar.xz
    URL_HASH       ${qtlocation_patch_hash}
)

superbuild_package(
  NAME           qtlocation-opensource-src
  VERSION        ${qtlocation_version}
  DEPENDS        
    source:qtlocation-opensource-src-patches-${qtlocation_patch_version}
    qtbase-${short_version}
    qtserialport-${short_version}
  
  SOURCE
    URL             ${qtlocation_base_url}qtlocation-opensource-src_${qtlocation_version}.orig.tar.xz
    URL_HASH        ${qtlocation_download_hash}
    
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=qtlocation-opensource-src-patches-${qtlocation_patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING qmake USE_SYSTEM_QT module short_version qtlocation_patch_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "@qmake@" "${SOURCE_DIR}"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../qtlocation-opensource-src-patches-${qtlocation_patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qtlocation-${qtlocation_patch_version}.txt"
  ]]
)



# qtsensors

set(module Qt5Sensors)
set(qtsensors_version       ${version})
set(qtsensors_download_hash SHA256=8096b9ffe737434f9564432048f622f6be795619da4e1ed362ce26dddb2cea00)
set(qtsensors_patch_version ${qtsensors_version}-1)
set(qtsensors_patch_hash    SHA256=336c3968441d92c225a106c606d6c157a3cedfe209e58dcb326f6d36a906fc38)
set(qtsensors_base_url      https://snapshot.debian.org/archive/debian/20200911T205121Z/pool/main/q/qtsensors-opensource-src/)

superbuild_package(
  NAME           qtsensors
  VERSION        ${short_version}
  DEPENDS        qtsensors-opensource-src-${qtsensors_version}
)

superbuild_package(
  NAME           qtsensors-opensource-src-patches
  VERSION        ${qtsensors_patch_version}
  
  SOURCE
    URL            ${qtsensors_base_url}qtsensors-opensource-src_${qtsensors_patch_version}.debian.tar.xz
    URL_HASH       ${qtsensors_patch_hash}
)

superbuild_package(
  NAME           qtsensors-opensource-src
  VERSION        ${qtsensors_version}
  DEPENDS        
    source:qtsensors-opensource-src-patches-${qtsensors_patch_version}
    qtbase-${short_version}
  
  SOURCE
    URL             ${qtsensors_base_url}qtsensors-opensource-src_${qtsensors_version}.orig.tar.xz
    URL_HASH        ${qtsensors_download_hash}
    
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=qtsensors-opensource-src-patches-${qtsensors_patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING qmake USE_SYSTEM_QT module short_version qtsensors_patch_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "@qmake@" "${SOURCE_DIR}"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../qtsensors-opensource-src-patches-${qtsensors_patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qtsensors-${qtsensors_patch_version}.txt"
  ]]
)



# qtserialport

set(module Qt5SerialPort)
set(qtserialport_version       5.14.2)
set(qtserialport_download_hash SHA256=a6d977dd723ad4d3368b5163691405b8852f809974a96ec54103494e834aea21)
set(qtserialport_patch_version ${qtserialport_version}-2)
set(qtserialport_patch_hash    SHA256=7ce6102edf72aee96a1e7386cad058fed1387e72e3bbb8d3d4d2b6a836ef2c48)
set(qtserialport_base_url      https://snapshot.debian.org/archive/debian/20200624T145103Z/pool/main/q/qtserialport-opensource-src/)

superbuild_package(
  NAME           qtserialport
  VERSION        ${short_version}
  DEPENDS        qtserialport-opensource-src-${qtserialport_patch_version}
)

superbuild_package(
  NAME           qtserialport-opensource-src-patches
  VERSION        ${qtserialport_patch_version}
  
  SOURCE
    URL            ${qtserialport_base_url}qtserialport-opensource-src_${qtserialport_patch_version}.debian.tar.xz
    URL_HASH       ${qtserialport_patch_hash}
)

superbuild_package(
  NAME           qtserialport-opensource-src
  VERSION        ${qtserialport_patch_version}
  DEPENDS        
    source:qtserialport-opensource-src-patches-${qtserialport_patch_version}
    qtbase-${short_version}
  
  SOURCE
    URL             ${qtserialport_base_url}qtserialport-opensource-src_${qtserialport_version}.orig.tar.xz
    URL_HASH        ${qtserialport_download_hash}
    
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=qtserialport-opensource-src-patches-${qtserialport_patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING qmake USE_SYSTEM_QT module short_version qtserialport_patch_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "@qmake@" "${SOURCE_DIR}"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../qtserialport-opensource-src-patches-${qtserialport_patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qtserialport-${qtserialport_patch_version}.txt"
  ]]
)



# qttools

set(module Qt5LinguistTools)
set(qttools_version       ${version})
set(qttools_download_hash SHA256=c98ee5f0f980bf68cbf0c94d62434816a92441733de50bd9adbe9b9055f03498)
set(qttools_patch_version ${qttools_version}-1)
set(qttools_patch_hash    SHA256=bfcba47e8c4c439830cb32542d053a9567c57a24cfc6c1210db68d9e3a2e5c0b)
set(qttools_base_url      https://snapshot.debian.org/archive/debian/20200914T205536Z/pool/main/q/qttools-opensource-src/)

superbuild_package(
  NAME           qttools
  VERSION        ${short_version}
  DEPENDS        qttools-opensource-src-${qttools_patch_version}
)

superbuild_package(
  NAME           qttools-opensource-src-patches
  VERSION        ${qttools_patch_version}
  
  SOURCE
    URL            ${qttools_base_url}qttools-opensource-src_${qttools_patch_version}.debian.tar.xz
    URL_HASH       ${qttools_patch_hash}
)

superbuild_package(
  NAME           qttools-opensource-src
  VERSION        ${qttools_patch_version}
  DEPENDS        
    source:qttools-opensource-src-patches-${qttools_patch_version}
    qtbase-${short_version}
  
  SOURCE
    URL             ${qttools_base_url}qttools-opensource-src_${qttools_version}.orig.tar.xz
    URL_HASH        ${qttools_download_hash}
    
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=qttools-opensource-src-patches-${qttools_patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING qmake USE_SYSTEM_QT module short_version qttools_patch_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${CMAKE_COMMAND}" -E make_directory src/assistant
    COMMAND
      "${CMAKE_COMMAND}" -E chdir src/assistant "@qmake@" "${SOURCE_DIR}/src/assistant"
    COMMAND
      "${CMAKE_COMMAND}" -E make_directory src/linguist
    COMMAND
      "${CMAKE_COMMAND}" -E chdir src/linguist "@qmake@" "${SOURCE_DIR}/src/linguist"
    BUILD_COMMAND
      "$(MAKE)" -C src/linguist
    $<$<NOT:$<BOOL:@ANDROID@>>:COMMAND
      "$(MAKE)" -C src/assistant
        sub-assistant-make_first
        sub-qcollectiongenerator-make_first
        sub-qhelpgenerator-make_first
    >
    INSTALL_COMMAND
      "$(MAKE)" -C src/linguist
        install
        INSTALL_ROOT=${DESTDIR}
    $<$<NOT:$<BOOL:@ANDROID@>>:COMMAND
      "$(MAKE)" -C src/assistant
         sub-assistant-install_subtargets
         sub-qcollectiongenerator-install_subtargets
         sub-qhelpgenerator-install_subtargets
         INSTALL_ROOT=${DESTDIR}
    >
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../qttools-opensource-src-patches-${qttools_patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qttools-${qttools_patch_version}.txt"
  ]]
)



# qttranslations

set(module Qt5Core) # Can't find qttranslations via CMake.
set(qttranslations_version       ${version})
set(qttranslations_download_hash SHA256=46e0c0e3a511fbcc803a4146204062e47f6ed43b34d98a3c27372a03b8746bd8)
set(qttranslations_patch_version ${qttranslations_version}-1)
set(qttranslations_patch_hash    SHA256=aca5d19297d33aa3db2bea53db47860d09196b3e520c4952282d0800a91e9ec1)
set(qttranslations_base_url      https://snapshot.debian.org/archive/debian/20200916T084220Z/pool/main/q/qttranslations-opensource-src/)

superbuild_package(
  NAME           qttranslations
  VERSION        ${short_version}
  DEPENDS        qttranslations-opensource-src-${qttranslations_patch_version}
)

superbuild_package(
  NAME           qttranslations-opensource-src-patches
  VERSION        ${qttranslations_patch_version}
  
  SOURCE
    URL            ${qttranslations_base_url}qttranslations-opensource-src_${qttranslations_patch_version}.debian.tar.xz
    URL_HASH       ${qttranslations_patch_hash}
)

superbuild_package(
  NAME           qttranslations-opensource-src
  VERSION        ${qttranslations_patch_version}
  DEPENDS        
    source:qttranslations-opensource-src-patches-${qttranslations_patch_version}
    qtbase-${short_version}
    qttools-${short_version}
  
  SOURCE
    URL             ${qttranslations_base_url}qttranslations-opensource-src_${qttranslations_version}.orig.tar.xz
    URL_HASH        ${qttranslations_download_hash}
    
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=qttranslations-opensource-src-patches-${qttranslations_patch_version}
        -P "${APPLY_PATCHES_SERIES}"
  
  USING qmake USE_SYSTEM_QT module short_version qttranslations_patch_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "@qmake@" "${SOURCE_DIR}"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../qttranslations-opensource-src-patches-${qttranslations_patch_version}/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qttranslations-${qttranslations_patch_version}.txt"
  ]]
)



# All

superbuild_package(
  NAME           qt
  VERSION        ${version}
  DEPENDS
    qtandroidextras-${short_version}
    qtbase-${short_version}
    qtimageformats-${short_version}
    qtlocation-${short_version}
    qtsensors-${short_version}
    qttools-${short_version}
    qttranslations-${short_version}
)



# Attribution maintenance, in git

find_package(Git QUIET)
find_package(PythonInterp 3 QUIET)
if(GIT_EXECUTABLE AND PYTHONINTERP_FOUND
   AND "${openorienteering_version}" STREQUAL "${patch_version}")
    superbuild_package(
      NAME           qt-${short_version}-openorienteering
      VERSION        git
      DEPENDS
        qttools-opensource-src-${patch_version}  # for qtattributionsscanner
        source:qtandroidextras-everywhere-src-${patch_version}
        source:qtbase-opensource-src-${patch_version}
        source:qtimageformats-opensource-src-${patch_version}
        source:qtlocation-opensource-src-${patch_version}
        source:qtsensors-opensource-src-${patch_version}
        source:qtserialport-opensource-src-${patch_version}
        source:qttools-opensource-src-${patch_version}
        source:qttranslations-opensource-src-${patch_version}
      
      SOURCE
        GIT_REPOSITORY https://github.com/OpenOrienteering/superbuild.git
        GIT_TAG        qt-${short_version}-openorienteering
      
      USING patch_version PYTHON_EXECUTABLE
      BUILD [[
        CMAKE_ARGS
          "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
          "-DVERSION=${patch_version}"
          "-DPYTHON_EXECUTABLE=${PYTHON_EXECUTABLE}"
        BUILD_COMMAND
          "${CMAKE_COMMAND}" --build . --target update-copyright
        BUILD_ALWAYS 1
        INSTALL_COMMAND ""
      ]]
    )
endif()
