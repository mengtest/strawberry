local skynet = require "skynet"
-- local cluster = require "cluster"
local csvreader = require "common.csvReader"
-- local query = require "query"
local errorcode = require "gm.web.errorcode"
local json = require "rapidjson"
local pcall = skynet.pcall
local template = {}
local string_split = string.split
local rdb = ".DB"
local wdb = ".DB"

local function root(filename, ... )
	-- body
	return "./../../" .. filename
end

local function web(filename, ... )
	-- body
	return "./../../module/mahjongmgr/web/" .. filename
end

local function print_table(db_name, table_name)
	-- body
	local sql = string.format("select * from columns where table_schema='%s' and table_name='%s';", db_name, table_name)
	assert(rdb and table_name and sql)
	skynet.error(sql)
	local r = query.read(rdb, table_name, sql)
	if #r == 0 then
		return false
	else
	end

	local head = "{\n"
	local head_ord = ""

	local pk = ""
	local fk = ""
	local funcs = ""
	local count = "{\n"
	local fields = "{\n"
	
	for i,v in ipairs(r) do
		head_ord = head_ord..string.format("\tself._head_ord[%d] = self._head['%s']\n", i, v.COLUMN_NAME)

		local seg = "\t\t"..v.COLUMN_NAME.." = {\n"
		local pk_seg = string.format("\t\t\tpk = false,\n")
		local fk_seg = string.format("\t\t\tfk = false,\n")
		if v.COLUMN_KEY == "PRI" then
			pk = v.COLUMN_NAME
			pk_seg = string.format("\t\t\tpk = true,\n")
		else
			local sql = string.format("select * from INFORMATION_SCHEMA.KEY_COLUMN_USAGE WHERE TABLE_NAME ='%s' and COLUMN_NAME = '%s'", table_name, v.COLUMN_NAME)
			assert(rdb and table_name and sql)
			local r = query.read(rdb, table_name, sql)
			for i,vv in ipairs(r) do
				if vv.CONSTRAINT_NAME == "PRIMARY" then
					print(sql)
					ret.ok = 0
					ret.msg = "PRIMARY failture"
					return ret
				end	
				local sql = string.format("select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS t where t.TABLE_NAME='%s' and CONSTRAINT_TYPE='FOREIGN KEY' and CONSTRAINT_NAME = '%s'", table_name, vv.CONSTRAINT_NAME)
				assert(rdb and table_name and sql)
				local r = query.read(rdb, table_name, sql)
				print(sql)
				if #r == 1 then
					fk_seg = string.format("\t\t\tfk = true,\n")	
					fk = v.COLUMN_NAME
				end	
			end
		end
		seg = seg .. pk_seg
		seg = seg .. fk_seg
		seg = seg .. string.format("\t\t\tcn = \"%s\",\n", v.COLUMN_NAME)
		seg = seg .. string.format("\t\t\tuq = false,\n")
		if v.DATA_TYPE=="int" or v.DATA_TYPE=="bigint" or v.DATA_TYPE=="tinyint" or v.DATA_TYPE=="smallint" then
			seg = seg .. string.format("\t\t\tt = \"%s\",\n", "number")
		elseif v.DATA_TYPE == "varchar" or v.DATA_TYPE == "char" then
			seg = seg .. string.format("\t\t\tt = \"%s\",\n", "string")
		end
		seg = seg .. "\t\t},\n"
		head = head .. seg

		count = count .. string.format("\t\t\t%s = 0,\n", v.COLUMN_NAME)
		fields = fields .. string.format("\t\t\t%s = 0,\n", v.COLUMN_NAME)
	end
	head = head.."\t}\n"
	fields = fields.."\t\t}\n"
	count = count.."\t\t}\n"
	
	local module_path = skynet.getenv("module_path")
	local path = module_path.."lualib/models/"
	
	local s = require("entity_template")
	local entitycls = table_name.."_entity"
	local entitypath = path..table_name.."_entity.lua"
	local addr = io.open(entitypath, "w")
	local content = string.format(s, entitycls, fields, count, "string.format(\"no exist %s\", k)")
	addr:write(content)
	addr:close()

	local s = require("set_template")
	local setcls = table_name.."_set"
	local setpath = path..table_name.."_set.lua"
	local addr = io.open(setpath, "w")
	local content = string.format(s, setcls, table_name, head, head_ord, pk, fk, entitycls)
	addr:write(content)
	addr:close()
	return true
end

