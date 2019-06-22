local s = [[
local dbset = require "dbset"
local assert = assert
local type   = type

local cls = class("%s", dbset)

function cls:ctor(env, dbctx, rdb, wdb, ... )
	-- body
	cls.super.ctor(self, env, dbctx, rdb, wdb)
	self._data        = {}
	self._count       = 0
	self._cap         = 0
	self._tname       = "%s"
	self._head        = %s
	self._head_ord    = {}
%s
	self._pk          = "%s"
	self._fk          = "%s"
	self._stm         = false
	self._entity_cls  = "%s"
	return self
end

return cls]]

return s