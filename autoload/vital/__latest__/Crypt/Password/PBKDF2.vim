" Utilities for PBKDF2
" RFC 2898 - PKCS #5: Password-Based Cryptography Specification Version 2.0 https://tools.ietf.org/html/rfc2898

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V         = a:V
  let s:Bitwise   = s:V.import('Bitwise')
  let s:Type      = s:V.import('Vim.Type')
  let s:HMAC      = s:V.import('Crypt.MAC.HMAC')
  let s:ByteArray = s:V.import('Data.List.Byte')
endfunction

function! s:_vital_depends() abort
  return ['Bitwise',
        \ 'Vim.Type',
        \ 'Crypt.MAC.HMAC',
        \ 'Data.List.Byte']
endfunction

function! s:pbkdf2(password, salt, iteration, derivedKeyLength, algo) abort
  " password
  let password = a:password
  let typeval = type(a:password)
  if typeval == s:Type.types.string
    let password = s:ByteArray.from_string(a:password)
  elseif typeval == s:Type.types.list
    " already set
  else
    call s:_throw('non-support password type (support only string or bytes-list)')
  endif
  unlet typeval

  " salt
  let salt = a:salt
  let typeval = type(a:salt)
  if typeval == s:Type.types.string
    let salt = s:ByteArray.from_string(a:salt)
  elseif typeval == s:Type.types.list
    " already set
  else
    call s:_throw('non-support salt type (support only string or bytes-list)')
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
    let u = s:HMAC.new(a:algo, password).calc(salt[:] + s:ByteArray.from_int(s:Bitwise.uint32(i), 32))
    let t = u[:]

    for j in range(2, a:iteration)
      let u = s:HMAC.new(a:algo, password).calc(u)
      call map(t, { i, v -> s:Bitwise.xor(v, u[i])})
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

function! s:_throw(message) abort
  throw 'vital: Crypt.Password.PBKDF2: ' . a:message
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
