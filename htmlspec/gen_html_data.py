#! /usr/bin/python
# -*- coding:utf-8 -*-

# Usaeg: python gen_html_data.py < 'Index — HTML Standard.html'

from bs4 import BeautifulSoup
from sys import stdin, stdout, stderr

soup = BeautifulSoup(stdin)

tables = soup.find_all('table')

def get_table(caption):
  ts = [t for t in tables if caption in t.caption.text]
  if len(ts) == 1:
    return ts[0]
  else:
    print "ERROR %s N=%d"%(caption, len(ts))
    exit(1)

element_table         = get_table('List of elements')
base_attribute_table  = get_table('List of attributes')
event_attribute_table = get_table('List of event handler content attributes')


#
# Elements
#

elements = []
for row in element_table.tbody.find_all('tr'):
  tagname = row.th.find('a').text

  allowed_children = row.find_all('td')[3].text
  if tagname in ('script', 'style'):
    typ = 'Raw'
  elif 'empty' in allowed_children:
    typ = 'Void'
  else:
    typ = 'Normal'

  elements.append({
    'Name':tagname,
    'Type':typ,
  })


#
# Attributes
#

safe_attributes = [
  #User supplied:
  'abbr', 'alt', 'challenge', 'download',
  'label', 'title',
  
  #Template writer
  'accesskey', 'class', 'content', 'dirname',
  'formtarget', 'mediagroup', 'name', 'radiogroup',
  'target', 'usemap', 'keytype', 'rel',
  
  #IDs
  'command', 'contextmenu', 'for', 'form',
  'id', 'menu',
  #ID lists
  'headers', 'itemref',
  
  #Integers,
  'cols', 'colspan', 'height', 
  'rows', 'rowspan',  'span', 'start', 'tabindex',
  'width',
 
  #Floats
  'high', 'low', 'optimum',
  'max', #
  
  #Space separated lists
  'coords', 'dropzone', 
  
  #Dates
  'datetime',
  
  #Languages
  'hreflang', 'lang', 'srclang',
  
  #Form validation
  'maxlength', 'minlength', 'size','pattern',
  'min', 'max','step', 'list', 'placeholder',
  
  #Complex enums
  'autocomplete', 'sizes', 'sorted', 'type',
  
  #Misc
  'value',
]

enum_attributes = [
  'contenteditable', 'crossorigin', 'dir',
  'draggable', 'enctype', 'formmethod', 'formenctype',
  'inputmode', 'kind', 'method', 'preload', 'spellcheck',
  'scope', 'shape', 'translate', 'wrap',
]

boolean_attributes = [
  'allowfullscreen', 'async', 'autofocus', 'autoplay', 'checked',
  'controls', 'default', 'defer', 'disabled', 'formnovalidate',
  'hidden', 'inert', 'ismap', 'itemscope', 'loop', 'multiple',
  'muted', 'novalidate', 'open', 'readonly', 'required', 'reversed',
  'scoped', 'seamless', 'selected', 'typemustmatch'
]

url_attributes = [
  'action', 'cite', 'data',
  'formaction', 'href', 'icon',
  'itemid', 'manifest', 'poster',
  'src',
  
  #Lists
  'itemprop',
  'itemtype',
  'ping',
]

unsafe_attributes = [
  #Upload filetype
  'accept',

  #Charsets & Pragmas
  'accept-charset', 'charset', 'http-equiv',
  
  #CSS
  'style', 'media',
  
  #Security
  'sandbox',
  
  #??
  'srcdoc',
  'srcset',
]

