local skynet = require "skynet"
local errorcode = require "enum.servicecode"
local json = require "rapidjson"
local pcall = skynet.pcall
local template = {}
local string_split = string.split
local rdb = ".DB"
local wdb = ".DB"

local VIEW = {}

function VIEW:index()
	local body = json.encode({errorcode = 0, content = "hello index"})
	self.body = body
end

function VIEW:user()
end

function VIEW:role()
	-- body
	if self.method == "get" then
		local func = template.compile(path("role.html"))
		return func()
	elseif self.method == "file" then
		print(self.file)
		return "succss"
	end
end

function VIEW:get_email()
	-- skynet.
end

function VIEW:send_email()
	local body = json.decode(self.body)
	local send_type = tonumber(body["send_type"])
	local c = {}
	c["type"] = tonumber(body["type"]) -- 1 or 2
	c["title"] = body["title"]
	c["content"] = body["content"]
	c["itemsn1"] = tonumber(body["itemsn1"])
	c["itemnum1"] = tonumber(body["itemnum1"])
	c["itemsn2"] = tonumber(body["itemsn2"])
	c["itemnum2"] = tonumber(body["itemnum2"])
	c["itemsn3"] = tonumber(body["itemsn3"])
	c["itemnum3"] = assert(tonumber(body["itemnum3"]))
	c["iconid"] = tonumber(tonumber(body["iconid"]))

	local receiver = tonumber(body["receiver"])
	if send_type == 1 then
		skynet.send(".channel", "lua", "send_email_to_group", c, {{uid = receiver}})
		print("********************************************send_email_to_group is called")
		local ret = {}
		ret.errorcode = errorcode[1].code
		ret.msg = errorcode[1].msg
		return json.encode(ret)
	elseif send_type == 2 then
		-- assert(false)
		skynet.send(".channel", "lua", "send_public_email_to_all", c)
		print("********************************************send_email_to_all is called")
		local ret = {}
		ret.errorcode = errorcode[1].code
		ret.msg = errorcode[1].msg
		return json.encode(ret)
	end
end

function VIEW:add_email()
	local file = self.file
	assert(csvreader and file)
	print("filecont is  ", file)
	local cont = string_split(file, "\r\n")
	assert(cont)
	for k, v in ipairs(cont) do
		local ne = {}
		ne.type = tonumber(v.email_type)
		print()
		ne.title = v.title
		ne.content = v.content
		local titem = util.parse_text(v.reward, "(%d+%*%d+%*?)", 2)
		assert(titem)
		local i = 1
		for sk, sv in ipairs(titem) do
			local itemsn = "itemsn" .. i
			local itemnum = "itemnum" .. i

			ne[itemsn] = tonumber(sv[1])
			ne[itemnum] = tonumber(sv[2])
			print(ne[itemsn], ne[itemnum])
			i = i + 1
		end

		skynet.send(".channel", "lua", "send_email_to_group", ne, {{uid = assert(tonumber(v.csv_id))}})
	end

	local ret = {}
	ret.errorcode = errorcode[1].code
	ret.msg = errorcode[1].msg
	self.body = json.encode(ret)
end

function VIEW:props()
	-- body
	if self.method == "get" then
		local users = skynet.call(db, "lua", "command", "select_and", "users")
		for i, v in ipairs(users) do
			for kk, vv in pairs(v) do
				print(kk, vv)
			end
		end
		local func = template.compile(path("props.html"))
		return func {message = "fill in the blank text.", users = users}
	elseif self.method == "post" then
		local uaccount = self.body["uaccount"]
		local csv_id = tonumber(self.body["csv_id"])
		local num = tonumber(self.body["num"])
		if not csv_id and not num then
			local ret = {}
			ret.errorcode = errorcode.E_SUCCUSS
			return ret
		end
		local user = skynet.call(db, "lua", "command", "select_user", {uaccount = uaccount})
		print(user.id, csv_id, num)
		skynet.send(util.random_db(), "lua", "command", "insert_prop", user.id, csv_id, num)
		local ret = {}
		ret.errorcode = errorcode.E_SUCCUSS
		return ret
	end
