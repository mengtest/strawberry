-- 
-- @此模块只用来判断是否是跨服的推送
-- 
local skynet = require 'skynet'
local cluster = require 'skynet.cluster'

local function is_logind(addr)
    if type(addr) == 'string' and addr == '.LOGIND' then
        return true
    end
end

local function is_cross(addr)
end

local function is_gm(addr)
end

local function is_game(addr)
end

local _M = {}

function _M.send(addr, type, name, ...)
    if is_logind(addr) then
        return cluster.send('logind', addr, name, ...)
    else
        skynet.send(addr, type, name, ...)
    end
end

function _M.call(addr, type, name, ...)
    if is_logind(addr) then
        return cluster.call('logind', addr, name, ...)
    else
        skynet.call(addr, type, name, ...)
    end
end

return _M