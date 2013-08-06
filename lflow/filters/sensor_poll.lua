local toribio = require 'lflow/toribiostarter'.toribio
local sched = require 'sched'

local dev_task

return function(device, step, start)
  if start==true then 
    if dev_task then dev_task:kill() end
    local bd = toribio.wait_for_device('bb-'..device)
    dev_task = sched.run(function()
      while true do
        sched.sleep(step)
        output(bd.getValue())
      end
    end)
  else 
    if dev_task then dev_task:kill() end
  end
end

