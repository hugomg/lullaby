local html_data = require 'html_data'
local sax = require 'sax'
local U = require 'util'
local escape = require 'escape'


---
-- Helpers
---

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
		if not url_schemes[scheme] then
			error(string.format("Unrecognized scheme %q", tostring(scheme)))
		end
		assert(host)
	end
	
	if host then
		if string.match(host, '[^%w%-%.]') then
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


local function case_insensitive_pattern(str)
	return (string.gsub(str, '%w', function(s)
		assert(#s == 1)
		return '['..s:upper()..s:lower()..']'
	end))
end

local function YieldElement(elem, attrs, body)
	if elem.kind == 'Flow' then
		--everything is allowed
	elseif elem.kind == 'Void' then
		assert(type(body) == 'nil')
	elseif elem.kind == 'Raw' then
		assert((isRawType(body)))
		local bodystr = body.value
		if string.find(bodystr, '</'..case_insensitive_pattern(elem.name)..'[\t\f\n\r >/]') then
			error(string.format("Close tag in raw context for %s", elem.name))
		end
	else
		error('impossible')
	end
	
	-- Check attributes;
	
	for _, attr, attrvalue in U.xpairs(attrs) do
		
		if not attr then
			error(string.format("Unknown attribute %q", attrname))
		end
		if not attr.allowed_on[elem.name] then
			error(string.format("Attribute %q not allowed on tag %q", attr.name, elem.name))
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

	sax.EmitStartEvent(elem.name, attrs)
	if     type(body) == 'nil' then
		-- No contents.
	elseif type(body) == 'string' then
		sax.EmitTextEvent(body)
	elseif type(body) == 'function' then
		body()
	else
		error("bad type")
	end
	sax.EmitEndEvent(elem.name)
end

---
-- Public Html constructors
---

local H = {} --Exports

H.AbsUrl = AbsUrl
H.RelUrl = RelUrl
H.Raw = Raw

for _, elem in pairs(ElemMap) do
	H[elem.name:upper()] = function(args)
		local body = args[1]
		local attrs = U.xmap(tableToPairs(args), function(name, v)
			local attr = assert(AttrMap[name:lower()])
			return {attr, v}
		end)
		return YieldElement(elem, attrs, body)
	end
end

-- string, function -> stream
local function Document(title, body)
	assert(type(title) == 'string')
	return sax.from_coro(function()
		H.HTML{function()
			H.HEAD{function()
				H.TITLE{title}
			end}
			H.BODY{body}
		end}
	end)
end

H.Document = Document

local function _printTo(indent, file, stream)
	file:write("<!doctype html>\n")
	sax.fold_stream(stream, 0, {
			
		Start = function(depth, evt)
			file:write('<'..evt.tagname)
			for _, attr, attrvalue in U.xpairs(evt.attrs) do
				if attr.kind == 'Boolean'then
					if attrvalue then
						file:write(string.format(' %s', attrname))
					end
				else
					file:write(string.format(' %s="%s"', attr.name, escape.html_double_quoted_attribute(tostring(attrvalue))))
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
			file:write(escape.html_text(evt.text))
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

H.printTo       = function(file, doc) return _printTo(false, file, doc) end
H.prettyPrintTo = function(file, doc) return _printTo(true,  file, doc) end


return H

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