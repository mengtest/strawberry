project(sssl)

include_directories(../../3rd)
include_directories(../../3rd/lua)
include_directories(../../3rd/openssl/include)
include_directories(../../skynet-src)

IF(MSVC)
	include_directories(../../3rd/pthread-win32/include)
	include_directories(../../skynet-src/posix)
ELSE(MSVC)
	set (CMAKE_C_FLAGS "-std=gnu99 -Wall -Wextra -Werror")
	set (CMAKE_C_FLAGS_DEBUG "-g -O0")
	set (CMAKE_CXX_FLAGS "-std=c++11 -Wall -Wextra -Werror")
	set (CMAKE_CXX_FLAGS_DEBUG "-g -O0")
ENDIF(MSVC)

IF(CMAKE_BUILD_TYPE MATCHES "Debug")
	add_definitions(-D_DEBUG)
ENDIF()

SET(SSL_H ./sssl.h ./write_buffer.h ./protoc.h)
SET(SSL_C ./sssl.c ./write_buffer.c ./lua-sssl.c)
add_library(sssl SHARED ${SSL_H} ${SSL_C})
add_dependencies(sssl strawberry)
set_target_properties(sssl
	PROPERTIES
	PREFIX ""
	SUFFIX ".so"
	FOLDER "lualib"
	RUNTIME_OUTPUT_DIRECTORY ../../../luaclib
	RUNTIME_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
	ARCHIVE_OUTPUT_DIRECTORY ../../../luaclib
	ARCHIVE_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
	LIBRARY_OUTPUT_DIRECTORY ../../../luaclib
    LIBRARY_OUTPUT_DIRECTORY_DEBUG ../../../luaclib
)

IF(MSVC)
	target_compile_definitions(sssl PRIVATE LUA_BUILD_AS_DLL)
	target_compile_definitions(sssl PRIVATE DNOUSE_JEMALLOC HAVE_STRUCT_TIMESPEC USE_PTHREAD_LOCK _CRT_SECURE_NO_WARNINGS)
	target_link_libraries(sssl ws2_32 ../../../strawberry)
	target_link_libraries(sssl ../../../3rd/openssl/lib/libcrypto ../../../3rd/openssl/lib/libssl)
	target_link_libraries(sssl ../../../3rd/pthread-win32/lib/pthread_lib)
ELSE(MSVC)
	find_library(CRYPTO_LIB libcrypto.a ../../3rd/openssl/lib NO_DEFAULT_PATH)
	find_library(SSL_LIB libssl.a ../../3rd/openssl/lib NO_DEFAULT_PATH)
	message(${CRYPTO_LIB})
    target_link_libraries(sssl ${CRYPTO_LIB} ${SSL_LIB})
    # target_link_libraries(ssock crypto ssl)
ENDIF()




SET(SSSLTEST_H ./stringx.h ./urlparser.h ./sssl_test.h ./sssl.h ./write_buffer.h ./protoc.h)
SET(SSSLTEST_C ./sssl_test.c ./sssl.c ./write_buffer.c)
add_executable(sssltest ${SSSLTEST_H} ${SSSLTEST_C})
set_target_properties(sssltest
	PROPERTIES#
	FOLDER "test"
	RUNTIME_OUTPUT_DIRECTORY ../../..
	RUNTIME_OUTPUT_DIRECTORY_DEBUG ../../..
	ARCHIVE_OUTPUT_DIRECTORY ../../..
	ARCHIVE_OUTPUT_DIRECTORY_DEBUG ../../..
	LIBRARY_OUTPUT_DIRECTORY ../../..
    LIBRARY_OUTPUT_DIRECTORY_DEBUG ../../..
)

IF(MSVC)
	target_compile_definitions(sssltest PRIVATE _CRT_SECURE_NO_WARNINGS)
	target_link_libraries(sssltest ../../../3rd/openssl/lib/libcrypto ../../../3rd/openssl/lib/libssl)
ELSE(MSVC)
	find_library(CRYPTO_LIB libcrypto.a ../../3rd/openssl/lib NO_DEFAULT_PATH)
	find_library(SSL_LIB libssl.a ../../3rd/openssl/lib NO_DEFAULT_PATH)
	message(${CRYPTO_LIB})
    target_link_libraries(sssltest ${CRYPTO_LIB} ${SSL_LIB})
    # target_link_libraries(ssock crypto ssl)
ENDIF()
