# This file is part of OpenOrienteering.

# Copyright 2016-2018 Kai Pastor
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

# We use qtbase 5.9.5, but version 5.9.2 of most other modules because of the
# Debian copyright files existing for this version of Qt. Selected post-5.9.2
# changes are added to these sources via patches.
set(short_version  5.9)
set(version        5.9.5)
set(patch_version  ${version}-1)
set(debian_version 5.9.2)
set(debian_patch_version ${debian_version}-0)

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
  NAME           qt-superbuild
  VERSION        ${patch_version}
  DEPENDS
    common-licenses
  
  SOURCE
    URL            https://github.com/OpenOrienteering/superbuild/archive/qt-superbuild_${patch_version}.tar.gz
    URL_HASH       SHA256=cc9f62b010ed3a96c432e0c248c1e0495c53c4027b93763109cdf7752cd9e614
  
  BUILD [[
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
    BUILD_COMMAND ""
    INSTALL_COMMAND
      "${CMAKE_COMMAND}" -E env "DESTDIR=${INSTALL_DIR}"
      "${CMAKE_COMMAND}" -P cmake_install.cmake
  ]]
)



# qtbase

superbuild_package(
  NAME           qtbase
  VERSION        ${short_version}
  DEPENDS
    qtbase-opensource-src-${version}
)

set(module Qt5Core)
superbuild_package(
  NAME         qtbase-opensource-src
  VERSION      ${version}
  DEPENDS
    source:qt-superbuild-${patch_version} # patches, early
    qt-superbuild-${patch_version}        # installed copyright
    libjpeg-turbo
    libpng
    pcre2
    sqlite3
    zlib
  
  SOURCE
    #URL            https://download.opensuse.org/repositories/home:/dg0yt/Windows/qtbase-opensource-src_${version}+dfsg.orig.tar.xz
    #URL_HASH       SHA256=911467c13c7d69ecff00a46b02ca92992e6fb9938c9e2f2f258a2ca451d76670
    URL            https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qtbase-opensource-src-${version}.tar.xz
    URL_HASH       MD5=4679267d10a5489545e165e641ea4da5
    PATCH_COMMAND
      "${CMAKE_COMMAND}" -E touch <SOURCE_DIR>/.git
    COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=qt-superbuild-${patch_version}/qtbase
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
      $<${macos}:-no-framework>
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
      -prefix "${CMAKE_INSTALL_PREFIX}"
      -datadir "${CMAKE_INSTALL_PREFIX}/share"
      -extprefix "${CMAKE_STAGING_PREFIX}"
      $<${crosscompiling}:
        -no-pkg-config
        -hostprefix "${TOOLCHAIN_DIR}"
        $<${windows}:
          -device-option CROSS_COMPILE=${SUPERBUILD_TOOLCHAIN_TRIPLET}-
          -xplatform     win32-g++
          -opengl desktop
        >
        $<${android}:
          $<$<STREQUAL:${CMAKE_CXX_COMPILER_ID},GNU>:
            -xplatform     android-g++
          >$<$<STREQUAL:${CMAKE_CXX_COMPILER_ID},Clang>:
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
  ]]
)



# qtandroidextras

superbuild_package(
  NAME           qtandroidextras
  VERSION        ${short_version}
  DEPENDS        qtandroidextras-opensource-src-${version}
)

set(module Qt5AndroidExtras)
superbuild_package(
  NAME           qtandroidextras-opensource-src
  VERSION        ${version}
  DEPENDS        qtbase-${short_version}
  
  SOURCE
    URL            https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qtandroidextras-opensource-src-${version}.tar.xz
    URL_HASH       MD5=9b0bc75a639d0edb738d3532763aecd1
    PATCH_COMMAND  "${CMAKE_COMMAND}" -E touch "<SOURCE_DIR>/.git"
  
  USING qmake USE_SYSTEM_QT module
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${qmake}" "${SOURCE_DIR}"
  ]]
)



# qtimageformats

superbuild_package(
  NAME           qtimageformats
  VERSION        ${short_version}
  DEPENDS        qtimageformats-opensource-src-${debian_patch_version}
)

set(module Qt5Gui) # qtimageformats adds plugins to Qt5Gui
superbuild_package(
  NAME           qtimageformats-opensource-src
  VERSION        ${debian_patch_version}
  DEPENDS        qtbase-${short_version}
                 tiff
  
  SOURCE
    URL            ${SUPERBUILD_DEBIAN_BASE_URL_2018_02}/pool/main/q/qtimageformats-opensource-src/qtimageformats-opensource-src_${debian_version}.orig.tar.xz
    URL_HASH       SHA256=3a626ca0ac7ffc56b59c4b3f66aac6bc76954054cedb6938b961562228eb9df3
    PATCH_COMMAND
      "${CMAKE_COMMAND}" -E touch "<SOURCE_DIR>/.git"
    # Don't accidently used bundled copies
    COMMAND
      "${CMAKE_COMMAND}" -E copy_directory src/3rdparty/jasper src/3rdparty/jasper.unused
    COMMAND
      "${CMAKE_COMMAND}" -E remove_directory src/3rdparty/jasper
    COMMAND
      "${CMAKE_COMMAND}" -E copy_directory src/3rdparty/libtiff src/3rdparty/libtiff.unused
    COMMANDqt-superbuild-5.9.5-0/qtserialport
      "${CMAKE_COMMAND}" -E remove_directory src/3rdparty/libtiff
  
  USING qmake USE_SYSTEM_QT module
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${qmake}" "${SOURCE_DIR}"
  ]]
)



