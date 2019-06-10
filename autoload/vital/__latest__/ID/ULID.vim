" Utilities for ULID
" ulid/spec: The canonical spec for ulid https://github.com/ulid/spec

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V        = a:V
  let s:bitwise  = s:V.import('Bitwise')
  let s:Random   = s:V.import('Random')
  let s:List     = s:V.import('Data.List')
  let s:BigNum   = s:V.import('Data.BigNum')
  let s:Base32cf = s:V.import('Data.Base32.Crockford')
  let s:UUID     = s:V.import('ID.UUID')
endfunction

function! s:_vital_depends() abort
  return ['Bitwise', 'Random', 'Data.List',
        \ 'Data.BigNum' 'Data.Base32.Crockford',
        \ 'ID.UUID']
endfunction

function! s:generate(...) abort
  let ulid = call('s:_ulid_generate', a:000)
  return s:_ulid_encode(ulid)
endfunction

function! s:generateUUID(...) abort
  let ulid = call('s:_ulid_generate', a:000)
  return s:_bytes2uuid(ulid.bytes).uuid_hex
endfunction

function! s:ULID2UUID(ulid_b32) abort
  let ulid = s:_ulid_decode(a:ulid_b32)
  return s:_bytes2uuid(ulid.bytes)
endfunction

function! s:_ulid_generate(...) abort
  let timelist   = s:List.new(6,  {-> 0})
  let randomlist = s:List.new(10, {-> 0})

  " 48bit timestamp
  let timelist_mod = s:List.new(6, {-> {}}) " index is No. x byte
  let timelist_div = s:List.new(6, {-> {}}) " index is remain ,0 is now 5 is last divided value

  " localtime is Unix epoch second timestanp, need msec; generate x1000
  let now_timestamp = localtime()

  let timelist_div[0] = s:BigNum.mul(now_timestamp, 1000)

  " byte 1-5 generate
  for i in range(6 - 1)
    " div +1 next byte's source  / mod offset
    let [timelist_div[i + 1], timelist_mod[6 - (i + 1)]] = s:BigNum.div_mod(timelist_div[i], 0x100)
  endfor
  " byte 0
  let timelist_mod[0] = s:BigNum.mod(timelist_div[5], 0x100)

  for i in range(6)
    let timelist[i] = str2nr(s:BigNum.to_string(timelist_mod[i]), 10)
  endfor

  " 80bit random (8bit = 1byte) x 10
  let r = call(s:Random.new, a:000)
  for i in range(10)
    let randomlist[i] = r.range(256)
  endfor

  let retval = {
        \ 'bytes'     : timelist + randomlist,
        \ 'timestamp' : timelist,
        \ 'random'    : randomlist,
        \ }

  return retval
endfunction

function! s:_ulid_encode(ulid) abort
  " timestamp 6byte,8bitx5bit lcm 40bit -> left dummy need 10-6 = 4byte
  let timestamp_dummy =  s:List.new(4,  {-> 0})
  let timestamp_b32_w_dummy = s:Base32cf.encodebytes(timestamp_dummy + a:ulid.timestamp)
  " cut 6char (10byte->16char, tamptamp 10char)
  let timestamp_b32 = strpart(timestamp_b32_w_dummy, 6)

  " random 10byte -> no dummy need
  let random_b32 = s:Base32cf.encodebytes(a:ulid.random)

  return timestamp_b32 . random_b32
endfunction

function! s:_ulid_decode(ulid_b32) abort
  let timestamp_top = strpart(a:ulid_b32, 0, 1)
  " max 7ZZZZZZZZZZZZZZZZZZZZZZZZZ
  if timestamp_top !~? '[0-7]'
    " 8?... or higher
    call s:_throw('48bit timestamp overflow')
  endif

  let timestamp_b32 = strpart(a:ulid_b32, 0, 10)
  " dummy 6char 0
  let timestamp_b32_w_dummy = '000000' . timestamp_b32
  let timelist_w_dummy = s:Base32cf.decoderaw(timestamp_b32_w_dummy)
  " cut 4byte / tail 6byte
  let timelist =  timelist_w_dummy[-6:-1]

  " random 10byte -> no dummy need
  let random_b32 = strpart(a:ulid_b32, 10)
  let randomlist = s:Base32cf.decoderaw(random_b32)

  let retval = {
        \ 'bytes'     : timelist + randomlist,
        \ 'timestamp' : timelist,
        \ 'random'    : randomlist,
        \ }

  return retval
endfunction

function! s:_bytes2uuid(bytes) abort
  let uuid = s:UUID.new()

  let uuid.bytes = a:bytes
  let uuid.endian  = 1 " big endian
  let uuid.variant = 8 " no care
  let uuid.version = 0

  call uuid.byte_encode()
  return uuid
endfunction

function! s:_uint8(n) abort
  return s:bitwise.and(a:n, 0xFF)
endfunction

function! s:_throw(message) abort
  throw 'vital: ID.ULID: ' . a:message
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
