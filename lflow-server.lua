package.path = package.path .. ";;;./lflow/Toribio/?.lua;./lflow/Toribio/Lumen/?.lua"

local log = require 'log'
log.setlevel('ALL', 'LFLOWSRV')
--require "log".setlevel('ALL', 'HTTP')

--require "strict"

local service = _G.arg [1] or 'nixio'

local sched = require "sched"
require "tasks/selector".init({service=service})

local http_server = require "tasks/http-server"
local lflow = require 'lflow/init'

if service=='nixio' then
	http_server.serve_static_content_from_stream('/', 'lflow/www')
else
	http_server.serve_static_content_from_ram('/', 'lflow/www')
end

local ffilters = {}

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

local linenumber = 0

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
				ws:close()
        filters_stop ()
				return
			end
			if opcode == ws.TEXT then
				--sh.pipe_in:write('line', message)
        for line in message:gmatch("[^\r\n]+") do
          --print ('line:', line)
          if line == '#RUN' then
            filters_start()
          elseif line == '#STOP' then
            filters_stop()
          elseif line == '#CLEAR' then
            filters_delete()
          else
            linenumber=linenumber+1
            if line~=string.rep(' ', #line) and not line:find('^%s*#') then
              local oldprint = lflow.proto_filter_env.print
              lflow.proto_filter_env.print = function(...)
                for i = 1, select('#', ...) do
                  ws:send(tostring(select(i, ...))..'\t')
                end
                ws:send('\r\n')
              end
              local filter, err = lflow.parse_line(line)
              lflow.proto_filter_env.print = oldprint
              if filter then 
                ffilters['filter: '..linenumber] = filter
              else
                ws:send('lflow ['..linenumber..']: '..tostring(err)..'\r\n')
              end
            end
          end
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

sched.go()
