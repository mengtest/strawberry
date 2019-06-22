local skynet = require "skynet"
local query = require "query"
local errorcode = require "errorcode"
local dbutil = require "dbutil"
local json = require "cjson"
local rdb = ".DB"
local wdb = ".DB"

local function root(filename, ... )
	-- body
	return "../../"..filename
end

local function current(filename, ... )
	-- body
	return "./../../service/web/"..filename
end

local VIEW = {}

function VIEW:pull()
	-- body
	if self.method == "get" then
	elseif self.method == "post" then
		local body = self.body
		local uid    = body.uid
		local pet_id = body.pet_id
		local table_name = "u_pet"
		local sql = dbutil.select(table_name, {{uid=uid, pet_id=pet_id}})
		skynet.error(sql)
		local r = query.read(rdb, table_name, sql)
		if r and #r > 0 then
			assert(uid == r[1]["uid"])
			assert(pet_id == r[1]["pet_id"])
			local ret = {}
			ret["errorcode"] = errorcode.E_SUCCUSS
			ret["uid"] = uid
			ret["pet_id"] = pet_id
			ret["gold"] = r[1]["gold"]
			ret["stage"] = r[1]["stage"]
			ret["level"] = r[1]["level"]
			return json.encode(ret)
		else
			skynet.error("no data.")
			local ret = {}
			ret["errorcode"] = errorcode.E_FAIL
			return json.encode(ret)
		end
	end
end

function VIEW:push( ... )
	-- body
	if self.method == "post" then
		local body = self.body
		local uid    = body.uid
		local pet_id = body.pet_id
		skynet.error("uid:", uid, "pet_id:", pet_id)
		local table_name = "u_pet"
		local sql = dbutil.select(table_name, {{uid=uid, pet_id=pet_id}})
		skynet.error(sql)
		local r = query.read(rdb, table_name, sql)
		if r and #r > 0 then
			assert(uid == r[1]["uid"])
			assert(pet_id == r[1]["pet_id"])
			local gold  = body["gold"]
			local stage = body["stage"]
			local level = body["level"]
			-- gold  = gold > r[1]["gold"] and gold or r[1]["gold"]
			-- stage = stage > r[1]["stage"] and stage or r[1]["stage"]
			-- level = level > r[1]["level"] and level or r[1]["level"]
			local sql = dbutil.update(table_name, {{uid=uid, pet_id=pet_id}}, {gold=gold, stage=stage, level=level}) 
			skynet.error(sql)
			local r = query.write(wdb, table_name, sql)
			local res = {}
			res.errorcode = errorcode.E_SUCCUSS
			return json.encode(res)
		else
			local id = cc.genpk_2(uid, pet_id)
			local sql = dbutil.insert(table_name, {id=id, uid=uid, pet_id=pet_id, gold=self.body["gold"], stage=self.body["stage"], level=self.body["level"]})
			skynet.error(sql)
			local r = query.write(wdb, table_name, sql)
			local res = {}
			res.errorcode = errorcode.E_SUCCUSS
			return json.encode(res)
		end
	else
	end
end

return VIEW
