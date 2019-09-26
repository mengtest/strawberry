local skynet = require "skynet"
local _M = {}

skynet.init(
    function()
    end
)

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
