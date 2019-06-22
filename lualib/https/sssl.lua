local driver = require "sssl.core"

local _M = {}

_M.ss_normal     = 0
_M.ss_connect    = 1
_M.ss_connecting = 2
_M.ss_connected  = 3
_M.ss_shutdown   = 4
_M.ss_close      = 5
_M.ss_error      = 6

_M.new = assert(driver)

return _M
