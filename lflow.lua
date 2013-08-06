--look for packages one folder up.
package.path = package.path .. ";;;./lflow/Toribio/?.lua;./lflow/Toribio/Lumen/?.lua"

require "log".setlevel('INFO', 'FFLOW')
require "log".setlevel('INFO', 'TORIBIO')
--require "log".setlevel('ALL', 'TORIBIO')

local sched = require "sched"
local lflow = require 'lflow/init'
local loadfile = require 'lib/compat_env'.loadfile

--sched.sigrun({emitter='*', events={'*'}}, print)

local filename = _G.arg[1] --'lflow/test.lflow'

if filename then
  local file=assert(io.open(filename, 'r'))
  local linenumber = 0
  for line in file:lines() do
    linenumber=linenumber+1
    sched.run(function()
        
      --line = line:gsub('%s+', '') --remove whitespaces
      
      if line~='' and line:sub(1,1)~='#' then
        --print ('line:', line)
        local filter_name, in_params, filter_body, out_params 
          = line:match('^%s*(.-)%s*%:(.*)%>%s*(.-)%s*%>%s*(.-)%s*$')
        --print ('line parsed:', filter_name, in_params, filter_body, out_params)
        if filter_name then 
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
          local filter_path = './lflow/filters/'..filter_body..'.lua'
          local filter, err = lflow.create_filter(filter_name, inputs, outputs, filter_path)
          if not filter then 
            io.stderr:write('lflow: '..filename..':'..linenumber..': '..tostring(err)..'\n')
          end
        else
          error() --FIXME
        end
      end
    end)
  end
  sched.run(lflow.start)
end

sched.go()
