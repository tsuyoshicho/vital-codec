" Utilities for SipHash.
" https://131002.net/siphash/
" currently need num64
" currently length 64
" currently round 2-4

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_created(module) abort
  let a:module.name = s:DEFAULT.name
  let a:module.hash_length = s:DEFAULT.hash_length
endfunction

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:bitwise = s:V.import('Bitwise')
  let s:int     = s:V.import('Vim.Type.Number')
  let s:ByteArray = s:V.import('Data.List.Byte')
endfunction

function! s:_vital_depends() abort
  return ['Bitwise', 'Vim.Type.Number', 'Data.List.Byte']
endfunction

let s:DEFAULT = {
      \ 'name' : 'SipHash',
      \ 'hash_length' : 64,
      \ 'rounds' : {
      \   'c' : 2,
      \   'd' : 4,
      \  },
      \}

" hash length is bit length
" rounds c is block rounds count
" rounds d is finalize rounds count

function! s:_common_hash() abort
  if !exists('s:common_hash')
    let s:common_hash = s:new(s:DEFAULT.hash_length, s:DEFAULT.rounds.c, s:DEFAULT.rounds.d)
  endif
  return s:common_hash
endfunction

let s:OBJECT = extend({
      \  'state' : {},
      \ },
      \ s:DEFAULT, 'keep')

function! s:new(...) abort
  let obj = deepcopy(s:OBJECT)
  if a:0 == 0
    " default
  elseif a:0 == 1
    let obj.hash_length = a:1
  elseif a:0 == 3
    let obj.hash_length = a:1
    let obj.rounds.c = a:2
    let obj.rounds.d = a:3
  else
    " throw e
  endif
  if obj.hash_length == 64 || obj.hash_length == 128
    " legal
  else
    " throw e
  endif
  let obj.state = deepcopy(s:siphash_state)
  return obj
endfunction

function! s:setkey(key) abort
  call s:_common_hash().state.setkey(a:key)
endfunction

" compatible interface
function! s:sum(data) abort
  return s:_common_hash().sum(a:data)
endfunction

function! s:sum_raw(bytes) abort
  return s:_common_hash().sum_raw(a:bytes)
endfunction

function! s:digest(data) abort
  return s:_common_hash().digest(a:data)
endfunction

function! s:digest_raw(bytes) abort
  return s:_common_hash().digest_raw(a:bytes)
endfunction

" object interface
function! s:OBJECT.sum(data) abort
  let bytes = s:ByteArray.from_string(a:data)
  return self.sum_raw(bytes)
endfunction

function! s:OBJECT.sum_raw(bytes) abort
  return s:ByteArray.to_hexstring(self.digest_raw(a:bytes))
endfunction

function! s:OBJECT.digest(data) abort
  let bytes = s:ByteArray.from_string(a:data)
  return self.digest_raw(bytes)
endfunction

function! s:OBJECT.digest_raw(bytes) abort
  let self.state.hash_length = self.hash_length
  let self.state.rounds.c = self.rounds.c
  let self.state.rounds.d = self.rounds.d
  return self.state.hash(a:bytes)
endfunction

" based on
" https://github.com/veorq/SipHash/blob/master/siphash.c
" https://github.com/vcatechnology/siphashsum/blob/master/siphash.h

let s:siphash_state = {
      \ 'key' : range(16),
      \ 'hash_length' : 0,
      \ 'rounds' : {
      \   'c' : 0,
      \   'd' : 0,
      \  },
      \ 'v'   : repeat([0z00], 4),
      \ 'k'   : repeat([0z00], 2),
      \}

function! s:siphash_state.setkey(key) abort
  if len(a:key) != 16
    " throw e
  endif
  let self.key = copy(a:key)
endfunction

