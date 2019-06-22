#define LUA_LIB

#include "sssl.h"
#include <lua.h>
#include <lauxlib.h>
#include <assert.h>

const char *gkey = "ssockaux";

#define SSOCKAUX_BUFFER_SIZE (2048)

struct ssockaux {
	lua_State    *L;
	struct sssl_ctx  *fd;
	int           free;  // 0, 1: gc
};

static int
ssockaux_connect_callback(int how, void *ud) {
	struct ssockaux *aux = ud;
	lua_State *L = aux->L;
	lua_getglobal(L, gkey);
	lua_getfield(L, -1, "shutdown");
	if (lua_isfunction(L, -1)) {
		lua_pushvalue(L, -2);
		assert(lua_rawgetp(L, -1, aux) == LUA_TUSERDATA);
		lua_rotate(L, -2, 1);
		lua_pop(L, 1);

		lua_pushinteger(L, how);
		lua_pcall(L, 1, 0, 0);
	}
	return 0;
}

static int
ssockaux_connected_callback(int how, void *ud) {
	struct ssockaux *aux = ud;
	lua_State *L = aux->L;
	lua_getglobal(L, gkey);
	lua_getfield(L, -1, "shutdown");
	if (lua_isfunction(L, -1)) {
		lua_pushvalue(L, -2);
		assert(lua_rawgetp(L, -1, aux) == LUA_TUSERDATA);
		lua_rotate(L, -2, 1);
		lua_pop(L, 1);

		lua_pushinteger(L, how);
		lua_pcall(L, 1, 0, 0);
	}
	return 0;
}

static int
ssockaux_shutdown_callback(int how, void *ud) {
	struct ssockaux *aux = ud;
	lua_State *L = aux->L;
	lua_getglobal(L, gkey);
	lua_getfield(L, -1, "shutdown");
	if (lua_isfunction(L, -1)) {
		lua_pushvalue(L, -2);
		assert(lua_rawgetp(L, -1, aux) == LUA_TUSERDATA);
		lua_rotate(L, -2, 1);
		lua_pop(L, 1);

		lua_pushinteger(L, how);
		lua_pcall(L, 1, 0, 0);
	}
	return 0;
}

static int
ssockaux_close_callback(void *ud) {
	struct ssockaux *aux = ud;
	lua_State *L = aux->L;
	lua_getglobal(L, gkey);
	lua_getfield(L, -1, "close");
	if (lua_isfunction(L, -1)) {
		lua_pushvalue(L, -2);
		assert(lua_rawgetp(L, -1, aux) == LUA_TUSERDATA);
		lua_rotate(L, -2, 1);
		lua_pop(L, 1);

		int status = lua_pcall(L, 0, 0, 0);
		if (status == LUA_OK) {
		}
	}
	return 0;
}

static int 
(ssockaux_callback)(void *ud, const char * cmd, int how) {

}

/*
** @breif alloc aux
*/

static int
lssockaux_alloc(lua_State *L) {
	if (lua_gettop(L) >= 1) {
		luaL_checktype(L, 1, LUA_TTABLE);

		struct ssockaux *aux = lua_newuserdata(L, sizeof(struct ssockaux));
		aux->L = L;

		aux->fd = sssl_alloc(aux, ssockaux_callback);
		aux->free = 0;

		lua_pushvalue(L, -1);
		lua_rawsetp(L, 1, aux);  // 

		lua_pushvalue(L, 1);
		lua_setglobal(L, gkey);

		lua_pushvalue(L, lua_upvalueindex(1));
		lua_setmetatable(L, -2);

		return 1;
	} else {
		luaL_error(L, "please give a table contains callback.");
		return 0;
	}
}

static int
lssockaux_ss(lua_State *L) {
	luaL_checktype(L, 1, LUA_TUSERDATA);
	struct ssockaux *aux = lua_touserdata(L, 1);
	int idx = luaL_checkinteger(L, 2);
	int r = sssl_get_state(aux->fd, idx);
	lua_pushinteger(L, r);
	return 1;
}

