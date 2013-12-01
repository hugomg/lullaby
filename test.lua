require 'lullaby.strict'
local sax = require 'lullaby.sax'

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

local H = require 'lullaby'

H.usingHtml(function(_ENV)
	prettyPrintDocumentToFile(io.stdout,
		Document{
			encoding="utf-8",
			title="Hello",
			head=function()
				LINK{rel='stylesheet', href=Raw'./foo.css'} 
			end,
			body=function()
				RawHtml("<!-- This is a comment -->")
				SPAN{ onclick=Raw'alert("oi")', 'as<d'}
				RawHtml("<span>OI</span>")
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
							A{"no scheme", ['data-foo']="true",
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
					--SPAN{B{"x"}} --this line should raise an error
				end}
			end,
		}
	)
	print()
end)

local H = require 'lullaby'

local document = H.Document({
  title = 'My first Document',
  head = function()
    H.LINK{rel="stylesheet", href=H.RelUrl{{'style.css'}}}
  end,
  body = function()
    H.H1{"hello World"}
    H.DIV{class="foo", function()
      H.Text("Hello ")
      H.BUTTON{disabled = true, "World"}
    end}
  end,
})


print("====")
H.printDocumentToFile(io.stdout, document)
print()

print("====")
H.prettyPrintDocumentToFile(io.stdout, document)
print()

print("------")
print("==", H.printDocumentToString(function()
	H.DIV{"Hello"}
end))