#define LUA_LIB

#include "aoi.h"

#include <lua.h>
#include <lauxlib.h>
#include <stdlib.h>

struct alloc_cookie {
	int count;
	int max;
	int current;
};

struct aoi_aux {
	struct lua_State *L;
	struct aoi_space *space;
	struct alloc_cookie cookie;
};

static int err_msg(lua_State *L) {
	return 0;
}

static void	
message(void *ud, uint32_t watcher, uint32_t marker) {
	printf("%u => %u\n", watcher, marker);

	struct aoi_aux *aux = (struct aoi_aux *)(ud);
	struct lua_State *L = aux->L;
	if (L == NULL) {
		printf("%s\n", "L is empty.");
		return;
	}
	// lua_pushcfunction(L, err_msg);
	// printf("(%s)\n", message);
	lua_geti(L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS);
	lua_getfield(L, -1, "aoi_Callback");   // function
	lua_pushinteger(L, watcher);
	lua_pushinteger(L, marker);
	lua_pcall(L, 2, 0, 0);
	return;
}

static void *
my_alloc(void * ud, void *ptr, size_t sz) {
	struct aoi_aux *aux = ud;
	struct alloc_cookie * cookie = &aux->cookie;
	if (ptr == NULL) {
		void *p = malloc(sz);
		++ cookie->count;
		cookie->current += sz;
		if (cookie->max < cookie->current) {
			cookie->max = cookie->current;
		}
//		printf("%p + %u\n",p, sz);
		return p;
	}
	-- cookie->count;
	cookie->current -= sz;
//	printf("%p - %u \n",ptr, sz);
	free(ptr);
	return NULL;
}

static int 
lnew(lua_State *L) {
	struct aoi_aux *aux = (struct aoi_aux *)lua_newuserdata(L, sizeof(*aux));
	if (aux == NULL) {
		printf("%s\n", "malloc failture.");
		return 0;
	} else {
		lua_pushvalue(L, lua_upvalueindex(1));
		lua_setmetatable(L, -2);

		aux->L = L;
		lua_geti(L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS);
		lua_newtable(L);
		lua_rawsetp(L, -2, aux);
		lua_pop(L, 1);
		
		struct alloc_cookie cookie = {0, 0, 0};
		aux->cookie = cookie;
		struct aoi_space *space = aoi_create(my_alloc, aux);
		aux->space = space;

		// lua_pushlightuserdata(L, aux);
		return 1;	
	}
}

static int
lrelease(lua_State *L) {
	if (lua_gettop(L) >= 1) {
		/* code */
		struct aoi_aux *aux = (struct aoi_aux *)lua_touserdata(L, 1);
		struct aoi_space *space = aux->space;
		aoi_release(space);
		free(aux);
		return 0;
	} else {
		luaL_error(L, "must be.");
		return 0;
	}
}

static int 
lupdate(lua_State *L) {
	luaL_checktype(L, 1, LUA_TUSERDATA);
	struct aoi_aux *aux = (struct aoi_aux *)lua_touserdata(L, 1);
	struct aoi_space *space = aux->space;
	lua_Integer id = luaL_checkinteger(L, 2);
	const char *m = luaL_checkstring(L, 3);
	lua_Number x = luaL_checknumber(L, 4);
	lua_Number y = luaL_checknumber(L, 5);
	lua_Number z = luaL_checknumber(L, 6);
	float pos[3] = {x, y, z};
	aoi_update(space, id, m, pos);
	return 0;
}

static int 
lmessage(lua_State *L) {
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TFUNCTION);
	struct aoi_aux *aux = (struct aoi_aux *)lua_touserdata(L, 1);
	aux->L = L;
	struct aoi_space *space = aux->space;
	
	lua_geti(L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS);
	lua_pushvalue(L, 2);
	lua_setfield(L, -2, "aoi_Callback");
	aoi_message(space, message, aux);
	return 0;
}

static int 
ltest(lua_State *L) {
	struct aoi_aux *aux = (struct aoi_aux *)lua_touserdata(L, 1);
	printf("max memory = %d, current memory = %d\n", aux->cookie.max , aux->cookie.current);
	return 0;
}


LUAMOD_API int
luaopen_aoi(lua_State *L) {
	luaL_checkversion(L);
	lua_newtable(L); // met
	luaL_Reg l[] = {
		{ "update", lupdate },
		{ "message", lmessage },
		{ "test", ltest },
		{ NULL, NULL },
	};
	luaL_newlib(L,l);
	lua_setfield(L, -2, "__index");
	lua_pushcclosure(L, lrelease, 0);
	lua_setfield(L, -2, "__gc");
	lua_pushcclosure(L, lnew, 1);
	return 1;
}