" Utilities for List for Byte data.

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:List = s:V.import('Data.list')
  let s:Base16 = s:V.import('Data.Base16')
endfunction

function! s:_vital_depends() abort
  return ['Data.list', 'Data.Base16']
endfunction

function! s:from_blob(b) abort
  return s:List.new(len(a:b),{i -> a:b[i]})
endfunction

function! s:to_blob(bytes) abort
  return eval('0z' . s:Base16.encodebytes(a:bytes))
endfunction

function! s:from_string(str) abort
  return map(range(len(a:str)), 'char2nr(a:str[v:val])')
endfunction

function! s:to_string(bytes) abort
  return eval('"' . join(map(copy(a:bytes), 'printf(''\x%02x'', v:val)'), '') . '"')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
