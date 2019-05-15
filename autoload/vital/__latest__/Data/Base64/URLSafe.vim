" Utilities for Base64. URL and filename safe type
" RFC 4648 https://tools.ietf.org/html/rfc4648

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Base64 = s:V.import('Data.Base64')
  let s:String = s:V.import('Data.String')
endfunction

function! s:_vital_depends() abort
  return ['Data.Base64', 'Data.String']
endfunction

function! s:encode(data) abort
  let b64 = s:Base64.encode(a:data)
  let b64replace62 = s:String.replace(b64,          '+', '-')
  let retval       = s:String.replace(b64replace62, '/', '_')
  return retval
endfunction

function! s:encodebin(data) abort
  let b64 = s:Base64.encodebin(a:data)
  let b64replace62 = s:String.replace(b64,          '+', '-')
  let retval       = s:String.replace(b64replace62, '/', '_')
  return retval
endfunction

function! s:decode(data) abort
  let b64replace62 = s:String.replace(a:data,       '-', '+')
  let b64          = s:String.replace(b64replace62, '_', '/')
  return s:Base64.decode(b64)
endfunction

" padding skip need

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
