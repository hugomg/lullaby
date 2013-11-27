--Escaping functions for XML and HTML
--Do not use these directly unless you are sure that you are using them in the correct context.
--The smart constructors and serializers from html.lua should take care of that.

local Exports = {}

local function escaper(pattern, substitution)
	return function(str)
		return (string.gsub(str, pattern, substitution))
	end
end

---
-- XML Entity encoding
---

local named_xml_entities = {
	['&'] = "&amp;",
  ['<'] = "&lt;",
  ['>'] = "&gt;",
  ['\"'] = "&quot;",
	-- `&apos;` not included because its not on the HTML4 standard and won't work in IE8.
}

local function xml_entity_escape(c)
	assert(#c == 1)
	return named_xml_entities[c] or string.format("&#x%02X;", string.byte(c))
end

Exports.xml_text                    = escaper('[&<>\"]', xml_entity_escape)
Exports.xml_attribute               = escaper('[&<>\"]', xml_entity_escape)

Exports.html_text                    = escaper('[&<>]'  , xml_entity_escape)
Exports.html_single_quoted_attribute = escaper('[&\']'  , xml_entity_escape)
Exports.html_double_quoted_attribute = escaper('[&\"]'  , xml_entity_escape)
Exports.html_any_quoted_attribute    = escaper('[&\'\"]', xml_entity_escape)
Exports.html_unquoted_attribute      = escaper('[^%w]'  , xml_entity_escape)

---
-- URL Encoding
---

local function url_encode(c)
	assert(#c == 1)
	return string.format("%%%02X", string.byte(c))
end

Exports.url_param = escaper('[^%w]', url_encode)
Exports.url_path  = escaper('[^%w-_.]', url_encode)

return Exports