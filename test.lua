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

print("=======")

local H = require 'html'
local AbsUrl = H.AbsUrl
local RelUrl = H.RelUrl
local Raw    = H.Raw

H.prettyPrintTo(io.stdout,
	H.Document("Hello", function()
		H.SPAN({{'onclick', Raw'alert("oi")'}}, 'as<d')
		H.IMG({{'src', AbsUrl('http', 'www.pudim.com.br')}, {'alt', "Pudim" }})
		H.DIV({{'class',"FOO"}}, function()
			H.PRE({}, 'XXX')
			H.A({
				{'href',AbsUrl('http', 'www.example.com', {'a','b'}, {params={{'t', '10m'}, {'x', 'y'}}, hash="x1"}) }
			}, "hello")
			H.A({
				{'href',AbsUrl('http', 'www.google.com') }
			}, "google")
			H.A({
				{'href',RelUrl({'foo'}, {params={{'t', '10m'}}, hash="x1"}) }
			}, "world")
		end)
	end)
)
print()

