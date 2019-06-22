project(md5)

file(GLOB MD5_H *.h)
file(GLOB MD5_C *.c)

include_directories(.)
include_directories(../../3rd/lua)
include_directories(../../skynet-src/)
if (MSVC)
	include_directories(../../3rd/posix)
endif (MSVC)

if (MSVC)
	add_definitions(-DLUA_BUILD_AS_DLL)
	add_definitions(-DNOUSE_JEMALLOC -DHAVE_STRUCT_TIMESPEC)
else (MSVC)
	set (CMAKE_C_FLAGS "-std=gnu99 -Wall")
	set (CMAKE_C_FLAGS_DEBUG "-g -O0")
	set (CMAKE_CXX_FLAGS "-std=c++11 -Wall")
	set (CMAKE_CXX_FLAGS_DEBUG "-g -O0")
endif ()

if (CMAKE_BUILD_TYPE MATCHES "Debug")
	add_definitions(-D_DEBUG)
endif()

# target
add_library(md5 SHARED ${MD5_H} ${MD5_C})
set_target_properties(md5
	PROPERTIES
	PREFIX ""
	SUFFIX ".so"
	FOLDER "3rd"
	RUNTIME_OUTPUT_DIRECTORY ../../../luaclib
	RUNTIME_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
	ARCHIVE_OUTPUT_DIRECTORY ../../../luaclib
	ARCHIVE_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
)

if (MSVC)
	target_link_libraries(md5 ws2_32 ../../../strawberry)
endif(MSVC)

add_dependencies(md5 strawberry)
