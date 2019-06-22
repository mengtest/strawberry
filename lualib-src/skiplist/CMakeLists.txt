project(skiplist)

include_directories(.)
include_directories(../../3rd/lua)
include_directories(../../skynet-src)

IF(MSVC)
	include_directories(../../3rd/pthread-win32)
	include_directories(../../3rd/posix)
	ADD_DEFINITIONS(-DLUA_BUILD_AS_DLL)
	ADD_DEFINITIONS(-DNOUSE_JEMALLOC -DHAVE_STRUCT_TIMESPEC -D_CRT_SECURE_NO_WARNINGS)
ELSE(MSVC)
	set (CMAKE_C_FLAGS "-std=gnu99 -Wall -fPIC --shared -Werror")
	set (CMAKE_C_FLAGS_DEBUG "-g -O0")
	set (CMAKE_CXX_FLAGS "-std=c++11 -Wall -fPIC --shared -Werror")
	set (CMAKE_CXX_FLAGS_DEBUG "-g -O0")
ENDIF(MSVC)

IF(CMAKE_BUILD_TYPE MATCHES "Debug")
	ADD_DEFINITIONS(-D_DEBUG)
ENDIF()

SET(SKIPLIST_H ./skiplist.h)
SET(SKIPLIST_C ./skiplist.c ./lua-skiplist.c)
add_library(skiplist SHARED ${SKIPLIST_H} ${SKIPLIST_C})
set_target_properties(skiplist PROPERTIES PREFIX "")
set_target_properties(skiplist PROPERTIES SUFFIX ".so")
set_target_properties(skiplist PROPERTIES FOLDER "lualib")
set_target_properties(skiplist PROPERTIES
	RUNTIME_OUTPUT_DIRECTORY ../../../luaclib
	RUNTIME_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
	ARCHIVE_OUTPUT_DIRECTORY ../../../luaclib
	ARCHIVE_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
    LIBRARY_OUTPUT_DIRECTORY ../../../luaclib
    LIBRARY_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
)

IF(MSVC)
	target_link_libraries(skiplist ws2_32 ../../../strawberry)
ENDIF()

add_dependencies(skiplist strawberry)
