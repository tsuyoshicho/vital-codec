" Utilities for Number data.

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:bitwise = s:V.import('Bitwise')
endfunction

function! s:_vital_depends() abort
  return ['Bitwise']
endfunction

function! s:uint8(value) abort
  return s:bitwise.and(a:value, 0xFF)
endfunction

function! s:uint16(value) abort
  return s:bitwise.and(a:value, 0xFFFF)
endfunction

function! s:uint32(value) abort
  return s:bitwise.and(a:value, 0xFFFFFFFF)
endfunction

function! s:uint64(value) abort
  return s:bitwise.and(a:value, 0xFFFFFFFFFFFFFFFF)
endfunction

" move to Bitwise
function! s:rotate8l(data, bits) abort
  let data = s:uint8(a:data)
  return s:uint8(s:bitwise.or(s:bitwise.lshift(data, a:bits),
                            \ s:bitwise.rshift(data, 8 - a:bits)))
endfunction
function! s:rotate8r(data, bits) abort
  return s:rotate8l(a:data, 8 - bits)
endfunction

function! s:rotate16l(data, bits) abort
  let data = s:uint16(a:data)
  return s:uint16(s:bitwise.or(s:bitwise.lshift(data, a:bits),
                             \ s:bitwise.rshift(data, 16 - a:bits)))
endfunction
function! s:rotate16r(data, bits) abort
  return s:rotate16l(a:data, 16 - bits)
endfunction

function! s:rotate32l(data, bits) abort
  let data = s:uint32(a:data)
  return s:uint32(s:bitwise.or(s:bitwise.lshift(data, a:bits),
                             \ s:bitwise.rshift(data, 32 - a:bits)))
endfunction
function! s:rotate32r(data, bits) abort
  return s:rotate32l(a:data, 32 - bits)
endfunction

function! s:rotate64l(data, bits) abort
  let data = s:uint64(a:data)
  return s:uint64(s:bitwise.or(s:bitwise.lshift(data, a:bits),
                             \ s:bitwise.rshift(data, 64 - a:bits)))
endfunction
function! s:rotate64r(data, bits) abort
  return s:rotate64l(a:data, 64 - bits)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
