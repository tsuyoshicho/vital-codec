" Poly1305
" RFC 7539 - ChaCha20 and Poly1305 for IETF Protocols https://tools.ietf.org/html/rfc7539
" based on https://github.com/calvinmetcalf/chacha20poly1305

function! s:_vital_loaded(V) abort
  let s:V = a:V

  let s:Bitwise   = s:V.import('Bitwise')
  let s:Blob      = s:V.import('Vim.Type.Blob')
  let s:List      = s:V.import('Data.List')
  let s:ByteArray = s:V.import('Data.List.Byte')
endfunction

function! s:_vital_depends() abort
  return ['Bitwise', 'Data.List', 'Data.List.Byte', 'Vim.Type.Blob']
endfunction

let s:Poly1305 = {
      \   '__type__': 'Poly1305',
      \   '_dict': {
      \     'crypt' : v:null,
      \     'key'   : v:null,
      \   }
      \ }

" s:new() creates a new instance of Poly1305 object.
" @param {crypt object},{key string|bytes list}
function! s:new(...) abort
  if a:0 > 2
    call s:_throw(printf('.new() expected at most 2 arguments, got %d', a:0))
  endif
  let poly1305 = deepcopy(s:Poly1305)
  if a:0 is# 1
    call call(poly1305.crypt, [a:1], poly1305)
  elseif a:0 is# 2
    call call(poly1305.crypt, [a:1], poly1305)
    call call(poly1305.key,   [a:2], poly1305)
  endif
  return poly1305
endfunction

function! s:Poly1305.key(key) abort
  if type(a:key) is# type([])
    let self._dict['key'] = a:key
  elseif type(a:key) is# type('')
    let self._dict['key'] = s:ByteArray.from_string(a:key)
  else
    call s:_throw('given argument is not key data')
  endif
endfunction

function! s:Poly1305.crypt(obj) abort
  if type(a:obj) is# type({})
        \ && has_key(a:obj,'encrypt')
        \ && type(a:obj.encrypt) is# type(function('tr'))
    let self._dict['crypt'] = a: obj
  else
    call s:_throw('given argument is not Crypt API object')
  endif
endfunction

let poly1305_state = {
      \ 'r'        : repeat([0],5),  " uint32_t r0,r1,r2,r3,r4; r0-r4
      \ 's'        : repeat([0],5),  " uint32_t s1,s2,s3,s4;    s1-s4 not use 0
      \ 'h'        : repeat([0],5),  " uint32_t h0,h1,h2,h3,h4; r0-r4
      \ 'buf'      : repeat([0],16), " unsigned char buf[16];
      \ 'buf_used' : 0,              " unsigned int buf_used;
      \ 'key'      : repeat([0],16), " unsigned char key[16];
      \}

