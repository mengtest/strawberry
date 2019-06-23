include skynet/platform.mk

LUA_CLIB_PATH ?= luaclib
CSERVICE_PATH ?= cservice

CFLAGS = -g -O2 -Wall -I$(LUA_INC) $(MYCFLAGS)

LUA_INC ?= skynet/3rd/lua

skynet/Makefile :
	git submodule update --init

skynet/skynet : skynet/Makefile
	cd skynet && $(MAKE) $(PLAT)

strawberry : skynet/skynet
	cp skynet/skynet strawberry

update3rd :
	rm -rf skynet && git submodule update --init

LUA_CLIB = aoi \
  chestnut crab math3d rapidjson \
  skiplist xlog \
  lfs

LUA_CLIB_FIXMATH = \
  lua-skynet.c lua-seri.c \
  lua-socket.c \
  lua-mongo.c \
  lua-netpack.c \
  lua-memory.c \
  lua-profile.c \
  lua-multicast.c \
  lua-cluster.c \
  lua-crypt.c lsha1.c \
  lua-sharedata.c \
  lua-stm.c \
  lua-debugchannel.c \
  lua-datasheet.c \
  lua-ssm.c \
  lua-sharetable.c \
  \

all : \
	strawberry \
  $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so) 

$(LUA_CLIB_PATH) :
	mkdir $(LUA_CLIB_PATH)

$(CSERVICE_PATH) :
	mkdir $(CSERVICE_PATH)

$(LUA_CLIB_PATH)/aoi.so : lualib-src/aoi/aoi.c lualib-src/aoi/lua-aoi.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -Ilualib-src/aoi $^ -o $@ 

$(LUA_CLIB_PATH)/chestnut.so : lualib-src/chestnut/lua-array.c lualib-src/chestnut/lua-float.c \
  lualib-src/chestnut/lua-queue.c lualib-src/chestnut/lua-snowflake.c lualib-src/chestnut/lua-sortedvector.c \
  lualib-src/chestnut/lua-stack.c lualib-src/chestnut/lua-vector.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -Ilualib-src/chestnut -Iskynet/skynet-src $^ -o $@

$(LUA_CLIB_PATH)/crab.so : lualib-src/crab/crab.c lualib-src/crab/lua-crab.c lualib-src/crab/lua-utf8.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -Ilualib-src/crab $^ -o $@

$(LUA_CLIB_PATH)/math3d.so : lualib-src/math3d/CCAABB.cc lualib-src/math3d/lua-math.c | $(LUA_CLIB_PATH)
	g++ -std=c++11 $(CFLAGS) $(SHARED) -Ilualib-src/math3d $^ -o $@

$(LUA_CLIB_PATH)/rapidjson.so : lualib-src/rapidjson/Document.cpp lualib-src/rapidjson/rapidjson.cpp \
	lualib-src/rapidjson/Schema.cpp lualib-src/rapidjson/values.cpp | $(LUA_CLIB_PATH)
	g++ -std=c++11 $(CFLAGS) $(SHARED) -Ilualib-src/rapidjson -Ilualib-src/rapidjson/include $^ -o $@

$(LUA_CLIB_PATH)/skiplist.so : lualib-src/skiplist/skiplist.c lualib-src/skiplist/lua-skiplist.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -Ilualib-src/skiplist $^ -o $@

$(LUA_CLIB_PATH)/xlog.so : lualib-src/xlog/lua-host.c lualib-src/xlog/xloggerdd.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -Ilualib-src/xlog $^ -o $@

$(LUA_CLIB_PATH)/lfs.so : 3rd/luafilesystem/lfs.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I3rd/luafilesystem $^ -o $@

clean :
	rm -f $(LUA_CLIB_PATH)/*.so