project(chestnut)

# include
include_directories(../../foundation)
include_directories(../../3rd/lua)
include_directories(../../skynet-src)
IF(MSVC)
	include_directories(../../3rd/pthread-win32/include)
	include_directories(../../skynet-src/posix)
ENDIF(MSVC)

# definitions
IF(MSVC)
	add_definitions(-DLUA_BUILD_AS_DLL)
	#add_definitions(-DUSE_PTHREAD_LOCK)
	add_definitions(-DNOUSE_JEMALLOC -DHAVE_STRUCT_TIMESPEC -D_CRT_SECURE_NO_WARNINGS)
ELSE(MSVC)
	SET(CMAKE_C_FLAGS "-std=gnu99 -Wall -fPIC --shared")
	SET(CMAKE_C_FLAGS_DEBUG "-g -O0")
	SET(CMAKE_CXX_FLAGS "-std=c++11 -Wall -fPIC --shared")
	SET(CMAKE_CXX_FLAGS_DEBUG "-g -O0")
ENDIF(MSVC)

IF(CMAKE_BUILD_TYPE MATCHES "Debug")
	add_definitions(-D_DEBUG)
ENDIF()

add_definitions(-DSKYNET)

# target
SET(CHESTNUT_H ./snapshot.h ./math3d.h)
aux_source_directory(. CHESTNUT_C)
add_library(chestnut SHARED ${CHESTNUT_H} ${CHESTNUT_C})
set_target_properties(chestnut PROPERTIES PREFIX "")
set_target_properties(chestnut PROPERTIES SUFFIX ".so")
set_target_properties(chestnut PROPERTIES FOLDER "lualib")
set_target_properties(chestnut PROPERTIES
	RUNTIME_OUTPUT_DIRECTORY ../../../luaclib
	RUNTIME_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
	ARCHIVE_OUTPUT_DIRECTORY ../../../luaclib
	ARCHIVE_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
    LIBRARY_OUTPUT_DIRECTORY ../../../luaclib
    LIBRARY_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
)

if(MSVC)
	target_link_libraries(chestnut ws2_32 ../../../strawberry)
	target_link_libraries(chestnut ../../../3rd/pthread-win32/lib/pthread_lib)
endif()

#target_link_directories(chestnut PUBLIC ../../..)
#link_directories(../..)
#target_link_libraries(chestnut libfixedptmath)

add_dependencies(chestnut strawberry)
