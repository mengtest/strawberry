local skynet = require "skynet"
local savedata = require "savedata"
local context = require "chestnut.mail_mgr.context"
local CMD = require "cmd"
local subscribe = {}

function subscribe.save_data()
    -- context.save_data()
end

function CMD.start()
    savedata.init {
        command = subscribe
    }
    savedata.subscribe()
    return true
end

function CMD.init_data()
    return context.init_data()
end

function CMD.sayhi()
    -- 初始化各种全服信息
    return true
end

function CMD.close()
    -- context.save_data()
    return true
end

function CMD.kill()
    skynet.exit()
end

-- 各种全服服务初始
function CMD:init_rooms(rooms, ...)
    -- body
    rooms = rooms
end

-- 用户初始
function CMD:poll(uid, agent, max_id, ...)
    assert(users[uid] == nil)
    local u = {uid = uid, agent = agent}
    users[uid] = u

    -- 取自己的并且超过max_id
    if zs:count() > 0 then
        local t = zs:range(1, zs:count())
        local res = {}
        for _, v in ipairs(t) do
            if v.id > max_id then
                table.insert(res, v)
            end
        end
        return res
    else
        return {}
    end
end

function CMD:afk(uid, ...)
    assert(users[uid])
    users[uid] = nil
end

function CMD.new_mail(title, content, appendix, to, ...)
end

return CMD
