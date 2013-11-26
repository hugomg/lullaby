#! /usr/bin/python
# -*- coding:utf-8 -*-

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



elements = []
for row in element_table.tbody.find_all('tr'):
  tagname = row.th.find('a').text

  allowed_children = row.find_all('td')[3].text
  if tagname in ('script', 'style'):
    typ = 'Raw'
  elif 'empty' in allowed_children:
    typ = 'Void'
  else:
    typ = 'Flow'

  elements.append({
    'Name':tagname,
    'Type':typ,
  })

attributes = []

for table in (base_attribute_table, event_attribute_table):
  for row in table.tbody.find_all('tr'):
    attrname = row.th.find('code').text
    tds = row.find_all('td')

    allowed_values = tds[2].text
    if 'Boolean' in allowed_values:
      typ = 'Boolean'
    elif 'Valid URL potentially surrounded by spaces' in allowed_values or \
         'Valid non-empty URL potentially surrounded by spaces' in allowed_values:
      typ = 'URL'
    elif 'Event handler content attribute' in allowed_values:
      typ = 'Raw'
    else:
      typ = 'Text'

    allowed_td = tds[0]
    if 'HTML elements' in allowed_td.a.text:
      allowed_in = True
    else:
      allowed_in = [code.text for code in allowed_td.find_all('code')]

    #Some attributes are split into multiple rows
    #But in all cases we can merge them because the differences don matter to us.
    old_attr = next((attr for attr in attributes if attr['Name'] == attrname), None)
    if old_attr:
      assert old_attr['Type'] == typ
      if old_attr['Allowed Elements'] != True:
        old_attr['Allowed Elements'].extend(allowed_in)
    else:  
      attributes.append({
        'Name':attrname,
        'Type':typ,
        'Allowed Elements':allowed_in,
      })

#Serializing Python values into Lua:

def to_lua(x):
  if type(x) == str or type(x) == unicode:
    return "'"+x.replace("'", "\\'")+"'"
  elif type(x) == bool:
    return "true" if x else "false"
  elif type(x) == list:
    return '{ ' + ', '.join(to_lua(item) for item in x) + ' }'
  else:
    print >> stderr, "Bad type %s"%type(x)
    exit(1)

def print_table(columns, rows):

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

stdout.write("local M = {}\n")
stdout.write("M.Elems = "); print_table(['Name', 'Type'], elements)
stdout.write("M.Attrs = "); print_table(['Name', 'Type', 'Allowed Elements'], attributes)
stdout.write("return M\n")
