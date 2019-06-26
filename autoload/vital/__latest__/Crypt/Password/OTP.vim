" Utilities for HOTP/TOTP
" RFC 4226 - HOTP: An HMAC-Based One-Time Password Algorithm https://tools.ietf.org/html/rfc4226
" RFC 6238 - TOTP: Time-Based One-Time Password Algorithm https://tools.ietf.org/html/rfc6238

let s:save_cpo = &cpo
set cpo&vim

let s:DEFAULTS = {
      \ 'HOTP' : {
      \   'digit'   : 6,
      \   'algo'    : 'SHA1',
      \   'counter' : 8,
      \ },
      \ 'TOTP' : {
      \   'digit'   : 6,
      \   'algo'    : 'SHA1',
      \   'period'  : 30,
      \ },
      \}

function! s:_vital_created(module) abort
  let a:module.defaults = s:DEFAULTS
endfunction

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:bitwise  = s:V.import('Bitwise')
  let s:type     = s:V.import('Vim.Type')
  let s:int      = s:V.import('Vim.Type.Number')
  let s:HMAC     = s:V.import('Crypt.MAC.HMAC')
  let s:List     = s:V.import('Data.List')
  let s:DateTime = s:V.import('DateTime')
  let s:ByteArray = s:V.import('Data.List.Byte')
endfunction

function! s:_vital_depends() abort
  return ['Bitwise',
        \ 'Vim.Type',
        \ 'Vim.Type.Number',
        \ 'Crypt.MAC.HMAC',
        \ 'Data.List',
        \ 'DateTime',
        \ 'Data.List.Byte']
endfunction

function! s:hotp(key, counter, algo, digit) abort
  let hmac = s:HMAC.new(a:algo, a:key)
  if s:DEFAULTS.HOTP.counter == len(a:counter)
    let counter = copy(a:counter)
  elseif s:DEFAULTS.HOTP.counter > len(a:counter)
    let counter = s:List.new(s:DEFAULTS.HOTP.counter, {-> 0})
    for i in range(s:DEFAULTS.HOTP.counter)
      if 0 <= (i - (s:DEFAULTS.HOTP.counter - len(a:counter)))
        let counter[i] = a:counter[i - (s:DEFAULTS.HOTP.counter - len(a:counter))]
      endif
    endfor
  else
    call s:_throw(printf('counter size over:%d', len(a:counter)))
  endif

  let hmac_list =  hmac.calc(counter)

  let offset = s:bitwise.and(hmac_list[-1],0xf)
  let bincode = s:bitwise.and(s:_bytes2int32_be(hmac_list[offset:offset+3]), 0x7FFFFFFF)

  let modulo_base = float2nr(pow(10, a:digit))
  let hotp_value = bincode % modulo_base

  return printf('%0' . string(a:digit) . 'd', hotp_value)
endfunction

function! s:totp(key, period, algo, digit, ...) abort
  if a:0
    let typeval = type(a:1)
    if typeval == s:type.types.number
      let datetime = s:DateTime.from_unix_time(a:1)
    elseif typeval == s:type.types.dict && 'DateTime' == get(a:1,'class','')
      let datetime = a:1
    else
      call s:_throw('non-support extra datetime data (support only unix epoch int value or DateTime object)')
    endif
  endif
  if !exists('datetime')
    let datetime = s:DateTime.now()
  endif

  let now_sec = datetime.unix_time()
  let epoch_sec = 0

  if has('num64')
    let counter = s:_int642bytes_be(float2nr(floor((now_sec - epoch_sec) / a:period)))
  else
    let counter = s:_int322bytes_be(float2nr(floor((now_sec - epoch_sec) / a:period)))
  endif

  return s:hotp(a:key, counter, a:algo, a:digit)
endfunction

"---------------------------------------------------------------------
" misc

function! s:_uint8(n) abort
  " return s:bitwise.and(a:n, 0xFF)
  return s:int.uint8(a:n)
endfunction

function! s:_bytes2int32_be(bytes) abort
  " return  s:bitwise.or(s:bitwise.lshift(a:bytes[0], 24),
  "      \ s:bitwise.or(s:bitwise.lshift(a:bytes[1], 16),
  "      \ s:bitwise.or(s:bitwise.lshift(a:bytes[2], 8),
  "      \ a:bytes[3])))
  return s:ByteArray.to_int(a:bytes)
endfunction

function! s:_int322bytes_be(value) abort
  " return [s:_uint8(s:bitwise.rshift(a:value, 24)),
  "      \ s:_uint8(s:bitwise.rshift(a:value, 16)),
  "      \ s:_uint8(s:bitwise.rshift(a:value, 8)),
  "      \ s:_uint8(a:value)]
  return s:ByteArray.from_int(a:value, 32)
endfunction

function! s:_int642bytes_be(value) abort
  " return [s:_uint8(s:bitwise.rshift(a:value, 56)),
  "      \ s:_uint8(s:bitwise.rshift(a:value, 48)),
  "      \ s:_uint8(s:bitwise.rshift(a:value, 40)),
  "      \ s:_uint8(s:bitwise.rshift(a:value, 32)),
  "      \ s:_uint8(s:bitwise.rshift(a:value, 24)),
  "      \ s:_uint8(s:bitwise.rshift(a:value, 16)),
  "      \ s:_uint8(s:bitwise.rshift(a:value, 8)),
  "      \ s:_uint8(a:value)]
  return s:ByteArray.from_int(a:value, 64)
endfunction

function! s:_throw(message) abort
  throw 'vital: Crypt.Password.OTP: ' . a:message
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