local function exe_percudure(table_name)
	-- body
	-- local sql = "select TABLE_NAME from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = " .. '"' .. "user" .. '"' .. "and TABLE_NAME NOT like" .. "'" .. "g_%" .. "'";
    -- print(sql)
    -- local table_list = db:query(sql)

    -- for k, v in ipairs(table_list) do
        -- print("db_table_list value: ", v)
        local script =  {}
        local tmpsql1 = {}
        local tmpsql2 = {}
        local tmpsql3 = {}
        local tmpsql4 = {}

        local sql = string.format("select COLUMN_NAME , DATA_TYPE , COLUMN_TYPE from information_schema.`COLUMNS` where table_name = " .. '"' .. "%s" .. '";', table_name)
        assert(rdb and table_name and sql)
        local col_val = query.read(rdb, table_name, sql)
        assert(col_val)                 
        for k, v in ipairs(col_val) do 
            for sk, sv in pairs(v) do  
                if sv == "int" then 
                    -- print("string is ")
                end                      
                -- print(sk, sv, type(sv))
            end                        
        end                            
                        
        --format each percudure part   
        local idx = 0                       
        for sk, sv in ipairs(col_val) do
            if idx > 0 then             
                table.insert(tmpsql1, ", ")
                table.insert(tmpsql2, ", ")
                table.insert(tmpsql3, ", ")
                table.insert(tmpsql4, ", ")
            else
                idx = 1
            end 
            
            if sv.DATA_TYPE == "varchar" then
                table.insert(tmpsql1, string.format("IN %s %s", "in_" .. sv.COLUMN_NAME, sv.COLUMN_TYPE))
            else
                table.insert(tmpsql1, string.format("IN %s %s", "in_" .. sv.COLUMN_NAME, sv.DATA_TYPE))
            end

            table.insert(tmpsql2, string.format("`%s`", sv.COLUMN_NAME))
            table.insert(tmpsql3, string.format("in_%s", sv.COLUMN_NAME))
            table.insert(tmpsql4, string.format("`%s` = in_%s", sv.COLUMN_NAME, sv.COLUMN_NAME))
        end 
        
        table.insert(tmpsql1, ")\n")
        table.insert(tmpsql2, ")")
        table.insert(tmpsql3, ")\n")
        table.insert(tmpsql4, ";\n")

        --chain all tmpsqlx up
        table.insert(script, "DELIMITER $$\n")
        table.insert(script, string.format("DROP PROCEDURE IF EXISTS `%s` $$\n ", "qy_insert_" .. table_name))
        table.insert(script, string.format("CREATE DEFINER=`root`@`%%` PROCEDURE `%s`(", "qy_insert_" .. table_name))
        table.insert(script, table.concat(tmpsql1))
        table.insert(script, "BEGIN \n")
        table.insert(script, string.format("insert into %s (%s values (%s", table_name, table.concat(tmpsql2), table.concat(tmpsql3)))
        table.insert(script, string.format("on duplicate key update %s", table.concat(tmpsql4)))
        table.insert(script, "END$$ \n")
        table.insert(script, "DELIMITER ;")
        local percudure = table.concat(script)
        -- print("#####################################BEGIN")
        -- print(percudure)
        -- print("#####################################end")
        -- query.write(".db", table_name, percudure)
        return percudure
    -- end 
end

local VIEW = {}

function VIEW:index()
	-- body
	if self.method == "get" then
		local filename = "../../service/web/statics/index.html"
		if template[filename] then
			return template[filename]
		else
			local fd = io.open(filename)
			if fd then
				local c = fd:read("a")
				return c
			else
				assert(false)
			end
		end
	end
end

function VIEW:user()
	-- body
	if self.method == "get" then
	end
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