function! s:siphash_state.round() abort
  let self.v[0] = s:_blob64bit_add(self.v[0], self.v[1])  " v0 += v1;
  let self.v[1] = s:_blob64bit_rotl(self.v[1], 13)        " v1 = ROTL(v1, 13);
  let self.v[1] = s:_blob64bit_xor(self.v[1], self.v[0])  " v1 ^= v0;
  let self.v[0] = s:_blob64bit_rotl(self.v[0], 32)        " v0 = ROTL(v0, 32);

  let self.v[2] = s:_blob64bit_add(self.v[2], self.v[3])  " v2 += v3;
  let self.v[3] = s:_blob64bit_rotl(self.v[3], 16)        " v3 = ROTL(v3, 16);
  let self.v[3] = s:_blob64bit_xor(self.v[3], self.v[2])  " v3 ^= v2;

  let self.v[0] = s:_blob64bit_add(self.v[0], self.v[3])  " v0 += v3;
  let self.v[3] = s:_blob64bit_rotl(self.v[3], 21)        " v3 = ROTL(v3, 21);
  let self.v[3] = s:_blob64bit_xor(self.v[3], self.v[0])  " v3 ^= v0;

  let self.v[2] = s:_blob64bit_add(self.v[2], self.v[1])  " v2 += v1;
  let self.v[1] = s:_blob64bit_rotl(self.v[1], 17)        " v1 = ROTL(v1, 17);
  let self.v[1] = s:_blob64bit_xor(self.v[1], self.v[2])  " v1 ^= v2;
  let self.v[2] = s:_blob64bit_rotl(self.v[2], 32)        " v2 = ROTL(v2, 32);
endfunction

" trace disable
function! s:siphash_state.trace(len) abort
endfunction

" " trace enable
" function! s:siphash_state.trace(len) abort
"   for i in range(len(self.v))
"     echo '(' . string(a:len) . ')' . 'v' . i .':' . string(self.v[i])
"   endfor
" endfunction

" data   byte-list
" key    byte-list 16byte
" length hash bitlength (64 or 128)
function! s:siphash_state.hash(data) abort
  let data = copy(a:data)
  let outputByteLen = self.hash_length / 8

  let self.v[0] = 0z736f6d6570736575
  let self.v[1] = 0z646f72616e646f6d
  let self.v[2] = 0z6c7967656e657261
  let self.v[3] = 0z7465646279746573

  let self.k[0] = s:ByteArray.to_blob(self.key[0 :  7])
  let self.k[1] = s:ByteArray.to_blob(self.key[8 : 15])

  let leftshift = s:bitwise.and(len(data), 7)
  let blockshift = s:_blob64bit_new(s:bitwise.lshift(len(data), 56))

  " initial xor
  let self.v[3] = s:_blob64bit_xor(self.v[3], self.k[1]) " v3 ^= k1;
  let self.v[2] = s:_blob64bit_xor(self.v[2], self.k[0]) " v2 ^= k0;
  let self.v[1] = s:_blob64bit_xor(self.v[1], self.k[1]) " v1 ^= k1;
  let self.v[0] = s:_blob64bit_xor(self.v[0], self.k[0]) " v0 ^= k0;

  if (outputByteLen == 16)
    let self.v[1] = s:_blob64bit_xor(self.v[1], s:_blob64bit_new(0xee)) " v1 ^= 0xee;
  endif

  if len(data) >= 8
    for i in range(0, len(data) - 7, 8)
      let m = s:ByteArray.to_blob(data[i : i+7]))
      let self.v[3] = s:_blob64bit_xor(self.v[3], m) " v3 ^= m;

      " debug
      cal self.trace(len(data))

      for j in range(self.rounds.c)
        call self.round()
      endfor

      let self.v[0] = s:_blob64bit_xor(self.v[0], m) " v0 ^= m;
    endfor
  endif

  if 0 != leftshift
    if leftshift > 6
      let blockshift = s:_blob64bit_or(blockshift, s:_blob64bit_new(s:bitwise.lshift(data[6], 48))) " b |= ((uint64_t)in[6]) << 48;
    endif
    if leftshift > 5
      let blockshift = s:_blob64bit_or(blockshift, s:_blob64bit_new(s:bitwise.lshift(data[5], 40))) " b |= ((uint64_t)in[5]) << 40;
    endif
    if leftshift > 4
      let blockshift = s:_blob64bit_or(blockshift, s:_blob64bit_new(s:bitwise.lshift(data[4], 32))) " b |= ((uint64_t)in[4]) << 32;
    endif
    if leftshift > 3
      let blockshift = s:_blob64bit_or(blockshift, s:_blob64bit_new(s:bitwise.lshift(data[3], 24))) " b |= ((uint64_t)in[3]) << 24;
    endif
    if leftshift > 2
      let blockshift = s:_blob64bit_or(blockshift, s:_blob64bit_new(s:bitwise.lshift(data[2], 16))) " b |= ((uint64_t)in[2]) << 16;
    endif
    if leftshift > 1
      let blockshift = s:_blob64bit_or(blockshift, s:_blob64bit_new(s:bitwise.lshift(data[1],  8))) " b |= ((uint64_t)in[1]) << 8;
    endif
    if leftshift > 0
      let blockshift = s:_blob64bit_or(blockshift, s:_blob64bit_new(                 data[0],    )) " b |= ((uint64_t)in[0]);
    endif
  endif

  let self.v[3] = s:_blob64bit_xor(self.v[3], blockshift) " v3 ^= b;

  " debug
  cal self.trace(len(data))

  for i in range(self.rounds.c)
    call self.round()
  endfor

  let self.v[0] = s:_blob64bit_xor(self.v[0], blockshift) " v0 ^= b;

  if (outputByteLen == 16)
    let self.v[2] = s:_blob64bit_xor(self.v[2], s:_blob64bit_new(0xee)) " v2 ^= 0xee;
  else
    let self.v[2] = s:_blob64bit_xor(self.v[2], s:_blob64bit_new(0xff)) " v2 ^= 0xff;
  endif

  " debug
  cal self.trace(len(data))

  for i in range(self.rounds.d)
    call self.round()
  endfor

  " b = v0 ^ v1 ^ v2 ^ v3;
  let blockshift = s:_blob64bit_xor(
        \ s:_blob64bit_xor(self.v[0], self.v[1]),
        \ s:_blob64bit_xor(self.v[2], self.v[3])
        \)

  let output = s:ByteArray.endian_convert(s:_blob64bit_to_list_le(blockshift))

  if (outputByteLen == 8)
    return output
  endif

  let self.v[1] = s:bitwise.xor(self.v[1], 0xdd) " v1 ^= 0xdd;

  " debug
  cal self.trace(len(data))

  for i in range(self.rounds.d)
    call self.round()
  endfor

  " b = v0 ^ v1 ^ v2 ^ v3;
  let blockshift = s:_blob64bit_xor(
        \ s:_blob64bit_xor(self.v[0], self.v[1]),
        \ s:_blob64bit_xor(self.v[2], self.v[3])
        \)

  let output = output + s:ByteArray.endian_convert(s:_blob64bit_to_list_le(blockshift))

  return output
