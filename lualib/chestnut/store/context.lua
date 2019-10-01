local skynet = require "skynet"
local sd = require "skynet.sharetable"
local objmgr = require "objmgr"
local servicecode = require "enum.servicecode"
local _M = {}
local shop_cfg
local table_insert = table.insert

skynet.init(
    function()
        shop_cfg = sd.query("ShopConfig")
    end
)

function _M.init_data(dbData)
end

function _M.save_data(dbData)
end

function _M.on_enter(self)
end

function _M.fetch_store_items(uid, args)
    local items = {}
    for k, v in pairs(shop_cfg) do
        item = {}
        item.id = v.sid
        table_insert(items, item)
    end
    return {
        errorcode = 0,
        items = items
    }
end

function _M.fetch_store_item(uid, args)
end

function _M.buy_store_item(uid, args)
end

return _M
