project(rapidjson)

include_directories(../../3rd/lua)
include_directories(include)

IF(MSVC)
	add_definitions(-DLUA_BUILD_AS_DLL)
	add_definitions(-DNOUSE_JEMALLOC -DHAVE_STRUCT_TIMESPEC)
ELSE(MSVC)
	SET(CMAKE_C_FLAGS "-std=gnu99 -Wall -fPIC --shared")
	SET(CMAKE_C_FLAGS_DEBUG "-g -O0")
	SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -Wall -fPIC --shared")
	SET(CMAKE_CXX_FLAGS_DEBUG "-g -O0")
ENDIF()

IF(CMAKE_BUILD_TYPE MATCHES "Debug")
	add_definitions(-D_DEBUG)
ENDIF()

# target
file(GLOB RAPIDJSON_HXX *.hpp)
file(GLOB RAPIDJSON_CXX *.cpp)
add_library(rapidjson SHARED ${RAPIDJSON_HXX} ${RAPIDJSON_CXX})

set_target_properties(rapidjson PROPERTIES PREFIX "")
set_target_properties(rapidjson PROPERTIES SUFFIX ".so")
set_target_properties(rapidjson PROPERTIES FOLDER "lualib")
set_target_properties(rapidjson PROPERTIES
	RUNTIME_OUTPUT_DIRECTORY ../../../luaclib
	RUNTIME_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
	ARCHIVE_OUTPUT_DIRECTORY ../../../luaclib
	ARCHIVE_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
    LIBRARY_OUTPUT_DIRECTORY ../../../luaclib
    LIBRARY_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
)

IF(MSVC)
	target_link_libraries(rapidjson ws2_32 ../../../strawberry)
ENDIF()

add_dependencies(rapidjson strawberry)
