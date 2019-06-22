project(math3d)

SET(MATH3D_H ./math3d.h ./CCAABB.h)
SET(MATH3D_C ./lua-math.c ./CCAABB.cc) 

include_directories(../../3rd/lua)
include_directories(../../skynet-src)

IF(MSVC)
include_directories(../../3rd/pthread-win32)
include_directories(../../3rd/posix)
ADD_DEFINITIONS(-DLUA_BUILD_AS_DLL)
ADD_DEFINITIONS(-DNOUSE_JEMALLOC -DHAVE_STRUCT_TIMESPEC -DUSE_PTHREAD_LOCK -D_CRT_SECURE_NO_WARNINGS)

ELSE(MSVC)
ADD_DEFINITIONS(-Wno-unused-function -Wno-unused-variable -Werror)
SET(CMAKE_C_FLAGS "-Wall -std=gnu99")
SET(CMAKE_C_FLAGS_DEBUG "-g -O0")
SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -std=c++11")
SET(CMAKE_CXX_FLAGS_DEBUG "-g -O0")
ENDIF(MSVC)

IF(CMAKE_BUILD_TYPE MATCHES "Debug")
ADD_DEFINITIONS(-D_DEBUG)
ENDIF()

add_library(math3d SHARED ${MATH3D_H} ${MATH3D_C})
set_target_properties(math3d PROPERTIES PREFIX "")
set_target_properties(math3d PROPERTIES SUFFIX ".so")
set_target_properties(math3d PROPERTIES ARCHIVE_OUTPUT_DIRECTORY_DEBUG ../../../luaclib)
set_target_properties(math3d PROPERTIES RUNTIME_OUTPUT_DIRECTORY_DEBUG ../../../luaclib)

IF(MSVC)
set_target_properties(math3d PROPERTIES FOLDER "lualib")
IF(CMAKE_CL_64)
target_link_libraries(math3d ws2_32 ../../../strawberry)
ENDIF(CMAKE_CL_64)
ELSE(MSVC)
ENDIF()

ADD_DEPENDENCIES(math3d strawberry)
