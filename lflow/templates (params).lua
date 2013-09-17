local fmax = {
  parameters = {},
  outputs = {'max'},
  s = [[
    local max
    for _, v in ipairs(flow_in) do
      if not max or v>max then
        max=v
      end
    end
    flow_out.max(max)
  ]],
}

local fmin = {
  parameters = {},
  outputs = {'min'},
  s = [[
    local min
    for _, v in ipairs(flow_in) do
      if not min or v>min then
        min=v
      end
    end
    flow_out.min(min)
  ]],
}

local fequal = {
  parameters = {},
  outputs = {'value'},
  s = [[
    local v = flow_in[1]
    for k = 2, #flow_in do
      if v~=flow_in[2] then return end
    end
    flow_out.value(v)
  ]],
}

local fprint = {
  parameters = {},
  outputs = {},
  s = [[
    print('>', table.concat(flow_in, ' '))
  ]],
}

return {
  max = fmax,
  min = fmin,
  equal = fequal,
  print = fprint,
}
