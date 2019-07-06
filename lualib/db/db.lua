local skynet = require "skynet"
local log = require "chestnut.skynet.log"
local address
local _M = {}

local function get_address()
    if not address then
        address = skynet.uniqueservice 'db'
    end
    return address
end

function _M.read_sysmail( ... )
    -- body
    local handle = get_address()
    return skynet.call(handle, 'lua', 'read_sysmail')
end

function _M.read_account_by_username(username, password)
    local handle = get_address()
    return skynet.call(handle, 'lua', 'read_account_by_username', username, password)
end

function _M.read_user(uid)
    local handle = get_address()
    return skynet.call(handle, 'lua', 'read_user', uid)
end

function _M.read_room_mgr()
    local handle = get_address()
    return skynet.call(handle, 'lua', 'read_room_mgr')
end

function _M.read_room(roomid)
    local handle = get_address()
    return skynet.call(handle, 'lua', 'read_room', roomid)
end

function _M.write_account(account)
    local handle = get_address()
    skynet.send(handle, 'lua', 'write_account', account)
end

function _M.write_union(union)
    local handle = get_address()
    skynet.send(handle, 'lua', 'write_union', union)
end

function _M.write_user(user)
    local handle = get_address()
    skynet.send(handle, 'lua', 'write_user', user)
end

return _M