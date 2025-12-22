#!/bin/bash

# ===========================================
# Configuration
# ===========================================
SCRIPT_DIR=$(dirname "$(realpath "$0")")
# Build and install directories
BUILD_DIR="$SCRIPT_DIR/build"
INSTALL_DIR="$SCRIPT_DIR/install"

# Architectures and configurations
ARCHITECTURES=("arm" "aarch64" "x86" "x64")
CONFIGURATIONS=("Release")

# Cross-compiler prefixes (adjust based on your setup)
declare -A COMPILER_PREFIX=(
    ["arm"]="arm-linux-gnueabihf-"
    ["aarch64"]="aarch64-linux-gnu-"
    ["x86"]=""  # Native x86 (uses -m32)
    ["x64"]=""  # Native x64 (default)
)

# ===========================================
# Build for a specific architecture/config
# ===========================================
build_json() {
    local arch="$1"
    local config="$2"
    
    local build_path="$BUILD_DIR/$arch-$config/json"
    local install_path="$INSTALL_DIR/$arch"
    local json_path="$SCRIPT_DIR/src/json-3.11.3"

    echo "Building for $arch ($config) for $json_path and install to ($install_path)"    
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
    
    # Run CMake (top-level CMakeLists.txt includes src/)
    cmake \
        -DJSON_Install=ON \
        -DJSON_BuildTests=OFF \
        -DCMAKE_BUILD_TYPE="$config" \
        -DCMAKE_INSTALL_PREFIX:PATH="$install_path" \
        $cmake_flags \
        "$json_path"
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
# Build for a specific architecture/config
# ===========================================
build_project() {
    local arch="$1"
    local config="$2"
    
    local build_path="$BUILD_DIR/$arch-$config"
    local install_path="$INSTALL_DIR/$arch"

    echo "Building for $arch ($config)... and install to ($install_path)"    
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
    
    # Run CMake (top-level CMakeLists.txt includes src/)
    cmake \
        -DCMAKE_BUILD_TYPE="$config" \
        -DCMAKE_INSTALL_PREFIX:PATH="$install_path" \
        $cmake_flags \
        "$SCRIPT_DIR"
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
# Main Script
# ===========================================
# Clean old builds (optional)
clean_builds() {
    read -p "Are you sure you want to clean old builds? (y/n): " answer
    if [ "$answer" = "y" ]; then
        rm -rf "$BUILD_DIR" "$INSTALL_DIR"
    fi
}
# clean_builds

# Build all combinations
for arch in "${ARCHITECTURES[@]}"; do
    unset OPENSSL_ROOT_DIR
    OPENSSL_ROOT_DIR="$INSTALL_DIR/$arch"
    export OPENSSL_ROOT_DIR

    unset nlohmann_json_DIR    
    nlohmann_json_DIR="$INSTALL_DIR/$arch/share/cmake/nlohmann_json/"
    export nlohmann_json_DIR

    for config in "${CONFIGURATIONS[@]}"; do
        build_json "$arch" "$config"
        build_project "$arch" "$config"
    done
done

echo "All builds completed!"
