LIBNAME
========

LIBNAME is a stream-based, Turing-complete template library for HTML. It helps you write complex HTML documents and lets you use familiar Lua constructs instead of forcing you to learn a whole new templating language.

LIBNAME is written in pure Lua and is compatible with versions 5.1 and 5.2

##Contents
* [Instalation](#instalation)
* [Quick Start](#quick-start)
* [Events](#events)
* [Element Types](#element-types)
* [Attribute Types](#attribute-types)
* [Document](#document)
* [Pros and cons](#pros-and-cons-of-LIBNAME)
* [License](#license)

##Instalation

$TODO luarocks

##Quick Start

Here is how we can create a small HTML document using LIBNAME:

```lua
local H = require 'html'

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
    end}
  end,
})

H.prettyPrintDocumentToFile(io.stdout, document)
```

Running this script should print out the following output:

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
      ></div
    ></body
  ></html
>
```

The `>`s appearing on a separate line from the `<`s might seem strange at first. The reason we do it this way is because that makes all the indentation whitespace stay inside the open and close tags. This means that the indentation whitespace gets fully ignored and does *not* get converted to text nodes when the browser converts our document into a DOM tree.

###Avoiding the library prefix

Typing the `H.` prefix over and over can be tiresome. To help with that, you can use the `usingHTML` function to create a local environment where all the names from the LIBNAME namespace are automatically available.

```lua
local H = require 'html'

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
```

Note that the first parameter of the `usingHtml` callback must be named `_ENV` and that, due to the way `usingHtml` is implemented it is forbidden to write to global variabes inside the `usingHtml` block (you can still read from globals though).

##Events

In LIBNAME, we create documents by generating a stream of events, instead of constructing a tree-like representation of the DOM. The `printDocument` functions then consume the event stream and convert it into a textual representation of the document.

There are two main types of events: text events and tag events. Additionally, there is also a "raw HTML" event for those cases when regular text and tag events won do the trick.

### Text events

Use the `H.Text` function to write some text to the document:

```lua
Text("text goes here")
```

### Tag events

The functions to create HTML tags have the same name as the corresponding tag, but in upper case. For example, to create a `span` tag we use the `H.SPAN` function:

```lua
SPAN{ "contents" }
```

The tag creation functions all receive a table as their sole argument. Attributes are encoded as key-value pairs with string keys and the contents of the tag go on field `1` of the array part of the table:

```lua
H.SPAN{id="myspan", class="somecssclass", "Hello World"}
```

Tag contents can either be `nil` (empty tag), a `string` (text contents) or a `function` (html event stream for the child nodes)

```lua

-- No contents:
DIV{}

--Text contents:
STRONG{ "hello world" } 

--HTML contents:
DIV{function()
  Text("Hello ")
  STRONG("World")
end)
```

```html
<div></div>

<strong>helo world</strong>

<div>Hello <strong>World</string></div>
```

Its important to note that to create nested tags the content parameter for the oiuter tag must be a function. You must not directly pass the return value for the inner tag constructor as you would do in a DOM representation of the document

```lua
-- Do not do this. It will raise an error:
DIV{ STRONG{"Hello"} }
```

###Raw HTML

In cases where LIBNAME cannot generate the HTML you are looking for, you can fall back to directly outputting raw, un-escaped HTML:

```lua
--HTML comments:
RawHtml("<!-- this is a comment -->")

--Custom tags not in the HTML5 spec
RawHtml("<fb:like href="myurl" />")
```

##Element Types

For void elements, such as `img` or `br`, the only allowed value for the content parameter is `nil`

--TODO: RAW LINK
For the `script` and `style` elements, the content parameter must be a `Raw` string. The reason for this is that these elements contain executable Javascript and CSS code instead of regular entity-encodable text.

Otherwise, an element is considered "Normal" and its allowed to contain anything.

LIBNAME does not attempt to detect nesting restrictions in HTML (for example, `div` is not allowed inside `p`). For these, you should use a separate HTML validator.

Additionally, LIBNAME does not support foreign elements, such as MathML and SVG. 

##Attribute Types

To help detect errors and avoid [Cross Site Scripting](https://en.wikipedia.org/wiki/Cross-site_scripting) vulnerabilities, not every HTML attribute in LIBNAME is allowed to receive arbitrary string values. Attributes are classified in the followed categories:

###Text attributes

These are safe attributes that can receive user-supplied values without anything too bad happening. LIBNAME represents their values with regular Lua strings.

Examples: `id`, `class`, `title`

```lua
DIV{class="comment"}
```

```html
<div class="comment"></div>
```

###Enumerated attributes

Some text attributes expect a value from a fixed set of strings. For example, the `method` attribute of the `form` element expects either `"GET"`, `"POST"` or `"DIALOG"` as values:

Examples: `contenteditable`, `method`

```lua
FORM{name="formname", method="GET", function()
  LABEL{for="username", "Username:"}
  INPUT{id="username", type="text"}
end}
```

```html
<form name="formname" method="GET"><label for="username">Username:</label><input type="text"></form>
```

###Boolean attributes

For some HTML attributes, what really matters is whether the attribute is present or not; The attribute value is ignored and can even be omitted. In these cases, LIBNAME expects a boolean as the attribute value.

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

URLs are complex values and its easy to fall into a trap if we try to build large URLs using string concatenation. Because of this, LIBNAME represents URLs with a special data type and all URL attributes expect to receive a value of this data type.

```lua
-- Full URLs consist of a
--  protocol (ex.:http)
--  host (ex.: www.example.com)
--  path (ex.: posts/january/post1.html)
--  query string (ex.: ?a=b&c=d)
--  hash fragment (ex.: "#FirstSection"
-- http://www.example.com/posts/january/post1.html?a=b&c=d#FirstSection

-- Paths are represented as an array of path segments:
A{"absolute link", href=AbsUrl{'http', 'www.example.com', {'posts', 'post1.html'}}
--   http://www.example.com/posts/post1.html

-- Query parameters go on the `params`  field; The hash goes on the `hash` field
A{"query params", href=AbsUrl{'http', 'www.example.com', params={a="b', c="d"}, hash="x2"}
--   http://ww.example.com/?a=b&c=d#x2

-- The scheme and host parameters are optional:
A{"scheme-relative", href=AbsUrl{nil, 'www.example.com', {index.html'}}
--   //www.example.com/index.html
A{"absolute-path", href=AbsUrl{nil, nil, {'index.html'}}
--   /index.html

-- For relative URLs, use the RelUrl constructor. It receives the same arguments as
-- the AbsUrl constructor, except for the scheme and host:
A{"relative", href=RelUrl{{'index.html'}}}
--   index.html
```

As an alternative to using URL objects, its also possible to pass `Raw` URL values, as described in the following section.

###Raw text

Some attributes cannot safely receive user-supplied values. In this case, LIBNAME requires that their values be wrapped in a `Raw` datatype, so that the programmer can demonstrate that he is aware that the attribute is potentially unsafe and should not be receiving user-supplied values without the proper precautions.

Examples: `style`, `media`, `onX` Javascript event handlers.

```lua
DIV{onclick=Raw'alert("Hello")', "click me"}
```

```html
<div onclick="alert(&quot;Hello&quot;)">click me</div>
```

Additionally, `Raw` can be used to override other attribute values restrictions

```lua
DIV{ contenteditable=Raw"asdasdasd" }
A{ href=Raw'http://www.example.com' }
BUTTON{ disabled=Raw"disabled" }
```

and to insert custom attributes not in the HTML5 spec

```lua
DIV{ mycustomattribute=Raw"value" }
```

##Document

The full argument list for the `Document` function is

* **encoding** The text encoding used in the document (ex.: utf-8, ISO-8859-1, etc). Informing what character encoding you are using means the browser does not have to guess what it is (and guessing has bad security implications) but you should be sure that the encoding you say you are using is the actual encoding of your data, according to your text editor and user input.

* **title** This string value goes in the `<title>` tag inside the `<head>` tag. Every html document should have a title.

* **head** A function representing the remaining contents of the `<head>` tag (in addition to the encoding and title). This is where you would usually put most Javascript `<script>` tags, CSS `<link>` tags and assorted `<meta>` tags.

* **body** A function representing the contends of the `<body>` tag.
    
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

##Pros and cons of LIBNAME

There are many libraries out there for generating HTML. Why should I use LIBNAME over them?

First, the pros:

* Using regular Lua code for things like conditionals, iteration, subtemplates and table access means that there is no need to learn a separate templating DSL.

* LIBNAME is aware that it is generating HTML:
  * It can enforce some simple restrictions (correct element names, correct attribute values, matching open and close tags...).
  * Instead of blindly entity-encoding everything, LIBNAME can use appropriate escaping algorithms depending on the context (element text, attribute  values, url parameters, ...)
  * No significant indentation whitespace cluttering the resulting DOM.

And now the biggest cons:

* LIBNAME is fairly verbose. Its better suited for documents with lots of tags and little raw text and where you need to do lots of iterations or conditionals. If all you need is to insert a couple of values into a big document with lots of text then all those anonymous functions for the nested tags start becoming a lot of noise.

* LIBNAME does not attempt to enforce a strict model-view separation, as [Cosmo](http://cosmo.luaforge.net/), [Mustache](http://mustache.github.io/) or [StringTemplate](http://www.stringtemplate.org/) attempt to. Its your responsibility as the programmer to keep the business logic out of your LIBNAME templates or they could easily become an unmaintainable mess.
