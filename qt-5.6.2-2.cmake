# This file is part of OpenOrienteering.

# Copyright 2016, 2017 Kai Pastor
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

set(version        5.6.2)
set(patch_version  ${version}-2)
set(base_url       https://download.qt.io/archive/qt/5.6/${version}/submodules/)

option(USE_SYSTEM_QT "Use the system Qt if possible" ON)

string(CONFIGURE [[
	if("${module}" MATCHES "Android" AND NOT ANDROID)
		set(BUILD_CONDITION 0)
	elseif(USE_SYSTEM_QT)
		find_package(Qt5Core @version@ CONFIG QUIET)
		if(Qt5Core_VERSION)
			find_package(${module} ${Qt5Core_VERSION} CONFIG EXACT REQUIRED)
			string(FIND "${{module}_INCLUDE_DIRS}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
			if(${module}_VERSION AND NOT staging_prefix_start EQUAL 0)
				message(STATUS "Found ${SYSTEM_NAME} ${module}: ${${module}_VERSION}")
				set(BUILD_CONDITION 0)
			else()
				message(STATUS "Found ${SYSTEM_NAME} Qt5Core ${Qt5Core_VERSION}, but no matching ${module}")
			endif()
		endif()
	endif()

	if(BUILD_CONDITION AND "${PROJECT_NAME}" MATCHES "qtbase")
		# Preparation for cross compiling
		# Cf. qtbase configure "SYSTEM_VARIABLES"
		set(pattern "^load(qt_config)")
		set(qmake "QMAKE")
		if(ANDROID)
			set(pattern "^include(.*\\/android-base-tail.conf)")
			set(qmake "QMAKE_ANDROID_PLATFORM")
		endif()
		set(qmake_conf_changes )
		if(DEFINED ENV_CFLAGS)
			list(APPEND qmake_conf_changes "/${pattern}/ i QMAKE_CFLAGS   *= ${ENV_CFLAGS}\n")
		endif()
		if(DEFINED ENV_CXXFLAGS)
			list(APPEND qmake_conf_changes "/${pattern}/ i QMAKE_CXXFLAGS *= ${ENV_CXXFLAGS}\n")
		endif()
		if(DEFINED ENV_LDFLAGS)
			list(APPEND qmake_conf_changes "/${pattern}/ i QMAKE_LFLAGS   *= ${ENV_LDFLAGS}\n")
		endif()
		string(REGEX REPLACE "-f[^ ]*exceptions|-O[^ ]*|-g|-W[a-z][a-z][^ ]*|[^ ]*_FORTIFY_SOURCE[^ ]*" "" qmake_conf_changes "${qmake_conf_changes}")
		file(WRITE "${BINARY_DIR}/qmake_conf_changes.sed"
		  "/${pattern}/ i\n"
		  "/${pattern}/ i # Begin of changes from superbuild\n"
		  ${qmake_conf_changes}
		  "/${pattern}/ i ${qmake}_INCDIR *= \"${CMAKE_STAGING_PREFIX}/include\"\n"
		  "/${pattern}/ i ${qmake}_LIBDIR *= \"${CMAKE_STAGING_PREFIX}/lib\"\n"
		  "/${pattern}/ i # End of changes from superbuild\n"
		  "/${pattern}/ i\n"
		)
	endif()
]] use_system_qt @ONLY)

# qtbase

set(default        [[$<STREQUAL:${SYSTEM_NAME},default>]])
set(crosscompiling [[$<BOOL:${CMAKE_CROSSCOMPILING}>]])
set(windows        [[$<STREQUAL:${CMAKE_SYSTEM_NAME},Windows>]])
set(macos          [[$<STREQUAL:${CMAKE_SYSTEM_NAME},Darwin>]])
set(android        [[$<BOOL:${ANDROID}>]])
set(use_sysroot    [[$<NOT:$<AND:$<BOOL:${CMAKE_CROSSCOMPILING}>,$<BOOL:${ANDROID}>>>]])
set(qmake          [[$<$<BOOL:${CMAKE_CROSSCOMPILING}>:${TOOLCHAIN_DIR}>$<$<NOT:$<BOOL:${CMAKE_CROSSCOMPILING}>>:${CMAKE_STAGING_PREFIX}>/bin/qmake]])


set(module Qt5Core)
superbuild_package(
  NAME           qt-copyright
  VERSION        ${version}
  DEPENDS
    common-licenses
  
  SOURCE
    URL            ${SUPERBUILD_RELEASE_BASE_URL_2017_06}/qt-copyright_${version}.tar.gz
    URL_HASH       SHA256=9d0ef95724c0f3f9c84441f7f25481299fe982926fc1b585b57884d8d60001ca
  
  USING            USE_SYSTEM_QT module
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND ""
    BUILD_COMMAND     ""
    INSTALL_COMMAND
      "${CMAKE_COMMAND}"
        "-DINSTALL_DIR=${CMAKE_STAGING_PREFIX}/share/doc/copyright"
        -P "<SOURCE_DIR>/cmake_install.cmake"
  ]]
)
  

