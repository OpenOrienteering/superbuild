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

# No Debian package yet.
set(short_version  5.12)
set(version        5.12.0)
set(patch_version  ${version}-1)

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
			find_package(${module} ${Qt5Core_VERSION_MAJOR}.${Qt5Core_VERSION_MINOR} CONFIG REQUIRED
			  NO_CMAKE_FIND_ROOT_PATH
			  NO_CMAKE_SYSTEM_PATH
			  NO_SYSTEM_ENVIRONMENT_PATH
			)
			string(FIND "${{module}_INCLUDE_DIRS}" "${CMAKE_STAGING_PREFIX}/" staging_prefix_start)
			if(${module}_VERSION AND NOT staging_prefix_start EQUAL 0)
				message(STATUS "Found ${SYSTEM_NAME} ${module}: ${${module}_VERSION}")
				set(BUILD_CONDITION 0)
			else()
				message(STATUS "Found ${SYSTEM_NAME} Qt5Core ${Qt5Core_VERSION}, but no matching ${module}")
			endif()
		endif()
	endif()
]] use_system_qt @ONLY)



# extras for superbuild support

set(default        [[$<STREQUAL:${SYSTEM_NAME},default>]])
set(crosscompiling [[$<BOOL:${CMAKE_CROSSCOMPILING}>]])
set(windows        [[$<STREQUAL:${CMAKE_SYSTEM_NAME},Windows>]])
set(macos          [[$<STREQUAL:${CMAKE_SYSTEM_NAME},Darwin>]])
set(android        [[$<BOOL:${ANDROID}>]])
set(use_sysroot    [[$<NOT:$<AND:$<BOOL:${CMAKE_CROSSCOMPILING}>,$<BOOL:${ANDROID}>>>]])
set(qmake          [[$<$<BOOL:${CMAKE_CROSSCOMPILING}>:${TOOLCHAIN_DIR}>$<$<NOT:$<BOOL:${CMAKE_CROSSCOMPILING}>>:${CMAKE_STAGING_PREFIX}>/bin/qmake]])


set(module Qt5Core)
superbuild_package(
  NAME           qt-${short_version}-openorienteering
  VERSION        ${patch_version}
  DEPENDS
    common-licenses
  
  SOURCE
    URL            https://github.com/OpenOrienteering/superbuild/archive/qt-${short_version}-openorienteering_${patch_version}.tar.gz
    URL_HASH       SHA256=8b57b96a7ca336853a46b01b2303a979255be73347e9ead355c4b215dde75d45
  
  USING version
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
      "-DVERSION=${version}"
    BUILD_COMMAND ""
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" -P cmake_install.cmake
  ]]
)



# qtbase

superbuild_package(
  NAME           qtbase
  VERSION        ${short_version}
  DEPENDS
    qtbase-everywhere-src-${version}
)

set(module Qt5Core)
superbuild_package(
  NAME         qtbase-everywhere-src
  VERSION      ${version}
  DEPENDS
    qt-${short_version}-openorienteering-${patch_version} # patches and installed copyright
    libjpeg-turbo
    libpng
    pcre2
    sqlite3
    zlib
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qtbase-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=5e03221d780e121aabd734896aab8f331e5d8c9d9b54f1eb04907d0818eaeecb
    
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
      # Fix bootstrap of cross tools after zlib removal: We have external system and host zlib.
      "${CMAKE_COMMAND}" -E copy_if_different src/3rdparty/zlib_dependency.pri src/3rdparty/zlib.pri
    COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=qt-${short_version}-openorienteering-${patch_version}/qtbase
        -P "${APPLY_PATCHES_SERIES}"
  
  USING default crosscompiling windows android macos USE_SYSTEM_QT module
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
      -prefix "${CMAKE_INSTALL_PREFIX}"
      -datadir "${CMAKE_INSTALL_PREFIX}/share"
      -extprefix "${CMAKE_STAGING_PREFIX}"
      $<@crosscompiling@:
        -no-pkg-config
        -hostprefix "${TOOLCHAIN_DIR}"
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
  ]]
)



# qtandroidextras

superbuild_package(
  NAME           qtandroidextras
  VERSION        ${short_version}
  DEPENDS        qtandroidextras-everywhere-src-${version}
)

set(module Qt5AndroidExtras)
superbuild_package(
  NAME           qtandroidextras-everywhere-src
  VERSION        ${version}
  DEPENDS        qtbase-${short_version}
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qtandroidextras-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=f5a9a13bf8b8999250b27fd68c1ed4287f333d1cebed05ae9d0b29bf9f1d0868
  
  USING qmake USE_SYSTEM_QT module
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${qmake}" "${SOURCE_DIR}"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
  ]]
)



# qtimageformats

superbuild_package(
  NAME           qtimageformats
  VERSION        ${short_version}
  DEPENDS        qtimageformats-everywhere-src-${version}
)

set(module Qt5Gui) # qtimageformats adds plugins to Qt5Gui
superbuild_package(
  NAME           qtimageformats-everywhere-src
  VERSION        ${version}
  DEPENDS        qtbase-${short_version}
                 tiff
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qtimageformats-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=5f907de96d3db6276816f321b7e11cba7beb1fcc81bcb3f1729cde3b7599732e
    
    # Don't accidently used bundled copies
    PATCH_COMMAND
      "${CMAKE_COMMAND}" -E remove_directory src/3rdparty/libtiff
  
  USING qmake USE_SYSTEM_QT module
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${qmake}" "${SOURCE_DIR}"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
  ]]
)



# qtlocation

superbuild_package(
  NAME           qtlocation
  VERSION        ${short_version}
  DEPENDS        qtlocation-everywhere-src-${version}
)

