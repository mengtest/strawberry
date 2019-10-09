local skynet = require "skynet"
local objmgr = require "objmgr"
local _M = {}

function _M.on_data_init(self, dbData)
end

function _M.on_data_save(self, dbData)
end

function _M.on_enter(self)
end

function _M.fetch_teams(fd, args)
    local obj = objmgr.get_by_fd(fd)
    return skynet.call(".TEAM_MGR", "lua", "fetch_teams", obj.uid, args)
end

function _M.fetch_team(fd, args)
    local obj = objmgr.get_by_fd(fd)
    return skynet.call(".TEAM_MGR", "lua", "fetch_team", obj.uid, args)
end

function _M.create_team(fd, args)
    local obj = objmgr.get_by_fd(fd)
    return skynet.call(".TEAM_MGR", "lua", "create_team", obj.uid, args)
end

function _M.join_team(fd, args)
    local obj = objmgr.get_by_fd(fd)
    return skynet.call(".TEAM_MGR", "lua", "join_team", obj.uid, args)
end

function _M.fetch_myteams(fd, args)
    local obj = objmgr.get_by_fd(fd)
    return skynet.call(".TEAM_MGR", "lua", "fetch_myteams", obj.uid, args)
end

function _M.quit_team(fd, args)
    local obj = objmgr.get_by_fd(fd)
    return skynet.call(".TEAM_MGR", "lua", "quit_team", obj.uid, args)
end

return _M
