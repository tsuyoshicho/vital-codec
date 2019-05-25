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

function! s:generate() abort
  return s:Base32cf.encodebytes(s:_ulid())
endfunction

function! s:generateUUID() abort
  return s:_bytes2uuid(s:_ulid()).uuid_hex
endfunction

function! s:ULID2UUID(ulid) abort
  return s:_bytes2uuid(s:Base32cf.decoderaw(a:ulid))
endfunction

function! s:_ulid() abort
  let timelist   = s:List.new(6,  {-> 0})
  let randomlist = s:List.new(10, {-> 0})

  " localtime is Unix epoch second timestanp, need msec; generate x1000
  let now = s:BigNum.mul(localtime(), 1000)

  " 48bit timestamp
  let timelist_mod = s:List.new(6, {-> now}) " index is No. x byte
  let timelist_div = s:List.new(6, {-> now}) " index is remain 6-x byte(cut x byte) block, 0 is now
  let [timelist_div[1], timelist_mod[5]] = s:BigNum.div_mod(timelist_div[0], 0x100)
  let [timelist_div[2], timelist_mod[4]] = s:BigNum.div_mod(timelist_div[1], 0x100)
  let [timelist_div[3], timelist_mod[3]] = s:BigNum.div_mod(timelist_div[2], 0x100)
  let [timelist_div[4], timelist_mod[2]] = s:BigNum.div_mod(timelist_div[3], 0x100)
  let [timelist_div[5], timelist_mod[1]] = s:BigNum.div_mod(timelist_div[4], 0x100)
  let                   timelist_mod[0]  = s:BigNum.mod(    timelist_div[5], 0x100)

  for i in range(6)
    let timelist[i] = str2nr(s:BigNum.to_string(timelist_mod[i]), 10)
  endfor

  " 80bit random (8bit = 1byte) x 10
  let r = s:Random.new()
  call r.seed(s:Random.next())
  for i in range(10)
    let randomlist[i] = r.range(256)
  endfor

  return timelist + randomlist
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

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
