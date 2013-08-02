local in_range = false

-- v
-- op
-- reference
-- hysteresis

-- ret 1: true, goes in range; false, leaves range
return  function(v, op, reference, hysteresis)
  if in_range then 
    if 	(op==">" and v<reference-hysteresis) or (op=="<" and v>reference+hysteresis) then
      in_range = false
      return false
    end
  else
    if 	(op==">" and v>reference) or (op=="<" and v<reference) then
      in_range = true
      return true
    end
  end
end


