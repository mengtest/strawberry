local skynet = require "skynet"
require "skynet.manager"
local httpc = require "https.httpc"
local dns = require "skynet.dns"

local log = require "log"


local function main()
	httpc.dns()	-- set dns server
	httpc.timeout = 100	-- set timeout 1 second
	print("GET baidu.com")
	local respheader = {}
	local status, body = httpc.get("baidu.com", "/", respheader)
	print("[header] =====>")
	for k,v in pairs(respheader) do
		print(k,v)
	end
	print("[body] =====>", status)
	print(body)

	local respheader = {}
	dns.server()
	local ip = dns.resolve "baidu.com"
	print(string.format("GET %s (baidu.com)", ip))
	local status, body = httpc.get("baidu.com", "/", respheader, { host = "baidu.com" })
	print(status)
end

-- skynet.start(function()
-- 	print(pcall(main))
-- 	skynet.exit()
-- end)

skynet.start(function()
	local logger = skynet.uniqueservice("log")
	skynet.call(logger, "lua", "start")
	
	-- skynet.uniqueservice("protoloader")
	local console = skynet.newservice("console")
	skynet.newservice("debug_console",8000)

	-- local codweb = skynet.uniqueservice("codweb")
	-- skynet.call(codweb, "lua", "start")
	
	print(pcall(main))

	log.info("host successful .")
	skynet.exit()
end)
