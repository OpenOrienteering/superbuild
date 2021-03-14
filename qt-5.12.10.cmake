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

set(short_version  5.12)
set(version        5.12.7)
set(patch_version  ${version}-0)
set(openorienteering_version ${version}-qtbase-5.12.10-2)

option(USE_SYSTEM_QT "Use the system Qt if possible" ON)

# Note for Android
# Set environment variable ANDROID_API_VERSION to specify the target API level.
# Building Qt 5.12.10 needs "android-24" or higher.
# Cf. https://bugreports.qt.io/browse/QTBUG-89616

string(CONFIGURE [[
	if("${module}" MATCHES "Android" AND NOT ANDROID)
		set(BUILD_CONDITION 0)
	elseif(ANDROID AND "${module}" STREQUAL "Qt5SerialPort")
		set(BUILD_CONDITION 0)
	elseif(ANDROID AND "${module}" STREQUAL "Qt5Help")
		set(BUILD_CONDITION 0)
	elseif("${module}" STREQUAL "qtattributionsscanner")
		find_program(QTATTRIBUTIONSCANNER NAME "${module}" ONLY_CMAKE_FIND_ROOT_PATH QUIET)
		string(FIND "${QTATTRIBUTIONSCANNER}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
		if(CMAKE_CROSSCOMPILING)
			set(BUILD_CONDITION 0)
		elseif(QTATTRIBUTIONSCANNER AND NOT staging_prefix_start EQUAL 0)
			message(STATUS "Found ${SYSTEM_NAME} ${module}: ${QTATTRIBUTIONSCANNER}")
		endif()
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



# copyright and patches for superbuild of Qt

set(default        [[$<STREQUAL:${SYSTEM_NAME},default>]])
set(crosscompiling [[$<BOOL:${CMAKE_CROSSCOMPILING}>]])
set(windows        [[$<STREQUAL:${CMAKE_SYSTEM_NAME},Windows>]])
set(macos          [[$<STREQUAL:${CMAKE_SYSTEM_NAME},Darwin>]])
set(android        [[$<BOOL:${ANDROID}>]])
set(use_sysroot    [[$<NOT:$<AND:$<BOOL:${CMAKE_CROSSCOMPILING}>,$<BOOL:${ANDROID}>>>]])
set(qmake          [[$<$<BOOL:${CMAKE_CROSSCOMPILING}>:$${}{HOST_PREFIX}>$<$<NOT:$<BOOL:${CMAKE_CROSSCOMPILING}>>:${CMAKE_STAGING_PREFIX}>/bin/qmake]])


set(module Qt5Core)
superbuild_package(
  NAME           qt-${short_version}-openorienteering
  VERSION        ${openorienteering_version}
  
  SOURCE
    URL            https://github.com/OpenOrienteering/superbuild/archive/qt-${short_version}-openorienteering_${openorienteering_version}.tar.gz
    URL_HASH       SHA256=63a9e4a5000e6a6de572644867e8f926274dd13d9b32d51e97548d5c498070b7
)



# qtbase

set(qtbase_version       5.12.10)
set(qtbase_patch_version ${qtbase_version}-1)
set(module Qt5Core)
superbuild_package(
  NAME         qtbase-everywhere-src
  VERSION      ${qtbase_patch_version}
  PROVIDES     qtbase-${short_version}
  DEPENDS
    source:qt-${short_version}-openorienteering-${openorienteering_version}
    freetype
    libjpeg
    libpng
    pcre2
    pkg-config
    sqlite3
    zlib
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${qtbase_version}/submodules/qtbase-everywhere-src-${qtbase_version}.tar.xz
    URL_HASH        SHA256=8088f174e6d28e779516c083b6087b6a9e3c8322b4bc161fd1b54195e3c86940
    
    # Don't accidently used bundled copies
    PATCH_COMMAND
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
    COMMAND
      "${CMAKE_COMMAND}" -E remove_directory src/3rdparty/zlib # excluded by -system-zlib
    COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=qt-${short_version}-openorienteering-${openorienteering_version}/qtbase
        -P "${APPLY_PATCHES_SERIES}"
    COMMAND
      # Enforce make for MSYS. Needed for config.tests outside qtbase, e.g. libtiff in qtimageformats
      # Cf. https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-qt5/0025-qt-5.8.0-force-using-make-on-msys.patch
      sed -i -e "/MAKEFILE_GENERATOR, MINGW/,/mingw32-make/ s/.equals.QMAKE_HOST.os, Windows./\\!isEmpty(QMAKE_SH)|\\!equals(QMAKE_HOST.os, Windows)/"
        mkspecs/features/configure_base.prf
  
  USING default crosscompiling windows android macos USE_SYSTEM_QT module short_version openorienteering_version qtbase_patch_version
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
         $<@android@:
           # Required to satisfy qconfigure.pri
           PKG_CONFIG_SYSROOT_DIR=set-but-not-used
           PKG_CONFIG_LIBDIR=set-but-not-used
         >
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
        -hostprefix "${HOST_PREFIX}"
        #-hostdatadir "${HOST_PREFIX}/share/qt5"
        $<@windows@:
          -device-option CROSS_COMPILE=${SUPERBUILD_TOOLCHAIN_TRIPLET}-
          -xplatform     win32-g++
          -opengl desktop
          -no-feature-systemtrayicon # Workaround missing ChangeWindowMessageFilterEx symbol
        >
        $<@android@:
          -pkg-config
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
        "<SOURCE_DIR>/../qt-${short_version}-openorienteering-${openorienteering_version}/qtbase/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qtbase-${qtbase_patch_version}.txt"
  ]]
)



# qtandroidextras

set(qtandroidextras_version ${patch_version})
set(module Qt5AndroidExtras)
superbuild_package(
  NAME           qtandroidextras-everywhere-src
  VERSION        ${qtandroidextras_version}
  PROVIDES       qtandroidextras-${short_version}
  DEPENDS
    source:qt-${short_version}-openorienteering-${openorienteering_version}
    qtbase-${short_version}
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qtandroidextras-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=a5acc927bd46ed87627e2ae0f0bfc199189d383a3e17c2f34b8c34ea57b2aea1
  
  USING qmake USE_SYSTEM_QT module short_version openorienteering_version qtandroidextras_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "@qmake@" "${SOURCE_DIR}"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../qt-${short_version}-openorienteering-${openorienteering_version}/qtandroidextras/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qtandroidextras-${qtandroidextras_version}.txt"
  ]]
)



