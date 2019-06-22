local _M = {}

_M.NONE   = 0   -- 无
_M.HIGH_CARD       = 1  -- 高牌
_M.ONE_PAIR        = 2  -- 一对
_M.TWO_PAIRS       = 3
_M.THREE_OF_A_KIND = 4  -- 三条
_M.STRAIGHT        = 5  -- 顺子
_M.FLUSH           = 6  -- 同花
_M.FULL_HOUSE      = 7  -- 葫芦
_M.FOUR_OF_A_KIND  = 8  -- 铁质  (4张一样的牌再加任意牌)
_M.STRAIGHT_FLUSH  = 9  -- 同花顺
_M.ROYAL_FLUSH     = 10 -- 同花大顺

return _M