local opcode = require "chestnut.mahjongroom.opcode"
local gangtype = require "chestnut.mahjongroom.gangtype"

local _M = {}

_M[gangtype.bugang] = 1
_M[gangtype.zhigang] = 2
_M[gangtype.angang] = 2

return _M