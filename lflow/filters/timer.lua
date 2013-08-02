local sched = require 'sched'
local timer_taskd
return function(step, start)
  if timer_taskd then 
    timer_taskd:kill()
    timer_taskd=nil 
  end
  if start==true then 
    timer_taskd = sched.run(function()
      local i=1
      while true do
        sched.sleep(step)
        --print ('.', i)
        output(i)
        i=i+1
      end
    end)
  end
  return
end

