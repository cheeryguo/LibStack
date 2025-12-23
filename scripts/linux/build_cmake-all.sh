#!/bin/bash

# ===========================================
# Configuration
# ===========================================
SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR="$SCRIPT_DIR/../../"  # Fixed syntax error from original
BUILD_DIR="$ROOT_DIR/build"
INSTALL_DIR="$ROOT_DIR/install"

# Valid options
VALID_ARCHES=("all" "x86" "x64" "aarch64" "arm")
VALID_CONFIGS=("all" "Release" "Debug")

# Default values
DEFAULT_ARCH="x64"
DEFAULT_CONFIG="Release"

# ===========================================
# Parameter Handling
# ===========================================
# Parse input parameters
arch="$1"
config="$2"

# Set defaults if parameters are not provided
if [ -z "$arch" ]; then
    arch="$DEFAULT_ARCH"
fi
if [ -z "$config" ]; then
    config="$DEFAULT_CONFIG"
fi

# Validate architecture parameter
if ! [[ " ${VALID_ARCHES[@]} " =~ " $arch " ]]; then
    echo "Error: Invalid architecture '$arch'. Valid options: ${VALID_ARCHES[*]}"
    exit 1
fi

# Validate configuration parameter
if ! [[ " ${VALID_CONFIGS[@]} " =~ " $config " ]]; then
    echo "Error: Invalid configuration '$config'. Valid options: ${VALID_CONFIGS[*]}"
    exit 1
fi

# Determine target architectures to build
if [ "$arch" = "all" ]; then
    TARGET_ARCHES=("x86" "x64" "aarch64" "arm")
else
    TARGET_ARCHES=("$arch")
fi

# Determine target configurations to build
if [ "$config" = "all" ]; then
    TARGET_CONFIGS=("Release" "Debug")
else
    TARGET_CONFIGS=("$config")
fi

# Cross-compiler prefixes (adjust based on your setup)
declare -A COMPILER_PREFIX=(
    ["arm"]="arm-linux-gnueabihf-"
    ["aarch64"]="aarch64-linux-gnu-"
    ["x86"]=""  # Native x86 (uses -m32)
    ["x64"]=""  # Native x64 (default)
)

# ===========================================
# Build functions (unchanged)
# ===========================================
build_json() {
    local arch="$1"
    local config="$2"
    
    local build_path="$BUILD_DIR/$arch-$config/json"
    local install_path="$INSTALL_DIR/$arch"
    local json_path="$ROOT_DIR/src/json-3.12"

    echo "Building JSON for $arch ($config) from $json_path to $install_path"    
    mkdir -p "$build_path"
    cd "$build_path" || exit 1
    
    # Configure compiler flags
    local cmake_flags=""
    case "$arch" in
        "arm"|"aarch64")
            cmake_flags="\
                -DCMAKE_C_COMPILER=${COMPILER_PREFIX[$arch]}gcc \
                -DCMAKE_CXX_COMPILER=${COMPILER_PREFIX[$arch]}g++"
            ;;
        "x86")
            cmake_flags="\
                -DCMAKE_C_FLAGS=-m32 \
                -DCMAKE_CXX_FLAGS=-m32"
            ;;
        "x64")
            cmake_flags=""  # Default 64-bit
            ;;
    esac
    
    # Run CMake
    cmake \
        -DJSON_Install=ON \
        -DJSON_BuildTests=OFF \
        -DCMAKE_BUILD_TYPE="$config" \
        -DCMAKE_INSTALL_PREFIX:PATH="$install_path" \
        $cmake_flags \
        "$json_path"
    if [ $? -ne 0 ]; then
        echo "CMake configuration failed for JSON $arch ($config)"
        cd - || exit 1
        return 1
    fi
    
    cmake --build . --config "$config" -j32
    if [ $? -ne 0 ]; then
        echo "Build failed for JSON $arch ($config)"
        cd - || exit 1
        return 1
    fi
    
    cmake --install . --config "$config"
    if [ $? -ne 0 ]; then
        echo "Installation failed for JSON $arch ($config)"
        cd - || exit 1
        return 1
    fi
    
    cd - || exit 1
}

build_project() {
    local arch="$1"
    local config="$2"
    
    local build_path="$BUILD_DIR/$arch-$config"
    local install_path="$INSTALL_DIR/$arch"

    echo "Building project for $arch ($config) to $install_path"    
    mkdir -p "$build_path"
    cd "$build_path" || exit 1
    
    # Configure compiler flags
    local cmake_flags=""
    case "$arch" in
        "arm"|"aarch64")
            cmake_flags="\
                -DCMAKE_C_COMPILER=${COMPILER_PREFIX[$arch]}gcc \
                -DCMAKE_CXX_COMPILER=${COMPILER_PREFIX[$arch]}g++"
            ;;
        "x86")
            cmake_flags="\
                -DCMAKE_C_FLAGS=-m32 \
                -DCMAKE_CXX_FLAGS=-m32"
            ;;
        "x64")
            cmake_flags=""  # Default 64-bit
            ;;
    esac
    
    # Run CMake
    cmake \
        -DCMAKE_BUILD_TYPE="$config" \
        -DCMAKE_INSTALL_PREFIX:PATH="$install_path" \
        $cmake_flags \
        "$ROOT_DIR"
    if [ $? -ne 0 ]; then
        echo "CMake configuration failed for $arch ($config)"
        cd - || exit 1
        return 1
    fi
    
    cmake --build . --config "$config" -j32
    if [ $? -ne 0 ]; then
        echo "Build failed for $arch ($config)"
        cd - || exit 1
        return 1
    fi
    
    cmake --install . --config "$config"
    if [ $? -ne 0 ]; then
        echo "Installation failed for $arch ($config)"
        cd - || exit 1
        return 1
    fi
    
    cd - || exit 1
}

# ===========================================
# Clean function (unchanged)
# ===========================================
clean_builds() {
    read -p "Are you sure you want to clean old builds? (y/n): " answer
    if [ "$answer" = "y" ]; then
        rm -rf "$BUILD_DIR" "$INSTALL_DIR"
    fi
}
# clean_builds  # Uncomment to enable clean prompt

# ===========================================
# Main Build Process
# ===========================================
for arch in "${TARGET_ARCHES[@]}"; do
    # Set environment variables for dependency paths
    export OPENSSL_ROOT_DIR="$INSTALL_DIR/$arch"
    export nlohmann_json_DIR="$INSTALL_DIR/$arch/share/cmake/nlohmann_json/"

    for config in "${TARGET_CONFIGS[@]}"; do
        build_project "$arch" "$config"
    done
done

echo "All specified builds completed!"