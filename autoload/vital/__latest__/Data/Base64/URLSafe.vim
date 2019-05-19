" Utilities for Base64. URL and filename safe type
" RFC 4648 https://tools.ietf.org/html/rfc4648

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Base64util = s:V.import('Data.Base64.Base64')
endfunction

function! s:_vital_depends() abort
  return ['Data.Base64.Base64']
endfunction

function! s:encode(data) abort
  return s:encodebytes(s:_str2bytes(a:data))
endfunction

function! s:encodebin(data) abort
  return s:encodebytes(s:_binstr2bytes(a:data))
endfunction

function! s:encodebytes(data) abort
  let b64 = s:Base64util.b64encode(a:data,
        \ s:urlsafe_encode_table,
        \ s:is_padding,
        \ s:padding_symbol)
  return join(b64, '')
endfunction

function! s:decode(data) abort
  return s:_bytes2str(s:decoderaw(a:data))
endfunction

function! s:decoderaw(data) abort
  return s:Base64util.b64decode(filter(split(a:data, '\zs'), '!s:is_ignore_symbol(v:val)'),
        \ s:urlsafe_decode_map,
        \ s:is_padding,
        \ s:is_padding_symbol)
endfunction

let s:is_padding = 0
let s:padding_symbol = ''
let s:is_padding_symbol = {c -> 0}
let s:is_ignore_symbol = {c -> 0}

let s:urlsafe_encode_table = [
      \ 'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
      \ 'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
      \ 'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
      \ 'w','x','y','z','0','1','2','3','4','5','6','7','8','9','-','_']

let s:urlsafe_decode_map = {}
for i in range(len(s:urlsafe_encode_table))
  let s:urlsafe_decode_map[s:urlsafe_encode_table[i]] = i
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
