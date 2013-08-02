return function(...)
  local sum =  select(1, ...)
  for i=2, select('#', ...)-1 do
    sum = sum + select(i, ...)
  end
  return sum
end
