" Utilities for Base64. Radix64 type
" RFC 4880 http://tools.ietf.org/html/rfc4880.html

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:CRC24Radix64 = a:V.import('Data.Checksum.CRC24Radix64')
  let s:Base64       = a:V.import('Data.Base64.RFC4648')
  let s:ByteArray    = a:V.import('Data.List.Byte')
endfunction

let s:padding = '='
lockvar s:padding

function! s:_vital_depends() abort
  return ['Data.Checksum.CRC24Radix64', 'Data.Base64.RFC4648', 'Data.List.Byte']
endfunction

function! s:encode(data) abort
  return s:encodebytes(s:ByteArray.from_string(a:data))
endfunction

function! s:encodebin(data) abort
  return s:encodebytes(s:ByteArray.from_hexstring(a:data))
endfunction

function! s:encodebytes(data) abort
  let checksum = s:CRC24Radix64.calculate(a:data)
  return [s:Base64.encodebytes(a:data), s:padding . s:Base64.encodebytes(checksum)]
endfunction

function! s:validate(data, sum) abort
  if strcharpart(a:sum, 0, 1) !=? s:padding
    return v:false
  endif
  let decode_data = s:decoderaw(a:data)
  let decode_sum  = s:decoderaw(strcharpart(a:sum, 1))
  return s:CRC24Radix64.validate(decode_data, decode_sum)
endfunction

function! s:decode(data) abort
  return s:ByteArray.to_string(s:decoderaw(a:data))
endfunction

function! s:decoderaw(data) abort
  return s:Base64.decoderaw(a:data)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
