package.path = package.path ..";;;./lflow/Toribio/?.lua;./lflow/Toribio/?/init.lua;;./lflow/Toribio/lumen/?.lua"


local log = require 'lumen.log'
log.setlevel('ALL', 'LFLOWSRV')
--require "log".setlevel('ALL', 'HTTP')

local json=require "lumen.lib.dkjson"
local jencode, jdecode = json.encode, json.decode

--require "strict"

local service = _G.arg [1] or 'nixio'

local sched = require "lumen.sched"
require "lumen.tasks.selector".init({service=service})

local http_server = require "lumen.tasks.http-server"
local lflow = require 'lflow'

if service=='nixio' then
	http_server.serve_static_content_from_stream('/', 'lflow/www')
else
	http_server.serve_static_content_from_ram('/', 'lflow/www')
end

local ffilters = {}
local linenumber = 0

local function filters_stop ()
  sched.run( function()
    log('LFLOWSRV', 'DETAIL', 'Stopping flow')
    --sched.run(function() sched.signal(fevents['lflow_run'], false) end)
    lflow.stop()
    for fname, f in pairs(ffilters)do
      log('LFLOWSRV', 'DEBUG', 'Pausing "%s" (%s)', fname, tostring(f.taskd))
      f.taskd:set_pause(true)
    end
  end)
end

local function filters_delete ()
  sched.run( function()
    log('LFLOWSRV', 'DETAIL', 'Resetting flow')
    --sched.run(function() sched.signal(fevents['lflow_run'], false) end)
    lflow.stop()
    for fname, f in pairs(ffilters)do
      log('LFLOWSRV', 'DEBUG', 'Killing "%s" (%s)', fname, tostring(f.taskd.status))
      if f.taskd then
        f.taskd:set_pause(true)
        f.taskd:kill()
      end
      ffilters[fname]=nil
    end
    linenumber = 0
  end)
end

local function filters_start ()
  sched.run( function()
    log('LFLOWSRV', 'DETAIL', 'Starting flow')
    for fname, f in pairs(ffilters)do
      log('LFLOWSRV', 'DEBUG', 'Unpausing "%s" (%s)', fname, tostring(f.taskd))
      f.taskd:set_pause(false)
    end
    --sched.run(function() sched.signal(fevents['lflow_run'], true) end)
    lflow.start()
  end)
end

http_server.set_websocket_protocol('lumen-lflow-protocol', function(ws)
  --[[
  print=function(...) 
    for i=1, select('#',...) do
      ws:send(tostring(select(i,...))..'\r\n')  
    end
  end
  --]]
	--local shell = require 'tasks/shell' 
	--local sh = shell.new_shell()
	
	sched.run(function()
		while true do
			local message,opcode = ws:receive()
      --print('from ws', message,opcode)
			if not message then
        log('LFLOWSRV', 'DEBUG', 'Closing websocket')
				ws:close()
        filters_stop ()
				return
			end
			if opcode == ws.TEXT then
				--sh.pipe_in:write('line', message)
        local command = jdecode(message)
        --print ('>>>>>', message, command.action)
        
        if type(command.program) == 'string' then
          for line in (command.program):gmatch("[^\r\n]+") do
            linenumber=linenumber+1
            if line~=string.rep(' ', #line) and not line:find('^%s*#') then
              local oldprint = lflow.proto_filter_env.print
              lflow.proto_filter_env.print = function(...)
                --for i = 1, select('#', ...) do
                --  ws:send(tostring(select(i, ...))..'\t')
                --end
                --ws:send('\r\n')
                ws:send(jencode({
                  action = 'OUTPUT',
                  output = {...},
                }))
              end
              local filter, err = lflow.parse_line(line)
              lflow.proto_filter_env.print = oldprint
              if filter then 
                ffilters['filter: '..linenumber] = filter
              else
                ws:send(jencode({
                  action = 'LOG',
                  text = 'lflow ['..linenumber..']: '..tostring(err)
                }))
              end
            end
          end
        end
        if command.action == 'RUN' then
          filters_start()
        elseif command.action == 'STOP' then
          filters_stop()
        elseif command.action == 'CLEAR' then
          filters_delete()
        elseif command.action ~= nil then
          log('LFLOWSRV', 'WARNING', 'Unknown command in websocket: "%s"', tostring(command.action))
        end          
      end
		end
	end)
	
	sched.run(function()
    --[[
		while true do
			local _, prompt, out = sh.pipe_out:read()
			if out then 
				assert(ws:send(tostring(out)..'\r\n'))
			end
			if prompt then
				assert(ws:send(prompt))
			end
		end
    --]]
	end)
end)

local conf = {
	ip='127.0.0.1', 
	port=8080,
	ws_enable = true,
	max_age = {ico=5, css=60*60},
}
http_server.init(conf)

log('LFLOWSRV', 'INFO', 'Server started at %s:%s', tostring(conf.ip), tostring(conf.port))

for _, h in pairs (http_server.request_handlers) do
  log('LFLOWSRV', 'INFO', 'Server listening for pattern "%s"', tostring(h.pattern))
end

sched.loop()
