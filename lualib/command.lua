local skynet = require 'skynet'
local cmd = {}
local _t1 = {}
local _t2 = {}
local _middlewares = {}

setmetatable(cmd, { __index = function (t, cmd, ...) 
    return function (...)
        -- step1
        local ctx = {}
		local f = assert(_t1[cmd])
		if f then
			return f(...)
        else
            for _,v in pairs(_middlewares) do
                v(ctx, ...)
            end
			local f = assert(_t2[cmd])
			return f(ctx, ...)
		end
	end
end})

local _M = {}

function _M.cmd()
    return cmd
end

function _M.cmd1()
    return _t1
end

function _M.use(middleware)
    assert(type(middleware) == 'function')
    table.insert(_middlewares, middleware())
end

function _M.cmd2()
    return _t2
end

return _M