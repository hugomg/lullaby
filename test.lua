
do
	local say = require("say")
	
	local function raises_error(state, arguments)
		local expected, func = arguments[1], arguments[2]
		local ok, err = pcall(func)
		if ok then return false end
		if type(err) == 'table' then
			return expected.tag == err.tag
		else
			return expected == err
		end
	end

	say:set_namespace("en")
	local pos_key = "assertion.raises_error.positive"
	local neg_key = "assertion.raises_error.negative"
	say:set(pos_key, "Expected error %s to be thrown")
	say:set(neg_key, "Expected error %s not to be thrown")
	assert:register("assertion", "raisesError", raises_error, pos_key, neg_key)
end

describe("SAX", function()
	
	local sax = require 'lullaby.sax'
	local yield = coroutine.yield
		
	it("Should print DOM", function()
		local stream = sax.from_coro(function()
			yield(sax.StartEvent('a', {}))
			for i=1,3 do
				yield(sax.StartEvent('b', {{'x', 'xv'}}))
				yield(sax.TextEvent(tostring(i)))
				yield(sax.EndEvent('b'))
			end
			yield(sax.EndEvent('a'))
		end)

		local dom = sax.to_dom(stream)
		
		assert.are_same(
			--expected
			{nodetype='TAG', tagname='a', attrs={}, children={
				{nodetype='TAG', tagname='b', attrs={{'x', 'xv'}}, children={
					{nodetype='TEXT', text='1'},
				}},
				{nodetype='TAG', tagname='b', attrs={{'x', 'xv'}}, children={
					{nodetype='TEXT', text='2'},
				}},
				{nodetype='TAG', tagname='b', attrs={{'x', 'xv'}}, children={
					{nodetype='TEXT', text='3'},
				}}
			}},
			--result:
			dom
		)
	end)
end)

describe("Lullaby", function()
	
	local H = require 'lullaby'
	
	local function dotest(pretty, body, expected)
		return H._printToString(pretty, function() H.usingHtml(body) end)
	end
	
	it("Text escaping", function()
		assert.are_same(
			[[ asd ; &amp; &lt; &gt; " ' foo]],
			dotest(false,function(_ENV)
				Text(" asd ; & < > \" \' foo")
			end))
	end)

	it("Attribute escaping", function()
		assert.are_same(
			[[<div id="x" title=" asd ; &amp; < > &quot; ' foo"></div>]],
			dotest(false, function(_ENV)
				DIV{title=" asd ; & < > \" \' foo", id="x"}
			end))
	end)

	describe("Normal elements", function()
		it("nil content", function()
			assert.are_same(
				[[<span></span>]],
				dotest(false, function(_ENV)	SPAN{} end))
		end)
		it("text content", function()
			assert.are_same(
				[[<span>Hello</span>]],
				dotest(false,	function(_ENV)SPAN{"Hello"}	end))
		end)
		it("html content", function()
			assert.are_same(
				[[<span><strong></strong></span>]],
				dotest(false, function(_ENV)
					SPAN{function()
						STRONG{}
					end}
				end))
		end)
	end)

	describe("Void elements", function()
		it("nil content", function()
			assert.are_same(
				[[<br>]],
				dotest(false, function(_ENV) BR{} end))
		end)
		it("text content", function()
			assert.raisesError(
				{tag='BAD_VOID_CONTENT'},
				function()
					dotest(false,	function(_ENV) BR{"Hello"}	end)
				end)
		end)
		it("html content", function()
			assert.raisesError(
				{tag='BAD_VOID_CONTENT'},
				function()
					dotest(false, function(_ENV)
						BR{function()
							STRONG{}
						end}
					end)
				end)
		end)
	end)

	it("Should forbid unwrapped child tags", function()
		assert.raisesError({tag="MISSING_TAG_WRAPPER"}, 
			function()
				dotest(false, function(_ENV)
					SPAN{STRONG{}}
				end)
			end)
	end)

	--Todo nested tags


--[=[
	describe("Void elements", function()
		it("nil content", function()
			dotest(false,
				function(_ENV)
					IMG{}
				end,
				"<img>"
			)
		end)
		it("text content", function()
			dotest(false,
				function(_ENV)
					IMG{"Hello"}
				end,
				"???"
			)
		end)
		it("html content", function()
			dotest(false,
				function(_ENV)
					IMG{function()
						STRONG{}
					end}
				end,
				"???"
			)
		end)
	end)
--]=]


end)
--[==[

print("=======")



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

--]==]