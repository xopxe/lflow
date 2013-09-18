--look for packages one folder up.
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
    sched.run(function()
        
      --line = line:gsub('%s+', '') --remove whitespaces
      
      if line~=string.rep(' ', #line) and not line:find('^%s*#') then
        --print ('line:', line)
        local in_params, filter_body, out_params 
          = line:match('^([^%>]*)%>%s*(.-)%s*%>%s*([^%>]*)%s*$')
        --print ('line parsed:', in_params, filter_body, out_params)
        if in_params and filter_body and out_params then 
          local inputs, outputs = {}, {}
          
          --list in params
          for p in in_params:gmatch("[^,]+") do
            p = p:match('^%s*(.-)%s*$')
            inputs[#inputs+1] = tonumber(p) or p
            --print('param', #inputs, p)
          end
          
          --list outparams
          for p in out_params:gmatch("[^,]+") do
            p = p:match('^%s*(.-)%s*$')
            outputs[#outputs+1] = p
            --print('output', #inputs, p)
          end
          
          --print ('+', filter_body)
          local filter, err
          --if filter_body:find('^%s*function%*%(.+end%s*$') then
          if filter_body:find('^%s*function%s*%(.+end%s*$') then
            --filter_body is source code
            filter, err = lflow.create_filter(inputs, outputs, 'string', 'return '..filter_body)
          else
            --filter_body must be filename
            local filter_path = './lflow/filters/'..filter_body..'.lua'
            filter, err = lflow.create_filter(inputs, outputs, 'file', filter_path)
          end
          if filter then 
            ffilters['filter: '..linenumber] = filter
          else
            io.stderr:write('lflow: '..filename..':'..linenumber..': '..tostring(err)..'\n')
          end
        else
          error() --FIXME
        end
      end
    end)
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
