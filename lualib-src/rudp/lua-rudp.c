#define LUA_LIB

#include "rudp.h"

#include <lua.h>
#include <lauxlib.h>
#include <string.h>
#include <assert.h>

struct rudp_aux {
	struct rudp *u;
};

static int
lsend(lua_State *L) {
	struct rudp_aux *aux = (struct rudp_aux *)lua_touserdata(L, 1);
	size_t sz = 0;
	const char *buffer = luaL_checklstring(L, 2, &sz);
	rudp_send(aux->u, buffer, sz);
	return 0;
}

static int
lrecv(lua_State *L) {
	struct rudp_aux *aux = (struct rudp_aux *)lua_touserdata(L, 1);
	char buffer[MAX_PACKAGE];
	int sz = rudp_recv(aux, buffer);
	if (sz > 0) {
		lua_pushlstring(L, buffer, sz);
		return 1;
	}
	return 0;
}

static int
lupdate(lua_State *L) {
	struct rudp_aux *aux = (struct rudp_aux *)lua_touserdata(L, 1);
	int tick = lua_tointeger(L, 2);

	size_t sz = 0;
	const char *buffer = NULL;
	if (lua_type(L, 3) == LUA_TSTRING) {
		buffer = luaL_checklstring(L, 3, &sz);
	}
	return 0;
}

static int
lfree(lua_State *L) {
	if (lua_gettop(L) >= 1) {
		struct rudp_aux *aux = (struct rudp_aux *)lua_touserdata(L, 1);
		rudp_delete(aux->u);
		return 0;
	} else {
		luaL_error(L, "must be.");
		return 0;
	}
}

static int
lalloc(lua_State *L) {
	struct rudp_aux *aux = (struct rudp_aux *)lua_newuserdata(L, sizeof(*aux));
	if (aux == NULL) {
		luaL_error(L, "new udata failture.");
		return 0;
	} else {
		struct rudp *U = rudp_new(1, 5);
		aux->u = U;
		return 1;
	}
}

LUAMOD_API int
luaopen_rudp(lua_State *L) {
	luaL_checkversion(L);
	lua_newtable(L); // met
	luaL_Reg l[] = {
		{ "send", lsend },
		{ "recv", lrecv },
		{ "update", lupdate },
		{ NULL, NULL },
	};
	luaL_newlib(L, l);
	lua_setfield(L, -2, "__index");
	lua_pushcclosure(L, lfree, 0);
	lua_setfield(L, -2, "__gc");
	lua_pushcclosure(L, lalloc, 1);
	return 1;
}