local skynet = require "skynet"

local addr
local function get_addr()
    if not addr then
        addr = skynet.uniqueservice("life_mgr")
    end
    return addr
end

local _M = {}

function _M.register(handle)
    return skynet.call(get_addr(), "lua", "register", handle)
end

function _M.uniqueservice(name)
    return skynet.call(get_addr(), "lua", "uniq", name)
end

function _M.newservice(name)
    return skynet.call(get_addr(), "lua", "new", name)
end

function _M.kill()
    return skynet.call(get_addr(), "lua", "kill")
end

return _M
