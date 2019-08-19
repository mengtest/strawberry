-- 
-- @此模块只用来判断是否是跨服的推送
-- 
local skynet = require 'skynet'
local cluster = require 'skynet.cluster'
local datacenter = require "skynet.datacenter"
local log = require "chestnut.skynet.log"
local nodes = {}
local serverd
local _config
local _cnode_name
local _M = {}
_M.host = {}

local function get_config()
    if _config == nil then
        local gm = skynet.getenv 'cluster_gm'
	    local logind = skynet.getenv 'cluster_logind'
	    local game1 = skynet.getenv 'cluster_game1'
        _config = {
            -- gm = gm,
            logind = logind,
            game1 = game1
        }
    end
    return _config
end

local function get_cnode_name()
    if _cnode_name == nil then
        _cnode_name = datacenter.get('cluster_node')
        assert(_cnode_name)
    end
    return _cnode_name
end

local function set_cnode_name(name)
    assert(name)
    _cnode_name = name
    datacenter.set('cluster_node', name)
end

local function get_node_name(addr)
    -- local
    assert(addr)
    local node_name = nodes[addr]
    if node_name then
        log.fields({ node_name = node_name }).info('call get_node_name')
        return node_name
    end

    -- local dc
    local cnode_name = get_cnode_name()
    local ok = datacenter.get(cnode_name, addr)
    if ok then
        nodes[addr] = cnode_name
        return cnode_name
    end

    -- remote
    local config = get_config()
    for k,_ in pairs(config) do
        if k ~= cnode_name then
            -- log.fields({ node_name = k }).info('test remote node name')
            node_name = cluster.call(k, '.serverd', 'query_service', addr)
            if node_name ~= nil then
                nodes[addr] = node_name
                return node_name
            end
        end
    end
end

skynet.init(function ()
    get_config()
end)

function _M.host.open_logind()
    skynet.uniqueservice('serverd')
    local config = get_config()
    cluster.reload(config)
    cluster.open 'logind'
    set_cnode_name('logind')
end

function _M.host.open_game1()
    skynet.uniqueservice('serverd')
    local config = get_config()
    cluster.reload(config)
    cluster.open 'game1'
    set_cnode_name('game1')
end

function _M.host.register_service(service_name, address)
    local cnode_name = get_cnode_name()
    nodes[service_name] = cnode_name
    datacenter.set(cnode_name, service_name, 'OK')
end

function _M.host.query_service(service_name)
    -- cache
    local node_name = nodes[service_name]
    if node_name then
        return node_name
    end
    local cnode_name = get_cnode_name()
    local ok = datacenter.get(cnode_name, service_name)
    if ok == 'OK' then
        nodes[service_name] = cnode_name
        return cnode_name
    end
    return nil
end

function _M.send(addr, type, name, ...)
    local cnode_name = get_cnode_name()
    
    -- query
    local node_name = get_node_name(addr)
    if node_name == nil then
        log.error('node_name is nil')
        return
    end
    
    if node_name ~= cnode_name then
        cluster.send(node_name, addr, name, ...)
    else
        skynet.send(addr, type, name, ...)
    end
end

function _M.call(addr, type, name, ...)

    local cnode_name = get_cnode_name()
    log.fields({ cnode_name = cnode_name }).info('call cnode_name')

    local node_name = get_node_name(addr)
    if node_name == nil then
        log.error('node_name is nil')
        return
    end
    log.fields({ node_name = node_name }).info('call node_name')

    if node_name ~= cnode_name then
        return cluster.call(node_name, addr, name, ...)
    else
        return skynet.call(addr, type, name, ...)
    end
end

return _M