function VIEW:email()
	-- body
	if self.method == "get" then
		local func = template.compile(path("email.html"))
		return func { message = "EMAIL"}
	elseif self.method == "post" then
		local body = json.decode(self.body)
		local send_type = tonumber(body["send_type"])
		local c = {}
		c["type"]     = tonumber(body["type"])  -- 1 or 2
		c["title"]    = body["title"]
		c["content"]  = body["content"]
		c["itemsn1"]  = tonumber(body["itemsn1"])
		c["itemnum1"] = tonumber(body["itemnum1"])
		c["itemsn2"]  = tonumber(body["itemsn2"])
		c["itemnum2"] = tonumber(body["itemnum2"])
		c["itemsn3"]  = tonumber(body["itemsn3"])
		c["itemnum3"] = assert(tonumber(body["itemnum3"]))
		c["iconid"]   = tonumber(tonumber(body["iconid"]))

		local receiver = tonumber(body["receiver"])
		if send_type == 1 then
			skynet.send(".channel", "lua", "send_email_to_group", c, {{ uid = receiver }})
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
	elseif self.method == "file" then
		local file = self.file
		assert( csvreader and file )
		print("filecont is  " , file )
		local cont = string_split( file , "\r\n" )
		assert( cont )
		for k , v in ipairs( cont ) do
			local ne = {}
			ne.type = tonumber( v.email_type )
			print()
			ne.title = v.title
			ne.content = v.content
			local titem = util.parse_text( v.reward , "(%d+%*%d+%*?)" , 2 )
			assert( titem )
			local i = 1
			for sk , sv in ipairs( titem ) do

				local itemsn = "itemsn" .. i
				local itemnum = "itemnum" .. i

				ne[ itemsn ] = tonumber( sv[ 1 ] )
				ne[ itemnum ] = tonumber( sv[ 2 ] )
				print( ne[ itemsn ] , ne[ itemnum ])
				i = i + 1
			end 

			skynet.send(".channel", "lua", "send_email_to_group", ne , { { uid = assert( tonumber( v.csv_id ) ) } } )
		end

		local ret = {}
		ret.errorcode = errorcode[1].code
		ret.msg = errorcode[1].msg
		return json.encode(ret)
	end
end

function VIEW:props()
	-- body
	if self.method == "get" then
		local users = skynet.call(db, "lua", "command", "select_and", "users")
		for i,v in ipairs(users) do
			for kk,vv in pairs(v) do
				print(kk,vv)
			end
		end
		local func = template.compile(path("props.html"))
		return func { message = "fill in the blank text.", users = users }
	elseif self.method == "post" then
		local uaccount = self.body["uaccount"]
		local csv_id = tonumber(self.body["csv_id"])
		local num = tonumber(self.body["num"])
		if not csv_id and not num then
			local ret = {}
			ret.errorcode = errorcode.E_SUCCUSS
			return ret
		end
		local user = skynet.call(db, "lua", "command", "select_user", { uaccount = uaccount})
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
		return func { message = "fill in the blank text.", users = users }
	elseif self.method == "post" then
		if self.body["cmd"] == "user" then
			local uaccount = self.body["uaccount"]
			local user = skynet.call(db, "lua", "command", "select_user", { uaccount = uaccount})
			local achievements = skynet.call(util.random_db(), "lua", "command", "select_and", "equipments", { user_id = user.id })
			local ret = {
				errorcode = 0,
				msg = "succss",
				achievements = achievements
			}
			return ret
		elseif self.body["cmd"] == "equip" then
			local user = skynet.call(db, "lua", "command", "select_user", { uaccount = uaccount})
			skynet.send(db, "lua", "command", "insert", { user_id = user.id, achievement_id = achievement_id, level = level})
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
		if db_name then else db_name = "project" end
		-- query table_name
		local sql = string.format("select table_name from information_schema.tables where table_schema='%s' and table_type='base table'", db_name)
		skynet.error(sql)
		local r = query.read(rdb, "all", sql)
		if r and #r > 0 then
			local seg = ""
			skynet.error("enter information_schema.")
			for i,v in ipairs(r) do
				for kk,vv in pairs(v) do
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

function VIEW:percudure( ... )
	-- body
	if self.method == "post" then
		local r = query.read(rdb, "all", "select table_name from information_schema.tables where table_schema='project' and table_type='base table'")
		if r then
			local ok, result = pcall(function ()
				-- body
				local state = ""
				for i,v in ipairs(r) do
					for kk,vv in pairs(v) do
						local s = exe_percudure(vv)
						state = state .. s .. "\n"
					end
				end
				local addr = io.open(root("config/cat/cat.sql"), "w")
				addr:write(state)
				addr:close()
			end)
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

function VIEW:addrole( ... )
	-- body
	if self.method == "post" then
		local uid = self.body["uid"]
	end
end

function VIEW:test( ... )
	-- body
	if true then
		return { id = 2}
	else
		if self.method == "post" then
			local data = {
				{id=1, author="Pete Hunt", text="This is one comment"},	
				{id=2, author="Jordan Walke", text="This is *another* comment"}
			};
			return data
		elseif self.method == "get" then
			return {id=1}
		end
	end
end

function VIEW:_404()
	-- body
	return "404"
end

return VIEW
