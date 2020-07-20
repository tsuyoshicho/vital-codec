" Utilities for CRC-24. Radix64 type
" RFC 4880 http://tools.ietf.org/html/rfc4880.html

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:B         = a:V.import('Bitwise')
  let s:L         = a:V.import('Data.List')
  let s:ByteArray = a:V.import('Data.List.Byte')
endfunction

function! s:_vital_depends() abort
  return ['Data.List.Byte', 'Data.List', 'Bitwise']
endfunction

function! s:calculatestr(data) abort
  return s:calculate(s:ByteArray.from_string(a:data))
endfunction

function! s:calculatebin(data) abort
  return s:calculate(s:ByteArray.from_hexstring(a:data))
endfunction

function! s:calculate(data) abort
  return s:_crc24radix64(a:data)
endfunction

function! s:validatestr(data, sum) abort
  return s:validate(s:ByteArray.from_string(a:data), a:sum)
endfunction

function! s:validatebin(data, sum) abort
  return s:validate(s:ByteArray.from_hexstring(a:data), a:sum)
endfunction

function! s:validate(data, sum) abort
  return (s:calculate(a:data) == a:sum) ? v:true : v:false
endfunction

let s:CRC24_RADIX64_INIT = [0x00, 0xB7, 0x04, 0xCE] " CRC24_INIT 0xB704CEL
let s:CRC24_RADIX64_POLY = [0x01, 0x86, 0x4C, 0xFB] " CRC24_POLY 0x1864CFBL
lockvar s:CRC24_RADIX64_INIT s:CRC24_RADIX64_POLY

function! s:_crc24radix64(data) abort
  return s:_crc24(a:data, s:CRC24_RADIX64_INIT, s:CRC24_RADIX64_POLY)
endfunction

" crc function
function! s:_crc24(data, init, poly) abort
  let octet = copy(a:data)
  let max_len = len(octet)
  let data_len = max_len

  let crc = copy(a:init)
  let i = 0

  while data_len
    let crc[1] = s:B.xor(crc[1], octet[max_len - data_len])
    let data_len -= 1

    for i in range(8)
      let shifted = s:L.map(crc, { v -> s:B.lshift(v, 1) })
      let crc[3] = s:B.and(shifted[3], 0xff)
      let crc[2] = s:B.or(s:B.and(shifted[2], 0xff), s:B.and(shifted[3], 0x100) != 0 ? 1 : 0)
      let crc[1] = s:B.or(s:B.and(shifted[1], 0xff), s:B.and(shifted[2], 0x100) != 0 ? 1 : 0)
      let crc[0] = s:B.or(s:B.and(shifted[0], 0xff), s:B.and(shifted[1], 0x100) != 0 ? 1 : 0)
      if crc[0] != 0
        let crc = s:L.map(
          \ s:L.zip(crc, a:poly),
          \{ v -> s:B.xor(v[0], v[1]) })
      endif
    endfor
  endwhile

  return crc[1:3]
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
