local objmgr = require "objmgr"

local function default()
    -- body
    return function (ctx, uid, ...)
        ctx.obj = assert(objmgr.get(uid))
    end
end

return default