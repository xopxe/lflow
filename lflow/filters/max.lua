return function(...)
  local max
  for i=1, select('#', ...)-1 do
    local v = select(i, ...)
    if not max or v>max then
      max=v
    end
  end
  return max
end
