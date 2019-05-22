" Utilities for Base16.
" RFC 4648 https://tools.ietf.org/html/rfc4648

let s:save_cpo = &cpo
set cpo&vim

function! s:encode(data) abort
  " 'abc' -> [xx, yy, zz](in hex) -> 'xxyyzz'
  return s:encodebytes(s:_str2bytes(a:data))
endfunction

function! s:encodebin(data) abort
  " 'xxyyzz' -> 'xxyyzz'
  return a:data
endfunction

function! s:encodebytes(data) abort
  " [xx, yy, zz](in hex) -> 'xxyyzz'
  return s:_bytes2binstr(a:data)
endfunction

function! s:decode(data) abort
  " 'xxyyzz' -> [xx, yy, zz](in hex) -> 'abc'
  return s:_bytes2str(s:decoderaw(a:data))
endfunction

function! s:decoderaw(data) abort
  " 'xxyyzz' -> [xx, yy, zz](in hex)
  let data = toupper(a:data) " case insensitive
  return s:_binstr2bytes(data)
endfunction

function! s:_binstr2bytes(str) abort
  return map(range(len(a:str)/2), 'str2nr(a:str[v:val*2 : v:val*2+1], 16)')
endfunction

function! s:_str2bytes(str) abort
  return map(range(len(a:str)), 'char2nr(a:str[v:val])')
endfunction

function! s:_bytes2binstr(bytes) abort
  return join(map(copy(a:bytes), 'printf(''%02x'', v:val)'), '')
endfunction	endfunction

function! s:_bytes2str(bytes) abort
  return eval('"' . join(map(copy(a:bytes), 'printf(''\x%02x'', v:val)'), '') . '"')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
