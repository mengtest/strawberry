local skynet = require "skynet"

local util = {}

function util.set_timeout(ti, f)
	assert(ti and f)
	local function cb()
		if f then
			f()
		end
	end
	skynet.timeout(ti, cb)
	return function()
		f = nil
	end
end

function util.cm_sec()
	local nt = os.date("*t")
	local t = {}
	t.year = nt.year
	t.month = nt.month
	t.day = 1
	return os.time(t), nt.month
end

function util.cd_sec()
	local nt = os.date("*t")
	local t = {}
	t.year = nt.year
	t.month = nt.month
	t.day = nt.day
	return os.time(t), nt.day
end

return util
