local toribio = require 'lflow/toribiostarter'.toribio

local md = toribio.wait_for_device('bb-motors')

return function(left, right, enable)
  if enable==true then 
    local l, r
    if left then l=1000 end
    if right then r=1000 end
    md.setvel2mtr(1, l, 1, r)
  else 
    md.setvel2mtr(1, 0, 1, 0)
  end
end

