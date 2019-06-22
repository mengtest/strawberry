local view = require "gm.web.view"
local _M = {}

_M['^/$']             = assert(view["index"])
_M['^/index$']        = assert(view["index"])
_M['^/user$']         = assert(view["user"])
_M['^/role']          = assert(view["role"])
_M['^/email']         = assert(view["email"])
_M['^/props']         = assert(view["props"])
_M['^/equipments']    = assert(view["equipments"])
_M['^/validation']    = assert(view["validation"])
_M['^/validation_ro'] = assert(view["validation_ro"])
_M['^/percudure']     = assert(view["percudure"])
_M['^/404']           = assert(view["_404"])
_M['^/test']          = assert(view["test"])

-- _M['^/version/1.0.1'] = assert(view[])

return _M
