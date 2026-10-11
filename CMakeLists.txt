cmake_minimum_required(VERSION 3.14)

project(usb4java C)
set(PROJECT_VERSION 1.3.1)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/.cmake/Modules/")

find_package(JNI REQUIRED)
find_package(LibUsb REQUIRED)

include_directories(${JNI_INCLUDE_DIRS})
include_directories(${LibUsb_INCLUDE_DIRS})

if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang|AppleClang")
    set(CMAKE_C_FLAGS_RELEASE "-O2 -DNDEBUG")
endif()

if(CMAKE_COMPILER_IS_GNUCC)
    add_definitions(-Wall -Werror -std=c99)
endif()

add_subdirectory(src)