# qtlocation

superbuild_package(
  NAME           qtlocation
  VERSION        ${short_version}
  DEPENDS        qtlocation-opensource-src-${debian_patch_version}
)

set(module Qt5Location)
superbuild_package(
  NAME           qtlocation-opensource-src
  VERSION        ${debian_patch_version}
  DEPENDS        qtbase-${short_version}
                 qtserialport-${short_version}
                 source:qt-superbuild-${patch_version}
  
  SOURCE
    URL            ${SUPERBUILD_DEBIAN_BASE_URL_2018_02}/pool/main/q/qtlocation-opensource-src/qtlocation-opensource-src_${debian_version}+dfsg.orig.tar.xz
    URL_HASH       SHA256=a2abd4193da52e643b6920f91377fba2ade648aa780d8c9f4433e0a7bc700939
    PATCH_COMMAND
      "${CMAKE_COMMAND}" -E touch "<SOURCE_DIR>/.git"
    COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=qt-superbuild-${patch_version}/qtlocation
        -P "${APPLY_PATCHES_SERIES}"
  
  USING qmake USE_SYSTEM_QT module
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${qmake}" "${SOURCE_DIR}"
  ]]
)



# qtsensors

superbuild_package(
  NAME           qtsensors
  VERSION        ${short_version}
  DEPENDS        qtsensors-opensource-src-${debian_patch_version}
)

set(module Qt5Sensors)
superbuild_package(
  NAME           qtsensors-opensource-src
  VERSION        ${debian_patch_version}
  DEPENDS        qtbase-${short_version}
  
  SOURCE
    URL            ${SUPERBUILD_DEBIAN_BASE_URL_2018_02}/pool/main/q/qtsensors-opensource-src/qtsensors-opensource-src_${debian_version}.orig.tar.xz
    URL_HASH       SHA256=79441588c9c8bd1b34b91481441614077ea335a0005e79a1dc68ad964284b5d3
    PATCH_COMMAND  "${CMAKE_COMMAND}" -E touch "<SOURCE_DIR>/.git"
  
  USING qmake USE_SYSTEM_QT module
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${qmake}" "${SOURCE_DIR}"
  ]]
)

# qtserialport

superbuild_package(
  NAME           qtserialport
  VERSION        ${short_version}
  DEPENDS        qtserialport-opensource-src-${debian_patch_version}
)

set(module Qt5SerialPort)
superbuild_package(
  NAME           qtserialport-opensource-src
  VERSION        ${debian_patch_version}
  DEPENDS        qtbase-${short_version}
                 source:qt-superbuild-${patch_version}
  
  SOURCE
    URL            ${SUPERBUILD_DEBIAN_BASE_URL_2018_02}/pool/main/q/qtserialport-opensource-src/qtserialport-opensource-src_${debian_version}.orig.tar.xz
    URL_HASH       SHA256=50ed9cc22db1615bc00267d24b0819813b854af3651ab6e5ffaa7f7c7e62cd42
    PATCH_COMMAND
      "${CMAKE_COMMAND}" -E touch "<SOURCE_DIR>/.git"
    COMMAND
      "${CMAKE_COMMAND}"
        -Dpackage=qt-superbuild-${patch_version}/qtserialport
        -P "${APPLY_PATCHES_SERIES}"
  
  USING qmake USE_SYSTEM_QT module
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${qmake}" "${SOURCE_DIR}"
  ]]
)



# qttools

superbuild_package(
  NAME           qttools
  VERSION        ${short_version}
  DEPENDS        qttools-opensource-src-${debian_patch_version}
)

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
  NAME           qttools-opensource-src
  VERSION        ${debian_patch_version}
  DEPENDS        qtbase-${short_version}
  
  SOURCE
	URL            ${SUPERBUILD_DEBIAN_BASE_URL_2018_02}/pool/main/q/qttools-opensource-src/qttools-opensource-src_${debian_version}.orig.tar.xz
	URL_HASH       SHA256=2bb996118b68e9939c185a593837e5a41bb3667bf5d4d5134fac02598bd2d81a
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

superbuild_package(
  NAME           qttranslations
  VERSION        ${short_version}
  DEPENDS        qttranslations-opensource-src-${version}
)

set(module Qt5Core) # Can't find qttranslations via CMake.
superbuild_package(
  NAME           qttranslations-opensource-src
  VERSION        ${version}
  DEPENDS        qtbase-${short_version}
                 qttools-${short_version}
  
  SOURCE
    URL            https://download.qt.io/archive/qt/${short_version}/${version}/submodules/qttranslations-opensource-src-${version}.tar.xz
    URL_HASH       MD5=cdeeeec5dfe7898a89e098a917973464
    PATCH_COMMAND  "${CMAKE_COMMAND}" -E touch "<SOURCE_DIR>/.git"
  
  USING qmake USE_SYSTEM_QT module
  BUILD_CONDITION  ${use_system_qt}
  BUILD [[
    CONFIGURE_COMMAND
      "${qmake}" "${SOURCE_DIR}"
  ]]
)
