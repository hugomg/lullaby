local M = {}

local unpack = unpack or table.unpack

M.Set = function(xs)
  local s = {}
  for _, x in ipairs(xs) do
    s[x] = true
  end
	return s
end

M.map = function(xs, f)
	local ys = {}
	for i,x in ipairs(xs) do
		ys[i] = f(x)
	end
	return ys
end

M.xpairs = function(xss)
  local f, s, i = ipairs(xss)
  return function()
    local xs
    i, xs = f(s, i)
		if i == nil then
			return nil
		else
			return i, unpack(xs)
		end
  end
end

M.xmap = function(xss, f)
	local ys = {}
	for i, xs in ipairs(xss) do
		ys[i] = f(unpack(xs))
	end
	return ys
end

return M