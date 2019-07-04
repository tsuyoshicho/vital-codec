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

function! s:uint8(...) abort
  return  s:_uintX(1,a:000)
endfunction

function! s:uint16(...) abort
  return  s:_uintX(2,a:000)
endfunction

function! s:uint32(...) abort
  return  s:_uintX(4,a:000)
endfunction

function! s:uint64(...) abort
  return  s:_uintX(8,a:000)
endfunction

function! s:_uintX(length, initial) abort
  let length = a:length
  let inital = 0
  if !empty(a:initial)
    let inital = a:initial[0]
  endif
  let retval = s:new(length)
  for i in range(length)
    let retval[i] = s:int.uint8(s:bitwise.rshift(inital, (8 * (length - (i + 1)))))
  endfor
  return retval
endfunction

" bit operation
function! s:or(x, y) abort
  return s:_bitop(a:x, a:y, s:bitwise.or)
endfunction

function! s:xor(x, y) abort
  return s:_bitop(a:x, a:y, s:bitwise.xor)
endfunction

function! s:and(x, y) abort
  return s:_bitop(a:x, a:y, s:bitwise.and)
endfunction

function! s:_bitop(x, y, op) abort
  " same size check
  if len(a:x) != len(a:y)
    call s:_throw('argments x and y''s size discrepancy.')
  endif
  let length = len(a:x)
  let retval = s:new(length)
  for i in range(length)
    let retval[i] = call(a:op,[a:x[i], a:y[i]])
  endfor
  return retval
endfunction

function! s:invert(x) abort
  let length = len(a:x)
  let retval = s:new(length)
  for i in range(length)
    let retval[i] = s:bitwise.invert(a:x[i])
  endfor
  return retval
endfunction

function! s:rotateright(x, bits) abort
  return s:rotr(a:x, a:bits)
endfunction
function! s:rotateleft(x, bits) abort
  return s:rotl(a:x, a:bits)
endfunction

function! s:rotr(x, bits) abort
  return s:rotl(a:x, len(a:x) - a:bits)
endfunction
function! s:rotl(x, bits) abort
  let length = len(a:x)
  let retval = s:new(length)
  let blocknum = a:bits / 8
  let shift    = a:bits % 8
  for i in range(length)
    let targetindex = (i + length - blocknum) % length
    let previndex = (i + 1) % length
    let retval[targetindex] = s:int.uint8(s:bitwise.or(s:bitwise.lshift(a:x[i], shift),
                                                     \ s:bitwise.rshift(a:x[previndex], 8 - shift)))
  endfor
  return retval
endfunction

" Arithmetic operation
function! s:uint_add(x, y,...) abort
  " same size check
  if len(a:x) != len(a:y)
    call s:_throw('argments x and y''s size discrepancy.')
  endif
  let length = len(a:x)
  let retval = s:add(a:x, a:y)

  let overflow_check = 1
  if a:0 > 0
    if a:1 is? 'nooverflow'
      let overflow_check = 0
    endif
  endif
  if length < len(retval)
    if overflow_check
      call s:_throw(printf('overflow %d byte uint.', length))
    else
      " treat size
      let retval = retval[-length : -1]
    endif
  endif
  return retval
endfunction

function! s:add(x, y) abort
  let x = s:ByteArray.from_blob(a:x)
  let y = s:ByteArray.from_blob(a:y)

  let lenx = len(x)
  let leny = len(y)

  if lenx == leny
    " skip
  elseif lenx < leny
    " expand x
    let x = repeat([0], leny - lenx) + x
  else
    " expand y
    let y = repeat([0], lenx - leny) + y
  endif

  let length = len(x)
  let retval = repeat([0], length)
  let carry = 0
  for i in range(length - 1, 0, -1)
    let retval[i] = s:int.uint8(x[i] + y[i] + carry)
    let carry = (x[i] + y[i]) / 0x100
  endfor
  if carry
    let retval = [1] + retval
  endif
  return  s:ByteArray.to_blob(retval)
endfunction

function! s:_throw(message) abort
  throw "vital: Vim.Type.Blob: " . a:message
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
