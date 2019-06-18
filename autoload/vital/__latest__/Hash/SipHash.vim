" Utilities for SipHash.
" https://131002.net/siphash/
" currently need num64
" currently length 64
" currently round 2-4

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_created(module) abort
  let a:module.name = 'SipHash'
  let a:module.hash_length = s:hash_size
endfunction

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:bitwise = s:V.import('Bitwise')
  let s:ByteList = s:V.import('Data.List.Byte')
endfunction

function! s:_vital_depends() abort
  return ['Bitwise', 'Data.List.Byte']
endfunction

function! s:sum(data) abort
  let bytes = s:ByteList.from_string(a:data)
  return s:sum_raw(bytes)
endfunction

function! s:sum_raw(bytes) abort
  return s:ByteList.to_hexstring(s:digest_raw(a:bytes))
endfunction

function! s:digest(data) abort
  let bytes = s:ByteList.from_string(a:data)
  return s:digest_raw(bytes)
endfunction

function! s:digest_raw(bytes) abort
  let siphash = deepcopy(s:siphash_state, 1)
  return siphash.hash(a:bytes, s:key, s:hash_size)
endfunction

function! s:seed(key) abort
  if len(a:key) != 16
    " throw e
  endif
  let s:key = a:key
endfunction

" based on
" https://github.com/veorq/SipHash/blob/master/siphash.c
" https://github.com/vcatechnology/siphashsum/blob/master/siphash.h

let s:siphash_state = {
      \ 'v'   : repeat([0], 4),
      \ 'k'   : repeat([0], 2),
      \}

" default: key setup
let s:key = range(16)
" default: hash size 64bit
let s:hash_size = 64
" default: SipHash-2-4
let s:cROUNDS = 2
let s:dROUNDS = 4

function! s:_int64rotator(word, bits) abort
  return s:bitwise.or(
        \ s:bitwise.lshift(a:word, a:bits),
        \ s:bitwise.rshift(a:word, 64 - a:bits)
        \)
endfunction

function! s:siphash_state.round() abort
  let self.v[0] += self.v[1]                          " v0 += v1;
  let self.v[1] = s:_int64rotator(self.v[1], 13)      " v1 = ROTL(v1, 13);
  let self.v[1] = s:bitwise.xor(self.v[1], self.v[0]) " v1 ^= v0;
  let self.v[0] = s:_int64rotator(self.v[0], 32)      " v0 = ROTL(v0, 32);

  let self.v[2] += self.v[3]                          " v2 += v3;
  let self.v[3] = s:_int64rotator(self.v[3], 16)      " v3 = ROTL(v3, 16);
  let self.v[3] = s:bitwise.xor(self.v[3], self.v[2]) " v3 ^= v2;

  let self.v[0] += self.v[3]                          " v0 += v3;
  let self.v[3] = s:_int64rotator(self.v[3], 21)      " v3 = ROTL(v3, 21);
  let self.v[3] = s:bitwise.xor(self.v[3], self.v[0]) " v3 ^= v0;

  let self.v[2] += self.v[1]                          " v2 += v1;
  let self.v[1] = s:_int64rotator(self.v[1], 17)      " v1 = ROTL(v1, 17);
  let self.v[1] = s:bitwise.xor(self.v[1], self.v[2]) " v1 ^= v2;
  let self.v[2] = s:_int64rotator(self.v[2], 32)      " v2 = ROTL(v2, 32);
endfunction

