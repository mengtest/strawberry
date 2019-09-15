local view = require "web.view"
local _M = {}
_M.get = {}
_M.get["/"] = assert(view["index"])
_M.get["/index"] = assert(view["index"])
_M.get["^/user$"] = assert(view["user"])
_M.get["^/role"] = assert(view["role"])
_M.get["/get_email"] = assert(view["get_email"])
_M.get["^/props"] = assert(view["props"])
_M.get["^/equipments"] = assert(view["equipments"])
_M.get["^/validation"] = assert(view["validation"])
_M.get["^/validation_ro"] = assert(view["validation_ro"])
_M.get["^/percudure"] = assert(view["percudure"])
_M.get["^/404"] = assert(view["_404"])
_M.get["^/test"] = assert(view["test"])

-- _M['^/version/1.0.1'] = assert(view[])

return _M
