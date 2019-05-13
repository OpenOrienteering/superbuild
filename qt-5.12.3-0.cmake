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
set(version        5.12.3)

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
    URL_HASH       SHA256=b1e1dfe9337f0eaca710f774f1f811e81bb532c69e216aaae5887147864a51e1
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
    URL_HASH        SHA256=fddfd8852ef7503febeed67b876d1425160869ae2b1ae8e10b3fb0fedc5fe701
    
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
    URL_HASH        SHA256=866b3fbcfc2cbebdb83b5adec4e5d0bd29b0e0b0762d66fb3fef0b400e37254f
  
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
    URL_HASH        SHA256=db5a9e784f9c327c1e6830b1550311024cc91202d3b8dde82cd0944164298be2
    
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
    URL_HASH        SHA256=52d589be2852ada0c000b06cc411b61e521cd0797470be567fd1625bcc9d75c6
    
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
    URL_HASH        SHA256=7f63fedf60fdf110a3fc529568c7226d7acd59cc5eaee908f4d5a969e34005fc
  
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
    URL_HASH        SHA256=1faf7df4a1f9028bef1ce79330badb4e5cbbba9f717c53cafc5aea41eed1de51
  
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
    URL_HASH        SHA256=c9e92d2f0d369e44bb1a60e9fa6d970f8d9893d653212305e04be5e6daec2cd8
  
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
    URL_HASH        SHA256=eefcec0a91c302548f9d948a138b8ec77d78570ce818931bd8475b1bff1205ca
  
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
        GIT_REPOSITORY https://github.com/OpenOrienteering/Superbuild.git
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
