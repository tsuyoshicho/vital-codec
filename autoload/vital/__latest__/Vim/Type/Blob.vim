" Utilities for Blob data.

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Bitwise   = s:V.import('Bitwise')
  let s:Type      = s:V.import('Vim.Type')
  let s:ByteArray = s:V.import('Data.List.Byte')
endfunction

function! s:_vital_depends() abort
  return ['Bitwise', 'Vim.Type', 'Data.List.Byte']
endfunction

" Create Function
function! s:new(length) abort
  let retval = repeat([0], a:length)
  return s:ByteArray.to_blob(retval)
endfunction

" Unsigned Integer Create/Cast Function
function! s:uint8(...) abort
  return  s:_uintX( 8, a:000)
endfunction

function! s:uint16(...) abort
  return  s:_uintX(16, a:000)
endfunction

function! s:uint32(...) abort
  return  s:_uintX(32, a:000)
endfunction

function! s:uint64(...) abort
  return  s:_uintX(64, a:000)
endfunction

function! s:_uintX(bits, initial) abort
  let bits = a:bits
  let length = bits / 8

  if empty(a:initial)
    let data = repeat([0], length)
  else
    let initial = a:initial[0]
    let typeval = type(initial)

    if typeval == s:Type.types.number
      let uintval = s:Bitwise['uint' . string(bits)](initial)
      let data = s:ByteArray.from_int(uintval, bits)
    elseif typeval == s:Type.types.string
      let data = s:ByteArray.from_hexstring(initial)
    elseif typeval == s:Type.types.list && s:ByteArray.validate(initial)
      let data = initial
    " types.blob currently not support
    " elseif typeval == s:type.types.blob
    " temporary fix
    elseif typeval == type(0z00)
      let data = s:ByteArray.from_blob(initial)
    else
      call s:_throw('non-support value type')
    endif
  endif

  if length > len(data)
    let data = repeat([0], length - len(data)) + data
  elseif length < len(data)
    let data = data[-length:-1]
  endif

  return s:ByteArray.to_blob(data)
endfunction

" Bitwise Function
function! s:or(x, y) abort
  return s:_bitop(a:x, a:y, s:Bitwise.or)
endfunction

function! s:xor(x, y) abort
  return s:_bitop(a:x, a:y, s:Bitwise.xor)
endfunction

function! s:and(x, y) abort
  return s:_bitop(a:x, a:y, s:Bitwise.and)
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
    let retval[i] = s:Bitwise.invert(a:x[i])
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
  return s:rotl(a:x, (len(a:x) * 8) - a:bits)
endfunction
function! s:rotl(x, bits) abort
  let length = len(a:x)
  let retval = s:new(length)
  let blocknum = a:bits / 8
  let shift    = a:bits % 8
  for i in range(length)
    let targetindex = (i + length - blocknum) % length
    let previndex = (i + 1) % length
    let retval[targetindex] = s:Bitwise.uint8(s:Bitwise.or(s:Bitwise.lshift(a:x[i], shift),
                                                     \ s:Bitwise.rshift(a:x[previndex], 8 - shift)))
  endfor
  return retval
endfunction

" Arithmetic Function
function! s:add(x, y) abort
  let [x, y] = s:_arith_arg_to_list(a:x, a:y)

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
    let sumvalue = x[i] + y[i] + carry
    let retval[i] = s:Bitwise.uint8(sumvalue)
    let carry = sumvalue / 0x100
  endfor
  if carry
    let retval = [1] + retval
  endif
  return  s:ByteArray.to_blob(retval)
endfunction

function! s:rshift(x, bits) abort
  if (len(a:x) * 8) <= a:bits
    call s:_throw('shift size over.')
  endif

  let blocknum = a:bits / 8
  let shift    = a:bits % 8

  " blocknum lower cut
  let value = a:x[ : (len(a:x) - blocknum) - 1]

  " create data : size+1 and save it
  let data = s:new(len(value) + 1)
  let data[1:] = value[:]

  " rotr
  let shifted = s:rotr(data, shift)
  " cut top
  let shifted = shifted[1 : ]

  " if top is all 0 cut
  if shifted[0] == 0
    let shifted_new = s:new(len(shifted) - 1)
    let shifted_new[:] = shifted[1 : ]
    let shifted = shifted_new
  endif

  return shifted
endfunction

function! s:lshift(x, bits) abort
  let blocknum = a:bits / 8
  let shift    = a:bits % 8

  " +1 data create
  let data = s:new(len(a:x) + 1)

  " save data and shift(rotl)
  let data[1:] = a:x[:]
  let shifted = s:rotl(data, shift)

  " if top is all 0 cut
  if shifted[0] == 0
    let shifted_new = s:new(len(shifted) - 1)
    let shifted_new[:] = shifted[1 : ]
    let shifted = shifted_new
  endif

  " add blocknum all 0 data
  let retval = s:new(len(shifted) + blocknum)
  let retval[0 : len(shifted) - 1] = shifted[:]

  return retval
endfunction

function! s:_arith_arg_to_list(x, y) abort
  let x = s:ByteArray.from_blob(a:x)

  let typeval = type(a:y)
  if typeval == s:type.types.number
    let y = s:ByteArray.from_int(a:y, len(x) * 8)
  " types.blob currently not support
  " elseif typeval == s:type.types.blob
  " temporary fix
  elseif typeval == type(0z00)
    let y = s:ByteArray.from_blob(a:y)
  else
    call s:_throw('non-support value type')
  endif
  unlet typeval

  return [x,y]
endfunction

" Arithmetic Unsigned Integer Function
function! s:uint_add(x, y,...) abort
  " same size check
  if len(a:x) != len(a:y)
    call s:_throw('argments x and y''s size discrepancy.')
  endif
  let length = len(a:x)
  let retval = s:add(a:x, a:y)

  let overflow_check = 0
  if a:0 > 0
    if a:1 is? 'overflow'
      let overflow_check = 1
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

" uint_sub,sub
" uint_mul,mul
" uint_div,div
" uint_mod,mod
" uint_rshift/lshift, rshift/lshift

function! s:_throw(message) abort
  throw "vital: Vim.Type.Blob: " . a:message
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
