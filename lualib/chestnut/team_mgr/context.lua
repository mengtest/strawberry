local skynet = require "skynet"
local objmgr = require "objmgr"
local dbc = require "db"
local json = require "rapidjson"
local _M = {}
local teams = {}
local users = {}

function _M.init_data()
    local d = dbc.read_team()
    for _, it in pairs(d.db_teams) do
        local item = {}
        item.id = it.id
        item.name = it.name
        item.simple = it.simple
        item.power = it.power
        item.join_tp = it.join_tp
        item.join_cond = it.join_cond
        teams[item.id] = item
    end
end

function _M.save_data()
end

function _M.login()
end

function _M.enter()
end

function _M.fetch_teams(uid, args)
    local obj = objmgr.get(uid)
    return {
        errorcode = 0,
        teams = {}
    }
end

function _M.fetch_team(uid, args)
    local obj = objmgr.get(uid)
    return {
        errorcode = 0,
        team = {}
    }
end

function _M.create_team(uid, args)
    return {
        errorcode = 0,
        id = 0
    }
end

function _M.join_team(uid, args)
    return {
        errorcode = 0
    }
end

function _M.fetch_myteams(uid, args)
    return {
        errorcode = 0,
        teams = {}
    }
end

function _M.quit_team(uid, args)
    return {
        errorcode = 0
    }
end

return _M