" data   byte-list
" key    byte-list 16byte
" length hash bitlength (64 or 128)
function! s:siphash_state.hash(data, key, length) abort
  if a:length == 64 || a:length == 128
    " legal
  else
    " throw e
  endif
  let data = copy(a:data)
  let outputByteLen = a:length / 8

  let self.v[0] = 0x736f6d6570736575
  let self.v[1] = 0x646f72616e646f6d
  let self.v[2] = 0x6c7967656e657261
  let self.v[3] = 0x7465646279746573

  let self.k[0] = s:_bytes2int64(a:key[0:7])
  let self.k[1] = s:_bytes2int64(a:key[8:15])

  let leftshift = s:bitwise.and(len(data), 7)
  let blockshift = s:bitwise.lshift(len(data), 56)

  " initial xor
  let self.v[3] = s:bitwise.xor(self.v[3], self.k[1]) " v3 ^= k1;
  let self.v[2] = s:bitwise.xor(self.v[2], self.k[0]) " v2 ^= k0;
  let self.v[1] = s:bitwise.xor(self.v[1], self.k[1]) " v1 ^= k1;
  let self.v[0] = s:bitwise.xor(self.v[0], self.k[0]) " v0 ^= k0;

  if (outputByteLen == 16)
    let self.v[1] = s:bitwise.xor(self.v[1], 0xee) " v1 ^= 0xee;
  endif

  for i in range(0, len(data), 8)
    let m = s:_bytes2int64(data[i:i+8])
    let self.v[3] = s:bitwise.xor(self.v[3], m) " v3 ^= m;

    for j in range(s:cROUNDS)
      call self.round()
    endfor

    let self.v[0] = s:bitwise.xor(self.v[0], m) " v0 ^= m;
  endfor

  if 0 != leftshift
    if leftshift > 6
      let blockshift = s:bitwise.or(blockshift, s:bitwise.lshift(data[6], 48)) " b |= ((uint64_t)in[6]) << 48;
    endif
    if leftshift > 5
      let blockshift = s:bitwise.or(blockshift, s:bitwise.lshift(data[5], 40)) " b |= ((uint64_t)in[5]) << 40;
    endif
    if leftshift > 4
      let blockshift = s:bitwise.or(blockshift, s:bitwise.lshift(data[4], 32)) " b |= ((uint64_t)in[4]) << 32;
    endif
    if leftshift > 3
      let blockshift = s:bitwise.or(blockshift, s:bitwise.lshift(data[3], 24)) " b |= ((uint64_t)in[3]) << 24;
    endif
    if leftshift > 2
      let blockshift = s:bitwise.or(blockshift, s:bitwise.lshift(data[2], 16)) " b |= ((uint64_t)in[2]) << 16;
    endif
    if leftshift > 1
      let blockshift = s:bitwise.or(blockshift, s:bitwise.lshift(data[1],  8)) " b |= ((uint64_t)in[1]) << 8;
    endif
    if leftshift > 0
      let blockshift = s:bitwise.or(blockshift,                  data[0]     ) " b |= ((uint64_t)in[0]);
    endif
  endif

  let self.v[3] = s:bitwise.xor(self.v[3], blockshift) " v3 ^= b;

  for i in range(s:cROUNDS)
    call self.round()
  endfor

  let self.v[0] = s:bitwise.xor(self.v[0], blockshift) " v0 ^= b;

  if (outputByteLen == 16)
    let self.v[2] = s:bitwise.xor(self.v[2], 0xee) " v2 ^= 0xee;
  else
    let self.v[2] = s:bitwise.xor(self.v[2], 0xff) " v2 ^= 0xff;
  endif

  for i in range(s:dROUNDS)
    call self.round()
  endfor

  " b = v0 ^ v1 ^ v2 ^ v3;
  let blockshift = s:bitwise.xor(
        \ s:bitwise.xor(self.v[0], self.v[1]),
        \ s:bitwise.xor(self.v[2], self.v[3])
        \)

  let output = s:_int642bytes(blockshift)

  if (outputByteLen == 8)
    return output;
  endif

  let self.v[1] = s:bitwise.xor(self.v[1], 0xdd) " v1 ^= 0xdd;

  for i in range(s:dROUNDS)
    call self.round()
  endfor

  " b = v0 ^ v1 ^ v2 ^ v3;
  let blockshift = s:bitwise.xor(
        \ s:bitwise.xor(self.v[0], self.v[1]),
        \ s:bitwise.xor(self.v[2], self.v[3])
        \)

  let output = output + s:_int642bytes(blockshift)

  return output;
endfunction

"---------------------------------------------------------------------
" misc

function! s:_bytes2int64(bytes) abort
  return  s:bitwise.or(s:bitwise.lshift(a:bytes[7], 56),
        \ s:bitwise.or(s:bitwise.lshift(a:bytes[6], 48),
        \ s:bitwise.or(s:bitwise.lshift(a:bytes[5], 40),
        \ s:bitwise.or(s:bitwise.lshift(a:bytes[4], 32),
        \ s:bitwise.or(s:bitwise.lshift(a:bytes[3], 24),
        \ s:bitwise.or(s:bitwise.lshift(a:bytes[2], 16),
        \ s:bitwise.or(s:bitwise.lshift(a:bytes[1], 8),
        \ a:bytes[0])))))))
endfunction

function! s:_int642bytes(value) abort
  return [s:_uint8(a:value),
        \ s:_uint8(s:bitwise.rshift(a:value, 8)),
        \ s:_uint8(s:bitwise.rshift(a:value, 16)),
        \ s:_uint8(s:bitwise.rshift(a:value, 24)),
        \ s:_uint8(s:bitwise.rshift(a:value, 32)),
        \ s:_uint8(s:bitwise.rshift(a:value, 40)),
        \ s:_uint8(s:bitwise.rshift(a:value, 48)),
        \ s:_uint8(s:bitwise.rshift(a:value, 56))]
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
