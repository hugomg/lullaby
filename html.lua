local html_data = require 'html_data'
local sax = require 'sax'
local U = require 'util'
local escape = require 'escape'


--======
--= Helpers
--======

-- We use {k=v} attributes in the user interface for convenience but the
-- lower-level libraries use {{k,v}} because ipairs more predictable than pairs
local function tableToPairs(t)
	local kvs = {}
	for k,v in pairs(t) do
		if type(k) == 'string' then
			table.insert(kvs, {k,v})
		end
	end
	-- Make this function deterministic:
	table.sort(kvs, function(a, b) return a[1] < b[1] end)
	return kvs
end

--======
--= Process html data from the spec
--======

local ElemMap = {}
for _, name, kind in U.xpairs(html_data.Elems) do
	name = name:lower()
  ElemMap[name] = {
		name=name,
		kind=kind,
	}
end

local function html_set(names)
	return U.Set(U.map(names, string.lower))
end

local UniverseSet = setmetatable({}, {
	__index = function() return true end,
})

local AttrMap = {}
for _, name, kind, allowed_elems in U.xpairs(html_data.Attrs) do
	name = name:lower()
	local attr = {}
	attr.name = name
	attr.kind = kind[1]
	if kind[1] == 'Enum' then
		attr.allowed_values = U.Set(kind[2])
	end
	if allowed_elems == true then
		attr.allowed_on = UniverseSet
	else
		attr.allowed_on = html_set(allowed_elems)
	end
  AttrMap[name] = attr
end

-- data-xxx attributes:
setmetatable(AttrMap, {
	__index = function(self, key)
		local name = key:lower()
		if string.match(name, 'data-[%w-]+') then
			return {name=name, kind='Text', allowed_on=UniverseSet}
		else
			return nil
		end
	end
})


--======
--= Internal HTML constructors.
--======

-- See note [Attribute datatypes]

-- Datatype for unsafe attributes (like event handlers)
local RawMt = {}
local function Raw(str)
	assert(type(str) == 'string')
	return setmetatable({value=str}, RawMt)
end
RawMt.__tostring = function(self)
	return self.value
end

local function isRawType(x) return getmetatable(x) == RawMt end

--Datatype for URL attributes
local UrlMt = {}

local url_schemes = U.Set{'http', 'https'}

