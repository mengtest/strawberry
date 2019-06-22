local id = 1
local users = {}
local fds = {}

local _M = {}

function _M.new_obj( ... )
    -- body
    local obj = { id = id }
    id = id + 1
    return obj
end

function _M.add(uid, obj)
    users[uid] = obj
    if obj.uid ~= uid then
        obj.uid = uid
    end
end

function _M.addfd(fd, obj, ... )
    -- body
    fds[fd] = obj
    if obj.fd ~= fd then
        obj.fd = fd
    end
end

function _M.del(uid)
    if users[uid] then
        users[uid] = nil
    end
end

function _M.have(uid)
    return users[uid]
end

function _M.get(uid)
    return users[uid]
end

function _M.get_by_fd(fd)
    return fds[fd]
end

function _M.foreach(cb, ... )
    -- body
    for _,v in pairs(users) do
        cb(v)
    end
end

return _M