# qtimageformats

set(qtimageformats_version ${patch_version})
set(module Qt5Gui) # qtimageformats adds plugins to Qt5Gui
superbuild_package(
  NAME           qtimageformats-everywhere-src
  VERSION        ${qtimageformats_version}
  PROVIDES       qtimageformats-${short_version}
  DEPENDS        
    source:qt-${short_version}-openorienteering-${openorienteering_version}
    qtbase-${short_version}
    libwebp
    tiff
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qtimageformats-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=9bd19ee24fb85f249d01c78e637c95377dd738feb61da0deeee6b770fa62f70b
    
    # Don't accidently used bundled copies
    PATCH_COMMAND
      "${CMAKE_COMMAND}" -E remove_directory src/3rdparty/libtiff
    COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=qt-${short_version}-openorienteering-${openorienteering_version}/qtimageformats
        -P "${APPLY_PATCHES_SERIES}"
	  
  
  USING qmake USE_SYSTEM_QT module short_version openorienteering_version qtimageformats_version
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
        "<SOURCE_DIR>/../qt-${short_version}-openorienteering-${openorienteering_version}/qtimageformats/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qtimageformats-${qtimageformats_version}.txt"
  ]]
)



# qtlocation

set(qtlocation_version ${patch_version})
set(module Qt5Location)
superbuild_package(
  NAME           qtlocation-everywhere-src
  VERSION        ${qtlocation_version}
  PROVIDES       qtlocation-${short_version}
  DEPENDS
    source:qt-${short_version}-openorienteering-${openorienteering_version}
    qtbase-${short_version}
    qtserialport-${short_version}
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qtlocation-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=d1e905b80befda3c9aaad92ea984e6dbf722568b5c91e8d15b027bc5bc22781f
    
  USING qmake USE_SYSTEM_QT module short_version openorienteering_version qtlocation_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "@qmake@" "${SOURCE_DIR}"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../qt-${short_version}-openorienteering-${openorienteering_version}/qtlocation/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qtlocation-${qtlocation_version}.txt"
  ]]
)



# qtsensors

