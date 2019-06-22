project(aoi)

set (AOI_H ./aoi.h)
set (AOI_C ./aoi.c ./lua-aoi.c)

include_directories(../../3rd/lua)
include_directories(../../skynet-src)
if (MSVC)
include_directories(../../3rd/pthread-win32)
include_directories(../../3rd/posix)
endif (MSVC)

if (MSVC)
	add_definitions(-DLUA_BUILD_AS_DLL)
	add_definitions(-DNOUSE_JEMALLOC -DHAVE_STRUCT_TIMESPEC -D_CRT_SECURE_NO_WARNINGS)
else (MSVC)
	set (CMAKE_C_FLAGS "-std=gnu99 -Wall -fPIC --shared")
	set (CMAKE_C_FLAGS_DEBUG "-g -O0")
	set (CMAKE_CXX_FLAGS "-std=c++11 -Wall -fPIC --shared")
	set (CMAKE_CXX_FLAGS_DEBUG "-g -O0")
endif (MSVC)

if (CMAKE_BUILD_TYPE MATCHES "Debug")
	add_definitions(-D_DEBUG)
endif()

add_library(aoi SHARED ${AOI_H} ${AOI_C})
set_target_properties(aoi PROPERTIES PREFIX "")
set_target_properties(aoi PROPERTIES SUFFIX ".so")
set_target_properties(aoi PROPERTIES FOLDER "lualib")
set_target_properties(aoi PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
    ARCHIVE_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
    LIBRARY_OUTPUT_DIRECTORY ../../../luaclib
    LIBRARY_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
)
if (MSVC)
	target_link_libraries(aoi ws2_32 ../../../strawberry)
endif (MSVC)
#target_link_libraries(aoi ../../../libbase)

add_dependencies(aoi strawberry)
