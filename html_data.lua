-- THIS FILE WAS AUTOMATICALLY GENERATED. DO NOT EDIT BY HAND --

local M = {}
M.Elems = {
  {'a','Normal'},
  {'abbr','Normal'},
  {'address','Normal'},
  {'area','Void'},
  {'article','Normal'},
  {'aside','Normal'},
  {'audio','Normal'},
  {'b','Normal'},
  {'base','Void'},
  {'bdi','Normal'},
  {'bdo','Normal'},
  {'blockquote','Normal'},
  {'body','Normal'},
  {'br','Void'},
  {'button','Normal'},
  {'canvas','Normal'},
  {'caption','Normal'},
  {'cite','Normal'},
  {'code','Normal'},
  {'col','Void'},
  {'colgroup','Normal'},
  {'data','Normal'},
  {'datalist','Normal'},
  {'dd','Normal'},
  {'del','Normal'},
  {'details','Normal'},
  {'dfn','Normal'},
  {'dialog','Normal'},
  {'div','Normal'},
  {'dl','Normal'},
  {'dt','Normal'},
  {'em','Normal'},
  {'embed','Void'},
  {'fieldset','Normal'},
  {'figcaption','Normal'},
  {'figure','Normal'},
  {'footer','Normal'},
  {'form','Normal'},
  {'h1','Normal'},
  {'head','Normal'},
  {'header','Normal'},
  {'hgroup','Normal'},
  {'hr','Void'},
  {'html','Normal'},
  {'i','Normal'},
  {'iframe','Normal'},
  {'img','Void'},
  {'input','Void'},
  {'ins','Normal'},
  {'kbd','Normal'},
  {'keygen','Void'},
  {'label','Normal'},
  {'legend','Normal'},
  {'li','Normal'},
  {'link','Void'},
  {'main','Normal'},
  {'map','Normal'},
  {'mark','Normal'},
  {'menu','Normal'},
  {'menuitem','Void'},
  {'meta','Void'},
  {'meter','Normal'},
  {'nav','Normal'},
  {'noscript','Normal'},
  {'object','Normal'},
  {'ol','Normal'},
  {'optgroup','Normal'},
  {'option','Normal'},
  {'output','Normal'},
  {'p','Normal'},
  {'param','Void'},
  {'pre','Normal'},
  {'progress','Normal'},
  {'q','Normal'},
  {'rp','Normal'},
  {'rt','Normal'},
  {'ruby','Normal'},
  {'s','Normal'},
  {'samp','Normal'},
  {'script','Raw'},
  {'section','Normal'},
  {'select','Normal'},
  {'small','Normal'},
  {'source','Void'},
  {'span','Normal'},
  {'strong','Normal'},
  {'style','Raw'},
  {'sub','Normal'},
  {'summary','Normal'},
  {'sup','Normal'},
  {'table','Normal'},
  {'tbody','Normal'},
  {'td','Normal'},
  {'template','Normal'},
  {'textarea','Normal'},
  {'tfoot','Normal'},
  {'th','Normal'},
  {'thead','Normal'},
  {'time','Normal'},
  {'title','Normal'},
  {'tr','Normal'},
  {'track','Void'},
  {'u','Normal'},
  {'ul','Normal'},
  {'var','Normal'},
  {'video','Normal'},
  {'wbr','Void'},
}
M.Attrs = {
  {'abbr',
    {'Text'},
    {'th'}},
  {'accept',
    {'Raw'},
    {'input'}},
  {'accept-charset',
    {'Raw'},
    {'form'}},
  {'accesskey',
    {'Text'},
    true},
  {'action',
    {'URL'},
    {'form'}},
  {'allowfullscreen',
    {'Boolean'},
    {'iframe'}},
  {'alt',
    {'Text'},
    {'area', 'img', 'input'}},
  {'async',
    {'Boolean'},
    {'script'}},
  {'autocomplete',
    {'Text'},
    {'form', 'input', 'select', 'textarea'}},
  {'autofocus',
    {'Boolean'},
    {'button', 'input', 'keygen', 'select', 'textarea'}},
  {'autoplay',
    {'Boolean'},
    {'audio', 'video'}},
  {'challenge',
    {'Text'},
    {'keygen'}},
  {'charset',
    {'Raw'},
    {'meta', 'script'}},
  {'checked',
    {'Boolean'},
    {'menuitem', 'input'}},
  {'cite',
    {'URL'},
    {'blockquote', 'del', 'ins', 'q'}},
  {'class',
    {'Text'},
    true},
  {'cols',
    {'Text'},
    {'textarea'}},
  {'colspan',
    {'Text'},
    {'td', 'th'}},
  {'command',
    {'Text'},
    {'menuitem'}},
  {'content',
    {'Text'},
    {'meta'}},
  {'contenteditable',
    {'Enum', {'true', 'false'}},
    true},
  {'contextmenu',
    {'Text'},
    true},
  {'controls',
    {'Boolean'},
    {'audio', 'video'}},
  {'coords',
    {'Text'},
    {'area'}},
  {'crossorigin',
    {'Enum', {'anonymous', 'use-credentials'}},
    {'audio', 'img', 'link', 'script', 'video'}},
  {'data',
    {'URL'},
    {'object'}},
  {'datetime',
    {'Text'},
    {'del', 'ins', 'time'}},
  {'default',
    {'Boolean'},
    {'menuitem', 'track'}},
  {'defer',
    {'Boolean'},
    {'script'}},
  {'dir',
    {'Enum', {'ltr', 'rtl', 'auto'}},
    true},
  {'dirname',
    {'Text'},
    {'input', 'textarea'}},
  {'disabled',
    {'Boolean'},
    {'button', 'menuitem', 'fieldset', 'input', 'keygen', 'optgroup', 'option', 'select', 'textarea'}},
  {'download',
    {'Text'},
    {'a', 'area'}},
  {'draggable',
    {'Enum', {'true', 'false'}},
    true},
  {'dropzone',
    {'Text'},
    true},
  {'enctype',
    {'Enum', {'application/x-www-form-urlencoded', 'multipart/form-data', 'text/plain'}},
    {'form'}},
  {'for',
    {'Text'},
    {'label', 'output'}},
  {'form',
    {'Text'},
    {'button', 'fieldset', 'input', 'keygen', 'label', 'object', 'output', 'select', 'textarea'}},
  {'formaction',
    {'URL'},
    {'button', 'input'}},
  {'formenctype',
    {'Enum', {'application/x-www-form-urlencoded', 'multipart/form-data', 'text/plain'}},
    {'button', 'input'}},
  {'formmethod',
    {'Enum', {'GET', 'POST'}},
    {'button', 'input'}},
  {'formnovalidate',
    {'Boolean'},
    {'button', 'input'}},
  {'formtarget',
    {'Text'},
    {'button', 'input'}},
  {'headers',
    {'Text'},
    {'td', 'th'}},
  {'height',
    {'Text'},
    {'canvas', 'embed', 'iframe', 'img', 'input', 'object', 'video'}},
  {'hidden',
    {'Boolean'},
    true},
  {'high',
    {'Text'},
    {'meter'}},
  {'href',
    {'URL'},
    {'a', 'area', 'link', 'base'}},
  {'hreflang',
    {'Text'},
    {'a', 'area', 'link'}},
  {'http-equiv',
    {'Raw'},
    {'meta'}},
  {'icon',
    {'URL'},
    {'menuitem'}},
  {'id',
    {'Text'},
    true},
  {'inert',
    {'Boolean'},
    true},
  {'inputmode',
    {'Enum', {'verbatim', 'latin', 'latin-name', 'latin-prose', 'full-width-latin', 'kana', 'katakana', 'numeric', 'tel', 'email', 'url'}},
    {'input', 'textarea'}},
  {'ismap',
    {'Boolean'},
    {'img'}},
  {'itemid',
    {'URL'},
    true},
  {'itemprop',
    {'URL'},
    true},
  {'itemref',
    {'Text'},
    true},
  {'itemscope',
    {'Boolean'},
    true},
  {'itemtype',
    {'URL'},
    true},
  {'keytype',
    {'Text'},
    {'keygen'}},
  {'kind',
    {'Enum', {'subtitles', 'captions', 'descriptions', 'chapters', 'metadata'}},
    {'track'}},
  {'label',
    {'Text'},
    {'menuitem', 'menu', 'optgroup', 'option', 'track'}},
  {'lang',
    {'Text'},
    true},
  {'list',
    {'Text'},
    {'input'}},
  {'loop',
    {'Boolean'},
    {'audio', 'video'}},
  {'low',
    {'Text'},
    {'meter'}},
  {'manifest',
    {'URL'},
    {'html'}},
  {'max',
    {'Text'},
    {'input', 'meter', 'progress'}},
  {'maxlength',
    {'Text'},
    {'input', 'textarea'}},
  {'media',
    {'Raw'},
    {'link', 'source', 'style'}},
  {'mediagroup',
    {'Text'},
    {'audio', 'video'}},
  {'menu',
    {'Text'},
    {'button'}},
  {'method',
    {'Enum', {'GET', 'POST', 'dialog'}},
    {'form'}},
  {'min',
    {'Text'},
    {'input', 'meter'}},
  {'minlength',
    {'Text'},
    {'input', 'textarea'}},
  {'multiple',
    {'Boolean'},
    {'input', 'select'}},
  {'muted',
    {'Boolean'},
    {'audio', 'video'}},
  {'name',
    {'Text'},
    {'button', 'fieldset', 'input', 'keygen', 'output', 'select', 'textarea', 'form', 'iframe', 'object', 'map', 'meta', 'param'}},
  {'novalidate',
    {'Boolean'},
    {'form'}},
  {'open',
    {'Boolean'},
    {'details', 'dialog'}},
  {'optimum',
    {'Text'},
    {'meter'}},
  {'pattern',
    {'Text'},
    {'input'}},
  {'ping',
    {'URL'},
    {'a', 'area'}},
  {'placeholder',
    {'Text'},
    {'input', 'textarea'}},
  {'poster',
    {'URL'},
    {'video'}},
  {'preload',
    {'Enum', {'none', 'metadata', 'auto'}},
    {'audio', 'video'}},
  {'radiogroup',
    {'Text'},
    {'menuitem'}},
  {'readonly',
    {'Boolean'},
    {'input', 'textarea'}},
  {'rel',
    {'Text'},
    {'a', 'area', 'link'}},
  {'required',
    {'Boolean'},
    {'input', 'select', 'textarea'}},
  {'reversed',
    {'Boolean'},
    {'ol'}},
  {'rows',
    {'Text'},
    {'textarea'}},
  {'rowspan',
    {'Text'},
    {'td', 'th'}},
  {'sandbox',
    {'Raw'},
    {'iframe'}},
  {'spellcheck',
    {'Enum', {'true', 'false'}},
    true},
  {'scope',
    {'Enum', {'row', 'col', 'rowgroup', 'colgroup'}},
    {'th'}},
  {'scoped',
    {'Boolean'},
    {'style'}},
  {'seamless',
    {'Boolean'},
    {'iframe'}},
  {'selected',
    {'Boolean'},
    {'option'}},
  {'shape',
    {'Enum', {'circle', 'default', 'poly', 'rect'}},
    {'area'}},
  {'size',
    {'Text'},
    {'input', 'select'}},
  {'sizes',
    {'Text'},
    {'link'}},
  {'sorted',
    {'Text'},
    {'th'}},
  {'span',
    {'Text'},
    {'col', 'colgroup'}},
  {'src',
    {'URL'},
    {'audio', 'embed', 'iframe', 'img', 'input', 'script', 'source', 'track', 'video'}},
  {'srcdoc',
    {'Raw'},
    {'iframe'}},
  {'srclang',
    {'Text'},
    {'track'}},
  {'srcset',
    {'Raw'},
    {'img'}},
  {'start',
    {'Text'},
    {'ol'}},
  {'step',
    {'Text'},
    {'input'}},
  {'style',
    {'Raw'},
    true},
  {'tabindex',
    {'Text'},
    true},
  {'target',
    {'Text'},
    {'a', 'area', 'base', 'form'}},
  {'title',
    {'Text'},
    true},
  {'translate',
    {'Enum', {'yes', 'no'}},
    true},
  {'type',
    {'Text'},
    {'a', 'area', 'link', 'button', 'embed', 'object', 'script', 'source', 'style', 'input', 'menu', 'menuitem', 'ol'}},
  {'typemustmatch',
    {'Boolean'},
    {'object'}},
  {'usemap',
    {'Text'},
    {'img', 'object'}},
  {'value',
    {'Text'},
    {'button', 'option', 'data', 'input', 'li', 'meter', 'progress', 'param'}},
  {'width',
    {'Text'},
    {'canvas', 'embed', 'iframe', 'img', 'input', 'object', 'video'}},
  {'wrap',
    {'Enum', {'soft', 'hard'}},
    {'textarea'}},
  {'onabort',
    {'Raw'},
    true},
  {'onafterprint',
    {'Raw'},
    {'body'}},
  {'onbeforeprint',
    {'Raw'},
    {'body'}},
  {'onbeforeunload',
    {'Raw'},
    {'body'}},
  {'onblur',
    {'Raw'},
    true},
  {'oncancel',
    {'Raw'},
    true},
  {'oncanplay',
    {'Raw'},
    true},
  {'oncanplaythrough',
    {'Raw'},
    true},
  {'onchange',
    {'Raw'},
    true},
  {'onclick',
    {'Raw'},
    true},
  {'onclose',
    {'Raw'},
    true},
  {'oncontextmenu',
    {'Raw'},
    true},
  {'oncuechange',
    {'Raw'},
    true},
  {'ondblclick',
    {'Raw'},
    true},
  {'ondrag',
    {'Raw'},
    true},
  {'ondragend',
    {'Raw'},
    true},
  {'ondragenter',
    {'Raw'},
    true},
  {'ondragexit',
    {'Raw'},
    true},
  {'ondragleave',
    {'Raw'},
    true},
  {'ondragover',
    {'Raw'},
    true},
  {'ondragstart',
    {'Raw'},
    true},
  {'ondrop',
    {'Raw'},
    true},
  {'ondurationchange',
    {'Raw'},
    true},
  {'onemptied',
    {'Raw'},
    true},
  {'onended',
    {'Raw'},
    true},
  {'onerror',
    {'Raw'},
    true},
  {'onfocus',
    {'Raw'},
    true},
  {'onhashchange',
    {'Raw'},
    {'body'}},
  {'oninput',
    {'Raw'},
    true},
  {'oninvalid',
    {'Raw'},
    true},
  {'onkeydown',
    {'Raw'},
    true},
  {'onkeypress',
    {'Raw'},
    true},
  {'onkeyup',
    {'Raw'},
    true},
  {'onload',
    {'Raw'},
    true},
  {'onloadeddata',
    {'Raw'},
    true},
  {'onloadedmetadata',
    {'Raw'},
    true},
  {'onloadstart',
    {'Raw'},
    true},
  {'onmessage',
    {'Raw'},
    {'body'}},
  {'onmousedown',
    {'Raw'},
    true},
  {'onmouseenter',
    {'Raw'},
    true},
  {'onmouseleave',
    {'Raw'},
    true},
  {'onmousemove',
    {'Raw'},
    true},
  {'onmouseout',
    {'Raw'},
    true},
  {'onmouseover',
    {'Raw'},
    true},
  {'onmouseup',
    {'Raw'},
    true},
  {'onmousewheel',
    {'Raw'},
    true},
  {'onoffline',
    {'Raw'},
    {'body'}},
  {'ononline',
    {'Raw'},
    {'body'}},
  {'onpagehide',
    {'Raw'},
    {'body'}},
  {'onpageshow',
    {'Raw'},
    {'body'}},
  {'onpause',
    {'Raw'},
    true},
  {'onplay',
    {'Raw'},
    true},
  {'onplaying',
    {'Raw'},
    true},
  {'onpopstate',
    {'Raw'},
    {'body'}},
  {'onprogress',
    {'Raw'},
    true},
  {'onratechange',
    {'Raw'},
    true},
  {'onreset',
    {'Raw'},
    true},
  {'onresize',
    {'Raw'},
    {'body'}},
  {'onscroll',
    {'Raw'},
    true},
  {'onseeked',
    {'Raw'},
    true},
  {'onseeking',
    {'Raw'},
    true},
  {'onselect',
    {'Raw'},
    true},
  {'onshow',
    {'Raw'},
    true},
  {'onsort',
    {'Raw'},
    true},
  {'onstalled',
    {'Raw'},
    true},
  {'onstorage',
    {'Raw'},
    {'body'}},
  {'onsubmit',
    {'Raw'},
    true},
  {'onsuspend',
    {'Raw'},
    true},
  {'ontimeupdate',
    {'Raw'},
    true},
  {'ontoggle',
    {'Raw'},
    true},
  {'onunload',
    {'Raw'},
    {'body'}},
  {'onvolumechange',
    {'Raw'},
    true},
  {'onwaiting',
    {'Raw'},
    true},
}
return M
