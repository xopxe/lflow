return function(...)
  local min
  for i=1, select('#', ...)-1 do
    local v = select(i, ...)
    if not min or v>min then
      min=v
    end
  end
  return min
end