" NOTE: shift is not size limitation / blob size incrase? it is problem!!
function! poly1305_state.init(key) abort
  let t = repeat([0],4)

  let t[0] = s:ByteArray.to_blob(a:key[ 0: 3]) " t0 = U8TO32_LE(key+0);
  let t[1] = s:ByteArray.to_blob(a:key[ 4: 7]) " t1 = U8TO32_LE(key+4);
  let t[2] = s:ByteArray.to_blob(a:key[ 8:11]) " t2 = U8TO32_LE(key+8);
  let t[3] = s:ByteArray.to_blob(a:key[12:15]) " t3 = U8TO32_LE(key+12);

  " precompute multipliers

  " state->r0 = t0 & 0x3ffffff; t0 >>= 26; t0 |= t1 << 6;
  let self.r[0] = s:Blob.and(t[0], 0z3ffffff)
  let t[0] = s:Blob.rshift(t[0], 26)
  let t[0] = s:Blob.or(t[0], s:Blob.lshift(t[1], 6))

  " state->r1 = t0 & 0x3ffff03; t1 >>= 20; t1 |= t2 << 12;
  let self.r[1] = s:Blob.and(t[0], 0z3ffff03)
  let t[1] = s:Blob.rshift(t[1], 20)
  let t[1] = s:Blob.or(t[1], s:Blob.lshift(t[2],12))

  " state->r2 = t1 & 0x3ffc0ff; t2 >>= 14; t2 |= t3 << 18;
  let self.r[2] = s:Blob.and(t[1], 0z3ffc0ff)
  let t[2] = s:Blob.rshift(t[2], 14)
  let t[2] = s:Blob.or(t[2], s:Blob.lshift(t[3],18))

  " state->r3 = t2 & 0x3f03fff; t3 >>= 8;
  let self.r[3] = s:Blob.and(t[2], 0z3f03fff)
  let t[3] = s:Blob.rshift(t[3],  8)

  " state->r4 = t3 & 0x00fffff;
  let self.r[4] = s:Blob.and(t[3], 0z00fffff)

  let self.s[1] = s:Blob.uint32(s:Blob.mul(self.r[1], 5)) " state->s1 = state->r1 * 5;
  let self.s[2] = s:Blob.uint32(s:Blob.mul(self.r[2], 5)) " state->s2 = state->r2 * 5;
  let self.s[3] = s:Blob.uint32(s:Blob.mul(self.r[3], 5)) " state->s3 = state->r3 * 5;
  let self.s[4] = s:Blob.uint32(s:Blob.mul(self.r[4], 5)) " state->s4 = state->r4 * 5;

  " init state
  let self.h[0] = s:Blob.uint32(0) " state->h0 = 0;
  let self.h[1] = s:Blob.uint32(0) " state->h1 = 0;
  let self.h[2] = s:Blob.uint32(0) " state->h2 = 0;
  let self.h[3] = s:Blob.uint32(0) " state->h3 = 0;
  let self.h[4] = s:Blob.uint32(0) " state->h4 = 0;

  let self.buf_used = 0                          " state->buf_used = 0;
  let self.key = s:ByteArray.to_blob(a:key[16:]) " memcpy(state->key, key + 16, sizeof(state->key));
endfunction

function! poly1305_state.update(in) abort
  let in = a:in
  let in_len = len(in)

  if self.buf_used
    let todo = 16 - self.buf_used          " unsigned int todo = 16 - state->buf_used;
    if (todo > in_len)                     "   if (todo > in_len)
      todo = in_len;                       "       todo = in_len;
    endif

    "   for (i = 0; i < todo; i++)
    "       state->buf[state->buf_used + i] = in[i];
    self.buf[self.buf_used : ] = in[0:todo]

    let self.buf_used += todo        "   state->buf_used += todo;
    let in_len        -= todo        "   in_len -= todo;
    let in             = in[todo:]   "   in += todo;

    if self.buf_used == 16            "   if (state->buf_used == 16) {
      call self._update(self.buf, 16) "     update(state, state->buf, 16);
      let self.buf_used = 0;          "     state->buf_used = 0;
    endif                             "   }
  endif

  if in_len >= 16                                  "  if (in_len >= 16) {
    let todo = s:Bitwise.and(in_len, 0xfffffff0)   "      size_t todo = in_len & ~0xf;
    call self._update(in, todo)                    "      update(state, in, todo);
    let in             = in[todo:]                 "      in += todo;
    let in_len = s:Bitwise.and(in_len, 0x0000000f) "      in_len &= 0xf;
  endif                                            "  }

  if in_len
    "  if (in_len) {
    "      for (i = 0; i < in_len; i++)
    "          state->buf[i] = in[i];
    "      state->buf_used = in_len;
    "  }
    let self.buf[:] = in[:]
    let self.buf_used = in_len
  endif
endfunction

