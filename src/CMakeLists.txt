file(GLOB_RECURSE USB4JAVA_SOURCES *.c)
add_library(usb4java SHARED ${USB4JAVA_SOURCES})
set_target_properties(usb4java PROPERTIES
    PREFIX                                 "lib"
    LIBRARY_OUTPUT_DIRECTORY               ${CMAKE_BINARY_DIR}/out
    LIBRARY_OUTPUT_DIRECTORY_RELEASE       ${CMAKE_BINARY_DIR}/out
)
target_link_libraries(usb4java ${LibUsb_LIBRARIES})
if(CMAKE_COMPILER_IS_GNUCC)
  set_target_properties(usb4java PROPERTIES LINK_FLAGS -static-libgcc)
endif()
install(TARGETS usb4java DESTINATION lib)
