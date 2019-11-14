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

set(short_version  5.12)
set(version        5.12.6)

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
  VERSION        ${version}-0
  
  SOURCE
    URL            https://github.com/OpenOrienteering/superbuild/archive/qt-${short_version}-openorienteering_${version}-0.tar.gz
    URL_HASH       SHA256=29786360f29489e6459c144a12d0828dca2f754833f841c09e45632abb45d8b9
)



# qtbase

set(qtbase_version ${version}-0)
superbuild_package(
  NAME           qtbase
  VERSION        ${short_version}
  DEPENDS
    qtbase-everywhere-src-${qtbase_version}
)

set(module Qt5Core)
superbuild_package(
  NAME         qtbase-everywhere-src
  VERSION      ${qtbase_version}
  DEPENDS
    source:qt-${short_version}-openorienteering-${qtbase_version}
    libjpeg-turbo
    libpng
    pcre2
    sqlite3
    zlib
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qtbase-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=6ab52649d74d7c1728cf4a6cf335d1142b3bf617d476e2857eb7961ef43f9f27
    
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
        -Dpackage=qt-${short_version}-openorienteering-${qtbase_version}/qtbase
        -P "${APPLY_PATCHES_SERIES}"
    COMMAND
      # Enforce make for MSYS. Needed for config.tests outside qtbase, e.g. libtiff in qtimageformats
      # Cf. https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-qt5/0025-qt-5.8.0-force-using-make-on-msys.patch
      sed -i -e "/MAKEFILE_GENERATOR, MINGW/,/mingw32-make/ s/.equals.QMAKE_HOST.os, Windows./\\!isEmpty(QMAKE_SH)|\\!equals(QMAKE_HOST.os, Windows)/"
        mkspecs/features/configure_base.prf
  
  USING default crosscompiling windows android macos USE_SYSTEM_QT module short_version qtbase_version
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
        "<SOURCE_DIR>/../qt-${short_version}-openorienteering-${qtbase_version}/qtbase/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qtbase-${qtbase_version}.txt"
  ]]
)



# qtandroidextras

set(qtandroidextras_version ${version}-0)
superbuild_package(
  NAME           qtandroidextras
  VERSION        ${short_version}
  DEPENDS        qtandroidextras-everywhere-src-${qtandroidextras_version}
)

set(module Qt5AndroidExtras)
superbuild_package(
  NAME           qtandroidextras-everywhere-src
  VERSION        ${qtandroidextras_version}
  DEPENDS
    source:qt-${short_version}-openorienteering-${qtandroidextras_version}
    qtbase-${short_version}
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qtandroidextras-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=a0f15a4ba29abe90de2b2c221efd22ecfb6793590ff9610f85e6e6b6562784fe
  
  USING qmake USE_SYSTEM_QT module short_version qtandroidextras_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "@qmake@" "${SOURCE_DIR}"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../qt-${short_version}-openorienteering-${qtandroidextras_version}/qtandroidextras/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qtandroidextras-${qtandroidextras_version}.txt"
  ]]
)



# qtimageformats

set(qtimageformats_version ${version}-0)
superbuild_package(
  NAME           qtimageformats
  VERSION        ${short_version}
  DEPENDS        qtimageformats-everywhere-src-${qtimageformats_version}
)

set(module Qt5Gui) # qtimageformats adds plugins to Qt5Gui
superbuild_package(
  NAME           qtimageformats-everywhere-src
  VERSION        ${qtimageformats_version}
  DEPENDS        
    source:qt-${short_version}-openorienteering-${qtimageformats_version}
    qtbase-${short_version}
    tiff
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qtimageformats-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=330d1c29a135c44bb36b5ffc2ba4f8915dbc446d5d75563523ebcfd373617858
    
    # Don't accidently used bundled copies
    PATCH_COMMAND
      "${CMAKE_COMMAND}" -E remove_directory src/3rdparty/libtiff
  
  USING qmake USE_SYSTEM_QT module short_version qtimageformats_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "@qmake@" "${SOURCE_DIR}"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../qt-${short_version}-openorienteering-${qtimageformats_version}/qtimageformats/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qtimageformats-${qtimageformats_version}.txt"
  ]]
)



# qtlocation

set(qtlocation_version ${version}-0)
superbuild_package(
  NAME           qtlocation
  VERSION        ${short_version}
  DEPENDS        qtlocation-everywhere-src-${qtlocation_version}
)

set(module Qt5Location)
superbuild_package(
  NAME           qtlocation-everywhere-src
  VERSION        ${qtlocation_version}
  DEPENDS
    source:qt-${short_version}-openorienteering-${qtlocation_version}
    qtbase-${short_version}
    qtserialport-${short_version}
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qtlocation-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=7ae231ca4de3c0915e92bb95440b0ddc7113790b1acb536c9394472e8dde2278
    
  USING qmake USE_SYSTEM_QT module short_version qtlocation_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "@qmake@" "${SOURCE_DIR}"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../qt-${short_version}-openorienteering-${qtlocation_version}/qtlocation/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qtlocation-${qtlocation_version}.txt"
  ]]
)



