#!/bin/bash

# 设置变量
WORKSPACE=$(pwd)
SRC_DIR="$WORKSPACE/src"
BUILD_DIR="$WORKSPACE/build"
INSTALL_DIR="$WORKSPACE/install"
OPENSSL_DIR="$SRC_DIR/openssl-3.4.0"
LIBMODBUS_DIR="$SRC_DIR/libmodbus-3.1.11"
PLATFORMS="x64 x86 arm aarch64"

# 检查源代码目录是否存在
if [ ! -d "$OPENSSL_DIR" ]; then
    echo "OpenSSL source directory not found: $OPENSSL_DIR"
    exit 1
fi

if [ ! -d "$LIBMODBUS_DIR" ]; then
    echo "libmodbus source directory not found: $LIBMODBUS_DIR"
    exit 1
fi

# 创建必要的目录
mkdir -p "$BUILD_DIR" "$INSTALL_DIR"

# 设置平台特定的编译器选项
set_platform_flags() {
    local platform=$1
    local build_type=$2
    
    unset HOST
    unset CC
    unset CXX
    unset CFLAGS
    unset CXXFLAGS
    unset LDFLAGS

    case $platform in
        x64)
            export CC="gcc"
            export CXX="g++"
            export CFLAGS="-m64"
            export CXXFLAGS="-m64"
            export LDFLAGS="-m64"
            HOST="x86_64-linux-gnu"
            OPENSSL_TARGET="linux-x86_64"
            ;;
        x86)
            export CC="gcc"
            export CXX="g++"
            export CFLAGS="-m32"
            export CXXFLAGS="-m32"
            export LDFLAGS="-m32"
            HOST="i686-linux-gnu"
            OPENSSL_TARGET="linux-elf"
            ;;
        arm)
            export CC="arm-linux-gnueabihf-gcc"
            export CXX="arm-linux-gnueabihf-g++"
            HOST="arm-linux-gnueabihf"
            OPENSSL_TARGET="linux-armv4"
            ;;
        aarch64)
            export CC="aarch64-linux-gnu-gcc"
            export CXX="aarch64-linux-gnu-g++"
            HOST="aarch64-linux-gnu"
            OPENSSL_TARGET="linux-aarch64"
            ;;
        *)
            echo "Unknown platform: $platform"
            exit 1
            ;;
    esac

    # 根据构建类型设置编译选项
    if [ "$build_type" = "Debug" ]; then
        export CFLAGS="$CFLAGS -g -O0"
        export CXXFLAGS="$CXXFLAGS -g -O0"
    else
        export CFLAGS="$CFLAGS -O2"
        export CXXFLAGS="$CXXFLAGS -O2"
    fi
}

# 准备libmodbus构建环境
prepare_libmodbus() {
    echo "Preparing libmodbus build environment..."
    cd "$LIBMODBUS_DIR" || exit 1
    
    # 清理之前的配置
    if [ -f "Makefile" ]; then
        echo "Cleaning previous libmodbus configuration..."
        make distclean >/dev/null 2>&1
    fi
    
    if [ ! -f "autogen.sh" ]; then
        echo "autogen.sh not found in $LIBMODBUS_DIR"
        exit 1
    fi
    
    ./autogen.sh
    if [ $? -ne 0 ]; then
        echo "Failed to run autogen.sh for libmodbus"
        exit 1
    fi
    
    cd "$WORKSPACE" || exit 1
}

