local _M = {}

_M.NORET   = {}
_M.SUCCESS = 0
_M.FAIL    = 1
_M.LOGIN_AGENT_ERR = 2
_M.LOGIN_AGENT_LOAD_ERR = 3
_M.NOT_ENOUGH_AGENT = 4            -- 没有足够的agent
_M.NOT_AUTHED = 5                  -- 没有授权怎么afk

return _M