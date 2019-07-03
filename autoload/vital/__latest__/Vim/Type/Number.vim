" Utilities for Number data.

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:bitwise = s:V.import('Bitwise')

  if has('num64')
    let s:mask32bit = 0xFFFFFFFF
    let s:mask64bit = s:bitwise.or(
          \ s:bitwise.lshift(s:mask32bit, 32),
          \                  s:mask32bit
          \)
  else
    let s:mask32bit = s:bitwise.or(
          \ s:bitwise.lshift(0xFFFF, 16),
          \                  0xFFFF
          \)
  endif
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
  return s:bitwise.and(a:value, s:mask32bit)
endfunction

if has('num64')
  function! s:uint64(value) abort
    return s:bitwise.and(a:value, s:mask64bit)
  endfunction
else
  function! s:uint64(value) abort
    call s:_throw('64bit unsupport.')
  endfunction
endif

" move to Bitwise
function! s:rotate8l(data, bits) abort
  let data = s:uint8(a:data)
  return s:uint8(s:bitwise.or(s:bitwise.lshift(data, a:bits),
                            \ s:bitwise.rshift(data, 8 - a:bits)))
endfunction
function! s:rotate8r(data, bits) abort
  return s:rotate8l(a:data, 8 - a:bits)
endfunction

function! s:rotate16l(data, bits) abort
  let data = s:uint16(a:data)
  return s:uint16(s:bitwise.or(s:bitwise.lshift(data, a:bits),
                             \ s:bitwise.rshift(data, 16 - a:bits)))
endfunction
function! s:rotate16r(data, bits) abort
  return s:rotate16l(a:data, 16 - a:bits)
endfunction

function! s:rotate32l(data, bits) abort
  let data = s:uint32(a:data)
  return s:uint32(s:bitwise.or(s:bitwise.lshift(data, a:bits),
                             \ s:bitwise.rshift(data, 32 - a:bits)))
endfunction
function! s:rotate32r(data, bits) abort
  return s:rotate32l(a:data, 32 - a:bits)
endfunction

if has('num64')
  function! s:rotate64l(data, bits) abort
    let data = s:uint64(a:data)
    return s:uint64(s:bitwise.or(s:bitwise.lshift(data, a:bits),
          \ s:bitwise.rshift(data, 64 - a:bits)))
  endfunction
  function! s:rotate64r(data, bits) abort
    return s:rotate64l(a:data, 64 - a:bits)
  endfunction
else
  function! s:rotate64l(data, bits) abort
    call s:_throw('64bit unsupport.')
  endfunction
  function! s:rotate64r(data, bits) abort
    call s:_throw('64bit unsupport.')
  endfunction
endif

function! s:_throw(msg) abort
  throw 'vital: Vim.Type.Number: ' . a:msg
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
