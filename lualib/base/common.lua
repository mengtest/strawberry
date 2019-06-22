function cc.genpk_1(_1, ... )
	-- body
	return _1
end

function cc.genpk_2(_1, _2, ... )
    -- body
    local pk = (~(1 << 33 -1) & _1)
    pk = pk << 32
    pk = (pk | (~(1 << 33 -1) & _2 ))
    return pk
end

function cc.genpk_3(_1, _2, ...)
	local pk = (~(1 << 9 - 1) & _1)
	pk = pk << 24
	pk = (pk | (~(1 << 25 - 1) & _2))
	return pk
end

local idx = 0
local mechin = 0
local service = 0

function cc.key()
	local r = 0
	idx = idx + 1
	local ti = os.time()
	ti = ti << 41
	local m = mechin << 15
	local s = service << 9
	r = r | ti
	r = r | mechin
	r = r | s
	r = r | idx
	return r
end