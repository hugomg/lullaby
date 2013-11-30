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
local U = require 'util'

U.inEnv(H, function(_ENV)
	prettyPrintTo(io.stdout,
		Document{encoding="utf-8", title="Hello", body=function()
			RawHtml(Raw"<!-- This is a comment -->")
			SPAN{ onclick=Raw'alert("oi")', 'as<d'}
			RawHtml(Raw"<span>OI</span>")
			IMG{ SRC=AbsUrl{'http', 'www.pudim.com.br'}, alt="Pudim" }
			DIV{ class="FOO", ["fb:foo"]=Raw"bar", function()
				BUTTON{disabled=true, function()
					Text("Click me")
				end}
				PRE{ style=Raw'background-color:green', contenteditable='true', 
					'XXX'}
				OL{function()
					LI{function() 
						A{"Full",
							href=AbsUrl{'http', 'www.example.com', {'a','b.html'}, params={t='10m',x='y'}, hash="x1"}}
					end}
					LI{function()
						A{"abs", 
							href=AbsUrl{'http', 'www.google.com'}}
					end}
					LI{function()
						A{"no scheme", ['data-foo']=Raw"qqq",
							href=AbsUrl{nil, 'www.google.com'}}
					end}
					LI{function()
						A{"absolute path", 
							href=AbsUrl{nil, nil, {'x', 'y', 'z.html'}}}
					end}
					LI{function()
						A{"relative",
							href=RelUrl{{'foo'}, params={t='10m'}, hash="x2"}}
					end}
					LI{function()
						A{"just query",
							href=RelUrl{nil, params={t='10m'}, hash="x3"}}
					end}
					LI{function()
						A{"just hash",
							href=RelUrl{nil, hash="x4"}}
					end}
					LI{function()
						A{"raw",
							href=Raw("http://www.example.com")}
					end}
				end}
			end}
		end}
	)
	print()
end)