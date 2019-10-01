local skynet = require "skynet"
local sd = require "skynet.sharetable"
local json = require "rapidjson"
local service = require "service"
local zset = require "zset"
local log = require "chestnut.skynet.log"
local traceback = debug.traceback
local _M = {}

local assert = assert
local users = {}
local rooms = {}
local zs = zset.new()

skynet.init(
    function()
    end
)

function _M.init_data()
    -- body
    -- local pack = redis:get("tb_sysmail")
    -- if pack then
    -- 	local data = json.decode(pack)
    -- 	for k,v in pairs(data.mails) do
    -- 		local db_mail = {}
    -- 		db_mail.id          = assert(v.id)
    -- 		db_mail.sender      = assert(v.sender)
    -- 		db_mail.to          = assert(v.to)
    -- 		db_mail.create_time = assert(v.create_time)
    -- 		db_mail.title       = assert(v.title)
    -- 		db_mail.content     = assert(v.content)
    -- 		db_mail.appendix    = assert(v.appendix)
    -- 		zs:add(tonumber(k), db_mail)
    -- 	end
    -- end
    log.info("mail_mgr init_data over.")
    return true
end

function _M.save_data()
    if zs:count() > 0 then
        local db_mails = {}
        local t = zs:range(1, zs:count())
        for k, v in pairs(t) do
            local db_mail = {}
            db_mail.id = assert(v.id)
            db_mail.sender = assert(v.sender)
            db_mail.to = assert(v.to)
            db_mail.create_time = assert(v.create_time)
            db_mail.title = assert(v.title)
            db_mail.content = assert(v.content)
            db_mail.appendix = assert(v.appendix)
            db_mails[string.format("%d", k)] = db_mail
        end
        local data = {}
        data.mails = db_mails
        local pack = json.encode(data)
        redis:set("tb_sysmail", pack)
    end
end

function _M.new_mail(title, content, appendix, to, ...)
    local now = skynet.time()
    local mail = {}
    mail.id = guid()
    mail.sender = 1
    mail.to = to
    mail.create_time = now
    mail.title = title
    mail.content = content
    mail.appendix = appendix
    zs:add(mail.id, mail)
    assert(to >= 0)
    if to == 0 then
        -- 所有人
        for _, v in pairs(users) do
            skynet.send(v.agent, "lua", "new_mail", mail)
        end
    elseif rooms[to] then
        local room = rooms[to]
        for _, v in pairs(room) do
            if users[v] then
                skynet.send(v.agent, "lua", "new_mail", mail)
            end
        end
    elseif users[to] then
        if users[to] then
            local u = users[to]
            skynet.send(u.agent, "lua", "new_mail", mail)
        end
    end
    return service.NORET
end

return _M
