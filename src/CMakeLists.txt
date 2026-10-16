file(GLOB_RECURSE USB4JAVA_SOURCES *.c)
add_library(usb4java SHARED ${USB4JAVA_SOURCES})
# On Unix the .so/.dylib is a library artifact (LIBRARY_OUTPUT_DIRECTORY). On
# Windows the .dll is a RUNTIME artifact and its import .lib uses
# IMPORT_LIBRARY_OUTPUT_DIRECTORY, so set all of them to keep the artifact in
# <binary>/out for every generator/config.
set_target_properties(usb4java PROPERTIES
    PREFIX                                 "lib"
    LIBRARY_OUTPUT_DIRECTORY               ${CMAKE_BINARY_DIR}/out
    LIBRARY_OUTPUT_DIRECTORY_RELEASE       ${CMAKE_BINARY_DIR}/out
    RUNTIME_OUTPUT_DIRECTORY               ${CMAKE_BINARY_DIR}/out
    RUNTIME_OUTPUT_DIRECTORY_RELEASE       ${CMAKE_BINARY_DIR}/out
    IMPORT_LIBRARY_OUTPUT_DIRECTORY        ${CMAKE_BINARY_DIR}/out
    IMPORT_LIBRARY_OUTPUT_DIRECTORY_RELEASE ${CMAKE_BINARY_DIR}/out
)
target_link_libraries(usb4java ${LibUsb_LIBRARIES})
if(CMAKE_COMPILER_IS_GNUCC)
  set_target_properties(usb4java PROPERTIES LINK_FLAGS -static-libgcc)
endif()
install(TARGETS usb4java DESTINATION lib)
