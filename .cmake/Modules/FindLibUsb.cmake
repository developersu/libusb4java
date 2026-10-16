# This module defines:
#
#   LibUsb_LIBRARIES         : The libraries to link against
#   LibUsb_INCLUDE_DIRS      : The directories to include
#
# pkg-config is used when available and CMAKE_SHARED_LINKER_FLAGS
# is filled with additional flags reported by it.
#
# When no pkg-config is found then the library is searched within the
# standard directories.
#
# When library was not found then you can define the following variables
# to help locate it:
#
#   LibUsb_LIBRARY_HINTS : List of libraries directory to search in
#   LibUsb_INCLUDE_HINTS : List of include directories to search in
#
# Alternatively you can manually override the locations:
#
#   LibUsb_LIBRARIES   : List of libraries to link against
#   LibUsb_INCLUDE_DIR : The include directory containing libusb.h
#
# Additionally the following variables can be defined:
#
#   LibUsb_LDFLAGS         : Additional linker flags to use
#   LibUsb_USE_STATIC_LIBS : Set to true to prefer static linking
#
# ============================================================================
# Copyright (C) 2015 Klaus Reimer (k@ailis.de)
# See COPYING file for copying conditions.
# ============================================================================

if(DEFINED ENV{LIBUSB_ROOT})
    set(LibUsb_LIBRARY_HINTS "$ENV{LIBUSB_ROOT}/lib")
    set(LibUsb_INCLUDE_HINTS "$ENV{LIBUSB_ROOT}/include")
endif()

# Change the find-library suffix order in case we prefer to use static libs
set(LibUsb_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES})
if (LibUsb_USE_STATIC_LIBS)
    if(WIN32)
        set(CMAKE_FIND_LIBRARY_SUFFIXES .lib .a ${CMAKE_FIND_LIBRARY_SUFFIXES})
    else()
        set(CMAKE_FIND_LIBRARY_SUFFIXES .a ${CMAKE_FIND_LIBRARY_SUFFIXES})
    endif()
endif()

# find_library prepends CMAKE_FIND_LIBRARY_PREFIXES to each name. On Unix that
# prefix is "lib", so the unprefixed name "usb-1.0" resolves to libusb-1.0.{a,so,
# dylib}. On Windows the prefix is empty, so the name must already carry the "lib"
# prefix ("libusb-1.0") to resolve to libusb-1.0.lib.
if(WIN32)
    set(LibUsb_LIBRARY_NAMES "libusb-1.0")
else()
    set(LibUsb_LIBRARY_NAMES "usb-1.0")
endif()

# Search libraries and include directories with pkg-config when possible
find_package(PkgConfig QUIET)
if(PKG_CONFIG_FOUND)
    pkg_check_modules(PkgConfigLibUsb libusb-1.0)
    if (PkgConfigLibUsb_FOUND)
        if(LibUsb_USE_STATIC_LIBS)
            # Static: leave LibUsb_LIBRARY_NAMES as "libusb-1.0" (set above) so that
            # find_library (with the .a/.lib suffix preference set above) plus the
            # LIBUSB_ROOT hints locate libusb-1.0.a / libusb-1.0.lib. Do NOT use
            # PkgConfigLibUsb_STATIC_LIBRARIES: libusb's .pc has no Static-Libraries
            # field and pkg_check_modules was not called with STATIC, so it is empty
            # and would break the search. Also do not clobber LibUsb_LDFLAGS or the
            # LIBUSB_ROOT hints here.
        else()
            set(LibUsb_LIBRARY_NAMES ${PkgConfigLibUsb_LIBRARIES})
            set(LibUsb_INCLUDE_HINTS ${PkgConfigLibUsb_INCLUDE_DIRS})
            set(LibUsb_LIBRARY_HINTS ${PkgConfigLibUsb_LIBRARY_DIRS})
            set(LibUsb_LDFLAGS ${PkgConfigLibUsb_LDFLAGS_OTHER})
        endif()
    endif()
endif()

# Set additional LDFLAGS
foreach(FLAG IN LISTS LibUsb_LDFLAGS)
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${FLAG}")
endforeach()

# Search for the libraries if not specified manually
if(NOT LibUsb_LIBRARIES)
    foreach(LIB IN LISTS LibUsb_LIBRARY_NAMES)
        find_library(LIB_LOCATION
            NAMES
                ${LIB}
            HINTS
                ${LibUsb_LIBRARY_HINTS}
        )
        list(APPEND LibUsb_LIBRARIES ${LIB_LOCATION})
        unset(LIB_LOCATION CACHE)
    endforeach()
endif()

# Search for the include directory if not specified manually
if(NOT LibUsb_INCLUDE_DIRS)
    find_path(LibUsb_INCLUDE_DIR
        NAMES
            libusb.h
        HINTS
            ${LibUsb_INCLUDE_HINTS}
        PATH_SUFFIXES
            libusb-1.0
    )
    set(LibUsb_INCLUDE_DIRS ${LibUsb_INCLUDE_DIR})
endif()

# Restore the original find-library suffixes
set(CMAKE_FIND_LIBRARY_SUFFIXES ${LibUsb_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES})

# Output search status
if(LibUsb_LIBRARIES)
    message(STATUS "Found libusb: ${LibUsb_LIBRARIES}")
else()
    message(FATAL_ERROR "libusb NOT FOUND! Try defining LibUsb_LIBRARIES manually")
endif()
if (LibUsb_INCLUDE_DIRS)
    message(STATUS "Found libusb include directory: ${LibUsb_INCLUDE_DIRS}")
else()
    message(FATAL_ERROR "libusb include directory NOT FOUND! Try defining LibUsb_INCLUDE_DIRS manually")
endif()
