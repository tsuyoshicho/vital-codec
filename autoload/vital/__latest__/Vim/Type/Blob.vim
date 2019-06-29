" Utilities for Blob data.

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:bitwise   = s:V.import('Bitwise')
  let s:int       = s:V.import('Vim.Type.Number')
  let s:ByteArray = s:V.import('Data.List.Byte')
endfunction

function! s:_vital_depends() abort
  return ['Bitwise', 'Vim.Type.Number', 'Data.List.Byte']
endfunction

function! s:new(length) abort
  let retval = repeat([0],a:length)
  return s:ByteArray.to_blob(retval)
endfunction

function! s:uint64bit(...) abort
  let inital = 0
  if a:0
    let inital = a:1
  endif
  let retval = s:new(8) " 8 byte 64bit length
  for i in range(8)
    let retval[i] = s:int.uint8(s:bitwise.rshift(inital, 64 - (8 * (i + 1))))
  endfor
  return retval
endfunction

" bit operation
" TODO: and/or/xor integration one function
function! s:uint_or(x, y) abort
  " same size check
  let length = len(a:x)
  let retval = s:new(length)
  for i in range(length)
    let retval[i] = s:bitwise.or(a:x[i], a:y[i])
  endfor
  return retval
endfunction

function! s:uint_xor(x, y) abort
  " same size check
  let length = len(a:x)
  let retval = s:new(length)
  for i in range(length)
    let retval[i] = s:bitwise.xor(a:x[i], a:y[i])
  endfor
  return retval
endfunction

function! s:uint_and(x, y) abort
  " same size check
  let length = len(a:x)
  let retval = s:new(length)
  for i in range(length)
    let retval[i] = s:bitwise.and(a:x[i], a:y[i])
  endfor
  return retval
endfunction

function! s:uint_rotl(x, bits) abort
  let length = len(a:x)
  let retval = s:new(length)
  let blocknum = a:bits / length
  let shift    = a:bits % length
  for i in range(length)
    let targetindex = (i + blocknum) % length
    let previndex = (i + length - 1) % length
    let retval[targetindex] = s:int.uint8(s:bitwise.or(s:bitwise.lshift(a:x[i], shift),
                                                     \ s:bitwise.rshift(a:x[previndex], 8 - shift)))
  endfor
  return retval
endfunction

" Arithmetic operation
function! s:uint_add(x, y) abort
  " same size check
  let length = len(a:x)
  let retval = s:new(length)
  let carry = 0
  for i in range(length, 0, -1)
    let retval[i] = s:int.uint8(a:x[i] + a:y[i] + carry)
    let carry = (a:x[i] + a:y[i]) / 255
  endfor
  return retval
endfunction

" uint operation
function! s:uint2list(x) abort
  let length = len(a:x)
  let retval = s:new(length)
  for i in range(length)
    let retval[i] = a:x[i]
  endfor
  return retval
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
