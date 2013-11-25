local Exports = {}

-------------------
--SAX Stream events
-------------------

-- (string, map[string->string]) -> Evt
local function StartEvent(tagname, attrs)
  return {tag='START', tagname=tagname, attrs=attrs}
end

-- string -> Evt
local function TextEvent(text)
  return {tag='TEXT', text=text}
end

-- string -> Evt
local function EndEvent(tagname)
  return {tag='END', tagname=tagname}
end

Exports.StartEvent = StartEvent
Exports.TextEvent = TextEvent
Exports.EndEvent = EndEvent

----------------
-- SAX Iterators
----------------

-- A SAX iterator is a function that returns new SAX events
-- each time its called and `nil` to signal the end of the stream.
-- Additionally, every open tag should have a matching close tag.
local function assert_stream(stream)
	
	local tag_stack = {}
	local is_done = false
	
  return function()
		
		--Argument checking
		assert(not is_done, "Event stream has already closed")
		
    local evt = stream()
		
		--Return checking
		if evt == nil then
			assert(#tag_stack == 0, "Unclosed tags")
			is_done = true
		else 
			if evt.tag == 'START' then
				table.insert(tag_stack, evt.tagname)
			elseif evt.tag == 'END' then
				local open_name = assert(table.remove(tag_stack), "Orphaned close tag")
				assert(open_name == evt.tagname, "Mismatched close tag")
			end
    end
		
    return evt
  end
end

-- Create a new SAX iterator given a coroutine body
local function sax_from_coro(body)
  return assert_stream(coroutine.wrap(body))
end

local function stream_foreach(stream, handlers)
	local onStart = assert(handlers.Start)
	local onText = assert(handlers.Text)
	local onEnd = assert(handlers.End)
	
	--TODO: make contracts indempotent
	-- stream = assert_sax(stream)
	
	for evt in stream do
		if     evt.tag == 'START' then onStart(evt)
		elseif evt.tag == 'TEXT' then onText(evt)
		elseif evt.tag == 'END' then onEnd(evt)
		else error('pattern') end
	end
end

Exports.assert_stream = assert_stream
Exports.from_coro = sax_from_coro
Exports.foreach = stream_foreach

-------
-- SSAX
-------

local function default(x, y)
  if y == nil then
    return x
  else
    return y
  end
end

-- SSAX-style stream folding
--  Start: (state, evt) -> state
--  Text: (state, evt) -> state?
--  End: (parentstate, childstate, evt) -> state?
-- In a purely functional setting, each handler should return the next value
 -- for the folding state. As a convenience for programs using mutation,
--  returning `nil` from a handler counts as returning the old state.
local function fold_stream(stream, initial_state, handlers)
	-- TODO: split off into scanl version if we want to support
	-- filter and map w/o needing coroutines.
	
  local onStart = assert(handlers.Start)
  local onText = assert(handlers.Text)
  local onEnd = assert(handlers.End)
  
  local depth = 0 -- can't use #parent_states because states can be nil
	local ancestor_states = {}
  local state = initial_state
	
	stream_foreach(stream, {
	  Start = function(evt)
			depth = depth + 1
			ancestor_states[depth] = state
			state = assert(onStart(state, evt), 'Folding state must not be nil')
		end,
		Text = function(evt)
			state = default(state, onText(state, evt))
		end,
		End = function(evt)
			local parent_state = ancestor_states[depth]
			ancestor_states[depth] = nil
			depth = depth - 1
			state = default(parent_state, onEnd(parent_state, state, evt))
		end,
	})
  
	return state
end

Exports.fold_stream = fold_stream

------
-- DOM
------

local function sax_to_dom(stream)
  local root = fold_stream(stream, {tag='TAG', tagname='ROOT', attrs={}, children={}}, {
    Start = function(st, evt)
      return {tag='TAG', tagname=evt.tagname, attrs=evt.attrs, children={}}
    end,
    Text = function(st, evt)
      table.insert(st.children, {tag='TEXT', text=evt.text})
    end,
    End = function(st, cst, evt)
      table.insert(st.children, cst)
    end,
  })
  return root.children[1]
end
   
local function print_dom(node)
  local function go(node, indent)
    for i=1,indent do
      io.write('  ')
    end
    if node.tag == 'TAG' then
      io.write('<', node.tagname, '>\n')
      for _, child in ipairs(node.children) do
        go(child, indent+1)
      end
    elseif node.tag == 'TEXT' then
      io.write('"', node.text, '"\n')
    else
      error('pattern')
    end
  end
  go(node, 0)
end

Exports.to_dom = sax_to_dom
Exports.print_dom = print_dom

return Exports