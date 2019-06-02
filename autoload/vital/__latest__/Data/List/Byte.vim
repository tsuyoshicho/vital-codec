" Utilities for List for Byte data.

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:List = s:V.import('Data.List')
endfunction

function! s:_vital_depends() abort
  return ['Data.list', 'Data.Base16']
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

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
