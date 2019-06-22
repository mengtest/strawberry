local skynet = require "skynet"

local address

local function get_address()
    if not address then
        address = skynet.uniqservice 'mail_mgr'
    end
    return address
end

local _M = {}

function _M.call_init_rooms( ... )
    -- body
    local handle = get_address()
    return skynet.call(handle, 'init_rooms', ...)
end

return _M