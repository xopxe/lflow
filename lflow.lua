package.path = package.path .. ";;;./lflow/Toribio/?.lua;./lflow/Toribio/Lumen/?.lua"

local log = require 'log'
log.setlevel('INFO', 'LFLOW')
log.setlevel('ALL', 'TORIBIO')
--require "log".setlevel('ALL', 'TORIBIO')

local sched = require "sched"
local lflow = require 'lflow/init'
local loadfile = require 'lib/compat_env'.loadfile

local filename = _G.arg[1] --'lflow/test.lflow'

local ffilters = {}

local function filters_stop ()
  sched.run( function()
    log('LFLOW', 'DETAIL', 'Stopping flow')
    --sched.run(function() sched.signal(fevents['lflow_run'], false) end)
    lflow.stop()
    for fname, f in pairs(ffilters)do
      log('LFLOW', 'DEBUG', 'Pausing "%s" (%s)', fname, tostring(f.taskd))
      f.taskd:set_pause(true)
    end
  end)
end

local function filters_start ()
  sched.run( function()
    log('LFLOW', 'DETAIL', 'Starting flow')
    for fname, f in pairs(ffilters)do
      log('LFLOW', 'DEBUG', 'Unpausing "%s" (%s)', fname, tostring(f.taskd))
      f.taskd:set_pause(false)
    end
    --sched.run(function() sched.signal(fevents['lflow_run'], true) end)
    lflow.start()
  end)
end

if filename then
  local file=assert(io.open(filename, 'r'))
  local linenumber = 0
  for line in file:lines() do
    linenumber=linenumber+1     
      --line = line:gsub('%s+', '') --remove whitespaces
      
      if line~=string.rep(' ', #line) and not line:find('^%s*#') then
        --print ('line:', line)
        local filter, err = lflow.parse_line(line)
        if filter then 
          ffilters['filter: '..linenumber] = filter
        else
          io.stderr:write('lflow: '..filename..':'..linenumber..': '..tostring(err)..'\n')
        end
      end
  end
  filters_start()
  --[[
  sched.run(function()
    while true do
      sched.sleep(1)
      for k, v in pairs(lflow.fevents) do
        print (k, v.emitted, v.caught)
      end
    end
  end)
  --]]
end

sched.go()