# 生成CMake配置文件
generate_cmake_config() {
    local platform=$1
    local build_type=$2
	local lib_ext=$3
	local build_type_UPPER=$(echo "$build_type" | tr '[:lower:]' '[:upper:]')
	local build_type_lower=$(echo "$build_type" | tr '[:upper:]' '[:lower:]')
    local install_dir="$INSTALL_DIR/$platform"
    local openssl_cmake_dir="$install_dir/lib/cmake/openssl"
    local libmodbus_cmake_dir="$install_dir/lib/cmake/modbus"
	
	if [ "$platform" = "aarch64" ] || [ "$platform" = "x64" ]; then
		size_int="8"
	else
		size_int="4"
	fi
	
    mkdir -p "$openssl_cmake_dir" "$libmodbus_cmake_dir"
	

	echo "============================================================"
	echo "Generate cmake scripts for platform: $platform ($build_type)" 
	echo "============================================================"
    
    # 生成OpenSSL的CMake目标文件
    local openssl_target_file="$openssl_cmake_dir/OpenSSLTargets-$build_type_lower.cmake"
    cat > "$openssl_target_file" <<EOF
#----------------------------------------------------------------
# Generated CMake target import file for configuration "$build_type".
#----------------------------------------------------------------

set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "OpenSSL::SSL" for configuration "$build_type"
set_property(TARGET OpenSSL::SSL APPEND PROPERTY IMPORTED_CONFIGURATIONS $build_type_UPPER)
set_target_properties(OpenSSL::SSL PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_$build_type_UPPER "CXX"
  IMPORTED_LOCATION_$build_type_UPPER "\${_IMPORT_PREFIX}/lib/libssl${lib_ext}.a"
  INTERFACE_INCLUDE_DIRECTORIES "\${_IMPORT_PREFIX}/include"
  INTERFACE_LINK_LIBRARIES "OpenSSL::Crypto"
)

# Import target "OpenSSL::Crypto" for configuration "$build_type"
set_property(TARGET OpenSSL::Crypto APPEND PROPERTY IMPORTED_CONFIGURATIONS $build_type_UPPER)
set_target_properties(OpenSSL::Crypto PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_$build_type "CXX"
  IMPORTED_LOCATION_$build_type_UPPER "\${_IMPORT_PREFIX}/lib/libcrypto${lib_ext}.a"
  INTERFACE_INCLUDE_DIRECTORIES "\${_IMPORT_PREFIX}/include"
)

list(APPEND _cmake_import_check_targets OpenSSL::SSL OpenSSL::Crypto)
list(APPEND _cmake_import_check_files_for_OpenSSL::SSL "\${_IMPORT_PREFIX}/lib/libssl${lib_ext}.a")
list(APPEND _cmake_import_check_files_for_OpenSSL::Crypto "\${_IMPORT_PREFIX}/lib/libcrypto${lib_ext}.a")

set(CMAKE_IMPORT_FILE_VERSION)
EOF

    # 生成libmodbus的CMake目标文件
    local libmodbus_target_file="$libmodbus_cmake_dir/modbusTargets-$build_type_lower.cmake"
    cat > "$libmodbus_target_file" <<EOF
#----------------------------------------------------------------
# Generated CMake target import file for configuration "$build_type".
#----------------------------------------------------------------

set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "modbus::modbus" for configuration "$build_type"
set_property(TARGET modbus::modbus APPEND PROPERTY IMPORTED_CONFIGURATIONS $build_type_UPPER)
set_target_properties(modbus::modbus PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_$build_type_UPPER "CXX"
  IMPORTED_LOCATION_$build_type_UPPER "\${_IMPORT_PREFIX}/lib/libmodbus${lib_ext}.a"
  INTERFACE_INCLUDE_DIRECTORIES "\${_IMPORT_PREFIX}/include"
)

list(APPEND _cmake_import_check_targets modbus::modbus)
list(APPEND _cmake_import_check_files_for_modbus::modbus "\${_IMPORT_PREFIX}/lib/libmodbus${lib_ext}.a")

set(CMAKE_IMPORT_FILE_VERSION)
EOF

    cat > "$openssl_cmake_dir/OpenSSLConfig.cmake" <<EOF
get_filename_component(PACKAGE_PREFIX_DIR "\${CMAKE_CURRENT_LIST_DIR}/../../../" ABSOLUTE)

macro(set_and_check _var _file)
  set(\${_var} "\${_file}")
  if(NOT EXISTS "\${_file}")
    message(FATAL_ERROR "File or directory \${_file} referenced by variable \${_var} does not exist !")
  endif()
endmacro()

macro(check_required_components _NAME)
  foreach(comp \${\${_NAME}_FIND_COMPONENTS})
    if(NOT \${_NAME}_\${comp}_FOUND)
      if(\${_NAME}_FIND_REQUIRED_\${comp})
        set(\${_NAME}_FOUND FALSE)
      endif()
    endif()
  endforeach()
endmacro()

include(CMakeFindDependencyMacro)

include("\${CMAKE_CURRENT_LIST_DIR}/OpenSSLTargets.cmake")
check_required_components("")
EOF

    cat > "$openssl_cmake_dir/OpenSSLTargets.cmake" <<EOF
# Generated by CMake

if("\${CMAKE_MAJOR_VERSION}.\${CMAKE_MINOR_VERSION}" LESS 2.8)
   message(FATAL_ERROR "CMake >= 2.8.12 required")
endif()
if(CMAKE_VERSION VERSION_LESS "2.8.12")
   message(FATAL_ERROR "CMake >= 2.8.12 required")
endif()
cmake_policy(PUSH)
cmake_policy(VERSION 2.8.12...3.29)

#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Protect against multiple inclusion, which would fail when already imported targets are added once more.
set(_cmake_targets_defined "")
set(_cmake_targets_not_defined "")
set(_cmake_expected_targets "")
foreach(_cmake_expected_target IN ITEMS OpenSSL::Crypto OpenSSL::SSL)
  list(APPEND _cmake_expected_targets "\${_cmake_expected_target}")
  if(TARGET "\${_cmake_expected_target}")
    list(APPEND _cmake_targets_defined "\${_cmake_expected_target}")
  else()
    list(APPEND _cmake_targets_not_defined "\${_cmake_expected_target}")
  endif()
endforeach()
unset(_cmake_expected_target)
if(_cmake_targets_defined STREQUAL _cmake_expected_targets)
  unset(_cmake_targets_defined)
  unset(_cmake_targets_not_defined)
  unset(_cmake_expected_targets)
  unset(CMAKE_IMPORT_FILE_VERSION)
  cmake_policy(POP)
  return()
endif()
if(NOT _cmake_targets_defined STREQUAL "")
  string(REPLACE ";" ", " _cmake_targets_defined_text "\${_cmake_targets_defined}")
  string(REPLACE ";" ", " _cmake_targets_not_defined_text "\${_cmake_targets_not_defined}")
  message(FATAL_ERROR "Some (but not all) targets in this export set were already defined.\nTargets Defined: \${_cmake_targets_defined_text}\nTargets not yet defined: \${_cmake_targets_not_defined_text}\n")
endif()
unset(_cmake_targets_defined)
unset(_cmake_targets_not_defined)
unset(_cmake_expected_targets)

get_filename_component(_IMPORT_PREFIX "\${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_IMPORT_PREFIX "\${_IMPORT_PREFIX}" PATH)
get_filename_component(_IMPORT_PREFIX "\${_IMPORT_PREFIX}" PATH)
get_filename_component(_IMPORT_PREFIX "\${_IMPORT_PREFIX}" PATH)
if(_IMPORT_PREFIX STREQUAL "/")
  set(_IMPORT_PREFIX "")
endif()

# Create imported target OpenSSL::SSL
add_library(OpenSSL::SSL STATIC IMPORTED)

set_target_properties(OpenSSL::SSL PROPERTIES
  INTERFACE_COMPILE_FEATURES "cxx_std_14"
  INTERFACE_INCLUDE_DIRECTORIES "\${_IMPORT_PREFIX}/include"
  INTERFACE_SYSTEM_INCLUDE_DIRECTORIES "\${_IMPORT_PREFIX}/include"
)

# Create imported target OpenSSL::Crypto
add_library(OpenSSL::Crypto STATIC IMPORTED)

set_target_properties(OpenSSL::Crypto PROPERTIES
  INTERFACE_COMPILE_FEATURES "cxx_std_14"
  INTERFACE_INCLUDE_DIRECTORIES "\${_IMPORT_PREFIX}/include"
  INTERFACE_SYSTEM_INCLUDE_DIRECTORIES "\${_IMPORT_PREFIX}/include"
)

# Load targets for the specified configuration
include("\${CMAKE_CURRENT_LIST_DIR}/OpenSSLTargets-*.cmake")

foreach(_cmake_config_file IN LISTS _cmake_config_files)
  include("\${_cmake_config_file}")
endforeach()
unset(_cmake_config_file)
unset(_cmake_config_files)

# Cleanup temporary variables.
set(_IMPORT_PREFIX)

# Loop over all imported files and verify that they actually exist
foreach(_cmake_target IN LISTS _cmake_import_check_targets)
  if(CMAKE_VERSION VERSION_LESS "3.28"
      OR NOT DEFINED _cmake_import_check_xcframework_for_\${_cmake_target}
      OR NOT IS_DIRECTORY "\${_cmake_import_check_xcframework_for_\${_cmake_target}}")
    foreach(_cmake_file IN LISTS "_cmake_import_check_files_for_\${_cmake_target}")
      if(NOT EXISTS "\${_cmake_file}")
        message(FATAL_ERROR "The imported target \"\${_cmake_target}\" references the file
   \"\${_cmake_file}\"
but this file does not exist.  Possible reasons include:
* The file was deleted, renamed, or moved to another location.
* An install or uninstall procedure did not complete successfully.
* The installation package was faulty and contained
   \"\${CMAKE_CURRENT_LIST_FILE}\"
but not all the files it references.
")
      endif()
    endforeach()
  endif()
  unset(_cmake_file)
  unset("_cmake_import_check_files_for_\${_cmake_target}")
endforeach()
unset(_cmake_target)
unset(_cmake_import_check_targets)

# This file does not depend on other imported targets which have
# been exported from the same project but in a separate export set.

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
cmake_policy(POP)

EOF

    cat > "$openssl_cmake_dir/OpenSSLConfigVersion.cmake" <<EOF
set(PACKAGE_VERSION "3.4.0")

if(PACKAGE_FIND_VERSION_RANGE)
    if((PACKAGE_FIND_VERSION_RANGE_MIN STREQUAL "INCLUDE" AND PACKAGE_VERSION VERSION_LESS PACKAGE_FIND_VERSION_MIN)
        OR ((PACKAGE_FIND_VERSION_RANGE_MAX STREQUAL "INCLUDE" AND PACKAGE_VERSION VERSION_GREATER PACKAGE_FIND_VERSION_MAX)
        OR (PACKAGE_FIND_VERSION_RANGE_MAX STREQUAL "EXCLUDE" AND PACKAGE_VERSION VERSION_GREATER_EQUAL PACKAGE_FIND_VERSION_MAX)))
        set(PACKAGE_VERSION_COMPATIBLE FALSE)
    else()
        set(PACKAGE_VERSION_COMPATIBLE TRUE)
    endif()
else()
    if(PACKAGE_VERSION VERSION_LESS PACKAGE_FIND_VERSION)
        set(PACKAGE_VERSION_COMPATIBLE FALSE)
    else()
        set(PACKAGE_VERSION_COMPATIBLE TRUE)
        if(PACKAGE_FIND_VERSION STREQUAL PACKAGE_VERSION)
            set(PACKAGE_VERSION_EXACT TRUE)
        endif()
    endif()
endif()

# if the installed or the using project don't have CMAKE_SIZEOF_VOID_P set, ignore it:
if("\${CMAKE_SIZEOF_VOID_P}" STREQUAL "" OR "$size_int" STREQUAL "")
  return()
endif()

# check that the installed version has the same 32/64bit-ness as the one which is currently searching:
if(NOT CMAKE_SIZEOF_VOID_P STREQUAL "$size_int")
  math(EXPR installedBits "$size_int * 8")
  set(PACKAGE_VERSION "\${PACKAGE_VERSION} (\${installedBits}bit)")
  set(PACKAGE_VERSION_UNSUITABLE TRUE)
endif()

EOF

    cat > "$libmodbus_cmake_dir/modbusConfig.cmake" <<EOF
get_filename_component(PACKAGE_PREFIX_DIR "\${CMAKE_CURRENT_LIST_DIR}/../../../" ABSOLUTE)

macro(set_and_check _var _file)
  set(\${_var} "\${_file}")
  if(NOT EXISTS "\${_file}")
    message(FATAL_ERROR "File or directory \${_file} referenced by variable \${_var} does not exist !")
  endif()
endmacro()

macro(check_required_components _NAME)
  foreach(comp \${\${_NAME}_FIND_COMPONENTS})
    if(NOT \${_NAME}_\${comp}_FOUND)
      if(\${_NAME}_FIND_REQUIRED_\${comp})
        set(\${_NAME}_FOUND FALSE)
      endif()
    endif()
  endforeach()
endmacro()

include(CMakeFindDependencyMacro)

include("\${CMAKE_CURRENT_LIST_DIR}/modbusTargets.cmake")
check_required_components("")
EOF

    cat > "$libmodbus_cmake_dir/modbusTargets.cmake" <<EOF
# Generated by CMake

if("\${CMAKE_MAJOR_VERSION}.\${CMAKE_MINOR_VERSION}" LESS 2.8)
   message(FATAL_ERROR "CMake >= 2.8.12 required")
endif()
if(CMAKE_VERSION VERSION_LESS "2.8.12")
   message(FATAL_ERROR "CMake >= 2.8.12 required")
endif()
cmake_policy(PUSH)
cmake_policy(VERSION 2.8.12...3.29)

#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Protect against multiple inclusion, which would fail when already imported targets are added once more.
set(_cmake_targets_defined "")
set(_cmake_targets_not_defined "")
set(_cmake_expected_targets "")
foreach(_cmake_expected_target IN ITEMS modbus::modbus)
  list(APPEND _cmake_expected_targets "\${_cmake_expected_target}")
  if(TARGET "\${_cmake_expected_target}")
    list(APPEND _cmake_targets_defined "\${_cmake_expected_target}")
  else()
    list(APPEND _cmake_targets_not_defined "\${_cmake_expected_target}")
  endif()
endforeach()
unset(_cmake_expected_target)
if(_cmake_targets_defined STREQUAL _cmake_expected_targets)
  unset(_cmake_targets_defined)
  unset(_cmake_targets_not_defined)
  unset(_cmake_expected_targets)
  unset(CMAKE_IMPORT_FILE_VERSION)
  cmake_policy(POP)
  return()
endif()
if(NOT _cmake_targets_defined STREQUAL "")
  string(REPLACE ";" ", " _cmake_targets_defined_text "\${_cmake_targets_defined}")
  string(REPLACE ";" ", " _cmake_targets_not_defined_text "\${_cmake_targets_not_defined}")
  message(FATAL_ERROR "Some (but not all) targets in this export set were already defined.\nTargets Defined: \${_cmake_targets_defined_text}\nTargets not yet defined: \${_cmake_targets_not_defined_text}\n")
endif()
unset(_cmake_targets_defined)
unset(_cmake_targets_not_defined)
unset(_cmake_expected_targets)

get_filename_component(_IMPORT_PREFIX "\${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_IMPORT_PREFIX "\${_IMPORT_PREFIX}" PATH)
get_filename_component(_IMPORT_PREFIX "\${_IMPORT_PREFIX}" PATH)
get_filename_component(_IMPORT_PREFIX "\${_IMPORT_PREFIX}" PATH)
if(_IMPORT_PREFIX STREQUAL "/")
  set(_IMPORT_PREFIX "")
endif()

# Create imported target modbus::modbus
add_library(modbus::modbus STATIC IMPORTED)

set_target_properties(modbus::modbus PROPERTIES
  INTERFACE_COMPILE_FEATURES "cxx_std_14"
  INTERFACE_INCLUDE_DIRECTORIES "\${_IMPORT_PREFIX}/include"
  INTERFACE_SYSTEM_INCLUDE_DIRECTORIES "\${_IMPORT_PREFIX}/include"
)

# Load information for each installed configuration.
file(GLOB _cmake_config_files "\${CMAKE_CURRENT_LIST_DIR}/modbusTargets-*.cmake")
foreach(_cmake_config_file IN LISTS _cmake_config_files)
  include("\${_cmake_config_file}")
endforeach()
unset(_cmake_config_file)
unset(_cmake_config_files)

# Cleanup temporary variables.
set(_IMPORT_PREFIX)

# Loop over all imported files and verify that they actually exist
foreach(_cmake_target IN LISTS _cmake_import_check_targets)
  if(CMAKE_VERSION VERSION_LESS "3.28"
      OR NOT DEFINED _cmake_import_check_xcframework_for_\${_cmake_target}
      OR NOT IS_DIRECTORY "\${_cmake_import_check_xcframework_for_\${_cmake_target}}")
    foreach(_cmake_file IN LISTS "_cmake_import_check_files_for_\${_cmake_target}")
      if(NOT EXISTS "\${_cmake_file}")
        message(FATAL_ERROR "The imported target \"\${_cmake_target}\" references the file
   \"\${_cmake_file}\"
but this file does not exist.  Possible reasons include:
* The file was deleted, renamed, or moved to another location.
* An install or uninstall procedure did not complete successfully.
* The installation package was faulty and contained
   \"\${CMAKE_CURRENT_LIST_FILE}\"
but not all the files it references.
")
      endif()
    endforeach()
  endif()
  unset(_cmake_file)
  unset("_cmake_import_check_files_for_\${_cmake_target}")
endforeach()
unset(_cmake_target)
unset(_cmake_import_check_targets)

# This file does not depend on other imported targets which have
# been exported from the same project but in a separate export set.

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)

cmake_policy(POP)
EOF

    cat > "$libmodbus_cmake_dir/modbusConfigVersion.cmake" <<EOF
set(PACKAGE_VERSION "3.1.11")

if(PACKAGE_FIND_VERSION_RANGE)
    if((PACKAGE_FIND_VERSION_RANGE_MIN STREQUAL "INCLUDE" AND PACKAGE_VERSION VERSION_LESS PACKAGE_FIND_VERSION_MIN)
        OR ((PACKAGE_FIND_VERSION_RANGE_MAX STREQUAL "INCLUDE" AND PACKAGE_VERSION VERSION_GREATER PACKAGE_FIND_VERSION_MAX)
        OR (PACKAGE_FIND_VERSION_RANGE_MAX STREQUAL "EXCLUDE" AND PACKAGE_VERSION VERSION_GREATER_EQUAL PACKAGE_FIND_VERSION_MAX)))
        set(PACKAGE_VERSION_COMPATIBLE FALSE)
    else()
        set(PACKAGE_VERSION_COMPATIBLE TRUE)
    endif()
else()
    if(PACKAGE_VERSION VERSION_LESS PACKAGE_FIND_VERSION)
        set(PACKAGE_VERSION_COMPATIBLE FALSE)
    else()
        set(PACKAGE_VERSION_COMPATIBLE TRUE)
        if(PACKAGE_FIND_VERSION STREQUAL PACKAGE_VERSION)
            set(PACKAGE_VERSION_EXACT TRUE)
        endif()
    endif()
endif()

# if the installed or the using project don't have CMAKE_SIZEOF_VOID_P set, ignore it:
if("\${CMAKE_SIZEOF_VOID_P}" STREQUAL "" OR "$size_int" STREQUAL "")
  return()
endif()

# check that the installed version has the same 32/64bit-ness as the one which is currently searching:
if(NOT CMAKE_SIZEOF_VOID_P STREQUAL "$size_int")
  math(EXPR installedBits "$size_int * 8")
  set(PACKAGE_VERSION "\${PACKAGE_VERSION} (\${installedBits}bit)")
  set(PACKAGE_VERSION_UNSUITABLE TRUE)
endif()
EOF

}

# 构建函数
build_lib() {
    local lib=$1
    local platform=$2
    local build_type=$3
    
    local build_dir="$BUILD_DIR/$platform-$build_type/$lib"
    local install_dir="$INSTALL_DIR/$platform"
    
    mkdir -p "$build_dir"
    cd "$build_dir" || exit 1
    
    local suffix=""
    [ "$build_type" = "Debug" ] && suffix="d"
	

    case $lib in
        openssl)
			echo "=========================================================="
			echo "Building for platform: $platform ($build_type) for OpenSSL" 
			echo "=========================================================="
            echo "Configuring OpenSSL for $platform ($build_type)"
            "$OPENSSL_DIR/Configure" \
                --prefix="$install_dir" \
                --openssldir="$install_dir/ssl" \
                no-shared \
                no-zlib \
                no-tests \
                $OPENSSL_TARGET \
                $( [ "$build_type" = "Debug" ] && echo "--debug" )
            
            echo "Building OpenSSL (without tests)"
            make -j$(nproc) build_sw
            make install_sw
            
            if [ "$build_type" = "Debug" ]; then
                echo "Renaming debug libraries"
                for libfile in "$install_dir/lib/"libcrypto.a "$install_dir/lib/"libssl.a; do
                    [ -f "$libfile" ] && mv "$libfile" "${libfile%.a}${suffix}.a"
                done
            fi
            ;;
            
        libmodbus)
			echo "============================================================"
			echo "Building for platform: $platform ($build_type) for libmodbus" 
			echo "============================================================"
            echo "Configuring libmodbus for $platform ($build_type)"
            "$LIBMODBUS_DIR/configure" \
                --prefix="$install_dir" \
                $(if [ -n "$HOST" ]; then echo "--host=$HOST"; fi) \
                --disable-shared \
                --enable-static \
                $( [ "$build_type" = "Debug" ] && echo "--enable-debug" )
            
            echo "Building libmodbus"
            make -j$(nproc)
            make install
            
            if [ "$build_type" = "Debug" ]; then
                echo "Renaming debug libraries"
                [ -f "$install_dir/lib/libmodbus.a" ] && mv "$install_dir/lib/libmodbus.a" "$install_dir/lib/libmodbus${suffix}.a"
            fi
            ;;
    esac
    
    cd "$WORKSPACE" || exit 1
}

# 主构建流程
echo "=============================================="
echo "Starting build process"
echo "=============================================="

prepare_libmodbus

for platform in $PLATFORMS; do
    # 先构建Debug版本
    local install_dir="$INSTALL_DIR/$platform"
    
    # 完全清理平台的安装目录
    echo "Cleaning installation directory for $platform..."
    rm -rf "$install_dir"
    mkdir -p "$install_dir"
	
    echo "Building Debug configuration..."
    set_platform_flags "$platform" "Debug"
    #build_lib "openssl" "$platform" "Debug"
    build_lib "libmodbus" "$platform" "Debug"
    generate_cmake_config "$platform" "Debug" "d"
    
    # 再构建Release版本
    echo "Building Release configuration..."
    set_platform_flags "$platform" "Release"
    #build_lib "openssl" "$platform" "Release"
    build_lib "libmodbus" "$platform" "Release"
    generate_cmake_config "$platform" "Release" ""
done

echo "All builds completed successfully!"