function! poly1305_state._update(in, size) abort
  let in = a:in
  let size = a:size

  let t_x   = repeat([0],4)   " uint32_t t0,t1,t2,t3;
  let t_buf = repeat([0],5)   " uint64_t t[5];
  let b     = 0               " uint32_t b;
  let c     = 0               " uint64_t c;
  let j     = 0               " size_t j;
  let mp    = repeat([0,16])  " unsigned char mp[16];

  let offset = 0

  "     if (len < 16)
  "     goto poly1305_donna_atmost15bytes;
  while size >= 16
    " poly1305_donna_16bytes:
    "   t0 = U8TO32_LE(in);
    "   t1 = U8TO32_LE(in+4);
    "   t2 = U8TO32_LE(in+8);
    "   t3 = U8TO32_LE(in+12);
    for i in range(4)
      let t_x[i] = in[offset + (i * 4): offset + (i * 4) + 3]
    endfor

    let offset += 16 " in += 16;
    let len    -= 16 " len -= 16;

    " state->h0 += t0 & 0x3ffffff;
    let self.h[0] = s:Blob.uint_add(self.h[0], s:Blob.and(t_x[0], 0z3ffffff))
    " state->h1 += ((((uint64_t)t1 << 32) | t0) >> 26) & 0x3ffffff;
    let self.h[1] = s:Blob.uint_add(self.h[1],
          \ s:Blob.and(
          \  s:Blob.rshift(
          \   s:Blob.or(
          \    s:Blob.lshift(t_x[1], 32),
          \    t_x[0]),
          \   26),
          \ 0z3ffffff)
          \)
    " state->h2 += ((((uint64_t)t2 << 32) | t1) >> 20) & 0x3ffffff;
    let self.h[2] = s:Blob.uint_add(self.h[2],
          \ s:Blob.and(
          \  s:Blob.rshift(
          \   s:Blob.or(
          \    s:Blob.lshift(t_x[2], 32),
          \    t_x[1]),
          \   20),
          \ 0z3ffffff)
          \)
    " state->h3 += ((((uint64_t)t3 << 32) | t2) >> 14) & 0x3ffffff;
    let self.h[3] = s:Blob.uint_add(self.h[3],
          \ s:Blob.and(
          \  s:Blob.rshift(
          \   s:Blob.or(
          \    s:Blob.lshift(t_x[3], 32),
          \    t_x[2]),
          \   14),
          \ 0z3ffffff)
          \)
    " state->h4 += (t3 >> 8) | (1 << 24);
    let self.h[4] = s:Blob.uint_add(self.h[4],
          \ s:Blob.or(
          \  s:Blob.lshift(t_x[3], 32),
          \  s:Blob.rshift(     1, 24)
          \)

    " poly1305_donna_mul:
    "   t[0] = mul32x32_64(state->h0,state->r0) +
    "          mul32x32_64(state->h1,state->s4) +
    "          mul32x32_64(state->h2,state->s3) +
    "          mul32x32_64(state->h3,state->s2) +
    "          mul32x32_64(state->h4,state->s1);
    let t_x[0] = s:Blob.uint_add(
          \ s:Blob.uint_add(
          \  s:Blob.uint_add(
          \   s:Blob.uint_mul(self.h[0], self.r[0]),
          \   s:Blob.uint_mul(self.h[1], self.s[4])
          \  ),
          \  s:Blob.uint_add(
          \   s:Blob.uint_mul(self.h[2], self.s[3]),
          \   s:Blob.uint_mul(self.h[3], self.s[2])
          \  )
          \ ),
          \ s:Blob.uint_mul(self.h[4], self.s[1])
          \)
    "   t[1] = mul32x32_64(state->h0,state->r1) +
    "          mul32x32_64(state->h1,state->r0) +
    "          mul32x32_64(state->h2,state->s4) +
    "          mul32x32_64(state->h3,state->s3) +
    "          mul32x32_64(state->h4,state->s2);
    let t_x[1] = s:Blob.uint_add(
          \ s:Blob.uint_add(
          \  s:Blob.uint_add(
          \   s:Blob.uint_mul(self.h[0], self.r[1]),
          \   s:Blob.uint_mul(self.h[1], self.r[0])
          \  ),
          \  s:Blob.uint_add(
          \   s:Blob.uint_mul(self.h[2], self.s[4]),
          \   s:Blob.uint_mul(self.h[3], self.s[3])
          \  )
          \ ),
          \ s:Blob.uint_mul(self.h[4], self.s[2])
          \)
    "   t[2] = mul32x32_64(state->h0,state->r2) +
    "          mul32x32_64(state->h1,state->r1) +
    "          mul32x32_64(state->h2,state->r0) +
    "          mul32x32_64(state->h3,state->s4) +
    "          mul32x32_64(state->h4,state->s3);
    let t_x[2] = s:Blob.uint_add(
          \ s:Blob.uint_add(
          \  s:Blob.uint_add(
          \   s:Blob.uint_mul(self.h[0], self.r[2]),
          \   s:Blob.uint_mul(self.h[1], self.r[1])
          \  ),
          \  s:Blob.uint_add(
          \   s:Blob.uint_mul(self.h[2], self.r[0]),
          \   s:Blob.uint_mul(self.h[3], self.s[4])
          \  )
          \ ),
          \ s:Blob.uint_mul(self.h[4], self.s[3])
          \)
    "   t[3] = mul32x32_64(state->h0,state->r3) +
    "          mul32x32_64(state->h1,state->r2) +
    "          mul32x32_64(state->h2,state->r1) +
    "          mul32x32_64(state->h3,state->r0) +
    "          mul32x32_64(state->h4,state->s4);
    let t_x[3] = s:Blob.uint_add(
          \ s:Blob.uint_add(
          \  s:Blob.uint_add(
          \   s:Blob.uint_mul(self.h[0], self.r[3]),
          \   s:Blob.uint_mul(self.h[1], self.r[2])
          \  ),
          \  s:Blob.uint_add(
          \   s:Blob.uint_mul(self.h[2], self.r[1]),
          \   s:Blob.uint_mul(self.h[3], self.r[0])
          \  )
          \ ),
          \ s:Blob.uint_mul(self.h[4], self.s[4])
          \)
    "   t[4] = mul32x32_64(state->h0,state->r4) +
    "          mul32x32_64(state->h1,state->r3) +
    "          mul32x32_64(state->h2,state->r2) +
    "          mul32x32_64(state->h3,state->r1) +
    "          mul32x32_64(state->h4,state->r0);
    let t_x[4] = s:Blob.uint_add(
          \ s:Blob.uint_add(
          \  s:Blob.uint_add(
          \   s:Blob.uint_mul(self.h[0], self.r[4]),
          \   s:Blob.uint_mul(self.h[1], self.r[3])
          \  ),
          \  s:Blob.uint_add(
          \   s:Blob.uint_mul(self.h[2], self.r[2]),
          \   s:Blob.uint_mul(self.h[3], self.r[1])
          \  )
          \ ),
          \ s:Blob.uint_mul(self.h[4], self.r[0])
          \)
    "
    "              state->h0 = (uint32_t)t[0] & 0x3ffffff; c =           (t[0] >> 26);
    "   t[1] += c; state->h1 = (uint32_t)t[1] & 0x3ffffff; b = (uint32_t)(t[1] >> 26);
    "   t[2] += b; state->h2 = (uint32_t)t[2] & 0x3ffffff; b = (uint32_t)(t[2] >> 26);
    "   t[3] += b; state->h3 = (uint32_t)t[3] & 0x3ffffff; b = (uint32_t)(t[3] >> 26);
    "   t[4] += b; state->h4 = (uint32_t)t[4] & 0x3ffffff; b = (uint32_t)(t[4] >> 26);
    "   state->h0 += b * 5;
    "
    "     if (len >= 16)
    "     goto poly1305_donna_16bytes;
  endwhile

  "     /* final bytes */
  " poly1305_donna_atmost15bytes:
  "   if (!len)
  "     return;
  if !size
    return
  endif
  "
  "   for (j = 0; j < len; j++)
  "     mp[j] = in[j];
  "   mp[j++] = 1;
  "   for (; j < 16; j++)
  "     mp[j] = 0;
  "   len = 0;
  "
  "   t0 = U8TO32_LE(mp+0);
  "   t1 = U8TO32_LE(mp+4);
  "   t2 = U8TO32_LE(mp+8);
  "   t3 = U8TO32_LE(mp+12);
  "
  "   state->h0 +=                          t0         & 0x3ffffff;
  "   state->h1 += ((((uint64_t)t1 << 32) | t0) >> 26) & 0x3ffffff;
  "   state->h2 += ((((uint64_t)t2 << 32) | t1) >> 20) & 0x3ffffff;
  "   state->h3 += ((((uint64_t)t3 << 32) | t2) >> 14) & 0x3ffffff;
  "   state->h4 += (t3 >> 8);
  "
  "     goto poly1305_donna_mul;
  " }
endfunction

function! poly1305_state.finish() abort
  let mac = repeat([0],16)
  let f = repeat([0],4)
  let g = repeat([0],5)
  let b = 0
  let nb = 0

  if self.buf_used                              " if (state->buf_used)
    call self._update(self.buf, self.buf_used)  "     update(state, state->buf, state->buf_used);
  endif

  " b = state->h0 >> 26; state->h0 = state->h0 & 0x3ffffff;
  let b = s:Blob.rshift(self.h[0], 26)
  let self.h[0] = s:Blob.and(self.h[0], 0z3ffffff)

  " state->h1 +=     b; b = state->h1 >> 26; state->h1 = state->h1 & 0x3ffffff;
  let self.h[1] = s:Blob.uint_add(self.h[1], b)
  let b = s:Blob.rshift(self.h[1], 26)
  let self.h[1] = s:Blob.and(self.h[1], 0z3ffffff)

  " state->h2 +=     b; b = state->h2 >> 26; state->h2 = state->h2 & 0x3ffffff;
  let self.h[2] = s:Blob.uint_add(self.h[2], b)
  let b = s:Blob.rshift(self.h[2], 26)
  let self.h[2] = s:Blob.and(self.h[2], 0z3ffffff)

  " state->h3 +=     b; b = state->h3 >> 26; state->h3 = state->h3 & 0x3ffffff;
  let self.h[3] = s:Blob.uint_add(self.h[3], b)
  let b = s:Blob.rshift(self.h[3], 26)
  let self.h[3] = s:Blob.and(self.h[3], 0z3ffffff)

  " state->h4 +=     b; b = state->h4 >> 26; state->h4 = state->h4 & 0x3ffffff;
  let self.h[4] = s:Blob.uint_add(self.h[4], b)
  let b = s:Blob.rshift(self.h[4], 26)
  let self.h[4] = s:Blob.and(self.h[4], 0z3ffffff)

  " state->h0 += b * 5;
  let self.h[0] = s:Blob.mul(b, 5)

  " g0 = state->h0 + 5; b = g0 >> 26; g0 &= 0x3ffffff;
  let g[0] = s:Blob.uint_add(self.h[0], s:Blob.uint32(5))
  let b = s:Blob.rshift(g[0], 26)
  let g[0] = s:Blob.and(g[0], 0z3ffffff)

  " g1 = state->h1 + b; b = g1 >> 26; g1 &= 0x3ffffff;
  let g[1] = s:Blob.uint_add(self.h[1], b)
  let b = s:Blob.rshift(g[1], 26)
  let g[1] = s:Blob.and(g[1], 0z3ffffff)

  " g2 = state->h2 + b; b = g2 >> 26; g2 &= 0x3ffffff;
  let g[2] = s:Blob.uint_add(self.h[2], b)
  let b = s:Blob.rshift(g[2], 26)
  let g[1] = s:Blob.and(g[2], 0z3ffffff)

  " g3 = state->h3 + b; b = g3 >> 26; g3 &= 0x3ffffff;
  let g[3] = s:Blob.uint_add(self.h[3], b)
  let b = s:Blob.rshift(g[3], 26)
  let g[1] = s:Blob.and(g[3], 0z3ffffff)

  " g4 = state->h4 + b - (1 << 26);
  g4 = state->h4 + b - (1 << 26);
  let g[4] = s:Blob.uint_add(self.h[4], b)
  let g[4] = s:Blob.uint_sub(g[4], s:Blob.uint32(s:Bitwise.lshift(1, 26)))

  " b = (g4 >> 31) - 1;
  let b = s:Blob.rshift(g4, 31)
  let b = s:Blob.uint_sub(b, s:Blob.uint32(1))
  let nb = s:Blob.invert(b) " nb = ~b;

  " state->h0 = (state->h0 & nb) | (g0 & b);
  " state->h1 = (state->h1 & nb) | (g1 & b);
  " state->h2 = (state->h2 & nb) | (g2 & b);
  " state->h3 = (state->h3 & nb) | (g3 & b);
  " state->h4 = (state->h4 & nb) | (g4 & b);
  for i in range(5)
    let self.h[i] = s:Blob.or(s:Blob.and(self.h[i], nb), s:Blob.and(g[i], b))
  endfor

  " f0 = ((state->h0      ) | (state->h1 << 26)) + (uint64_t)U8TO32_LE(&state->key[0]);
  let f[0] = s:Blob.uint_add(
        \ s:Blob.or(
        \               (self.h[0]    ),
        \  s:Blob.lshift(self.h[1], 26)
        \ ),
        \ self.key[ 0 :  3]
        \)
  " f1 = ((state->h1 >>  6) | (state->h2 << 20)) + (uint64_t)U8TO32_LE(&state->key[4]);
  let f[1] = s:Blob.uint_add(
        \ s:Blob.or(
        \  s:Blob.rshift(self.h[1],  6),
        \  s:Blob.lshift(self.h[2], 20)
        \ ),
        \ self.key[ 4 :  7]
        \)
  " f2 = ((state->h2 >> 12) | (state->h3 << 14)) + (uint64_t)U8TO32_LE(&state->key[8]);
  let f[2] = s:Blob.uint_add(
        \ s:Blob.or(
        \  s:Blob.rshift(self.h[2], 12),
        \  s:Blob.lshift(self.h[3], 14)
        \ ),
        \ self.key[ 8 : 11]
        \)
  " f3 = ((state->h3 >> 18) | (state->h4 <<  8)) + (uint64_t)U8TO32_LE(&state->key[12]);
  let f[3] = s:Blob.uint_add(
        \ s:Blob.or(
        \  s:Blob.rshift(self.h[3], 18),
        \  s:Blob.lshift(self.h[4],  8)
        \ ),
        \ self.key[12 : 15]
        \)

  " U32TO8_LE(&mac[ 0], f0); f1 += (f0 >> 32);
  let mac[ 0: 3] = s:ByteArray.from_blob(f[0])
  let f[1] = s:Blob.uint_add(f[1], s:Blob.rshift(f[0], 32))

  " U32TO8_LE(&mac[ 4], f1); f2 += (f1 >> 32);
  let mac[ 4: 7] = s:ByteArray.from_blob(f[1])
  let f[2] = s:Blob.uint_add(f[2], s:Blob.rshift(f[1], 32))

  " U32TO8_LE(&mac[ 8], f2); f3 += (f2 >> 32);
  let mac[ 8:11] = s:ByteArray.from_blob(f[2])
  let f[3] = s:Blob.uint_add(f[3], s:Blob.rshift(f[2], 32))

  " U32TO8_LE(&mac[12], f3);
  let mac[12:15] = s:ByteArray.from_blob(f[3])

  return mac
endfunction

function! s:Poly1305.calc(data) abort
  return digest
endfunction

function! s:Poly1305.mac(data) abort
  return s:ByteArray.to_hexstring(self.calc(a:data))
endfunction

function! s:Poly1305.poly1305(data) abort
  return self.mac(a:data)
endfunction

function! s:_throw(message) abort
  throw 'vital: Crypt.MAC.Poly1305: ' . a:message
endfunction
