--package.path = package.path .. ";;;Lumen/?.lua"

--require 'strict'

local sched = require 'sched'
local log = require 'log'
require "tasks/selector".init({service='nixio'})

local toribio = require 'toribio'

--loads from a configuration file
local function load_configuration(file)
	local func_conf, err = loadfile(file)
	assert(func_conf,err)
	local conf = toribio.configuration
	local meta_create_on_query 
	meta_create_on_query = {
		__index = function (table, key)
			table[key]=setmetatable({}, meta_create_on_query)
			return table[key]
		end,
	}
	setmetatable(conf, meta_create_on_query)
	setfenv(func_conf, conf)
	func_conf()
	meta_create_on_query['__index']=nil
end

load_configuration('toribio.conf')

--sched.run(function()
	for _, section in ipairs({'deviceloaders', 'tasks'}) do
		for task, conf in pairs(toribio.configuration[section] or {}) do
			log ('LFLOWTRB', 'DETAIL', 'Processing Toribio conf %s %s: %s', section, task, tostring((conf and conf.load) or false))

			if conf and conf.load==true then
				--[[
				local taskmodule = require (section..'/'..task)
				if taskmodule.start then
					local ok = pcall(taskmodule.start,conf)
				end
				--]]
				log ('LFLOWTRB', 'INFO', 'Starting Toribio %s %s', section, task)
				toribio.start(section, task)
			end
		end
	end
--end)

--print('Toribio go!')
log ('LFLOWTRB', 'INFO', 'Toribio Ready')

return {
  toribio = toribio
}
