local toribio = require 'lflow/toribiostarter'.toribio
local ld = toribio.wait_for_device('bb-lback')

return function(s)
  return ld.send(tostring(s))
end

