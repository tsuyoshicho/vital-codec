" Poly1305
" RFC 7539 - ChaCha20 and Poly1305 for IETF Protocols https://tools.ietf.org/html/rfc7539
" based on https://github.com/floodyberry/poly1305-donna poly1305-donna-32.h
" and see
" https://cr.yp.to/mac.html
" https://github.com/calvinmetcalf/chacha20poly1305

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

" new implement
" /*
"   poly1305 implementation using 32 bit * 32 bit = 64 bit multiplication and 64 bit addition
" */
"
" #if defined(_MSC_VER)
"   #define POLY1305_NOINLINE __declspec(noinline)
" #elif defined(__GNUC__)
"   #define POLY1305_NOINLINE __attribute__((noinline))
" #else
"   #define POLY1305_NOINLINE
" #endif
"
" #define poly1305_block_size 16
"
" /* 17 + sizeof(size_t) + 14*sizeof(unsigned long) */
" typedef struct poly1305_state_internal_t {
"   unsigned long r[5];
"   unsigned long h[5];
"   unsigned long pad[4];
"   size_t leftover;
"   unsigned char buffer[poly1305_block_size];
"   unsigned char final;
" } poly1305_state_internal_t;
"
" /* interpret four 8 bit unsigned integers as a 32 bit unsigned integer in little endian */
" static unsigned long
" U8TO32(const unsigned char *p) {
"   return
"     (((unsigned long)(p[0] & 0xff)      ) |
"        ((unsigned long)(p[1] & 0xff) <<  8) |
"          ((unsigned long)(p[2] & 0xff) << 16) |
"          ((unsigned long)(p[3] & 0xff) << 24));
" }
"
" /* store a 32 bit unsigned integer as four 8 bit unsigned integers in little endian */
" static void
" U32TO8(unsigned char *p, unsigned long v) {
"   p[0] = (v      ) & 0xff;
"   p[1] = (v >>  8) & 0xff;
"   p[2] = (v >> 16) & 0xff;
"   p[3] = (v >> 24) & 0xff;
" }
"
" void
" poly1305_init(poly1305_context *ctx, const unsigned char key[32]) {
"   poly1305_state_internal_t *st = (poly1305_state_internal_t *)ctx;
"
"   /* r &= 0xffffffc0ffffffc0ffffffc0fffffff */
"   st->r[0] = (U8TO32(&key[ 0])     ) & 0x3ffffff;
"   st->r[1] = (U8TO32(&key[ 3]) >> 2) & 0x3ffff03;
"   st->r[2] = (U8TO32(&key[ 6]) >> 4) & 0x3ffc0ff;
"   st->r[3] = (U8TO32(&key[ 9]) >> 6) & 0x3f03fff;
"   st->r[4] = (U8TO32(&key[12]) >> 8) & 0x00fffff;
"
"   /* h = 0 */
"   st->h[0] = 0;
"   st->h[1] = 0;
"   st->h[2] = 0;
"   st->h[3] = 0;
"   st->h[4] = 0;
"
"   /* save pad for later */
"   st->pad[0] = U8TO32(&key[16]);
"   st->pad[1] = U8TO32(&key[20]);
"   st->pad[2] = U8TO32(&key[24]);
"   st->pad[3] = U8TO32(&key[28]);
"
"   st->leftover = 0;
"   st->final = 0;
" }
"
" static void
" poly1305_blocks(poly1305_state_internal_t *st, const unsigned char *m, size_t bytes) {
"   const unsigned long hibit = (st->final) ? 0 : (1UL << 24); /* 1 << 128 */
"   unsigned long r0,r1,r2,r3,r4;
"   unsigned long s1,s2,s3,s4;
"   unsigned long h0,h1,h2,h3,h4;
"   unsigned long long d0,d1,d2,d3,d4;
"   unsigned long c;
"
"   r0 = st->r[0];
"   r1 = st->r[1];
"   r2 = st->r[2];
"   r3 = st->r[3];
"   r4 = st->r[4];
"
"   s1 = r1 * 5;
"   s2 = r2 * 5;
"   s3 = r3 * 5;
"   s4 = r4 * 5;
"
"   h0 = st->h[0];
"   h1 = st->h[1];
"   h2 = st->h[2];
"   h3 = st->h[3];
"   h4 = st->h[4];
"
"   while (bytes >= poly1305_block_size) {
"     /* h += m[i] */
"     h0 += (U8TO32(m+ 0)     ) & 0x3ffffff;
"     h1 += (U8TO32(m+ 3) >> 2) & 0x3ffffff;
"     h2 += (U8TO32(m+ 6) >> 4) & 0x3ffffff;
"     h3 += (U8TO32(m+ 9) >> 6) & 0x3ffffff;
"     h4 += (U8TO32(m+12) >> 8) | hibit;
"
"     /* h *= r */
"     d0 = ((unsigned long long)h0 * r0) + ((unsigned long long)h1 * s4) + ((unsigned long long)h2 * s3) + ((unsigned long long)h3 * s2) + ((unsigned long long)h4 * s1);
"     d1 = ((unsigned long long)h0 * r1) + ((unsigned long long)h1 * r0) + ((unsigned long long)h2 * s4) + ((unsigned long long)h3 * s3) + ((unsigned long long)h4 * s2);
"     d2 = ((unsigned long long)h0 * r2) + ((unsigned long long)h1 * r1) + ((unsigned long long)h2 * r0) + ((unsigned long long)h3 * s4) + ((unsigned long long)h4 * s3);
"     d3 = ((unsigned long long)h0 * r3) + ((unsigned long long)h1 * r2) + ((unsigned long long)h2 * r1) + ((unsigned long long)h3 * r0) + ((unsigned long long)h4 * s4);
"     d4 = ((unsigned long long)h0 * r4) + ((unsigned long long)h1 * r3) + ((unsigned long long)h2 * r2) + ((unsigned long long)h3 * r1) + ((unsigned long long)h4 * r0);
"
"     /* (partial) h %= p */
"                   c = (unsigned long)(d0 >> 26); h0 = (unsigned long)d0 & 0x3ffffff;
"     d1 += c;      c = (unsigned long)(d1 >> 26); h1 = (unsigned long)d1 & 0x3ffffff;
"     d2 += c;      c = (unsigned long)(d2 >> 26); h2 = (unsigned long)d2 & 0x3ffffff;
"     d3 += c;      c = (unsigned long)(d3 >> 26); h3 = (unsigned long)d3 & 0x3ffffff;
"     d4 += c;      c = (unsigned long)(d4 >> 26); h4 = (unsigned long)d4 & 0x3ffffff;
"     h0 += c * 5;  c =                (h0 >> 26); h0 =                h0 & 0x3ffffff;
"     h1 += c;
"
"     m += poly1305_block_size;
"     bytes -= poly1305_block_size;
"   }
"
"   st->h[0] = h0;
"   st->h[1] = h1;
"   st->h[2] = h2;
"   st->h[3] = h3;
"   st->h[4] = h4;
" }
"
" POLY1305_NOINLINE void
" poly1305_finish(poly1305_context *ctx, unsigned char mac[16]) {
"   poly1305_state_internal_t *st = (poly1305_state_internal_t *)ctx;
"   unsigned long h0,h1,h2,h3,h4,c;
"   unsigned long g0,g1,g2,g3,g4;
"   unsigned long long f;
"   unsigned long mask;
"
"   /* process the remaining block */
"   if (st->leftover) {
"     size_t i = st->leftover;
"     st->buffer[i++] = 1;
"     for (; i < poly1305_block_size; i++)
"       st->buffer[i] = 0;
"     st->final = 1;
"     poly1305_blocks(st, st->buffer, poly1305_block_size);
"   }
"
"   /* fully carry h */
"   h0 = st->h[0];
"   h1 = st->h[1];
"   h2 = st->h[2];
"   h3 = st->h[3];
"   h4 = st->h[4];
"
"                c = h1 >> 26; h1 = h1 & 0x3ffffff;
"   h2 +=     c; c = h2 >> 26; h2 = h2 & 0x3ffffff;
"   h3 +=     c; c = h3 >> 26; h3 = h3 & 0x3ffffff;
"   h4 +=     c; c = h4 >> 26; h4 = h4 & 0x3ffffff;
"   h0 += c * 5; c = h0 >> 26; h0 = h0 & 0x3ffffff;
"   h1 +=     c;
"
"   /* compute h + -p */
"   g0 = h0 + 5; c = g0 >> 26; g0 &= 0x3ffffff;
"   g1 = h1 + c; c = g1 >> 26; g1 &= 0x3ffffff;
"   g2 = h2 + c; c = g2 >> 26; g2 &= 0x3ffffff;
"   g3 = h3 + c; c = g3 >> 26; g3 &= 0x3ffffff;
"   g4 = h4 + c - (1UL << 26);
"
"   /* select h if h < p, or h + -p if h >= p */
"   mask = (g4 >> ((sizeof(unsigned long) * 8) - 1)) - 1;
"   g0 &= mask;
"   g1 &= mask;
"   g2 &= mask;
"   g3 &= mask;
"   g4 &= mask;
"   mask = ~mask;
"   h0 = (h0 & mask) | g0;
"   h1 = (h1 & mask) | g1;
"   h2 = (h2 & mask) | g2;
"   h3 = (h3 & mask) | g3;
"   h4 = (h4 & mask) | g4;
"
"   /* h = h % (2^128) */
"   h0 = ((h0      ) | (h1 << 26)) & 0xffffffff;
"   h1 = ((h1 >>  6) | (h2 << 20)) & 0xffffffff;
"   h2 = ((h2 >> 12) | (h3 << 14)) & 0xffffffff;
"   h3 = ((h3 >> 18) | (h4 <<  8)) & 0xffffffff;
"
"   /* mac = (h + pad) % (2^128) */
"   f = (unsigned long long)h0 + st->pad[0]            ; h0 = (unsigned long)f;
"   f = (unsigned long long)h1 + st->pad[1] + (f >> 32); h1 = (unsigned long)f;
"   f = (unsigned long long)h2 + st->pad[2] + (f >> 32); h2 = (unsigned long)f;
"   f = (unsigned long long)h3 + st->pad[3] + (f >> 32); h3 = (unsigned long)f;
"
"   U32TO8(mac +  0, h0);
"   U32TO8(mac +  4, h1);
"   U32TO8(mac +  8, h2);
"   U32TO8(mac + 12, h3);
"
"   /* zero out the state */
"   st->h[0] = 0;
"   st->h[1] = 0;
"   st->h[2] = 0;
"   st->h[3] = 0;
"   st->h[4] = 0;
"   st->r[0] = 0;
"   st->r[1] = 0;
"   st->r[2] = 0;
"   st->r[3] = 0;
"   st->r[4] = 0;
"   st->pad[0] = 0;
"   st->pad[1] = 0;
"   st->pad[2] = 0;
"   st->pad[3] = 0;
" }

