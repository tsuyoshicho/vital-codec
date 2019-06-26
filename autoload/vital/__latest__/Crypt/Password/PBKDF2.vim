" Utilities for PBKDF2
" RFC 2898 - PKCS #5: Password-Based Cryptography Specification Version 2.0 https://tools.ietf.org/html/rfc2898

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V         = a:V
  let s:bitwise   = s:V.import('Bitwise')
  let s:type      = s:V.import('Vim.Type')
  let s:int       = s:V.import('Vim.Type.Number')
  let s:HMAC      = s:V.import('Crypt.MAC.HMAC')
  let s:ByteArray = s:V.import('Data.List.Byte')
endfunction

function! s:_vital_depends() abort
  return ['Bitwise',
        \ 'Vim.Type',
        \ 'Vim.Type.Number',
        \ 'Crypt.MAC.HMAC',
        \ 'Data.List.Byte']
endfunction

function! s:pbkdf2(password, salt, iteration, derivedKeyLength, algo) abort
  " password
  let typeval = type(a:password)
  if typeval == s:type.types.string
    let password = s:ByteArray.from_string(a:password)
  elseif typeval == s:type.types.list
    let password = a:password
  else
    call s:_throw('non-support password type (suport only string or bytes-list)')
  endif
  unlet typeval

  " salt
  let typeval = type(a:salt)
  if typeval == s:type.types.string
    let salt = s:ByteArray.from_string(a:salt)
  elseif typeval == s:type.types.list
    let salt = a:salt
  else
    call s:_throw('non-support salt type (suport only string or bytes-list)')
  endif
  unlet typeval

  let derivedKeyLen = a:derivedKeyLength
  let hashLen = a:algo.hash_length / 8 " octet

  " float2nr(pow(2, 32)) - 1) = 0xffffffff
  if has('num64') && (derivedKeyLen > (0xffffffff * hashLen))
    call s:_throw('derived key too long')
  endif
  let derivedKey = []

  let l = float2nr(ceil((derivedKeyLen * 1.0) / hashLen))
  let lastBlockOctet = derivedKeyLen - ((l - 1) * hashLen)

  for i in range(1,l)
    " calc U_1
    let u = s:HMAC.new(a:algo, password).calc(salt[:] + s:_int2bytes_be(32, s:_uint32(i)))
    let t = u[:]

    for j in range(2, a:iteration)
      let u = s:HMAC.new(a:algo, password).calc(u)
      call map(t, { i, v -> s:bitwise.xor(v, u[i])})
    endfor

    " fill to derivedKey
    if i != l
      let derivedKey += t[:]
    else
      let derivedKey += t[: (lastBlockOctet - 1)]
    endif
  endfor

  return derivedKey
endfunction

function! s:_int2bytes_be(bits, int) abort
  return s:ByteArray.from_int(a:int, a:bits)
endfunction

function! s:_uint32(n) abort
  return s:int.uint32(a:n)
endfunction

function! s:_throw(message) abort
  throw 'vital: Crypt.Password.PBKDF2: ' . a:message
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
