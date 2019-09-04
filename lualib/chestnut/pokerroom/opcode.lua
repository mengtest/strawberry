local _M = {}

_M.NONE      = 0
_M.FOLD      = 1 << 0     -- 过，不出
_M.CHECK     = 1 << 1     -- 出牌
_M.CALL      = 1 << 2     -- 跟
_M.RAISE     = 1 << 3     -- 加注
_M.SBLIND    = 1 << 4     -- 小盲注
_M.BBLIND    = 1 << 5     -- 大盲注
_M.ALLIN     = 1 << 6

return _M