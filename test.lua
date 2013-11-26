require 'strict'
local sax = require 'sax'

local yield = coroutine.yield

local stream = sax.from_coro(function()
	yield(sax.StartEvent('a'))
	for i=1,3 do
		yield(sax.StartEvent('b'))
		yield(sax.TextEvent(tostring(i)))
		yield(sax.EndEvent('b'))
	end
	yield(sax.EndEvent('a'))
end)

sax.print_dom(sax.to_dom(stream))


