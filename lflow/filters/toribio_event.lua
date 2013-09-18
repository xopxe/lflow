local toribio = require 'lflow/toribiostarter'.toribio
local sched = require 'sched'

local dev_task

return function(device, event, start)
  if start==true then 
    if dev_task then dev_task:kill() end
    local d = toribio.wait_for_device(device)
    local dev_task = toribio.register_callback (d, event, output)
  elseif dev_task then 
    dev_task:kill() 
    dev_task=nil
  end
end