superbuild_package(
  NAME           qtbase-patches
  VERSION        ${version}-2
  SOURCE
    URL            ${SUPERBUILD_RELEASE_BASE_URL_2017_06}/qtbase_${patch_version}.openorienteering.tar.gz
    URL_HASH       SHA256=80e6821ed4f1a7da3cb15064f366ce08ccede149be9aec9550b1972d4115cefa
)
  
set(module Qt5Core)
superbuild_package(
  NAME         qtbase
  VERSION      ${version}
  DEPENDS
    source:qtbase-patches-${patch_version}
    qt-copyright-${version}
    libjpeg-turbo
    libpng
    pcre3
    sqlite3
    zlib
  
  SOURCE
    DOWNLOAD_NAME  qtbase-opensource-src_${version}+dfsg.orig.tar.gz
    # Cannot use "+" in Github releases downloads
    URL            ${SUPERBUILD_RELEASE_BASE_URL_2017_06}/qtbase-opensource-src_${version}-dfsg.orig.tar.gz
    URL_HASH       SHA256=146cc26240358c1c93fb833cd6a688a8d062dc29417f2199d7af00dd907e0ceb
    PATCH_COMMAND
      "${CMAKE_COMMAND}" -E touch <SOURCE_DIR>/.git
    COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=qtbase-patches-${patch_version}
        -P "${APPLY_PATCHES_SERIES}"
    # Don't accidently used bundled copies
    COMMAND
      "${CMAKE_COMMAND}" -E copy_directory src/3rdparty/libjpeg src/3rdparty/libjpeg.unused
    COMMAND
      "${CMAKE_COMMAND}" -E remove_directory src/3rdparty/libjpeg
    COMMAND
      "${CMAKE_COMMAND}" -E copy_directory src/3rdparty/libpng src/3rdparty/libpng.unused
    COMMAND
      "${CMAKE_COMMAND}" -E remove_directory src/3rdparty/libpng
    COMMAND
      "${CMAKE_COMMAND}" -E copy_directory src/3rdparty/pcre src/3rdparty/pcre.unused
    COMMAND
      "${CMAKE_COMMAND}" -E remove_directory src/3rdparty/pcre
    COMMAND
      "${CMAKE_COMMAND}" -E copy_directory src/3rdparty/sqlite src/3rdparty/sqlite.unused
    COMMAND
      "${CMAKE_COMMAND}" -E remove_directory src/3rdparty/sqlite
    COMMAND
      "${CMAKE_COMMAND}" -E copy_directory src/3rdparty/zlib src/3rdparty/zlib.unused
    COMMAND
      "${CMAKE_COMMAND}" -E remove -f src/3rdparty/zlib/*.c
  
  USING default crosscompiling windows android macos USE_SYSTEM_QT module
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND 
    $<${crosscompiling}:
      $<${windows}:
        mkdir -p "${SOURCE_DIR}/mkspecs/win32-g++-${SYSTEM_NAME}"
        COMMAND cp "${SOURCE_DIR}/mkspecs/win32-g++/qmake.conf" "${SOURCE_DIR}/mkspecs/win32-g++-${SYSTEM_NAME}/"
        COMMAND cp "${SOURCE_DIR}/mkspecs/win32-g++/qplatformdefs.h" "${SOURCE_DIR}/mkspecs/win32-g++-${SYSTEM_NAME}/"
        COMMAND sed -i -f "qmake_conf_changes.sed" "${SOURCE_DIR}/mkspecs/win32-g++-${SYSTEM_NAME}/qmake.conf"
      >
      $<${android}:
        mkdir -p "${SOURCE_DIR}/mkspecs/android-g++-${SYSTEM_NAME}"
        COMMAND cp "${SOURCE_DIR}/mkspecs/android-g++/qmake.conf" "${SOURCE_DIR}/mkspecs/android-g++-${SYSTEM_NAME}/"
        COMMAND cp "${SOURCE_DIR}/mkspecs/android-g++/qplatformdefs.h" "${SOURCE_DIR}/mkspecs/android-g++-${SYSTEM_NAME}/"
        COMMAND sed -i -f "qmake_conf_changes.sed" "${SOURCE_DIR}/mkspecs/android-g++-${SYSTEM_NAME}/qmake.conf"
      >
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
      $<$<CONFIG:Debug>:-debug>$<$<NOT:$<CONFIG:Debug>>:-release -no-qml-debug $<$<CONFIG:RelWithDebInfo>:-force-debug-info>>
      -shared
      -no-pch
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
      -no-sql-sqlite2
      -no-sql-tds
      -no-openssl
      -no-directfb
      -no-linuxfb
      $<$<OR:${android},${macos},${windows}>:
        -no-dbus
      >
      -make tools
      -nomake examples
      -nomake tests
      -system-proxies
      -no-glib
      -no-audio-backend
      -prefix "${CMAKE_INSTALL_PREFIX}"
      -datadir "${CMAKE_INSTALL_PREFIX}/share"
      -extprefix "${CMAKE_STAGING_PREFIX}"
      $<${crosscompiling}:
        -no-pkg-config
        -hostprefix "${TOOLCHAIN_DIR}"
        -device-option CROSS_COMPILE=${SUPERBUILD_TOOLCHAIN_TRIPLET}-
        $<${windows}:
          -xplatform     win32-g++-${SYSTEM_NAME}
        >
        $<${android}:
          -xplatform     android-g++-${SYSTEM_NAME}
          -android-arch  "${CMAKE_ANDROID_ARCH_ABI}"
          -android-ndk   "${ANDROID_NDK_ROOT}"
          -android-sdk   "${ANDROID_SDK_ROOT}"
        >
      >$<$<NOT:${crosscompiling}>:
        -I "${CMAKE_STAGING_PREFIX}/include"
        -L "${CMAKE_STAGING_PREFIX}/lib"
      >
  ]]
)

# qtandroidextras

set(module Qt5AndroidExtras)
superbuild_package(
  NAME           qtandroidextras
  VERSION        ${version}
  DEPENDS        qtbase-${version}
  
  SOURCE
    DOWNLOAD_NAME  qtandroidextras_${version}.orig.tar.gz
    URL            ${base_url}/qtandroidextras-opensource-src-${version}.tar.gz
    URL_HASH       SHA256=44d6b30dde1d1e99ccd735d9a28cf8eba5ca61923cb54712e0c0ef6422cfdccd
    PATCH_COMMAND  "${CMAKE_COMMAND}" -E touch "<SOURCE_DIR>/.git"
  
  USING qmake USE_SYSTEM_QT module
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${qmake}" "${SOURCE_DIR}"
  ]]
)

# qtimageformats

set(module Qt5Gui) # qtimageformats adds plugins to Qt5Gui
superbuild_package(
  NAME           qtimageformats
  VERSION        ${version}
  DEPENDS        qtbase-${version}
                 tiff
  
  SOURCE
    DOWNLOAD_NAME  qtimageformats_${version}.orig.tar.gz
    URL            ${base_url}/qtimageformats-opensource-src-${version}.tar.gz
    URL_HASH       SHA256=ff708dc1ba89df6be134c15289379ae462fc20f61662f87e32b3b23bae478da4
    PATCH_COMMAND
      "${CMAKE_COMMAND}" -E touch "<SOURCE_DIR>/.git"
    # Don't accidently used bundled copies
    COMMAND
      "${CMAKE_COMMAND}" -E copy_directory src/3rdparty/jasper src/3rdparty/jasper.unused
    COMMAND
      "${CMAKE_COMMAND}" -E remove_directory src/3rdparty/jasper
    COMMAND
      "${CMAKE_COMMAND}" -E copy_directory src/3rdparty/libtiff src/3rdparty/libtiff.unused
    COMMAND
      "${CMAKE_COMMAND}" -E remove_directory src/3rdparty/libtiff
  
  USING qmake USE_SYSTEM_QT module
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${qmake}" "${SOURCE_DIR}"
  ]]
)

# qtlocation

set(module Qt5Location)
superbuild_package(
  NAME           qtlocation
  VERSION        ${version}
  DEPENDS        qtbase-${version}
                 qtserialport-${version}
  
  SOURCE
    DOWNLOAD_NAME  qtlocation_${version}.orig.tar.gz
    URL            ${base_url}/qtlocation-opensource-src-${version}.tar.gz
    URL_HASH       SHA256=b153a4ab39f85d801699fe8adfa9e36496ecb392d2ded3c28e68a74b1c50e8d8
    PATCH_COMMAND  "${CMAKE_COMMAND}" -E touch "<SOURCE_DIR>/.git"
  
  USING qmake USE_SYSTEM_QT module
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${qmake}" "${SOURCE_DIR}"
  ]]
)

# qtsensors

set(module Qt5Sensors)
superbuild_package(
  NAME           qtsensors
  VERSION        ${version}
  DEPENDS        qtbase-${version}
  
  SOURCE
    DOWNLOAD_NAME  qtsensors_${version}.orig.tar.gz
    URL            ${base_url}/qtsensors-opensource-src-${version}.tar.gz
    URL_HASH       SHA256=463e2b3545cb7502bc02401b325557eae6cbf5556a31aba378dfdabd41695917
    PATCH_COMMAND  "${CMAKE_COMMAND}" -E touch "<SOURCE_DIR>/.git"
  
  USING qmake USE_SYSTEM_QT module
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${qmake}" "${SOURCE_DIR}"
  ]]
)

# qtserialport

set(module Qt5SerialPort)
superbuild_package(
  NAME           qtserialport
  VERSION        ${version}
  DEPENDS        qtbase-${version}
  
  SOURCE
    DOWNLOAD_NAME  qtserialport_${version}.orig.tar.gz
    URL            ${base_url}/qtserialport-opensource-src-${version}.tar.gz
    URL_HASH       SHA256=dfd98aad2e87939394e624c797ec162012f5b0dcd30323fa4d5e28841a90d17b
    PATCH_COMMAND  "${CMAKE_COMMAND}" -E touch "<SOURCE_DIR>/.git"
  
  USING qmake USE_SYSTEM_QT module
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${qmake}" "${SOURCE_DIR}"
  ]]
)

# qttools

set(qttools_install_android
  INSTALL_COMMAND
	"$(MAKE)" -C src/androiddeployqt install
  COMMAND
    "$(MAKE)" -C src/linguist/lconvert install
  COMMAND
    "$(MAKE)" -C src/linguist/lrelease install
  COMMAND
    "$(MAKE)" -C src/linguist/lupdate install
  COMMAND
    "$(MAKE)" -C src/linguist install_cmake_linguist_tools_files
  COMMAND
    "$(MAKE)" -C src/qdoc install
)

set(module Qt5LinguistTools)
superbuild_package(
  NAME           qttools
  VERSION        ${version}
  DEPENDS        qtbase-${version}
  
  SOURCE
    DOWNLOAD_NAME  qttools_${version}.orig.tar.gz
	URL            ${base_url}/qttools-opensource-src-${version}.tar.gz
	URL_HASH       SHA256=5f57ce5e612b2f7e1c3064ff0f8b12f1cfa4b615220d63c08c8e45234e8685b0
    PATCH_COMMAND  "${CMAKE_COMMAND}" -E touch "<SOURCE_DIR>/.git"
  
  USING qmake qttools_install_android USE_SYSTEM_QT module
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${qmake}" "${SOURCE_DIR}"
    $<$<AND:$<BOOL:${CMAKE_CROSSCOMPILING}>,$<BOOL:${ANDROID}>>:${qttools_install_android}>
  ]]
)

# qttranslations

set(module Qt5Core) # Can't find qttranslations via CMake.
superbuild_package(
  NAME           qttranslations
  VERSION        ${version}
  DEPENDS        qtbase-${version} qttools-${version}
  
  SOURCE
    DOWNLOAD_NAME  qttranslations_${version}.orig.tar.gz
    URL            ${base_url}/qttranslations-opensource-src-${version}.tar.gz
    URL_HASH       SHA256=0394ecf6e9ad97860d049cb475d948459fea0c7dd6bf001ddd67f4a7e0857db0
    PATCH_COMMAND  "${CMAKE_COMMAND}" -E touch "<SOURCE_DIR>/.git"
  
  USING qmake USE_SYSTEM_QT module
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${qmake}" "${SOURCE_DIR}"
  ]]
)
