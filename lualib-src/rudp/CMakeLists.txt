project(rudp)

include_directories(../../3rd/lua)
include_directories(../../skynet-src)

IF(MSVC)
	include_directories(../../3rd/pthread-win32)
	include_directories(../../skynet-src/posix)
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

SET(RUDP_H ./rudp.h)
SET(RUDP_C ./rudp.c ./lua-rudp.c)
add_library(rudp SHARED ${RUDP_H} ${RUDP_C})
set_target_properties(rudp PROPERTIES PREFIX "")
set_target_properties(rudp PROPERTIES SUFFIX ".so")
set_target_properties(rudp PROPERTIES FOLDER "lualib")
set_target_properties(rudp PROPERTIES
	RUNTIME_OUTPUT_DIRECTORY ../../../luaclib
	RUNTIME_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
	ARCHIVE_OUTPUT_DIRECTORY ../../../luaclib
	ARCHIVE_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
    LIBRARY_OUTPUT_DIRECTORY ../../../luaclib
    LIBRARY_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
)

IF(MSVC)
	target_link_libraries(rudp ws2_32 ../../../strawberry)
ENDIF()

add_dependencies(rudp strawberry)


SET(RUDP_H ./rudp.h)
SET(RUDP_C ./rudp.c ./main.c)
add_executable(rudptest ${RUDP_H} ${RUDP_C})
set_target_properties(rudptest
	PROPERTIES
	FOLDER "test"
	RUNTIME_OUTPUT_DIRECTORY ../../..
	RUNTIME_OUTPUT_DIRECTORY_DEBUG ../../..
	ARCHIVE_OUTPUT_DIRECTORY ../../..
	ARCHIVE_OUTPUT_DIRECTORY_DEBUG ../../..
	ARCHIVE_OUTPUT_DIRECTORY_RELEASE ../../..)

IF(MSVC)
	target_link_libraries(rudptest ws2_32)
ENDIF()