end

function VIEW:equipments()
	-- body
	if self.method == "get" then
		local users = skynet.call(db, "lua", "command", "select_and", "users")
		local func = template.compile(path("equipments.html"))
		return func {message = "fill in the blank text.", users = users}
	elseif self.method == "post" then
		if self.body["cmd"] == "user" then
			local uaccount = self.body["uaccount"]
			local user = skynet.call(db, "lua", "command", "select_user", {uaccount = uaccount})
			local achievements = skynet.call(util.random_db(), "lua", "command", "select_and", "equipments", {user_id = user.id})
			local ret = {
				errorcode = 0,
				msg = "succss",
				achievements = achievements
			}
			return ret
		elseif self.body["cmd"] == "equip" then
			local user = skynet.call(db, "lua", "command", "select_user", {uaccount = uaccount})
			skynet.send(db, "lua", "command", "insert", {user_id = user.id, achievement_id = achievement_id, level = level})
			local ret = {
				ok = 1,
				msg = "send succss."
			}
			return ret
		end
	end
end

function VIEW:validation()
	-- body
	if self.method == "post" then
		skynet.error("enter validation.")
		local body = self.body
		local db_name = body.db_name
		skynet.error(db_name)
		if db_name then
		else
			db_name = "project"
		end
		-- query table_name
		local sql =
			string.format(
			"select table_name from information_schema.tables where table_schema='%s' and table_type='base table'",
			db_name
		)
		skynet.error(sql)
		local r = query.read(rdb, "all", sql)
		if r and #r > 0 then
			local seg = ""
			skynet.error("enter information_schema.")
			for i, v in ipairs(r) do
				for kk, vv in pairs(v) do
					-- exe_percudure(vv)
					skynet.error("will print table name:", vv)
					local ok = print_table(db_name, vv)
					if ok then
					else
						local res = {}
						res.errorcode = errorcode.E_FAIL
						return json.encode(res)
					end
				end
			end
			local res = {}
			res.errorcode = errorcode.E_SUCCUSS
			return json.encode(res)
		else
			skynet.error("exist information_schema.")
			local res = {}
			res.errorcode = errorcode.E_FAIL
			res.msg = "database is empty."
			return json.encode(res)
		end
	end
end

function VIEW:validation_ro()
	-- body
	if self.method == "post" then
		local db_name = self.body["db_name"]
		local table_name = self.body["table_name"]
		print_table(table_name)
		local ret = {}
		ret.errorcode = errorcode.E_SUCCUSS
		return json.encode(ret)
	end
end

function VIEW:percudure(...)
	-- body
	if self.method == "post" then
		local r =
			query.read(
			rdb,
			"all",
			"select table_name from information_schema.tables where table_schema='project' and table_type='base table'"
		)
		if r then
			local ok, result =
				pcall(
				function()
					-- body
					local state = ""
					for i, v in ipairs(r) do
						for kk, vv in pairs(v) do
							local s = exe_percudure(vv)
							state = state .. s .. "\n"
						end
					end
					local addr = io.open(root("config/cat/cat.sql"), "w")
					addr:write(state)
					addr:close()
				end
			)
			if ok then
				local ret = {}
				ret.ok = 1
				ret.msg = "succss"
				return ret
			else
				print(result)
				local ret = {}
				ret.ok = 0
				ret.msg = "failture"
				return ret
			end
		end
	end
end

function VIEW:addrole()
	local uid = self.request.body["uid"]
end

function VIEW:test(...)
	-- body
	if true then
		return {id = 2}
	else
		if self.method == "post" then
			local data = {
				{id = 1, author = "Pete Hunt", text = "This is one comment"},
				{id = 2, author = "Jordan Walke", text = "This is *another* comment"}
			}
			return data
		elseif self.method == "get" then
			return {id = 1}
		end
	end
end

function VIEW:_404()
	-- body
	return "404"
end

return VIEW
