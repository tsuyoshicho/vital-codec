" Utilities for List for Byte data.

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:bitwise = s:V.import('Bitwise')
  let s:type    = s:V.import('Vim.Type')
  let s:int     = s:V.import('Vim.Type.Number')
  let s:List    = s:V.import('Data.List')
endfunction

function! s:_vital_depends() abort
  return ['Bitwise', 'Vim.Type', 'Vim.Type.Number', 'Data.List']
endfunction

function! s:validate(data) abort
  return type(a:data) == s:type.types.list
        \ && len(a:data) == len(s:List.filter(a:data, { v -> type(v) == s:type.types.number }))
        \ && min(a:data) >= 0
        \ && max(a:data) <= 255
endfunction

function! s:from_blob(blob) abort
  return s:List.new(len(a:blob), {i -> a:blob[i]})
endfunction

function! s:to_blob(bytes) abort
  return eval('0z' . s:to_hexstring(a:bytes))
endfunction

function! s:from_string(str) abort
  return s:List.new(len(a:str), {i -> char2nr(a:str[i])})
endfunction

function! s:to_string(bytes) abort
  return eval('"' . join(map(copy(a:bytes), 'printf(''\x%02x'', v:val)'), '') . '"')
endfunction

function! s:from_hexstring(hexstr) abort
  return s:List.new(len(a:hexstr)/2, {i -> str2nr(a:hexstr[i*2 : i*2+1], 16)})
endfunction

function! s:to_hexstring(bytes) abort
  return join(map(copy(a:bytes), 'printf(''%02x'', v:val)'), '')
endfunction

function! s:from_int(value, bits) abort
  " return to big endian
  return s:List.new(a:bits/8, {i -> s:int.uint8(s:bitwise.rshift(a:value, a:bits - (i + 1)*8))})
endfunction

function! s:to_int(bytes) abort
  " from big endian
  let ret = 0
  let maxlen = len(a:bytes)
  let values = map(copy(a:bytes), { i,v ->  s:bitwise.lshift(v, (maxlen-1 - i) * 8)})
  for v in values
    let ret = s:bitwise.or(v,ret)
  endfor
  return ret
endfunction

function! s:endian_convert(bytes) abort
  if !(len(a:bytes) > 1)
    call s:_throw('data count need 2 or more')
  endif
  if (len(a:bytes) % 2)
    call s:_throw('odd data count')
  endif
  return reverse(copy(a:bytes))
endfunction

" inner

function! s:_throw(message) abort
  throw "vital: Data.List.Byte: " . a:message
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