static int
lssockaux_connect(lua_State *L) {
	luaL_checktype(L, 1, LUA_TUSERDATA);
	struct ssockaux *aux = lua_touserdata(L, 1);
	const char *addr = luaL_checkstring(L, 2);
	int port = luaL_checkinteger(L, 3);
	int r = sssl_connect(aux->fd, addr, port);
	lua_pushinteger(L, r);
	return 1;
}

static int
lssockaux_poll(lua_State *L) {
	luaL_checktype(L, 1, LUA_TUSERDATA);
	struct ssockaux *aux = lua_touserdata(L, 1);
	int idx = luaL_checkinteger(L, 2);

	size_t l = 0;
	const char *buf = NULL;
	if (lua_type(L, 3) == LUA_TSTRING) {
		buf = luaL_checklstring(L, 3, &l);
	}

	struct write_buffer *wb = sssl_poll(aux->fd, idx, buf, l);
	if (wb != NULL) {
		lua_pushlstring(L, wb->buffer, wb->len);
		return 1;
	}
	return 0;
}

static int
lssockaux_send(lua_State *L) {
	luaL_checktype(L, 1, LUA_TUSERDATA);
	struct ssockaux *aux = lua_touserdata(L, 1);
	int idx = luaL_checkinteger(L, 2);
	size_t l = 0;
	const char *buf = luaL_checklstring(L, 3, &l);
	if (l > 0) {
		int r = sssl_send(aux, idx, buf, l);
		lua_pushinteger(L, r);
	} else {
		lua_pushinteger(L, 0);
	}
	return 1;
}

static int
lssockaux_recv(lua_State *L) {
	luaL_checktype(L, 1, LUA_TUSERDATA);
	struct ssockaux *aux = lua_touserdata(L, 1);
	int idx = luaL_checkinteger(L, 2);
	char BUF[SSOCKAUX_BUFFER_SIZE];
	int r = sssl_recv(aux->fd, idx, BUF, SSOCKAUX_BUFFER_SIZE);
	if (r > 0) {
		lua_pushlstring(L, BUF, r);
		return 1;
	}
	return 0;
}

static int
lssockaux_shutdown(lua_State *L) {
	luaL_checktype(L, 1, LUA_TUSERDATA);
	struct ssockaux *aux = lua_touserdata(L, 1);
	int idx = luaL_checkinteger(L, 2);
	int how = luaL_checkinteger(L, 3);
	int r = sssl_shutdown(aux->fd, idx, how);
	lua_pushinteger(L, r);
	return 1;
}

static int
lssockaux_close_gc(lua_State *L) {
	struct ssockaux *aux = lua_touserdata(L, 1);
	aux->free = 1;
	sssl_free(aux->fd);
	return 0;
}

static int
lssockaux_close(lua_State *L) {
	struct ssockaux *aux = lua_touserdata(L, 1);
	int idx = luaL_checkinteger(L, 2);
	int r = sssl_close(aux->fd, idx);
	lua_pushinteger(L, r);
	return 1;
}

LUAMOD_API int
luaopen_sssl_core(lua_State *L) {
	luaL_checkversion(L);
	lua_createtable(L, 0, 1);
	luaL_Reg l[] = {
		{ "state", lssockaux_ss },
		{ "connect", lssockaux_connect },
		{ "poll", lssockaux_poll },
		{ "send", lssockaux_send },
		{ "recv", lssockaux_recv },
		{ "shutdown", lssockaux_shutdown },
		{ "close", lssockaux_close },
		{ NULL, NULL },
	};
	luaL_newlib(L, l); // met
	lua_setfield(L, -2, "__index");
	lua_pushcfunction(L, lssockaux_close_gc);
	lua_setfield(L, -2, "__gc");

	lua_pushcclosure(L, lssockaux_alloc, 1);
	return 1;
}

