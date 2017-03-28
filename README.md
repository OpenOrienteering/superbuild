# OpenOrienteering SuperBuild

## Project goals

- Reproducible builds of packages, with clearly identified sources and scripts
- Leverage CMake language and modules
- Single central CMakeLists.txt file
- Single CMake script per package
- Handling of package dependencies
- Parallel build of packages
- Shadow build for multiple toolchains from single unpacked source directory
- Parallel build for multiple toolchains at the same time
- Leverage Debian/Ubuntu archives for cross-build and security patches
- Being friendly to IDEs and CMake GUIs


## Usage

- Create a build directory.
- Run `cmake SOURCE_DIR [ CONFIGURATION_OPTIONS ]` from the build directory.
  - Run cmake with `-DENABLE_<toolchain>=1` to enable an extra toolchain.
  - Run cmake with `-DUSE_SYSTEM_<package>=0` to force the build of a package
    which is already provided by the system or toolchain.
  - Run `cmake -L` to see available configuration options.
- Run `make PACKAGE-VERSION[-<toolchain>] [ -jNUM_JOBS ]` from the build
  directory to build a package.
- Run `make PACKAGE-VERSION[-<toolchain>]-package` from the build directory to
  produce a distributable package (such as ZIP, installer, APK) for a source
  package.
- You may overwrite some variables for each toolchain
  `<toolchain>_BUILD_TYPE`      - The CMAKE_BUILD_TYPE for this toolchain
                                  (default: CMAKE_BUILD_TYPE).
  `<toolchain>_INSTALL_DIR`     - The root directory where files will be placed
                                  (default: PROJECT_BINARY_DIR/<toolchain>/install).
  `<toolchain>_INSTALL_PREFIX`  - The path where files will be located in the target system.
  `<toolchain>_TOOLCHAIN_DIR`   - The root directory where the toolchain files are located.
- You may disable binary package depedencies by setting `DISABLE_DEPENDENCIES'.
  However, dependencies on the toolchain and on package sources will always be active.


## Writing Package Files

- Package files need to be in the source directory.
- The package file name must end with ".cmake".
  The recommended form is "NAME-VERSION.cmake".
- The core element of a package file is the call of the `superbuild_package` macro.
  Parameters of this macro are:
  - `NAME`           - The package name
  - `VERSION`        - The package version and revision, max. 4 components (a.b.c.d).
  - `SYSTEM_NAME`    - Declares the package to be the toolchain for this system.
  - `DEPENDS`        - Names of packages this one depends one.
                       Names may contain exact versions (DEPENDEE-a.b.c).
  - `SOURCE`         - Download, update and patch options as understood by
                       CMake's ExternalProject, or the name of another package,
                       reusing that package's source.
  - `SOURCE_WRITE`   - Write source files, given by pairs of file name and variable name.
                       File names are interpreted relative to the `SOURCE_DIR`.
                       If the named variable is a list, the items are joined,
                       like `file(WRITE list...)` does.
  - `USING`          - Names of variables which are to be passed from the top-level
                       configuration to the configuration for a target toolchain (BUILD,
                       BUILD_CONDITION). Use this to pass e.g. configuration options.
  - `BUILD_CONDITION - optional CMake code which may set the variable `BUILD_CONDITION`
                       to false in order to disable building of the package.
                       This may be used to check for system libraries which can
                       be used instead of the current package.
  - `BUILD`          - Configure, build, install and test options as understood
                       by CMake's ExternalProject. This parameter's value shall
                       be given quoted by double square brackets (`[[ ... ]]`)
                       because the expansion of variables and generator expressions
                       must take place in the context of the target toolchain.
  - `EXECUTABLES`    - Declares executables in the default toolchain's build tree
                       which shall be mirrored in the global build tree, for
                       convenient use in IDEs (run, debug).
- In addition to variables named by `USING`, the following variables are always
  available during configuration of package for a particular toolchain:
  - `CMAKE_TOOLCHAIN_FILE`
  - `HOST_DIR`
  - `TOOLCHAIN_DIR`
  - `SOURCE_DIR`
  - `BINARY_DIR`
  - `INSTALL_DIR`
  - `TMP_DIR`
- To apply patches from a Debian or Ubuntu modification archive
  (e.g. foo_1.0-1.debian.tar.gz), add a package (e.g. foo-patches 1.0-1) for
  this archive without build steps, make this package a dependency of the
  original package (e.g. foo 1.0), and add the following to the SOURCE argument
  of the original package:
  
~~~
  PATCH_COMMAND
    "${CMAKE_COMMAND}" -Dpackage=foo-patches-1.0-1 -P "${APPLY_PATCHES_SERIES}"
~~~


## Writing Toolchain Package Files

- Provide an `ENABLE_<TOOLCHAIN_NAME>` configuration option, default 0 (OFF).
- Use the `SYSTEM_NAME` argument to declare the target system's name.
- Install a toolchain.cmake file.
  - Set `SUPERBUILD_TOOLCHAIN_TRIPLET` to the target triplet.
  - Set the following variables to adjust CMake progress information:
  
~~~
set(CMAKE_RULE_MESSAGES   OFF CACHE BOOL "Whether to report a message for each make rule")
set(CMAKE_TARGET_MESSAGES OFF CACHE BOOL "Whether to report a message for each target")
set(CMAKE_VERBOSE_MAKEFILE ON CACHE BOOL "Enable verbose output from Makefile builds")
~~~


## TODO list

- Organization and product configuration (for deployment locations and packaging)
- Automatic collection of scripts and sources
- Automatic tests
- Cleanup

