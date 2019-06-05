" Utilities for UUID Namespace
" RFC 4122 - A Universally Unique IDentifier (UUID) URN Namespace https://tools.ietf.org/html/rfc4122

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  " let s:UUID = s:V.import('ID.UUID')
endfunction

function! s:_vital_created(module) abort
  " not wrok
  " let a:module.nil  = s:UUID.decode('00000000-0000-0000-0000-000000000000')
  " let a:module.DNS  = s:UUID.decode('6ba7b810-9dad-11d1-80b4-00c04fd430c8')
  " let a:module.URL  = s:UUID.decode('6ba7b811-9dad-11d1-80b4-00c04fd430c8')
  " let a:module.OID  = s:UUID.decode('6ba7b812-9dad-11d1-80b4-00c04fd430c8')
  " let a:module.X500 = s:UUID.decode('6ba7b814-9dad-11d1-80b4-00c04fd430c8')

  let a:module.nil  = '00000000-0000-0000-0000-000000000000'
  let a:module.DNS  = '6ba7b810-9dad-11d1-80b4-00c04fd430c8'
  let a:module.URL  = '6ba7b811-9dad-11d1-80b4-00c04fd430c8'
  let a:module.OID  = '6ba7b812-9dad-11d1-80b4-00c04fd430c8'
  let a:module.X500 = '6ba7b814-9dad-11d1-80b4-00c04fd430c8'
endfunction

" function! s:_vital_depends() abort
"   return ['ID.UUID']
" endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