local function _Url(scheme, host, path, kw, isabsolute)
	
	path = path or {}
	kw = kw or {}
	
	if scheme then
		if not escape.is_valid_url_scheme(scheme) then
			error(string.format("Unrecognized scheme %q", tostring(scheme)))
		end
		assert(host)
	end
	
	if host then
		if not escape.is_valid_url_host(host) then
			error(string.format("Bad characters in host %q", host))
		end
		assert(isabsolute)
	end
	
	local params = {}
	local hash = nil
	for k, v in pairs(kw) do
		if     k == 'params' then params = tableToPairs(v)
		elseif k == 'hash' then hash = v
		else
			if type(k) ~= 'number' then
				--Typos or wrong param names
				error(string.format("Unrecognized keyword %q", tostring(k)))
			end
		end
	end
	
	if not isabsolute then
		assert(#path > 0 or #params > 0 or hash)
	end
	
	return setmetatable({
		scheme=scheme,
		host=host,
		path=path,
		params=params,
		hash=hash,
		isabsolute=isabsolute,
	}, UrlMt)
end

UrlMt.__tostring = function(self)
	local res = {}
	
	local function w(s)
		assert(type(s) == 'string')
		table.insert(res, s)
	end
	
	if self.scheme then
		w(self.scheme)
		w(':')
	end
	
	if self.host then	
		w('//')
		w(self.host)
	end
	
	if self.isabsolute then
		w('/')
	end
	
	w(table.concat(U.map(self.path, escape.url_path), '/'))
	
	if #self.params > 0 then
		w('?')
		for i, key, value in U.xpairs(self.params) do
			if i > 1 then w('&') end
			w(escape.url_param(key))
			w('=')
			w(escape.url_param(value))
		end
	end
	
	if self.hash then
		w('#')
		w(escape.url_param(self.hash))
	end
	
	return table.concat(res)
end

local function isUrlType(x) return getmetatable(x) == UrlMt end

local function AbsUrl(args)
	assert(type(args) == 'table')
	return _Url(args[1], args[2], args[3], args, true)
end

local function RelUrl(args)
	assert(type(args) == 'table')
	return _Url(nil, nil, args[1], args, false)
end

local function YieldText(text)
	assert(type(text) == 'string')
	sax.EmitTextEvent(text)
end

--I'm shoehorning Raw HTML under a text event to avoid having to
-- modify the SAX infrastructure.
local function YieldHtml(html)
	assert(isRawType(html))
	sax.EmitTextEvent(html)
end

local function YieldElement(elemname, attrs, body)
	
	-- Check element contents
	local elem = ElemMap[elemname:lower()]
	if elem.kind == 'Normal' then
		--everything is allowed
	elseif elem.kind == 'Void' then
		assert(type(body) == 'nil')
	elseif elem.kind == 'Raw' then
		assert((isRawType(body)))
		local bodystr = body.value
		if string.find(bodystr, '</', 1, true) then
			-- Technically, we could allow "</" when its not followed by the corresponding tag name
			-- (case-insensitively). However, I would rather be more strict just in case.
			error(string.format("Close tag in raw context for %s", elem.name))
		end
	else
		error('impossible')
	end
	
	-- Check attributes:
	
	local event_attrs = U.xmap(attrs, function(attrname, attrvalue)
		
		if not isRawType(attrvalue) then
			
			local attr = AttrMap[attrname:lower()]
			if not attr then
				error(string.format("Unknown attribute %q", attrname))
			end
			if not attr.allowed_on[elem.name] then
				error(string.format("Attribute %q not allowed on tag %q", attrname, elem.name))
			end
		
			if attr.kind == 'Text' then
				if type(attrvalue) ~= 'string' then
					error(string.format("Attribute %q received a %s; expected string", attrname, type(attrvalue)))
				end
			elseif attr.kind == 'Enum' then
				if type(attrvalue) ~= 'string' then
					error(string.format("Attribute %q received a %s; expected string", attrname, type(attrvalue)))
				end
				if not attr.allowed_values[attrvalue] then
					error(string.format("Attribute %q does not allow value %q", attrname, tostring(attrvalue)))
				end
			elseif attr.kind == 'Boolean' then
				if type(attrvalue) ~= 'boolean' then
					error(string.format("Attribute %q received a %s; expected boolean", attrname, type(attrvalue)))
				end
			elseif attr.kind == 'URL' then
				if not isUrlType(attrvalue) then
					error(string.format("Attribute %q expected an URL or Raw value", attrname))
				end
			elseif attr.kind == 'Raw' then
				error(string.format("Attribute %q is unsafe and expects Raw values", attrname))
			else
				error('impossible')
			end
		end
		
		return {attrname, attrvalue}
	end)

	sax.EmitStartEvent(elem.name, event_attrs)
	if     type(body) == 'nil' then
		-- No contents.
	elseif type(body) == 'string' then
		YieldText(body)
	elseif type(body) == 'function' then
		body()
	else
		error("bad type")
	end
	sax.EmitEndEvent(elem.name)
end

--======
--= Public Html constructors
--======

local H = {} --Exports

-- Url Datatype
H.AbsUrl = AbsUrl
H.RelUrl = RelUrl

-- Unsafe string datatype
H.Raw = Raw

-- Element constructors
-- usage: TAGNAME{ attr=value, body }
for _, elem in pairs(ElemMap) do
	H[elem.name:upper()] = function(args)
		local body = args[1]
		local attrs = tableToPairs(args)
		return YieldElement(elem.name, attrs, body)
	end
end

-- Text nodes
H.Text = YieldText

-- Raw HTML (escape valve for ansty hacks)
H.RawHtml = YieldHtml

-- string, function -> stream
local function Document(args)
	local title = assert(args.title)
	local body = assert(args.body)
	local encoding = args.encoding
	
	assert(type(title) == 'string')
	return sax.from_coro(function()
		H.HTML{function()
			H.HEAD{function()
				if encoding then
					H.META{ charset=Raw(encoding) }
				end
				H.TITLE{title}
			end}
			H.BODY{body}
		end}
	end)
end

H.Document = Document

local function _printTo(indent, file, stream)
	file:write("<!DOCTYPE html>\n")
	sax.fold_stream(stream, 0, {
			
		Start = function(depth, evt)
			file:write('<'..evt.tagname)
			for _, attrname, attrvalue in U.xpairs(evt.attrs) do
				if type(attrvalue) == 'boolean' then
					if attrvalue then
						file:write(string.format(' %s', attrname))
					end
				else
					file:write(string.format(' %s="%s"', attrname, escape.html_double_quoted_attribute(tostring(attrvalue))))
				end
			end
			
			local eats_newline = evt.tagname == 'pre' or evt.tagname == 'textarea'
			
			if indent and not eats_newline then
				if ElemMap[evt.tagname].kind ~= 'Void' then
					file:write('\n', string.rep('  ', depth+1))
				else
					file:write('\n', string.rep('  ', depth))
				end
			end
			
			file:write('>')
			if eats_newline then
				file:write("\n")
			end
			return depth + 1
		end,
		
		Text = function(_, evt)
			if isRawType(evt.text) then
				file:write(tostring(evt.text))
			else
				file:write(escape.html_text(evt.text))
			end
		end,
		
		End = function(depth, _, evt)
			if ElemMap[evt.tagname].kind ~= 'Void' then
				file:write('</'..evt.tagname)
				if indent then
					file:write('\n', string.rep('  ', depth))
				end
				file:write('>')
			end
		end,
	})
end

--Compactily serialize an html document stream. Does not insert linebreaks or indentation.
H.printTo       = function(file, doc) return _printTo(false, file, doc) end

--Serialize an html document stream, inserting linebreaks and indentation.
--Whitespace gets inserted inside the tags so the resulting DOMshould be the same
--as the compact serialization.
H.prettyPrintTo = function(file, doc) return _printTo(true,  file, doc) end

return H

--[==[ Notes

- See https://www.owasp.org/index.php/XSS_(Cross_Site_Scripting)_Prevention_Cheat_Sheet

[Design Rationale]

  The HTML standard is too complicated for us to be able to enforce that only valid HTML is
	generated by our library, so you should still  pass the output to a validator. Therefore,
	we focus on protecting against injection attacks by representing things using appropriate
	datatypes.
	
	Using a streaming interface with coroutines has 2 main advantages:
	 - Output large documents without creating an intermediate document datastructure
	 - conditionals, variables, sequencing, subtemplates, etc all provided by Lua.
	 - Lexical scope instead of ad-hoc dynamically scoped templating.

[Element Types]

	The HTML element constructors receive a table as their only parameter. The string keys represent
	node attributes and the `1` key rrepresents the element body. It can come in three forms:
	
	  -- Empty content (nil)
		-- <span></span>
	  SPAN{ }
	
	  -- Text content (string)
		-- <span>Hello World</span>
	  SPAN{ "Hello World" }
	
	  -- Mixed content (function)
		-- <span>Hello <strong>World</strong></span>
	  SPAN{function()
		  Text("Hello ")
		  STRONG{"World"}
	  end)

	The HTML Standard specifies many restriction on what kind of content is allowed for each
	element node: (see http://www.whatwg.org/specs/web-apps/current-work/multipage/syntax.html#elements-0)
	
	1) Normal Elements (ex.: div, span, etc)

	  These are the "regular" HTML elements. Their contents can contain a mixture of text and otehr elements.
	
	2) Void Elements (ex.: img, br)

		These elements are not allowed to have any contents and, when serialized, they do *not* have close tags.
		Their constructors will only accept `nil` as a body parameter.
	
	3) Raw text Elements (script and style)

		These elements contain Javascript or CSS code that does *not* get entity escaped.
		They constructors will only accept strings as the body parameter and those strings must not contain the substring "</"
		as that could potentially cause the tag to be prematurely closed.
	
	-- The HTML spec also specifies the following element types: --
	
	4) Escapable Text Elements (ex.: textarea, title)

		These elements must not contain any elements, only text. The text is escapable with HTML entities.
		This library treats these elements as Normal elements. Incorrectly inserted child elements must
		be detected with an HTML validator.
	
	4) Foreign Elements (ex.: MathML, SVG)

		These elements are not supported for now.
		
	-- Content Models --
	
	Normal elements are actually divided in many subcategories (Flow, Phrasing, Sectioning, etc) and there are many restrictions
	as to what elements can be descendents of each other. For example, `div` elements are not allowed inside `p` so 
	
	  <p><div>x</div></p>
	
	actually gets converted to a DOM that is equivalent to
	
	  <p></p><div>x</div><p></p>
	
	This can be very unintuitive but unfortunately these content model restrictions are very complex to fully enforce.
	However, an HTML validator should be able to detect these violations.

