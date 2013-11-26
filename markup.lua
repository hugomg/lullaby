--Common functionality for XML and HTML

local named_entities = {
	['&'] = "&amp;",
  ['<'] = "&lt;",
  ['>'] = "&gt;",
  ['\"'] = "&quot;",
	-- `&apos;` not included because its not on the HTML4 standard and won work with IE8.
}

local function escape_char(s)
	assert(#s == 1)
	return named_entities[s] or string.format("&#x%x;", string.byte(s))
end

local function escape_text(str)          return (string.gsub(str, '[&<>]', escape_char)) end
local function escape_double_quotes(str) return (string.gsub(str, '["]', escape_char)) end

return {
	escape_text = escape_text,
	escape_double_quotes = escape_double_quotes,
}