attributes = []
for table in (base_attribute_table, event_attribute_table):
  for row in table.tbody.find_all('tr'):
    attrname = row.th.find('code').text
    tds = row.find_all('td')

    allowed_values = tds[2]
    if attrname in safe_attributes:
      typ = ['Text']
      
    elif attrname in enum_attributes:
      values = [c.text for c in allowed_values.find_all('code')]
      typ = ['Enum', values]
      
    elif attrname in boolean_attributes:
      typ = ['Boolean']
      
    elif attrname in url_attributes:
      typ = ['URL']
      
    elif attrname in unsafe_attributes or \
        'Event handler content attribute' in allowed_values.text:
      typ = ['Raw']
      
    else:
      print >> stderr , "UNKNOWN", attrname
      exit(1)

    allowed_td = tds[0]
    if 'HTML elements' in allowed_td.a.text:
      allowed_in = True
    else:
      allowed_in = [code.text for code in allowed_td.find_all('code')]
 
    #Some attributes are split into multiple rows but we can merge them
    #because we normalized the differences.
    old_attr = next((a for a in attributes if a['Name'] == attrname), None)
    if old_attr:
      assert old_attr['Type'][0] == typ[0]
      if old_attr['Allowed Elements'] != True:
        old_attr['Allowed Elements'].extend(allowed_in)
    else:
      attributes.append({
        'Name':attrname,
        'Type':typ,
        'Allowed Elements':allowed_in,
      })

#Some sanity tests:

attrlists = [safe_attributes, enum_attributes, boolean_attributes, url_attributes, unsafe_attributes]
    
# 1) Check for typos
for attr in sum(attrlists, []):
  for rule in attributes:
    if rule['Name'] == attr:
      break
  else:
    print >> stderr, "TYPO", attr
    exit(1)
    
# 2) Check for attrs mentioned twice
for lst1 in attrlists:
  for lst2 in attrlists:
    if lst1 != lst2:
      for attr in lst1:
        if attr in lst2:
          print >> stderr, "TWICE", attr
          print lst1
          print lst2
          exit(1)

#Serializing Python values into Lua:

def to_lua(x):
  if type(x) == str or type(x) == unicode:
    return "'"+x.replace("'", "\\'")+"'"
  elif type(x) == bool:
    return "true" if x else "false"
  elif type(x) == list:
    return '{' + ', '.join(to_lua(item) for item in x) + '}'
  else:
    print >> stderr, "Bad type %s"%type(x)
    exit(1)

def _print_table(columns, rows):

  lua_values = [
    dict( (k, to_lua(v)) for (k,v) in row.iteritems())
    for row in rows
  ]

  widths = [ max(len(col), max(len(x[col]) for x in lua_values)) for col in columns]

  stdout.write("{\n")

  stdout.write("--{ ")
  for width, col in zip(widths, columns):
    stdout.write("%s, " %col.ljust(width))
  stdout.write(" },\n")

  for x in lua_values:
    stdout.write("  { ")
    for width, col in zip(widths, columns):
      stdout.write("%s, " % x[col].ljust(width))
    stdout.write(" },\n")

  stdout.write("}\n")
  
def print_table(columns, rows, sep):

  lua_values = [
    dict( (k, to_lua(v)) for (k,v) in row.iteritems())
    for row in rows
  ]

  stdout.write("{\n")

  #stdout.write("--{ ")
  #for width, col in zip(widths, columns):
  #  stdout.write("%s, " %col.ljust(width))
  #stdout.write(" },\n")

  for x in lua_values:
    stdout.write("  {")
    for i, col in enumerate(columns):
      if i > 0: stdout.write(',' + sep)
      stdout.write("%s" % x[col])
    stdout.write("},\n")

  stdout.write("}\n")

#es = elements[:]
#es.sort(key=lambda e : e['Type'])
#for elem in es:
#  print elem['Type'], elem['Name']  
  
#aas = attribute_rules[:]
#aas.sort(key=lambda e : e['Type'])
#for attr in aas:
#  print attr['Type'], attr['Name']

stdout.write("-- THIS FILE WAS AUTOMATICALLY GENERATED. DO NOT EDIT BY HAND --\n")
stdout.write("\n")
stdout.write("local M = {}\n")
stdout.write("M.Elems = ")
print_table(['Name', 'Type'], elements, '')
stdout.write("M.Attrs = ");
print_table(['Name', 'Type', 'Allowed Elements'], attributes, '\n    ')
stdout.write("return M\n")