[Attribute datatypes]

	See http://www.whatwg.org/specs/web-apps/current-work/multipage/section-index.html#attributes-1
	
	Different attributes have different allowed values. Enforcing the standard for every specific
	attribute would be too complicated so instead we classify attributes in the following categories:
	
	1) String (ex.: id, class, title)
	
		Safe attributes that can receive any textual user-suplied value.
		This includes attributes that really can receive any value (for example, `label` or `title`)
		and attributes that shouldn't be receiving user-supplied data (`id`, `class`) but that aren't
		really prone to injection attacks.
		
		  DIV{ id="a", title=get_title() }
	
	2) Enumerated attributes (ex.: contenteditable, formmethod)

		These attributes only accept string values from a fixed set. For example, `formmethod` only
		allows "POST" and "GET" as values.
	
	2) Boolean: (ex.: async, disabled)
	  
		In HTML, Boolean attributes are represented just by their presence or absense. This means that
		we need to be aware of boolean values during serialization
		
		  <button disabled>  <!-- disabled button -->
			<button>           <!-- enabled button --> 		
			<button disabled="false"> <!-- This actually counts as disabled=true -->
		
	3) URL: (ex.: href, src)
		
		Urls are very prone to injection attacks if people use string concatenation to insert path
		segments or query parameters. Because of this, we use a separate datatype for URLS:
		
		Example:
		
			-- "http://www.example.com/dir1/foo.html?k1=a&k2=b#section1"
			local url = AbsUrl(
				'http', 'www.example.com', {'dir1', 'foo.html'},
				params = {k1='a', k2='b'},
				hash = 'section1'
			)
		  A{ "link text", href = url }
			
			--protocol relative Urls:
			-- "//www.example.com"
			AbsUrl(nil, 'www.example.com') 
			
			--absolute-path  relative urls
			-- "/scripts.foo.js"
			AbsUrl(nil, nil, {'scripts', 'foo.js'})
			
			--relative urls
			-- "foo/bar.html"
			RelUrl({'foo', 'bar.js'})
		
		TODO:
			For now, the URL datatype is the simplest thing that could work. Ideally, we would love to 
			have some more functions for combining URLs and building bigger URLs from smaller ones.
	
	4) Raw: (ex.: inline styles and event handlers, non-whitelisted attributes)

		For some attributes, the library cannot guarantee that it will safely handle user-supplied
		values. In these cases, we require that the template writer mark the values of
		these attributes with a `Raw` wrapper.
		
		local handler='alert("hello world")'
		
		-- Rejected because DIV can be sure that the handler isn user-suplied
		DIV{ onclick=handler } 
		
		-- Now the template writer is promising that handler is not user-supplied:
		DIV{ onclick=Raw(handler) }
		
		The template writer is responsible for being sure that the values passed to Raw are safe.
		The template writer is also responsible for correctly building and escaping these values as
		all the html will do is escape html entities. For example, to create an alert that writes an
		user's name, we need to manually escape the Javascript string contents:
		
		DIV{ onclick=Raw(string.format('alert("%s")', escape.js_string(user.name))) }

	Finally, you can use a `Raw` wrapper to bypass the usual attribute checking:
	
		-- Ignore typical datatype restrictions:
	  DIV{ contenteditable=Raw"asdasdasd" }
	  A{ "linked text", href=Raw("http://www.example.com") }
		BUTTON{ disabled=Raw("disabled") }
		
		-- Place attributes in elements where they are not expected:
		DIV{ for=Raw"asd" }
		
		-- Use custom attributes not mentioned in the spec.
		DIV{ ["fb:foo"]=Raw"bar" }  -- <div fb:foo="bar"></div>

--]==]