set(qtsensors_version ${patch_version})
set(module Qt5Sensors)
superbuild_package(
  NAME           qtsensors-everywhere-src
  VERSION        ${qtsensors_version}
  PROVIDES       qtsensors-${short_version}
  DEPENDS
    source:qt-${short_version}-openorienteering-${openorienteering_version}
    qtbase-${short_version}
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qtsensors-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=2b9aea9f4e2f681b4067f2b9d97c5073c135e41d26601c71f18f199bc980e740
  
  USING qmake USE_SYSTEM_QT module short_version openorienteering_version qtsensors_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "@qmake@" "${SOURCE_DIR}"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../qt-${short_version}-openorienteering-${openorienteering_version}/qtsensors/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qtsensors-${qtsensors_version}.txt"
  ]]
)



# qtserialport

set(qtserialport_version ${patch_version})
set(module Qt5SerialPort)
superbuild_package(
  NAME           qtserialport-everywhere-src
  VERSION        ${qtserialport_version}
  PROVIDES       qtserialport-${short_version}
  DEPENDS
    source:qt-${short_version}-openorienteering-${openorienteering_version}
    qtbase-${short_version}
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qtserialport-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=224c282ebed750f46b72dfe18260c3d26fbb74e928dec64bd8c51e7beed8721f
  
  USING qmake USE_SYSTEM_QT module short_version openorienteering_version qtserialport_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "@qmake@" "${SOURCE_DIR}"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../qt-${short_version}-openorienteering-${openorienteering_version}/qtserialport/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qtserialport-${qtserialport_version}.txt"
  ]]
)



# qttools

set(qttools_version ${patch_version})
superbuild_package(
  NAME           qttools-everywhere-src
  VERSION        ${qttools_version}
  PROVIDES       qttools-${short_version}
  DEPENDS
    source:qt-${short_version}-openorienteering-${openorienteering_version}
    # FIXME: Dependers shall use the sub-packages.
    qttools-linguist
    qttools-assistant
    qttools-qtattributionsscanner
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qttools-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=860a97114d518f83c0a9ab3742071da16bb018e6eb387179d5764a8dcca03948
    
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=qt-${short_version}-openorienteering-${openorienteering_version}/qttools
        -P "${APPLY_PATCHES_SERIES}"
)

set(module Qt5LinguistTools)  # proxy
superbuild_package(
  NAME           qttools-copyright
  VERSION        ${qttools_version}
  DEPENDS
    source:qt-${short_version}-openorienteering-${openorienteering_version}
  
  SOURCE         qttools-everywhere-src-${qttools_version}
  
  USING qmake USE_SYSTEM_QT module short_version openorienteering_version qttools_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../qt-${short_version}-openorienteering-${openorienteering_version}/qttools/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qttools-${qttools_version}.txt"
  ]]
)

set(module Qt5Help)
superbuild_package(
  NAME           qttools-assistant
  VERSION        ${qttools_version}
  PROVIDES       qttools-assistant-${short_version}
  DEPENDS
    qtbase-${short_version}
    qttools-copyright-${qttools_version}
  
  SOURCE         qttools-everywhere-src-${qttools_version}
  
  USING qmake USE_SYSTEM_QT module short_version openorienteering_version qttools_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${CMAKE_COMMAND}" -E make_directory src/assistant
    COMMAND
      "${CMAKE_COMMAND}" -E chdir src/assistant "@qmake@" "${SOURCE_DIR}/src/assistant"
    BUILD_COMMAND
      "$(MAKE)" -C src/assistant
        sub-assistant-make_first
        sub-qcollectiongenerator-make_first
        sub-qhelpgenerator-make_first
    INSTALL_COMMAND
      "$(MAKE)" -C src/assistant
         sub-assistant-install_subtargets
         sub-qcollectiongenerator-install_subtargets
         sub-qhelpgenerator-install_subtargets
         INSTALL_ROOT=${DESTDIR}
  ]]
)

set(module Qt5LinguistTools)
superbuild_package(
  NAME           qttools-linguist
  VERSION        ${qttools_version}
  PROVIDES       qttools-linguist-${short_version}
  DEPENDS
    qtbase-${short_version}
    qttools-copyright-${qttools_version}
  
  SOURCE         qttools-everywhere-src-${qttools_version}
  
  USING qmake USE_SYSTEM_QT module short_version openorienteering_version qttools_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${CMAKE_COMMAND}" -E make_directory src/linguist
    COMMAND
      "${CMAKE_COMMAND}" -E chdir src/linguist "@qmake@" "${SOURCE_DIR}/src/linguist"
    BUILD_COMMAND
      "$(MAKE)" -C src/linguist
    INSTALL_COMMAND
      "$(MAKE)" -C src/linguist install INSTALL_ROOT=${DESTDIR}
  ]]
)

