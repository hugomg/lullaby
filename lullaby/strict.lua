setmetatable(_G, {
	__index = function(k) error("Accesing undefined global variable", 2) end,
	__newindex = function(k,v) error("Assigning to undefined global variable", 2) end,
})