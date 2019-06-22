local skynet = require "skynet"
local sd = require "skynet.sharedata"
local mc = require "skynet.multicast"
local log = require "chestnut.skynet.log"
-- local json = require "rapidjson"
local servicecode = require "enum.servicecode"
local service = require "service"
local savedata = require "savedata"
local traceback = debug.traceback
local assert = assert
local records = {}
local CMD = {}
local SUB = {}

local function save_data()
	log.info('record_mgr save data.')
end

function SUB.save_data()
	save_data()
end

function CMD.start()
	-- body
	savedata.init {
		command = SUB
	}
	savedata.subscribe()
	return true
end

function CMD.init_data()
	-- body
	-- local pack = redis:get("tb_record")
	-- if pack then
	-- 	local data = json.decode(pack)
	-- 	for k,v in pairs(data.records) do
	-- 		records[tonumber(k)] = v
	-- 	end
	-- end
	return true
end

function CMD.sayhi()
	-- body
	return true
end

function CMD.close()
	-- body
	save_data()
	return true
end

function CMD.kill()
	-- body
	skynet.exit()
end

function CMD.load()
	-- body
	local idx =  db:get(string.format("tb_count:%d:uid", const.RECORD_ID))
	idx = math.tointeger(idx)
	if idx > 1 then
		local keys = db:zrange('tb_record', 0, -1)
		for k,v in pairs(keys) do
			zs:add(k, v)
		end

		for _,id in pairs(keys) do
			local vals = db:hgetall(string.format('tb_record:%s', id))
			local t = {}
			for i=1,#vals,2 do
				local k = vals[i]
				local v = vals[i + 1]
				t[k] = v
			end
			sd.new(string.format('tb_record:%s', id), t)
			-- t = sd.query(string.format('tg_sysmail:%s', id))
		end	
	end
end

function CMD.register(content, ... )
	-- body
	local id =  db:incr(string.format("tb_count:%d:uid", const.RECORD_ID))
	dbmonitor.cache_update(string.format("tb_count:%d:uid", const.RECORD_ID))

	-- sd.new
	local r = mgr:create(internal_id)
	mgr:add(r)
	r:insert_db()
end

function CMD.save_record(players, start_time, close_time, content, ... )
	-- body
end

service.init {
	name = '.RECORD_MGR',
	command = CMD
}
