" Utilities for UUID Namespace
" RFC 4122 - A Universally Unique IDentifier (UUID) URN Namespace https://tools.ietf.org/html/rfc4122

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:UUID = s:V.import('ID.UUID')

  let s:nil  = s:UUID.decode('00000000-0000-0000-0000-000000000000')
  let s:DNS  = s:UUID.decode('6ba7b810-9dad-11d1-80b4-00c04fd430c8')
  let s:URL  = s:UUID.decode('6ba7b811-9dad-11d1-80b4-00c04fd430c8')
  let s:OID  = s:UUID.decode('6ba7b812-9dad-11d1-80b4-00c04fd430c8')
  let s:X500 = s:UUID.decode('6ba7b814-9dad-11d1-80b4-00c04fd430c8')
endfunction

function! s:_vital_depends() abort
  return ['ID.UUID']
endfunction

let s:nil = {}
let s:DNS = {}
let s:URL = {}
let s:OID = {}
let s:X500 = {}

function! s:nil() abort
  return deepcopy(s:nil)
endfunction

function! s:DNS() abort
  return deepcopy(s:DNS)
endfunction

function! s:URL() abort
  return deepcopy(s:URL)
endfunction

function! s:OID() abort
  return deepcopy(s:OID)
endfunction

function! s:X500() abort
  return deepcopy(s:X500)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
