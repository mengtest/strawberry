local service = require "service"
local CMD = require "chestnut.store.cmd"

service.init {
    name = ".STORE",
    command = CMD
}