# qtsensors

set(qtsensors_version ${version}-0)
superbuild_package(
  NAME           qtsensors
  VERSION        ${short_version}
  DEPENDS
    qtsensors-everywhere-src-${qtsensors_version}
)

set(module Qt5Sensors)
superbuild_package(
  NAME           qtsensors-everywhere-src
  VERSION        ${qtsensors_version}
  DEPENDS
    source:qt-${short_version}-openorienteering-${qtsensors_version}
    qtbase-${short_version}
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qtsensors-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=59dba4c0bc72846d938e0862f14d8064fb664d893f270a41d3abf4e871290ef5
  
  USING qmake USE_SYSTEM_QT module short_version qtsensors_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "@qmake@" "${SOURCE_DIR}"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../qt-${short_version}-openorienteering-${qtsensors_version}/qtsensors/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qtsensors-${qtsensors_version}.txt"
  ]]
)



# qtserialport

set(qtserialport_version ${version}-0)
superbuild_package(
  NAME           qtserialport
  VERSION        ${short_version}
  DEPENDS        qtserialport-everywhere-src-${qtserialport_version}
)

set(module Qt5SerialPort)
superbuild_package(
  NAME           qtserialport-everywhere-src
  VERSION        ${qtserialport_version}
  DEPENDS
    source:qt-${short_version}-openorienteering-${qtserialport_version}
    qtbase-${short_version}
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qtserialport-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=77d0def93078fb5d9de6faa9ccff05cce5b934899e856b04bcf7f721a4e190be
  
  USING qmake USE_SYSTEM_QT module short_version qtserialport_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "@qmake@" "${SOURCE_DIR}"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../qt-${short_version}-openorienteering-${qtserialport_version}/qtserialport/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qtserialport-${qtserialport_version}.txt"
  ]]
)



# qttools

set(qttools_version ${version}-0)
superbuild_package(
  NAME           qttools
  VERSION        ${short_version}
  DEPENDS        qttools-everywhere-src-${qttools_version}
)

set(module Qt5LinguistTools)
superbuild_package(
  NAME           qttools-everywhere-src
  VERSION        ${qttools_version}
  DEPENDS
    source:qt-${short_version}-openorienteering-${qttools_version}
    qtbase-${short_version}
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qttools-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=e94991c7885c2650cefd71189873e45b1d64d6042e439a0a0d9652c191d3c777
  
  USING qmake USE_SYSTEM_QT module short_version qttools_version
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
        "<SOURCE_DIR>/../qt-${short_version}-openorienteering-${qttools_version}/qttools/copyright"
        "${DESTDIR}${CMAKE_STAGING_PREFIX}/share/doc/copyright/qttools-${qttools_version}.txt"
  ]]
)



# qttranslations

set(qttranslations_version ${version}-0)
superbuild_package(
  NAME           qttranslations
  VERSION        ${short_version}
  DEPENDS        qttranslations-everywhere-src-${qttranslations_version}
)

set(module Qt5Core) # Can't find qttranslations via CMake.
superbuild_package(
  NAME           qttranslations-everywhere-src
  VERSION        ${qttranslations_version}
  DEPENDS
    source:qt-${short_version}-openorienteering-${qttranslations_version}
    qtbase-${short_version}
    qttools-${short_version}
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qttranslations-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=798ac44414206898d0192653118de3f115c59016e2bf82ad0c659f9f8c864768
  
  USING qmake USE_SYSTEM_QT module short_version qttranslations_version
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "@qmake@" "${SOURCE_DIR}"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
    COMMAND
      "${CMAKE_COMMAND}" -E copy
        "<SOURCE_DIR>/../qt-${short_version}-openorienteering-${qttranslations_version}/qttranslations/copyright"
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
        qttools-everywhere-src-${version}-0  # for qtattributionsscanner
        source:qtandroidextras-everywhere-src-${version}-0
        source:qtbase-everywhere-src-${version}-0
        source:qtimageformats-everywhere-src-${version}-0
        source:qtlocation-everywhere-src-${version}-0
        source:qtsensors-everywhere-src-${version}-0
        source:qtserialport-everywhere-src-${version}-0
        source:qttools-everywhere-src-${version}-0
        source:qttranslations-everywhere-src-${version}-0
      
      SOURCE
        GIT_REPOSITORY https://github.com/OpenOrienteering/superbuild.git
        GIT_TAG        qt-${short_version}-openorienteering
      
      USING version PYTHON_EXECUTABLE
      BUILD [[
        CMAKE_ARGS
          "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
          "-DVERSION=${version}-0"
          "-DPYTHON_EXECUTABLE=${PYTHON_EXECUTABLE}"
        BUILD_COMMAND
          "${CMAKE_COMMAND}" --build . --target update-copyright
        BUILD_ALWAYS 1
        INSTALL_COMMAND ""
      ]]
    )
endif()
