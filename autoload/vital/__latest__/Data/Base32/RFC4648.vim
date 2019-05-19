" Utilities for Base32. RFC 4648 type
" RFC 4648 http://tools.ietf.org/html/rfc4648.html

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Base32util = s:V.import('Data.Base32.Base32')
endfunction

function! s:_vital_depends() abort
  return ['Data.Base32.Base32']
endfunction

function! s:encode(data) abort
  return s:encodebytes(s:_str2bytes(a:data))
endfunction

function! s:encodebin(data) abort
  return s:encodebytes(s:_binstr2bytes(a:data))
endfunction

function! s:encodebytes(data) abort
  let b32 = s:Base32util.b32encode(a:data,
        \ s:rfc4648_encode_table,
        \ s:is_padding,
        \ s:padding_symbol)
  return join(b32, '')
endfunction

function! s:decode(data) abort
  return s:_bytes2str(s:decoderaw(a:data))
endfunction

function! s:decoderaw(data) abort
  let data = toupper(a:data) " case insensitive
  return s:Base32util.b32decode(filter(split(data, '\zs'), {c -> !s:is_ignore_symbol(c)}),
        \ s:rfc4648_decode_map,
        \ s:is_padding,
        \ s:is_padding_symbol)
endfunction

let s:is_padding = 1
let s:padding_symbol = '='
let s:is_padding_symbol = {c -> c == s:padding_symbol}
let s:is_ignore_symbol = {c -> 0}

let s:rfc4648_encode_table = [
      \ 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
      \ 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
      \ 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
      \ 'Y', 'Z', '2', '3', '4', '5', '6', '7' ]

let s:rfc4648_decode_map = {}
for i in range(len(s:rfc4648_encode_table))
  let s:rfc4648_decode_map[s:rfc4648_encode_table[i]] = i
endfor

function! s:_binstr2bytes(str) abort
  return map(range(len(a:str)/2), 'str2nr(a:str[v:val*2 : v:val*2+1], 16)')
endfunction

function! s:_str2bytes(str) abort
  return map(range(len(a:str)), 'char2nr(a:str[v:val])')
endfunction

function! s:_bytes2str(bytes) abort
  return eval('"' . join(map(copy(a:bytes), 'printf(''\x%02x'', v:val)'), '') . '"')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
