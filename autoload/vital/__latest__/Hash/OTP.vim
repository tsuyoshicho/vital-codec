" Utilities for HOTP/TOTP Wrapper
" RFC 4226 - HOTP: An HMAC-Based One-Time Password Algorithm https://tools.ietf.org/html/rfc4226
" RFC 6238 - TOTP: Time-Based One-Time Password Algorithm https://tools.ietf.org/html/rfc6238

let s:save_cpo = &cpo
set cpo&vim

let s:DEFAULTS = {}

function! s:_vital_created(module) abort
  let a:module.defaults = s:DEFAULTS
endfunction

function! s:_vital_loaded(V) abort
  let s:V   = a:V
  let s:OTP = s:V.import('Crypt.Password.OTP')

  call extend(s:DEFAULTS, s:OTP.defaults)
endfunction

function! s:_vital_depends() abort
  return ['Crypt.Password.OTP']
endfunction

function! s:hotp(...) abort
  try
    return call(s:OTP.hotp, a:000)
  catch /vital: Crypt\.Password\.OTP: \zs.*$/
    call s:_throw(v:exception)
  endtry
endfunction

function! s:totp(...) abort
  try
    return call(s:OTP.totp, a:000)
  catch /vital: Crypt\.Password\.OTP: \zs.*$/
    call s:_throw(v:exception)
  endtry
endfunction

"---------------------------------------------------------------------
" misc

function! s:_throw(message) abort
  throw 'vital: Hash.OTP: ' . a:message
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
