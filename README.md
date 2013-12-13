Lullaby HTML templates
======================

Lullaby is a stream-based HTML template library for Lua 5.1 or 5.2. Unlike general text-based templating engines, it is HTML5-aware and it is implemented as a regular Lua library instead of defining a custom string-interpolation language. Lullaby is a bit similar to Ruby's [Markaby](https://github.com/markaby/markaby), Perl's [Template::Declare](http://search.cpan.org/~alexmv/Template-Declare-0.46/lib/Template/Declare.pm) and Haskell's [Blaze](http://jaspervdj.be/blaze/), but with a bit more emphasis in detecting unsafe HTML (user input in event handlers, etc).

##Pros and cons of Lullaby

There are many libraries out there for generating HTML. Why should I use Lullaby over them?

First, the pros:

* Using regular Lua code for things like conditionals, iteration, subtemplates and table access means that there is no need to learn a separate templating DSL.

* Lullaby is aware that it is generating HTML:
  * It knows what are the valid tag and attribute names as well as what kinds of values they expect.
  * It automatically adds close-tags in the appropriate spaces, if needed. Lullaby also knows what HTML elements are void and have no closing tags (it doesn't just prettend that everything is XML and use invalid "/>" tags).
  * It does not insert significant indentation whitespace that would be in the document.
  * It uses context-dependent escaping instead of using the same escaping algorithm for everything. Lullaby tells apart element contents, attribute values and URL parameters and also knows what places cannot escape their contents and should not receive uncontrolled used input.

And now the biggest cons:

* Lullaby is fairly verbose. It is better suited for documents with lots of tags and little raw text and where you need to do lots of iteration or conditionals.

* Lullaby does not attempt to enforce a strict model-view separation, as [Cosmo](http://cosmo.luaforge.net/), [Mustache](http://mustache.github.io/) or [StringTemplate](http://www.stringtemplate.org/) attempt to. It is your responsibility as the programmer to keep the business logic out of your Lullaby templates or they could easily become an unmaintainable mess.

##Contents
* [Instalation](#instalation)
* [Quick Start](#quick-start)
* [Events](#events)
* [Element Types](#element-types)
* [Attribute Types](#attribute-types)
* [Document](#document)
* [Pros and cons](#pros-and-cons-of-lullaby)

##Instalation

The easiest way to install this project is using [Luarocks](http://luarocks.org/). Download the source code for this repository and run the following command from inside the main directory:

```bash
luarocks make
```

Or, to install locally without needing admin permissions:

```bash
luarocks make --local
```

Note that if you are using a local instalation then you might need to configure the LUA_PATH environment variable or else the Lua interpreter might not find Lullaby when you `require` it.

Installation via packaged Luarocks rock will be available as soon as I manage to get it to work.

##Quick Start

Here is a short example of how we can use Lullaby to create a small HTML document and print it to standard output:

```lua
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
      H.OL{function()
        for i=1, 3 do
          H.LI{tostring(i)}
        end
      end}
    end}
  end,
})

H.prettyPrintToFile(io.stdout, document)
```

Lullaby represents document fragments as functions that call markup-generating functions such as `Text` or `DIV`. `Document` is a higher-level template that builds the full document given the document fragments for the head and body tags. Finally, we use one of the printing functions to serialize the full document to a file - `printToFile` serializes everything in a single line without indentation and `prettyPrintToFile` includes some extra indentation whitespace.

Running the example script should generate the following output. The `>`s on separate lines are not where most people would expect them to be but this way we avoid inserting significant whitespace just for indentation (whitespace inside tags is ignored while whitespace between tags is *not*).

```html
<!DOCTYPE html>
<html
  ><head
    ><title
      >My first Document</title
    ><link href="style.css" rel="stylesheet"
    ></head
  ><body
    ><h1
      >hello World</h1
    ><div class="foo"
      >Hello <button disabled
        >World</button
      ><ol
        ><li
          >1</li
        ><li
          >2</li
        ><li
          >3</li
        ></ol
      ></div
    ></body
  ></html
>
```

###Avoiding the library prefix

Typing the `H.` prefix over and over can be tiresome and to help with that, Lullaby provides a `usingHTML` function. It creates a local environment where all the names from the Lullaby namespace are automatically available.

**For brevity, all examples in this README from this point on will omit the `H.` namespace**

```lua
local H = require 'lullaby'

local document = H.usingHtml(function(_ENV)
  return Document({
    title = 'My first Document',
    head = function()
      LINK{rel="stylesheet", href=RelUrl{{'style.css'}}}
    end,
    body = function()
      H1{"hello World"}
      DIV{class="foo", function()
        Text("Hello ")
        BUTTON{disabled = true, "World"}
      end}
    end,
  })
end)

H.prettyPrintToFile(io.stdout, document)
```

For compatibility between Lua 5.1 and 5.2, the argument to `usingHtml` must be an anonymous function expression with a single argument, named `_ENV`. Additionally, due to the way `usingHtml` is implemented, it is not possible to write to global variables inside the `usingHtml` block (you can still read from globals though).

###Serializing to a string instead of to a file

If you don't want to print the HTML to a file, you can use the `printToString` functions to serialize the documents into Lua strings:

```lua
local document = H.Document({ })
local s1 = H.printToString(document)
local s2 = H.prettyPrintToString(document)
```

###Serializing HTML fragments

The document printing functions work with any event stream, not only full documents:

```
H.printToFile(io.stdout, function()
  H.SPAN{"Hello World"}
end)
```

##Events

Lullaby uses an event-based document construction mechanism. Instead of building a full document tree, we create a stream of "open tag", "text", and "close tag" events by calling the appropriate event-generating functions. The main advantage of this approach is that it composes well with existing Lua structuring features: if statements give us conditional templates, for loops give template iteration and functions let us abstract and call subtemplates.

```lua
local ordered_list = function(items)
  OL{function()
    for i, item in ipairs(items) do
      local cls = (i % 2 == 0 and "even" or "odd")
      LI{class=cls, item}
    end
  end}
end
```

There are two main types of events: text events and tag events. Additionally, there is also a "raw HTML" event for those cases when regular text and tag events won't do the trick.

### Text events

Use the `Text` function to write some text to the document:

```lua
Text("text goes here")
```

### Tag events

The functions to create HTML tags have the same name as the corresponding tag, but in upper case. For example, to create a `span` tag we use the `SPAN` function:

```lua
SPAN{ "contents" }
```

Lullaby should have functions for all tags in the HTML 5 specification. For a full list, see the lullaby/html_data.lua file.

The tag creation functions all receive a table as their sole argument. Attributes are encoded as key-value pairs with string keys and the contents of the tag go on field `1` of the array part of the table:

```lua
SPAN{id="myspan", class="somecssclass", "Hello World"}
```

Tag contents can either be `nil` (empty tag), a `string` (text contents) or a `function` (HTML event stream for the child nodes)

```lua

-- <div></div>
DIV{}

-- <strong>hello world</strong>
STRONG{ "hello world" } 

-- <div>Hello <strong>World</string></div>
DIV{function()
  Text("Hello ")
  STRONG("World")
end)
```

It is important to note that to create nested tags the content parameter for the outer tag must be a function. You must not directly pass the return value for the inner tag constructor as you would do in a DOM representation of the document

```lua
-- Do not do this. It will raise an error:
DIV{ STRONG{"Hello"} }
```

The reason for this is that function arguments are evaluated before the function is called so the events for the `strong` tag would be emmited before the `div` events instead of between them.

###Raw HTML

In cases where Lullaby cannot generate the HTML you are looking for, you can fall back to directly outputting raw, un-escaped HTML:

```lua
--HTML comments:
RawHtml([[<!-- this is a comment -->]])

--Custom tags not present in the HTML5 spec
RawHtml([[<fb:like href="myurl" />]])
```

##Element Types

For void elements, such as `img` or `br`, the only allowed value for the content parameter is `nil`

For the `script` and `style` elements, the content parameter must be a [`Raw`](#raw-text) string. The reason for this is that these elements contain executable Javascript and CSS code instead of regular entity-encodable text.

Otherwise, an element is considered "Normal" and it is allowed to contain anything.

Lullaby does not attempt to detect nesting restrictions in HTML (for example, `div` is not allowed inside `p`). For these, you should use a separate HTML validator.

Additionally, Lullaby does not support foreign elements, such as MathML and SVG (you can still use the RawHtml feature for those though). 

##Attribute Types

To help detect errors and avoid [Cross Site Scripting](https://en.wikipedia.org/wiki/Cross-site_scripting) vulnerabilities, Lullaby classifies attributes according to what values they are allowed to receive. The 5 categories are Text, Raw, Enumerated, Boolean and URL:

Lullaby should be aware of all attributes in the HTML5 specification. For a full list of attributes, including their category and what elements they are allowed on, see the lullaby/html_data.lua file.

###Text attributes

These are safe attributes that can receive user-supplied values without anything too bad happening. Lullaby expects their values to be a Lua string.

Examples: `id`, `class`, `title`, `data-XXX` attributes

```lua
DIV{class="comment"}
```

```html
<div class="comment"></div>
```

###Raw text

Some attributes cannot safely receive user-supplied values. In these cases, Lullaby requires that their values be wrapped in a `Raw` datatype, so that the programmer can demonstrate that he is aware that the attribute is potentially unsafe and should not be receiving user-supplied values without the proper precautions.

Examples: `style`, `media`, Javascript event handlers (`onclick`, etc).

```lua
DIV{onclick=Raw'alert("Hello")', "click me"}
```

```html
<div onclick="alert(&quot;Hello&quot;)">click me</div>
```

Additionally, the `Raw` datatype can be used to bypass Lullaby's attribute value restrictions and to insert custom attributes or to put attributes in elements they are not allowed on.

```lua
DIV{ contenteditable=Raw"asdasdasd" }
BUTTON{ disabled=Raw"disabled" }
DIV{ mycustomattribute=Raw"value" }
```

###Enumerated attributes

Some text attributes expect a value from a fixed set of strings. For example, the `method` attribute of the `form` element expects either `"GET"`, `"POST"` or `"DIALOG"` as values:

Examples: `contenteditable`, `method`

```lua
FORM{name="formname", method="GET", function()
  LABEL{['for']="username", "Username:"}
  INPUT{id="username", type="text"}
end}
```

```html
<form method="GET" name="formname"><label for="username">Username:</label><input id="username" type="text"></form>
```

###Boolean attributes

For some HTML attributes, what really matters is whether the attribute is present or not; The attribute value is ignored and can even be omitted. In these cases, Lullaby expects a boolean as the attribute value.

Examples: `autofocus`, `disabled`

```lua
BUTTON{disabled=true, "one"}
BUTTON{disabled=false, "two"}
```

```html
<button disabled>one</button>
<button>two</button>
```

###URLs

Since URLs are complex values with a nontrivial syntax, Lullaby considers URL attributes to be unsafe and does not allow you to simply pass them as strings. That said, the simplest way to give a value for an URL attribute is via the Raw datatype:

```lua
A{href=Raw"www.example.com"}
```

However, if the URL is not fixed and needs to be built up from smaller parts then the `Raw` approach becomes less appealing, given that we would need to manually escape the appropriate parameters. For these situations, Lullaby provides the `AbsUrl` and `RelUrl` for absolute and relative URLs, respectively.

First some terminology: URLs can be subdivided into the scheme (ex.: http), host (ex.: www.example.com), file path (ex.: foo/bar.html), query string (ex.: ?t=10m) and hash fragment (ex.: #section-name)

The `AbsUrl` constructor receives a scheme, host and path as positional parameters and the query string and hash as named parameters. The scheme, host and hash parameters are strings, the path is a list of strings representing the path segments and the query is table of key-value pairs. 

```lua
-- Paths are represented as an array of path segments:
A{"absolute link", href=AbsUrl{'http', 'www.example.com', {'posts', 'post1.html'}}
--   http://www.example.com/posts/post1.html

-- Query parameters go on the `params`  field; The hash goes on the `hash` field
A{"query params", href=AbsUrl{'http', 'www.example.com', params={a="b", c="d"}, hash="x2"}
--   http://www.example.com/?a=b&c=d#x2
```

All the parameters are optional:

```lua
-- scheme relative urls:
A{href=AbsUrl{nil, 'www.example.com', {index.html'}}
-- absolute paths relative to the root
A{href=AbsUrl{nil, nil, {'index.html'}}
--   /index.html
```

The `RelUrl` receives the same constructors as `AbsUrl`, except for the scheme and host.

```lua
--- Relative Urls are relative to the current path
A{href=RelUrl{{'posts','post2.html'}}}
--   posts/post2.html
```

##Document

The full argument list for the `Document` function is

* **encoding** The text encoding used in the document (ex.: utf-8, ISO-8859-1, etc). Informing what character encoding you are using means the browser does not have to guess what it is (and guessing has bad security implications) but you should be sure that the encoding you say you are using is the actual encoding of your data, according to your text editor and user input.

* **title** This string value goes in the `<title>` tag inside the `<head>` tag. Every html document should have a title.

* **head** A function representing the remaining contents of the `<head>` tag (in addition to the encoding and title). This is where you would usually put most Javascript `<script>` tags, CSS `<link>` tags and assorted `<meta>` tags.

* **body** A function representing the contents of the `<body>` tag.
    
All these parameters are optional but specifying the encoding and title is highly recommended.

```lua
local document = Document({
  encoding="utf-8",
  title="My Title",
  head=function()
    SCRIPT{src=Raw'hello.js'}
  end,
  body=function()
    H1{"Hello"}
  end,
})
```
