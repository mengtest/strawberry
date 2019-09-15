local skynet = require "skynet"
local addr
local _M = {}

local function get_addr()
    if not addr then
        addr = skynet.uniqueservice("sdata_mgr")
    end
    return addr
end

function _M.reload()
    local address = get_addr()
end

return _M
