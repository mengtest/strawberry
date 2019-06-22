include skynet/Makefile

LUA_CLIB = skynet \
  client \
  bson md5 sproto lpeg $(TLS_MODULE) \
  aoi

$(LUA_CLIB_PATH)/aoi.so : lualib-src/aoi/aoi.c lualib-src/aoi/lua-aoi.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -Ilualib-src/aoi $^ -o $@ 
