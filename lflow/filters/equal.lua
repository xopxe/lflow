return  function(...)
  local v = select(1, ...)
  for i=2, select('#', ...)-1 do
    if v~=select(i, ...) then return end
  end
  return v
end


