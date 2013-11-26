local html_data = require 'html_data'
local sax = require 'sax'
local U = require 'util'
local markup = require 'markup'

---
-- Process html data from the spec
---

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

local ElemSet = html_set(U.xmap(html_data.Elems, function(name) return name end))

local AttrMap = {}
for _, name, kind, allowed_elems in U.xpairs(html_data.Attrs) do
	name = name:lower()
  AttrMap[name] = {
		name = name,
		kind = kind,
		allowed_on = (allowed_elems == true and ElemSet or html_set(allowed_elems)),
	}
end


---
-- Define HTML constructors.
---

-- Url parameters need to be encoded as an associative map instead of a string.
local UrlMt = {}
local function Url(base, params, fragment)
	return setmetatable({
		base=base,
		params=params or {},
		fragment=fragment or {},
	}, UrlMt) 
end
UrlMt.__tostring = function(self)
	error("TODO")
end

-- Unsafe strings in the API are marked with this datatype
local RawMt = {}
local function Raw(str)
	assert(type(str) == 'string')
	return setmetatable({value=str}, RawMt)
end
RawMt.__tostring = function(self)
	return self.value
end

local function isUrlType(x) return getmetatable(x) == UrlMt end
local function isRawType(x) return getmetatable(x) == RawMt end

local function case_insensitive_pattern(str)
	return (string.gsub(str, '%w', function(s)
		assert(#s == 1)
		return '['..s:upper()..s:lower()..']'
	end))
end

local function YieldElement(elemname, attrs, body)

	elemname = elemname:lower()
	local elem = assert(ElemMap[elemname])
	if elem.kind == 'Flow' then
		--everything is allowed
	elseif elem.kind == 'Void' then
		assert(type(body) == 'nil')
	elseif elem.kind == 'Raw' then
		assert((isRawType(body)))
		local bodystr = body.value
		if string.find(bodystr, '</'..case_insensitive_pattern(elemname)..'[\t\f\n\r >/]') then
			error(string.format("Close tag in raw context for %s", elemname))
		end
	else
		error('impossible')
	end
	
	-- Check attributes;
	
	for _, attrname, attrvalue in U.xpairs(attrs) do
		attrname = attrname:lower()
		local attr = AttrMap[attrname]
		
		if not attr.allowed_on[elemname] then
			error(string.format("Attribute %q not allowed on tag %q", attrname, elemname))
		end
		
		if attr.kind == 'Text' then
			assert(type(attrvalue) == 'string')
		elseif attr.kind == 'Boolean' then
			assert(type(attrvalue) == 'boolean')
	  elseif attr.kind == 'URL' then
			assert((isUrlType(attrvalue)))
		elseif attr.kind == 'Raw' then
			assert((isRawType(attrvalue)))
		else
			error('impossible')
		end
				
	end

	sax.EmitStartEvent(elemname, attrs)
	if     type(body) == 'nil' then
		-- No contents.
	elseif type(body) == 'string' then
		sax.EmitTextEvent(body)
	elseif type(body) == 'function' then
		body()
	else
		error("bad type")
	end
	sax.EmitEndEvent(elemname)
end


local function Html(title, body)
	assert(type(title) == 'string')
	return sax.from_coro(function()
		YieldElement('head', {}, function()
			YieldElement('title', {}, title)
			YieldElement('body', {}, body)
		end)
	end)
end

local function printTo(file, stream)
	file:write("<!doctype html>")
	sax.foreach(stream, {
		Start = function(evt)
			file:write('<'..evt.tagname)
			for _, attrname, attrvalue in U.xpairs(evt.attrs) do
				local attr = AttrMap[attrname]
				if attr.kind == 'Boolean'then
					if attrvalue then
						file:write(string.format(' %s', attrname))
					end
				else
					file:write(string.format(' %s="%s"', attrname, markup.escape_double_quotes(tostring(attrvalue))))
				end
			end
			file:write('>')
		end,
		Text = function(evt)
			file:write((markup.escape_text(evt.text)))
		end,
		End = function(evt)
			if ElemMap[evt.tagname].kind ~= 'Void' then
				file:write('</'..evt.tagname..'>')
			end
		end,
	})
end

local Exports = {}

printTo(io.stdout, Html("Hello", function()
	YieldElement('span', {}, 'as<d')
	YieldElement('div', {{'class',"FOO"}}, function()
		--YieldElement('a', {{'href',Url("ASDF")}}, "hello")
	end)
end))
print()


--------
-- Notes
--------

--[[ [XSS Prevention]

https://www.owasp.org/index.php/XSS_(Cross_Site_Scripting)_Prevention_Cheat_Sheet

--]]

--[[ [Boolean Attributes]

A number of attributes are boolean attributes. The presence of a boolean attribute on an element represents the true value, and the absence of the attribute represents the false value.

If the attribute is present, its value must either be the empty string or a value that is an ASCII case-insensitive match for the attribute's canonical name, with no leading or trailing whitespace.

--]]
--TODO specify a character set