set(module qtattributionsscanner)  # dummy
superbuild_package(
  NAME           qttools-qtattributionsscanner
  VERSION        ${qttools_version}
  PROVIDES       qttools-qtattributionsscanner-${short_version}
  DEPENDS
    qtbase-${short_version}
    qttools-copyright-${qttools_version}
  
  SOURCE         qttools-everywhere-src-${qttools_version}
  
  USING qmake USE_SYSTEM_QT module short_version openorienteering_version qttools_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${CMAKE_COMMAND}" -E make_directory src/qtattributionsscanner
    COMMAND
      "${CMAKE_COMMAND}" -E chdir src/qtattributionsscanner "@qmake@" "${SOURCE_DIR}/src/qtattributionsscanner"
    BUILD_COMMAND
      "$(MAKE)" -C src/qtattributionsscanner
    INSTALL_COMMAND
      "$(MAKE)" -C src/qtattributionsscanner install INSTALL_ROOT=${DESTDIR}
  ]]
)



# qttranslations

set(qttranslations_version ${patch_version})
set(module Qt5Core) # Can't find qttranslations via CMake.
superbuild_package(
  NAME           qttranslations-everywhere-src
  VERSION        ${qttranslations_version}
  PROVIDES       qttranslations-${short_version}
  DEPENDS
    source:qt-${short_version}-openorienteering-${openorienteering_version}
    qtbase-${short_version}
    qttools-linguist-${short_version}
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qttranslations-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=2c8d1169f1f20ba32639181f1853b4159940cbaaac41adaa018b6f43ca31323f
  
  USING qmake USE_SYSTEM_QT module short_version openorienteering_version qttranslations_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "@qmake@" "${SOURCE_DIR}"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../qt-${short_version}-openorienteering-${openorienteering_version}/qttranslations/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qttranslations-${qttranslations_version}.txt"
  ]]
)



# Attribution maintenance, in git

find_package(Git QUIET)
find_package(PythonInterp 3 QUIET)
if(GIT_EXECUTABLE AND PYTHONINTERP_FOUND)
    superbuild_package(
      NAME           qt-${short_version}-openorienteering
      VERSION        git
      DEPENDS
        qttools-qtattributionsscanner-${patch_version}
        source:qtandroidextras-everywhere-src-${patch_version}
        source:qtbase-everywhere-src-${qtbase_patch_version}
        source:qtimageformats-everywhere-src-${patch_version}
        source:qtlocation-everywhere-src-${patch_version}
        source:qtsensors-everywhere-src-${patch_version}
        source:qtserialport-everywhere-src-${patch_version}
        source:qttools-everywhere-src-${patch_version}
        source:qttranslations-everywhere-src-${patch_version}
      
      SOURCE
        GIT_REPOSITORY https://github.com/OpenOrienteering/superbuild.git
        GIT_TAG        qt-${short_version}-openorienteering
      PATCH_COMMAND
        "${CMAKE_COMMAND}" -E make_directory "source/"
      COMMAND
        "${CMAKE_COMMAND}" -E create_symlink "<SOURCE_DIR>/../qtandroidextras-everywhere-src-${patch_version}" "source/qtandroidextras"
      COMMAND
        "${CMAKE_COMMAND}" -E create_symlink "<SOURCE_DIR>/../qtbase-everywhere-src-${qtbase_patch_version}" "source/qtbase"
      COMMAND
        "${CMAKE_COMMAND}" -E create_symlink "<SOURCE_DIR>/../qtimageformats-everywhere-src-${patch_version}" "source/qtimageformats"
      COMMAND
        "${CMAKE_COMMAND}" -E create_symlink "<SOURCE_DIR>/../qtlocation-everywhere-src-${patch_version}" "source/qtlocation"
      COMMAND
        "${CMAKE_COMMAND}" -E create_symlink "<SOURCE_DIR>/../qtsensors-everywhere-src-${patch_version}" "source/qtsensors"
      COMMAND
        "${CMAKE_COMMAND}" -E create_symlink "<SOURCE_DIR>/../qtserialport-everywhere-src-${patch_version}" "source/qtserialport"
      COMMAND
        "${CMAKE_COMMAND}" -E create_symlink "<SOURCE_DIR>/../qttools-everywhere-src-${patch_version}" "source/qttools"
      COMMAND
        "${CMAKE_COMMAND}" -E create_symlink "<SOURCE_DIR>/../qttranslations-everywhere-src-${patch_version}" "source/qttranslations"
      
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
