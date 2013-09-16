--look for packages two folders up.
--package.path = package.path .. ";;;../../?.lua"

-------------
local lossy_filtering=false
-------------

local M = {}

local require, tostring, assert, pairs, ipairs, select, unpack 
    = require, tostring, assert, pairs, ipairs, select, unpack 

local sched = require 'sched'
local load = require 'lib/compat_env'.load
local loadfile = require 'lib/compat_env'.loadfile
local setfenv = _G.setfenv or require 'compat_env'.setfenv

local log = require 'log'

-- fevents[name] = {} --singleton
local fevents = setmetatable(
  {
    ['lflow_run'] = {emitted=0, caught=0}, --true|false
  }, 
  { 
    __index = function( t, k )
      local v = {emitted=0, caught=0}
      t[k] = v
      return v
    end
  } 
)
M.fevents = fevents

-- fvalues[evname] = value
local fvalues = {}

-- in_events = {string par1, string par2, ...}
-- out_events = {string out1, string out2, ...}
-- p = {parameters={},outputs={},f=function}
M.create_filter = function (in_events, out_events, filter)
  log('LFLOW', 'DETAIL', 'Creating a filter with "%s"', filter)
  
  in_events[#in_events+1] = 'lflow_run'
  
  local waitd = {buff_mode='keep_last'}
  local parameter_values = {}
  local parameter_from_ev = {}
  
  --prepare waitd for in_events
  for i, in_event in ipairs(in_events) do
    if in_event=='true' then
      log('LFLOW', 'DETAIL', 'Adding parameter %d with boolean value "true"', i)
      parameter_values[i] = true
    elseif in_event=='false' then
      log('LFLOW', 'DETAIL', 'Adding parameter %d with boolean value "false"', i)
      parameter_values[i] = false
    elseif type(in_event)=='number' then
      log('LFLOW', 'DETAIL', 'Adding parameter %d with const value "%f"', i, in_event)
      parameter_values[i] = in_event
    elseif type(in_event) == 'string' then
      --test if const string
      local _, _, c, quotedPart = in_event:find("^([\"'])(.*)%1$")
      if c then 
        log('LFLOW', 'DETAIL', 'Adding parameter %d with const string "%s"', i, quotedPart)
        parameter_values[i] = quotedPart
      else
        local fevent = fevents[in_event]
        log('LFLOW', 'DETAIL', 'Adding parameter %d linked to signal "%s" (%s)'
          , i, in_event, tostring(fevent))
        parameter_from_ev[fevent] = i
        waitd[#waitd+1] = fevent
      end
    else
      local errmsg = 'malformed input event ['..i..'] '..tostring(in_event)
      log('LFLOW', 'ERROR', errmsg)
      return nil, errmsg
    end
  end
    
  local n_events_to_wait = #waitd
  local n_outputs = #out_events
  
  --[[
  if n_events_to_wait==0 then
    local errmsg = 'filter has no inputs linked'
    log('LFLOW', 'ERROR', errmsg)
    return nil, errmsg
  end
  --]]
    
  local function emit_output (...)
    for i = 1, select('#',...) do
      local output = select(i,...)
      if output~=nil then
        local out_event = out_events[i]
        log('LFLOW', 'DEBUG', 'Generating output %d linked to "%s": %s', i, out_event, tostring(output))
        local e = fevents[out_event]
        e.emitted = e.emitted+1
        sched.signal(e, output)
      end
    end
  end
    
  --set environment for f
  local env={
    output=emit_output,
  }
  for k, v in pairs(_G) do env[k]=v end
  
  local fdef, err = loadfile(filter, 't', env)
  if not fdef then 
    log('LFLOW', 'ERROR', 'Failed to load factory: %s', err)
    return nil, 'failed to load factory: '..tostring(err)
  end
  
  local f=fdef()
  
  if type(f)~='function' then
    local errmsg = 'factory '.. filter .. ' should return function, returned ' .. type(f)
    log('LFLOW', 'ERROR', errmsg); 
    return nil, errmsg
  end
  
  -- callback for signal arriving
  local n_arrived = 0
  local process_input_signal = function(event, v1, ...)
    local parameter = assert(parameter_from_ev[event])
    log('LFLOW', 'DEBUG', 'Received parameter %s (%s)', parameter, tostring(event))
    event.caught = event.caught + 1
    if parameter_values[parameter]==nil then 
      parameter_values[parameter]=v1
      n_arrived=n_arrived+1
    else
      parameter_values[parameter] = v1 --updating with arrived value
    end
    if n_events_to_wait == n_arrived then
      emit_output( f(unpack(parameter_values)) )
      
      if lossy_filtering then 
        --cleanup arrived_events
        for ev, param in pairs(parameter_from_ev) do 
          parameter_values[param] = nil 
        end
        n_arrived = 0
      end
    end
  end
    
  -- register in ffilter
  local ffilter = {
    --taskd = sched.new_sigrun_task(waitd, process_input_signal),
    taskd = sched.sigrun(waitd, process_input_signal),
    f=f,
    in_events = in_events, 
    out_events = out_events,
  }
  return ffilter
end

return M
