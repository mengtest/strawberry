project(chestnut)

SET(CHESTNUT_H ./snapshot.h)
aux_source_directory(. CHESTNUT_C)
list(REMOVE_ITEM CHESTNUT_C ./lua-fixedptmath.c)

#SET(AABB_H ./aabb/CCAABB.h)
#SET(AABB_CC ./aabb/CCAABB.cc ./aabb/lua-aabb.cc)
SET(AOI_H ./aoi/aoi.h)
SET(AOI_C ./aoi/aoi.c ./aoi/lua-aoi.c) 
SET(SSL_H ./ssock/ssock.h ./ssock/sssl.h)
SET(SSL_C ./ssock/ssock.c ./ssock/sssl.c ./ssock/lua-ssock.c) 
SET(SKIPLIST_H ./skiplist/skiplist.h)
SET(SKIPLIST_C ./skiplist/skiplist.c ./skiplist/lua-skiplist.c)

IF(MSVC)

source_group("src" FILES ${CHESTNUT_H} ${CHESTNUT_C})
#source_group("aabb" FILES ${AABB_H} ${AABB_CC})
source_group("aoi" FILES ${AOI_H} ${AOI_C})
source_group("ssl" FILES ${SSL_H} ${SSL_C})
source_group("skiplist" FILES ${SKIPLIST_H} ${SKIPLIST_C})
ENDIF(MSVC)

include_directories(.)
include_directories(aabb)
include_directories(aoi)
include_directories(cjson)
include_directories(crab)
include_directories(rudp)
include_directories(../../foundation)
include_directories(../../foundation/libfixmath/libfixmath)
include_directories(../../3rd/lua)
include_directories(../../skynet-src)

IF(MSVC)
include_directories(../../3rd/openssl/include)
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

link_libraries(crypto)
link_libraries(ssl)

ENDIF(MSVC)

IF(CMAKE_BUILD_TYPE MATCHES "Debug")
ADD_DEFINITIONS(-D_DEBUG)
ENDIF()

add_library(chestnut SHARED ${CHESTNUT_H} ${CHESTNUT_C} ${AOI_H} ${AOI_C} ${SSL_H} ${SSL_C} ${SKIPLIST_H} ${SKIPLIST_C})

set_target_properties(chestnut PROPERTIES PREFIX "")
set_target_properties(chestnut PROPERTIES SUFFIX ".so")

IF(MSVC)
set_target_properties(chestnut PROPERTIES FOLDER "lualib") 
set_target_properties(chestnut PROPERTIES ARCHIVE_OUTPUT_DIRECTORY_DEBUG ../../../luaclib)
set_target_properties(chestnut PROPERTIES RUNTIME_OUTPUT_DIRECTORY_DEBUG ../../../luaclib)

IF(CMAKE_CL_64)
#target_link_libraries(chestnut ../../../libbase)
target_link_libraries(chestnut ws2_32 ../../../strawberry)
target_link_libraries(chestnut ../../../3rd/openssl/libcrypto ../../../3rd/openssl/libssl)
ENDIF(CMAKE_CL_64)
ELSE(MSVC)

SET(EXECUTABLE_OUTPUT_PATH ../../../luaclib)
SET(LIBRARY_OUTPUT_PATH ../../../luaclib)

# linux
ENDIF()

ADD_DEPENDENCIES(chestnut xloggerd)
