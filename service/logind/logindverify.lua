local skynet = require "skynet"
require "skynet.manager"
local crypt = require "skynet.crypt"
local httpsc = require "https.httpc"
local log = require "chestnut.skynet.log"
local guid = require "guid"

local NORET = {}
local server_win = { ["sample1"] = true }
local server_adr = { ["sample"]  = true }
local appid  = "wx3207f9d59a3e3144"
local secret = "d4b630461cbb9ebb342a8794471095cd"
local assert = assert

local function gen_uid()
	-- body
	return guid()
end

local function new_account(username, password, uid) 
	local account = {}
	account.username = username
	account.password = password
	account.uid = uid
	skynet.call(".DB", "lua", "write_new_account", account)
end

local function new_unionid(unionid, uid)
	-- body
	assert(unionid and uid)
	local db_union = {}
	db_union.unionid = unionid
	db_union.uid = uid
	skynet.call(".DB", "lua", "write_new_union", db_union)
end

local function new_user(uid, sex, nickname, province, city, country, headimg, openid)
	-- body
	assert(uid and sex and nickname and province and city and country and headimg)
	local user = {}
	user.uid = uid
	user.sex            = sex
	user.nickname       = nickname
	user.province       = province
	user.city           = city
	user.country        = country
	user.headimg        = headimg
	user.openid         = openid
	user.nameid         = 0
	user.create_at      = os.time()
	user.update_at      = os.time()
	user.login_at       = os.time()
	user.new_user       = 1
	user.level          = 1
	skynet.call(".DB", "lua", "write_new_user", user)
end

-- @breif 账号登陆 username => uid
local function auth_win_myself(username, password)
	-- body
	print(username, password)
	assert(type(username) == 'string' and #username > 0)
	assert(type(password) == 'string' and #password > 0)
	local res = skynet.call(".DB", "lua", "read_account_by_username", username, password)
	for k,v in pairs(res) do
		print(k,v)
	end
	if type(res.accounts) == 'table' and #res.accounts == 1 then
		local uid = res.accounts[1].uid
		if #res.users <= 0 then
			-- 初始默认用户数据
			local sex = 1
			local r = math.random(1, 10)
			if r > 5 then
				sex = 1
			else
				sex = 0
			end
			local nickname = username
			local province = 'Beijing'
			local city     = "Beijing"
			local country  = "CN"
			local headimg  = "xx"
			new_user(uid, sex, nickname, province, city, country, headimg, 0)
		end
		return uid
	else
		-- 创建新账号和新用户信息
		local uid = gen_uid()          -- integer
		log.info(string.format("new user uid = %d", uid))

		local sex      = 1
		local nickname = "hell"
		local province = 'Beijing'
		local city     = "Beijing"
		local country  = "CN"
		local headimg  = "xx"

		new_account(username, password, uid)
		new_user(uid, sex, nickname, province, city, country, headimg, 0)
		return uid
	end
end

-- @breif OpenAuth登陆 openid => uid
local function auth_android_wx(code, ... )
	-- body
	httpc.dns()
	httpc.timeout = 1000 -- set timeout 1 second
	local respheader = {}
	local url = "/sns/oauth2/access_token?appid=%s&secret=%s&code=%s&grant_type=authorization_code"
	url = string.format(url, appid, secret, code)
	
	local ok, body, code = skynet.call(".https_client", "lua", "get", "api.weixin.qq.com", url)
	if not ok then
		local res = {}
		res.code = 201
		res.uid  = 0
		return res
	end
		
	local res = json.decode(body)
	local access_token  = res["access_token"]
	local expires_in    = res["expires_in"]
	local refresh_token = res["refresh_token"]
	local openid        = res["openid"]
	local scope         = res["scope"]
	local unionid       = res["unionid"]
	log.info("access_token = " .. access_token)
	log.info("openid = " .. openid)

	local uid = db:get(string.format("tb_openid:%s:uid", unionid))
	if uid and uid > 0 then
		return uid
	else
		url = "https://api.weixin.qq.com/sns/userinfo?access_token=%s&openid=%s"
		url = string.format(url, access_token, openid)
		local ok, body, code = skynet.call(".https_client", "lua", "get", "api.weixin.qq.com", url)
		if not ok then
			error("access api.weixin.qq.com wrong")
		end

		local res = json.decode(body)
		local nickname   = res["nickname"]
		local sex        = res["sex"]
		local province   = res["province"]
		local city       = res["city"]
		local country    = res["country"]
		local headimgurl = res["headimgurl"]
		url = string.sub(headimgurl, 19)
		log.info(url)
		local statuscode, body = httpc.get("wx.qlogo.cn", url, respheader)
		local headimg = crypt.base64encode(body)

		local uid = gen_uid()
		local nameid = gen_nameid()

		new_unionid(unionid, uid)
		new_nameid(nameid, uid)
		new_user(uid, sex, nickname, province, city, country, headimg, unionid, uid)

		return uid
	end
end

local CMD = {}

function CMD.start()
	-- body
	return true
end

function CMD.close()
	-- body
	return true
end

function CMD.kill()
	-- body
	skynet.exit()
end

function CMD.signup(server, code, ... )
	-- body
	if server_adr[server] then
		local ok, err = pcall(auth_android_wx, code)
		if ok then
			local res = {}
			res.code = 200
			res.uid = err
			return res
		else
			log.err(err)
			local res = {}
			res.code = 501
			return res
		end
	elseif server_win[server] then
		local ok, err = pcall(auth_win_myself, code, ...)
		if ok then
			local res = {}
			res.code = 200
			res.uid = err
			return res
		else
			log.error("auth_win_myself error is [%s]", err)
			local res = {}
			res.code = 501
			return res
		end
	end
end

skynet.start(function ()
	-- body
	skynet.dispatch("lua", function (_, _, cmd, ... )
		-- body
		local f = assert(CMD[cmd])
		local r = f( ... )
		if r ~= NORET then
			skynet.retpack(r)
		end
	end)
	skynet.register ".logindverify"
end)