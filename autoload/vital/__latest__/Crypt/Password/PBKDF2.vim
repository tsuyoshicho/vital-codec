" Utilities for PBKDF2
" RFC 2898 - PKCS #5: Password-Based Cryptography Specification Version 2.0 https://tools.ietf.org/html/rfc2898

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V    = a:V
  let s:HMAC = s:V.import('Hash.HMAC')
endfunction

function! s:_vital_depends() abort
  return ['Hash.HMAC']
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