endfunction

" inner function

function! s:_blob64bit_new(...) abort
  let inital = 0
  if a:0
    let inital = a:1
  endif
  let retval = repeat([0],8) " 8 byte 64bit length
  for i in range(8)
    let retval[i] = s:int.uint8(s:bitwise.rshift(inital, 64 - (8 * (i + 1))))
  endfor
  return s:ByteArray.to_blob(retval)
endfunction

function! s:_blob64bit_or(x, y) abort
  let retval = s:_blob64bit_new()
  for i in range(8)
    let retval[i] = s:bitwise.or(a:x[i], a:y[i])
  endfor
  return retval
endfunction

function! s:_blob64bit_xor(x, y) abort
  let retval = s:_blob64bit_new()
  for i in range(8)
    let retval[i] = s:bitwise.xor(a:x[i], a:y[i])
  endfor
  return retval
endfunction

function! s:_blob64bit_add(x, y) abort
  let retval = s:_blob64bit_new()
  let carry = 0
  for i in range(7, 0, -1)
    let retval[i] = s:int.uint8(a:x[i] + a:y[i] + carry)
    let carry = (a:x[i] + a:y[i]) / 255
  endfor
  return retval
endfunction

function! s:_blob64bit_rotl(x, bits) abort
  let retval = s:_blob64bit_new()
  let blocknum = a:bits / 8
  let shift    = a:bits % 8
  for i in range(8)
    let targetindex = (i + blocknum) % 8
    let previndex = (i + 8 - 1) % 8
    let retval[targetindex] = s:int.uint8(s:bitwise.or(s:bitwise.lshift(a:x[i], shift),
                                                     \ s:bitwise.rshift(a:x[previndex], 8 - shift)))
  endfor
  return retval
endfunction

function! s:_blob64bit_to_list_le(x) abort
  let retval = repeat([0],8) " 8 byte 64bit length
  for i in range(8)
    let retval[i] = a:x[i]
  endfor
  return retval
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
