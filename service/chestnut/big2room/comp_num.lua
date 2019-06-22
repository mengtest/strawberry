local assert = assert
local _M = {}

function _M.mt(a, b)
	-- body
	assert(a and b)
	assert(type(a) == 'number')
	assert(type(b) == 'number')
	if a == b then
		return 0
	elseif a == 2 then
		return 1
	elseif a == 1 and b ~= 2 then
		return 1
	else
		return a - b
	end
end

return _M