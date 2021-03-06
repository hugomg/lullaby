-- To run:
--   busted test.lua
-- You can install busted with Luarocks


-- Check if we are running in the Lua versions we want to:
print("LUA = ".._VERSION)
print("JIT = "..(jit and jit.version or 'no'))

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
  
  local function dotest(pretty, body)
    return H._printToString(pretty, function() H.usingHtml(body) end)
  end
  
  local function assert_html(expected, body)
    assert.are_same(expected, dotest(false, body))
  end
  
  local function assert_error(errmsg, body)
    assert.has_error(function() dotest(false, body) end, errmsg)
  end
  
  it("Text escaping", function()
    assert_html([[ asd ; &amp; &lt; &gt; " ' foo]],
      function(_ENV) Text(" asd ; & < > \" \' foo")  end)
  end)

  it("Attribute escaping", function()
    assert_html([[<div id="x" title=" asd ; &amp; < > &quot; ' foo"></div>]],
      function(_ENV) DIV{title=" asd ; & < > \" \' foo", id="x"} end)
  end)

  describe("Normal elements", function()
    it("nil content", function()
      assert_html([[<span></span>]],
        function(_ENV) SPAN{} end)
    end)
    it("text content", function()
      assert_html([[<span>Hello</span>]],
        function(_ENV) SPAN{"Hello"} end)
    end)
    it("html content", function()
      assert_html([[<span><strong></strong></span>]],
        function(_ENV) SPAN{function() STRONG{} end} end)
    end)
  end)

  describe("Void elements", function()
    it("nil content", function()
      assert_html([[<br>]],
        function(_ENV) BR{} end)
    end)
    it("text content", function()
      assert_error("Void element br should not have contents",
        function(_ENV) BR{"Hello"} end)
    end)
    it("html content", function()
      assert_error("Void element br should not have contents",
        function(_ENV) BR{function() end} end)
    end)
  end)

  describe("Raw elements", function()
    it("does not escape", function()
      assert_html([[<script>window.x=(1<2) && 3 > 4;</script>]],
        function(_ENV) SCRIPT{Raw"window.x=(1<2) && 3 > 4;"} end)
    end)
    it("should be raw", function()
      assert_error("script expects raw content",
        function(_ENV) SCRIPT{"x"} end)
    end)
    it("forbids close tag", function()
      assert_error("Close tag in raw content for script element",
        function(_ENV) SCRIPT{Raw"pattern = /</"} end)
    end)
  end)

  it("Should forbid unwrapped child tags", function()
    assert_error("Missing function wrapper in element body", 
      function(_ENV) SPAN{STRONG{}} end)
  end)

  it("Should expect a table argument", function()
    assert_error("Element constructor should receive a table parameter",
      function(_ENV) SPAN("hello") end)
  end)

  it("Should expect a table argument", function()
    assert_error("Multiple element body parameters",
      function(_ENV) SPAN{"hello", "world"} end)
  end)

  describe("Attributes", function()
    it("should be case insensitive", function()
      assert_html([[<div ID="asd"></div>]],
        function(_ENV) DIV{ ID="asd" } end)
    end)
    it("should detect unknown attributes", function()
      assert_error("Unknown attribute \"blablabla\"",
        function(_ENV) DIV{ blablabla="foo" } end)
    end)
    it("should detect misplaced attributes", function()
      assert_error("Attribute \"disabled\" not allowed on tag \"div\"",
        function(_ENV) DIV{ disabled=true } end)
    end)
  
    describe("Types", function()
      it("text", function()
        assert_html([[<div id="asd"></div>]],
          function(_ENV) DIV{ id="asd" } end)
        assert_error("Attribute \"id\" received a boolean; expected string",
          function(_ENV) DIV{ id=true } end)
      end)
      it("enum", function()
        assert_html([[<form method="POST"></form>]],
          function(_ENV) FORM{ method="POST" } end)
        assert_error("Attribute \"method\" does not allow value \"asd\"",
          function(_ENV) FORM{ method="asd" } end)
      end)
      it("bool", function()
        assert_html([[<button disabled></button>]],
          function(_ENV) BUTTON{ disabled=true } end)
        assert_html([[<button></button>]],
          function(_ENV) BUTTON{ disabled=false } end)
        assert_error("Attribute \"disabled\" received a string; expected boolean",
          function(_ENV) BUTTON{ disabled="true" } end)
      end)
      it("URL", function()
        assert_html([[<a href="http://www.example.com/">x</a>]],
          function(_ENV) A{ href=AbsUrl{'http', 'www.example.com'}, "x"} end)
        assert_error("Attribute \"href\" received a string; expected Url",
          function(_ENV) A{ href="www.example.com" } end)
      end)
      it("Raw", function()
        assert_html([[<div onclick="alert('hi')"></div>]],
          function(_ENV) DIV{ onclick=Raw"alert('hi')" } end)
        assert_error("Attribute \"onclick\" received a string; expected Raw",
          function(_ENV) DIV{ onclick="alert('hi')" } end)
      end)
    end)
  end)

  describe("Urls", function()
      
    local function assert_url(href, url)
      assert_html('<a href="'..href..'"></a>', function(_ENV) A{ href=url } end)
    end
    
    it("Everything", function()
      assert_url("http://www.example.com/a/b.html?t=10m&amp;x=y#x1",
        H.AbsUrl{'http', 'www.example.com', {'a','b.html'}, params={t='10m',x='y'}, hash="x1"})
    end)
  
    it("URL escaping", function()
      assert_url("http://www.example.com/?%3C%3E=%23&amp;%3F%25=%20#%2E%2E",
        H.AbsUrl{'http', 'www.example.com', nil, params={['?%']=' ', ['<>']='#'}, hash=".."})
    end)
    it("no scheme", function()
      assert_url("//www.example.com/",
        H.AbsUrl{nil, 'www.example.com'})
    end)
    it("asolute path", function()
      assert_url("/x/y/z.html",
        H.AbsUrl{nil, nil, {'x', 'y', 'z.html'}})
    end)
    it("relative", function()
      assert_url("foo?x=y#z",
        H.RelUrl{{'foo'}, params={x="y"}, hash="z"})
    end)
    it("just query", function()
      assert_url("?t=10m",
        H.RelUrl{nil, params={t='10m'}})
    end)
    it("just hash", function()
      assert_url("#Chen",
        H.RelUrl{nil, hash="Chen"})
    end)
  
    it("nonstring query params", function()
      assert_url("?n=42",
        H.RelUrl{nil, params={n=42}})
    end)
    it("null query params", function()
      assert_url("?bar&amp;foo",
        H.RelUrl{nil, params={foo=H.Nil, bar=H.Nil}})
    end)
  
    local function url_error(err, ctor, args)
      assert_error(err, function(_ENV) A{href=ctor(args)} end)
    end
    
    describe("Errors", function()
      it("bad scheme", function()
        url_error("Unrecognized scheme \"zzzz\"", H.AbsUrl, {'zzzz', 'www.example.com'})
      end)
      it("missing host", function() 
        url_error("Host must be present if scheme is present", H.AbsUrl, {'http', nil})
      end)
      it("slash in hostname", function()
        url_error("Bad characters in host \"www.foo.com/bar\"", H.AbsUrl, {'http', 'www.foo.com/bar'})
      end)
      it("empty relative url", function()
        url_error("Empty relative Url", H.RelUrl, {})
      end)
    end)
      
  end)

  it('data-X attributes', function()  
    assert_html([[<div data-1000="qwe" data-X-Y="zxc" data-foo="asd"></div>]],
      function(_ENV)
        DIV{ ['data-foo']="asd", ['data-X-Y']="zxc", ['data-1000']="qwe" }
      end)
  end)

  describe('Document Constructor', function()
    it("no spaces", function()
      assert.are_equal(
[[<!DOCTYPE html>
<html><head><title>T</title></head><body></body></html>]],
        dotest(false, function(_ENV)
          local doc = Document({
            title="T",
          })
          doc()
        end)
      )
    end)
  
  
    it("pretty printing", function()
      assert.are_equal(
[[<!DOCTYPE html>
<html
  ><head
    ><meta charset="utf-8"
    ><title
      >Hello</title
    ><link href="./foo.css" rel="stylesheet"
    ><script src="./foo.js"
      ></script
    ></head
  ><body
    ><!-- This is a comment --><span onclick="alert(&quot;oi&quot;)"
      >as&lt;d</span
    ><span>OI</span><img SRC="http://www.pudim.com.br/" alt="Pudim"
    ><div class="FOO" fb:foo="bar"
      ><button disabled
        >Click me</button
      ><pre contenteditable="true" style="background-color:green"
        >
XXX</pre
      ><ol
        ><li
          >1</li
        ><li
          ><strong
            >2</strong
          ></li
        ><li
          >3</li
        ></ol
      ></div
    ></body
  ></html
>]],
        dotest(true, function(_ENV)
          local doc = Document{
            encoding="utf-8",
            title="Hello",
            head=function()
              LINK{rel='stylesheet', href=Raw'./foo.css'}
              SCRIPT{src=Raw'./foo.js'}
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
                  for i = 1,3 do
                    LI{function()
                      if i == 2 then
                        STRONG{tostring(i)}
                      else
                        Text(tostring(i))
                      end
                    end}
                  end
                end}
              end}
            end,
          }
          doc()
        end)
      )
    end)
  end)

end)
