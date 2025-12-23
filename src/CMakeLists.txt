project(src)
find_program(PATCH_EXE patch REQUIRED)

# --- 1. Library Build Options ---
option(LIBSTACK_BUILD_GTEST "Build GoogleTest" ON)
option(LIBSTACK_BUILD_PAHO "Build Paho MQTT C++" OFF)
option(LIBSTACK_BUILD_MOSQUITTO "Build Mosquitto" OFF)
option(LIBSTACK_BUILD_PROTOBUF "Build Protobuf" ON)
option(LIBSTACK_BUILD_SPDLOG "Build spdlog" ON)
option(LIBSTACK_BUILD_ZMQ "Build ZeroMQ and cppzmq" ON)
option(LIBSTACK_BUILD_JSON "Build nlohmann_json" OFF)
option(LIBSTACK_BUILD_JSONCONS "Build jsoncons" OFF)
option(LIBSTACK_BUILD_JWT "Build jwt-cpp" OFF)
option(LIBSTACK_BUILD_SOES "Build SOES (with Zynq SPI patch)" OFF)
option(LIBSTACK_BUILD_EIGEN "Build Eigen3" ON)
option(LIBSTACK_BUILD_SML "Build SML" ON)
option(LIBSTACK_BUILD_PUGIXML "Build pugixml" ON)
option(LIBSTACK_BUILD_MODBUS "Build libmodbus" OFF)
option(LIBSTACK_BUILD_SOEM "Build SOEM" OFF)
option(LIBSTACK_BUILD_HYPODERMIC "Build Hypodermic" ON)

# --- 2. Global Configurations ---
set(BUILD_TESTING OFF CACHE BOOL "" FORCE)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)

# --- 3. GoogleTest ---
if(LIBSTACK_BUILD_GTEST)
    add_subdirectory(googletest-1.15.2)
endif()

# --- 4. Paho MQTT C++ / Mosquitto ---

#TBD: under windows, mosquitto and paho.mqtt.cpp are not enabled together, an workaround is needed: first build mosquittio, then build paho.mqtt.cpp

if(LIBSTACK_BUILD_MOSQUITTO)
    set(WITH_TLS OFF CACHE BOOL "Include SSL/TLS support?")
    set(WITH_CJSON OFF CACHE BOOL "Include CJSON support?" FORCE)
    set(DOCUMENTATION OFF CACHE BOOL "Include documents support?" FORCE)
    set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)

    if(WIN32)
        set(WITH_THREADING OFF CACHE BOOL "Include threading support?" FORCE)
    endif()

    add_subdirectory(mosquitto-2.0.22)

    if(WIN32)
        target_link_libraries(mosquitto ws2_32 crypt32 secur32)
    endif()
endif()

if(LIBSTACK_BUILD_PAHO)
    set(PAHO_BUILD_STATIC ON CACHE BOOL "" FORCE)
    set(PAHO_BUILD_SHARED OFF CACHE BOOL "" FORCE)
    set(PAHO_WITH_SSL ON CACHE BOOL "" FORCE)
    set(PAHO_WITH_MQTT_C ON CACHE BOOL "" FORCE)
    add_subdirectory(paho.mqtt.cpp-1.5.3)
endif()

# --- 5. Protobuf ---
if(LIBSTACK_BUILD_PROTOBUF)
    set(protobuf_BUILD_TESTS OFF CACHE BOOL "" FORCE)

    if(MSVC)
        add_compile_options("/UPROTOBUF_USE_DLLS")
    endif()

    add_subdirectory(protobuf-4.25.8)
endif()

# --- 6. spdlog ---
if(LIBSTACK_BUILD_SPDLOG)
    set(SPDLOG_INSTALL ON CACHE BOOL "" FORCE)
    add_subdirectory(spdlog-1.16)
endif()

# --- 7. ZeroMQ & cppzmq ---
if(LIBSTACK_BUILD_ZMQ)
    set(ZMQ_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(BUILD_SHARED OFF CACHE BOOL "" FORCE)
    add_subdirectory(zeromq-4.3.5)

    set(CPPZMQ_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    add_subdirectory(cppzmq-4.11)
endif()


# --- 8. nlohmann_json ---
if(LIBSTACK_BUILD_JSON)
    set(JSON_BuildTests OFF CACHE BOOL "" FORCE)
    set(JSON_Install ON CACHE BOOL "" FORCE)
    add_subdirectory(json-3.12)
endif()

# --- 9. jsoncons ---
if(LIBSTACK_BUILD_JSONCONS)
    set(JSONCONS_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    add_subdirectory(jsoncons-1.3.1)
endif()

# --- 10. jwt-cpp ---
if(LIBSTACK_BUILD_JWT)
    set(JWT_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(JWT_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    add_subdirectory(jwt-cpp-0.7.0)
endif()

# --- 11. SOES with Patch ---
if(LIBSTACK_BUILD_SOES)
    execute_process(
        COMMAND ${PATCH_EXE} --dry-run -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/soes-3.1.0-zynq-spi.patch
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/SOES-3.1.0
        RESULT_VARIABLE patch_check
    )

    if(patch_check EQUAL 0)
        execute_process(
            COMMAND ${PATCH_EXE} -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/soes-3.1.0-zynq-spi.patch
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/SOES-3.1.0
        )
    endif()

    add_subdirectory(SOES-3.1.0)
endif()

# --- 12. Eigen, SML, Pugixml, Modbus ---
if(LIBSTACK_BUILD_EIGEN)
    add_subdirectory(eigen-3.4.1)
endif()

if(LIBSTACK_BUILD_SML)
    add_subdirectory(sml-1.1.13)
endif()

if(LIBSTACK_BUILD_PUGIXML)
    add_subdirectory(pugixml-1.15)
endif()

if(LIBSTACK_BUILD_MODBUS)
    add_subdirectory(modbus-3.1.11)
endif()

# --- 13. SOEM ---
if(LIBSTACK_BUILD_SOEM)
    if(WIN32)
        if(CMAKE_SIZEOF_VOID_P EQUAL 8)
            link_directories(SOEM-1.4.0/oshw/win32/wpcap/Lib/x64)
        else()
            link_directories(SOEM-1.4.0/oshw/win32/wpcap/Lib)
        endif()
    endif()

    add_subdirectory(SOEM-1.4.0)
endif()

# --- 14. Hypodermic ---
if(LIBSTACK_BUILD_HYPODERMIC)
    set(Hypodermic_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    add_subdirectory(Hypodermic-2.5.3)
endif()

# --- Summary Printout ---
message(STATUS "--------------------------------------------")
message(STATUS " libstack Build Summary:")
message(STATUS "   Paho MQTT:    ${LIBSTACK_BUILD_PAHO}")
message(STATUS "   Protobuf:     ${LIBSTACK_BUILD_PROTOBUF}")
message(STATUS "   ZeroMQ:       ${LIBSTACK_BUILD_ZMQ}")
message(STATUS "   SOES (Patch): ${LIBSTACK_BUILD_SOES}")
message(STATUS "   SOEM:         ${LIBSTACK_BUILD_SOEM}")
message(STATUS "--------------------------------------------")