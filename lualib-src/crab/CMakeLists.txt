project(crab)

include_directories(../../3rd/lua)
include_directories(../../skynet-src)
IF(MSVC)
	include_directories(../../3rd/pthread-win32)
	include_directories(../../3rd/posix)
ENDIF(MSVC)

IF(MSVC)
	ADD_DEFINITIONS(-DLUA_BUILD_AS_DLL)
	ADD_DEFINITIONS(-DNOUSE_JEMALLOC -DHAVE_STRUCT_TIMESPEC -D_CRT_SECURE_NO_WARNINGS)
ELSE(MSVC)
	set (CMAKE_C_FLAGS "-std=gnu99 -Wall -fPIC --shared")
	set (CMAKE_C_FLAGS_DEBUG "-g -O0")
	set (CMAKE_CXX_FLAGS "-std=c++11 -Wall -fPIC --shared")
	set (CMAKE_CXX_FLAGS_DEBUG "-g -O0")
ENDIF(MSVC)

IF(CMAKE_BUILD_TYPE MATCHES "Debug")
	add_definitions(-D_DEBUG)
ENDIF()

SET(CRAB_C ./lua-crab.c ./lua-utf8.c)
add_library(crab SHARED ${CRAB_C})
set_target_properties(crab PROPERTIES PREFIX "")
set_target_properties(crab PROPERTIES SUFFIX ".so")
set_target_properties(crab PROPERTIES FOLDER "lualib")
set_target_properties(crab PROPERTIES
	RUNTIME_OUTPUT_DIRECTORY ../../../luaclib
	RUNTIME_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
	ARCHIVE_OUTPUT_DIRECTORY ../../../luaclib
	ARCHIVE_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
    LIBRARY_OUTPUT_DIRECTORY ../../../luaclib
    LIBRARY_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
)

IF(MSVC)
	target_link_libraries(crab ws2_32 ../../../strawberry)
ENDIF()

add_dependencies(crab strawberry)
