cmake_minimum_required(VERSION 3.23)

# 1. Force minimum policy version to 3.5 globally to fix ZeroMQ/older libs
set(CMAKE_POLICY_VERSION_MINIMUM 3.5)

# Ensure CMP0091 is set before project() to enable CMAKE_MSVC_RUNTIME_LIBRARY
cmake_policy(SET CMP0091 NEW)

project(libstack LANGUAGES C CXX)

# --- 1. Basic Compilation Settings ---
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF) # Improve cross-platform compatibility
set(CMAKE_DEBUG_POSTFIX "d")

# Enable folder organization for Visual Studio users
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

# --- 2. MSVC Runtime Library & Encoding ---
if(MSVC)
    # Force Static Runtime (MT/MTd)
    # Uses generator expressions to select MTd for Debug and MT for others
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    
    # Force UTF-8 encoding for source and execution
    add_compile_options("$<$<C_COMPILER_ID:MSVC>:/utf-8>")
endif()

# --- 3. Directory & Output Management ---
include(GNUInstallDirs)

# Centralize output directories for all subprojects
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_BINDIR})

# Flatten output for multi-config generators (like Visual Studio)
foreach(OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES})
    string(TOUPPER ${OUTPUTCONFIG} OUTPUTCONFIG)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_BINDIR})
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR})
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR})
endforeach()

# --- 4. Debug Symbols (PDB) Management ---
if(MSVC)
    set(pdb_output_dir "${CMAKE_BINARY_DIR}/pdb")
    set(CMAKE_PDB_OUTPUT_DIRECTORY "${pdb_output_dir}")
    set(CMAKE_COMPILE_PDB_OUTPUT_DIRECTORY "${pdb_output_dir}")
endif()

# --- 5. Source Subdirectory (MOVE THIS UP) ---
# Subprojects must be added first so they can register themselves to the export set
add_subdirectory(src)

