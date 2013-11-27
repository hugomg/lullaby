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


-- inEnv: Run the block with the given table as the environment.
-- The second argument MUST be an anonymous callback with `_ENV` as its first argument.
-- Ignores the environment of the callee, uses Util's global environment instead.
do
	
	local function layer_envs(parent, child)
		return setmetatable({}, {
			__index = function(self, k)
				local v = child[k]
				if v == nil then
					v = parent[k]
				end
				return v
			end,
			__newindex = function()
				--I don't know what would be sensible to do here
				error("Cannot set globals inside withEnv")
			end
		})
	end
	
	if 1 == ((function(_ENV) return _G end)({_G=1})) then --shadow an existing global to avoit triggering strict.lua
		--Lua 5.2 environments
		M.inEnv = function(env, body)
			return body(layer_envs(_ENV, env))
		end
	elseif setfenv then
		--Lua 5.1
		M.inEnv = function(env, body)
			local _env = layer_envs(getfenv(), env)
			setfenv(body, _env)
			return body(_env)
		end
	end
end

return M