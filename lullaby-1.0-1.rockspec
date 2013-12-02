package = "lullaby"
version = "1.0-1"
source = {
   url = "https://github.com/hugomg/lullaby/archive/v0.1.tar.gz"
}
description = {
   summary = "A stream-based, Turing-complete template library for HTML.",
   detailed = "Lullaby is a stream-based, Turing-complete template library for HTML that helps you write complex HTML documents using familiar Lua constructs instead of forcing you to learn a whole new templating language. Its a bit similar to Ruby's Markaby, Perl's Template::Declare and Haskell's Blaze.",
   homepage = "https://github.com/hugomg/lullaby",
   license = "MIT"
}
dependencies = {}
build = {
   type = "builtin",
   modules = {
      lullaby = "lullaby.lua",
      ['lullaby.escape'] = "lullaby/escape.lua",
      ['lullaby.html_data'] = "lullaby/html_data.lua",
      ['lullaby.sax'] = "lullaby/sax.lua",
      ['lullaby.strict'] = "lullaby/strict.lua",
      ['lullaby.util'] = "lullaby/util.lua"
   }
}
