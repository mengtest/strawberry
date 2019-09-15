local view = require "web.pet.view"
local _M = {}

_M["^/pull"] = assert(view["pull"])
_M["^/push"] = assert(view["push"])

return _M