set(module Qt5Location)
superbuild_package(
  NAME           qtlocation-everywhere-src
  VERSION        ${version}
  DEPENDS        qtbase-${short_version}
                 qtserialport-${short_version}
                 source:qt-${short_version}-openorienteering-${patch_version} # patches
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qtlocation-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=b0a3134df3a00f6045405d3c12e0ea3ae7e640feaf38e238873df85424674449
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=qt-${short_version}-openorienteering-${patch_version}/qtlocation
        -P "${APPLY_PATCHES_SERIES}"
    
  USING qmake USE_SYSTEM_QT module
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${qmake}" "${SOURCE_DIR}"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
  ]]
)



# qtsensors

superbuild_package(
  NAME           qtsensors
  VERSION        ${short_version}
  DEPENDS        qtsensors-everywhere-src-${version}
)

set(module Qt5Sensors)
superbuild_package(
  NAME           qtsensors-everywhere-src
  VERSION        ${version}
  DEPENDS        qtbase-${short_version}
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qtsensors-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=c53132847a1f70d5a4c5fe689a9943d8afae3f3648bf5b0d824015093addc5a6
  
  USING qmake USE_SYSTEM_QT module
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${qmake}" "${SOURCE_DIR}"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
  ]]
)



# qtserialport

superbuild_package(
  NAME           qtserialport
  VERSION        ${short_version}
  DEPENDS        qtserialport-everywhere-src-${version}
)

set(module Qt5SerialPort)
superbuild_package(
  NAME           qtserialport-everywhere-src
  VERSION        ${version}
  DEPENDS        qtbase-${short_version}
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qtserialport-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=59d4005695089c6b50fc5123094125d9224c1715655128640158a2404075a9bb
  
  USING qmake USE_SYSTEM_QT module
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${qmake}" "${SOURCE_DIR}"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
  ]]
)



# qttools

superbuild_package(
  NAME           qttools
  VERSION        ${short_version}
  DEPENDS        qttools-everywhere-src-${version}
)

set(module Qt5LinguistTools)
superbuild_package(
  NAME           qttools-everywhere-src
  VERSION        ${version}
  DEPENDS        qtbase-${short_version}
                 source:qt-${short_version}-openorienteering-${patch_version} # patches
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qttools-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=574ce34b6e5bcd5dce4020a3947730f3c2223eee65d0396a311099223364dac3
    PATCH_COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=qt-${short_version}-openorienteering-${patch_version}/qttools
        -P "${APPLY_PATCHES_SERIES}"
  
  USING qmake qttools_install_android USE_SYSTEM_QT module
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${qmake}" "${SOURCE_DIR}"
    BUILD_COMMAND
      "$(MAKE)"
    $<$<NOT:$<BOOL:@ANDROID@>>:
    COMMAND
      "$(MAKE)" -C src/assistant sub-assistant
    COMMAND
      "$(MAKE)" -C src/assistant sub-qhelpgenerator
    COMMAND
      "$(MAKE)" -C src/linguist sub-linguist
    >
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
    $<$<NOT:$<BOOL:@ANDROID@>>:
    COMMAND
      "$(MAKE)" -C src/assistant/assistant install INSTALL_ROOT=${DESTDIR}
    COMMAND
      "$(MAKE)" -C src/assistant/qhelpgenerator install INSTALL_ROOT=${DESTDIR}
    COMMAND
      "$(MAKE)" -C src/linguist/linguist install INSTALL_ROOT=${DESTDIR}
    >
  ]]
)



# qttranslations

superbuild_package(
  NAME           qttranslations
  VERSION        ${short_version}
  DEPENDS        qttranslations-everywhere-src-${version}
)

set(module Qt5Core) # Can't find qttranslations via CMake.
superbuild_package(
  NAME           qttranslations-everywhere-src
  VERSION        ${version}
  DEPENDS        qtbase-${short_version}
                 qttools-${short_version}
  
  SOURCE
    URL             https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qttranslations-everywhere-src-${version}.tar.xz
    URL_HASH        SHA256=5b4f186e0b96703041319b5b131393b6aa829ea74e067697ede548d936327508
  
  USING qmake USE_SYSTEM_QT module
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${qmake}" "${SOURCE_DIR}"
    INSTALL_COMMAND
      "$(MAKE)" install INSTALL_ROOT=${DESTDIR}
  ]]
)



# Attribution maintenance, in git

find_package(PythonInterp 3)
if(PYTHONINTERP_FOUND)
    superbuild_package(
      NAME           qt-${short_version}-openorienteering
      VERSION        git
      DEPENDS
        qttools-everywhere-src-${version}  # for qtattributionsscanner
        source:qtandroidextras-everywhere-src-${version}
        source:qtbase-everywhere-src-${version}
        source:qtimageformats-everywhere-src-${version}
        source:qtlocation-everywhere-src-${version}
        source:qtsensors-everywhere-src-${version}
        source:qtserialport-everywhere-src-${version}
        source:qttools-everywhere-src-${version}
        source:qttranslations-everywhere-src-${version}
      
      SOURCE
        GIT_REPOSITORY https://github.com/OpenOrienteering/Superbuild.git
        GIT_TAG        qt-${short_version}-openorienteering
      
      USING version PYTHON_EXECUTABLE
      BUILD [[
        CMAKE_ARGS
          "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
          "-DVERSION=${version}"
          "-DPYTHON_EXECUTABLE=${PYTHON_EXECUTABLE}"
        BUILD_COMMAND
          "${CMAKE_COMMAND}" --build . --target update-copyright
        BUILD_ALWAYS 1
        INSTALL_COMMAND ""
      ]]
    )
endif()
