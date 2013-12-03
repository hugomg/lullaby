--Escaping and validation functions for XML and HTML
--Do not use these directly unless you are sure that you are using them in the correct context.
--The smart constructors and serializers from html.lua should take care of that.

local U = require 'lullaby.util'

local Exports = {}

--======
--= Common patterns:
--======

local function escaper(pattern, substitution)
  return function(str)
    return (string.gsub(str, pattern, substitution))
  end
end

local function matcher(pattern)
  return function(str)
    return nil ~= string.match(str, pattern)
  end
end

local function enum_checker(values)
  local set = U.Set(values)
  return function(x)
    return nil ~= set[x]
  end
end

--======
--= XML Entity encoding
--======

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

-- For XML, we escape all named entities, just to be safe.
Exports.xml_text                    = escaper('[&<>\"]', xml_entity_escape)
Exports.xml_attribute               = escaper('[&<>\"]', xml_entity_escape)

-- For HTML, we try to escape less characters because browsers will allow it and because I
-- want to make it easier for people to read and write the HTML by hand.
-- In general, we escape the relevant delimiters and `&` (see note [Ambiguous Ampersand])
Exports.html_text                    = escaper('[&<>]'  , xml_entity_escape)
Exports.html_single_quoted_attribute = escaper('[&\']'  , xml_entity_escape)
Exports.html_double_quoted_attribute = escaper('[&\"]'  , xml_entity_escape)
Exports.html_any_quoted_attribute    = escaper('[&\'\"]', xml_entity_escape)
-- No function for unquoted attributes; See note

--======
--= URL Encoding 
--======

-- URL stuff can get pretty messy. I could definitely see this bit being forked into a full library
-- if the more advanced functionality starts being needed.

-- See http://url.spec.whatwg.org/

local function url_encode(c)
  assert(#c == 1)
  return string.format("%%%02X", string.byte(c))
end

-- A scheme must be one ASCII alpha, followed by zero or more of ASCII alphanumeric, "+", "-", and "."
-- But since different schemes use different syntaxes for the rest of the URL,
-- I'm restricting to http and https for now.
Exports.is_valid_url_scheme = enum_checker({'http', 'https'})

-- I'm only allowing domains and not supporting raw IP addresses for now.
-- Real domain-name checking should be more involved but this should preventing anything tooo weird.
Exports.is_valid_url_host = matcher('^[%w%-%.]+$')

-- I don't know for sure what we need to escape here so I default to escaping everything.
-- For paths, I allow some common characters that I know are sage and that look really weird when escaped.
Exports.url_param = escaper('[^%w]', url_encode)
Exports.url_path  = escaper('[^%w-_.]', url_encode)

--======
--= Javascript Strings
--======

local function js_string_encode(c)
  assert(#c == 1)
  return string.format("\\x%02X", string.byte(c))
end

Exports.js_string = escaper('[%w]', js_string_encode)

return Exports

--[==[ Notes

* See https://www.owasp.org/index.php/XSS_(Cross_Site_Scripting)_Prevention_Cheat_Sheet

[Ambiguous Ampersand]
  HTML allows unescaped umpersand as long as they are not followed by characters that form
  a named character reference. (So "Me & You" contains a raw ampersand). However, its much
  simpler for use to just escape all ampersands.

[Unquoted Attributes]
  For unquoted attributes we would need to escape aggressively since many things
  (such as [ %*+,-/;<=>^|] and maybe more) can break out of the attribute.
  Unquoted attributes aren very useful if we are generating the code though so I left it out.
  --Exports.html_unquoted_attribute      = escaper('[^%w]'  , xml_entity_escape)

[Javascript]
  If an event handler is properly quoted, breaking out requires the corresponding quote.
  However, we also need to worry about closing "</script>" tags and newlines inside the JS strings.
  
--]==]