" old code
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
    let self.h[0] = s:Bitwise.and(s:Bitwise.uint32(t_x[0]), 0x3ffffff)
    let c = s:Bitwise.uint32(s:Bitwise.rshift(t_x[0], 26))
    "   t[1] += c; state->h1 = (uint32_t)t[1] & 0x3ffffff; b = (uint32_t)(t[1] >> 26);
    let t_x[1] = s:Bitwise.uint32(t_x[1] + c)
    let self.h[1] = s:Bitwise.and(s:Bitwise.uint32(t_x[1]), 0x3ffffff)
    let b = s:Bitwise.uint32(s:Bitwise.rshift(t_x[1], 26))
    "   t[2] += b; state->h2 = (uint32_t)t[2] & 0x3ffffff; b = (uint32_t)(t[2] >> 26);
    let t_x[2] = s:Bitwise.uint32(t_x[2] + b)
    let self.h[2] = s:Bitwise.and(s:Bitwise.uint32(t_x[2]), 0x3ffffff)
    let b = s:Bitwise.uint32(s:Bitwise.rshift(t_x[2], 26))
    "   t[3] += b; state->h3 = (uint32_t)t[3] & 0x3ffffff; b = (uint32_t)(t[3] >> 26);
    let t_x[3] = s:Bitwise.uint32(t_x[3] + b)
    let self.h[3] = s:Bitwise.and(s:Bitwise.uint32(t_x[3]), 0x3ffffff)
    let b = s:Bitwise.uint32(s:Bitwise.rshift(t_x[3], 26))
    "   t[4] += b; state->h4 = (uint32_t)t[4] & 0x3ffffff; b = (uint32_t)(t[4] >> 26);
    let t_x[4] = s:Bitwise.uint32(t_x[4] + b)
    let self.h[4] = s:Bitwise.and(s:Bitwise.uint32(t_x[4]), 0x3ffffff)
    let b = s:Bitwise.uint32(s:Bitwise.rshift(t_x[4], 26))
    "   state->h0 += b * 5;
    let self.h[0] = s:Bitwise.uint32(b * 5)
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
