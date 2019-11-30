" random number generator using xoshiro128**
" http://prng.di.unimi.it/
" base code (xoshiro128** 32bit)
"  http://prng.di.unimi.it/xoshiro128starstar.c

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:P = a:V.import('Prelude')
  let s:B = a:V.import('Bitwise')

  let s:mask32bit = s:B.or(
          \ s:B.lshift(0xFFFF, 16),
          \            0xFFFF
          \)
endfunction

function! s:_vital_depends() abort
  return ['Prelude', 'Bitwise']
endfunction


" /*  Written in 2018 by David Blackman and Sebastiano Vigna (vigna@acm.org)
"
" To the extent possible under law, the author has dedicated all copyright
" and related and neighboring rights to this software to the public domain
" worldwide. This software is distributed without any warranty.
"
" See <http://creativecommons.org/publicdomain/zero/1.0/>. */
"
" #include <stdint.h>
"
" /* This is xoshiro128** 1.1, one of our 32-bit all-purpose, rock-solid
"    generators. It has excellent speed, a state size (128 bits) that is
"    large enough for mild parallelism, and it passes all tests we are aware
"    of.
"
"    Note that version 1.0 had mistakenly s[0] instead of s[1] as state
"    word passed to the scrambler.
"
"    For generating just single-precision (i.e., 32-bit) floating-point
"    numbers, xoshiro128+ is even faster.
"
"    The state must be seeded so that it is not everywhere zero. */
"
"
" static inline uint32_t rotl(const uint32_t x, int k) {
"   return (x << k) | (x >> (32 - k));
" }
" -> s:B.rotate32l()

" static uint32_t s[4];
let s:Generator = {
      \ 's'             : [0, 1, 2, 3],
      \ 'longjumpcount' : 0,
      \ 'jumpcount'     : 0,
      \ 'highcount'     : 0,
      \ 'lowcount'      : 0,
      \}

function! s:Generator._next() abort              " uint32_t next(void) {
                                                 "   const uint32_t result = rotl(s[1] * 5, 7) * 9;
  let result = s:B.uint32(
        \ s:B.rotate32l(self.s[1] * 5, 7) * 9
        \)

  let t = s:B.uint32(s:B.lshift(self.s[1], 9))   "   const uint32_t t = s[1] << 9;

  let self.s[2] = s:B.xor(self.s[2], self.s[0])  "   s[2] ^= s[0];
  let self.s[3] = s:B.xor(self.s[3], self.s[1])  "   s[3] ^= s[1];
  let self.s[1] = s:B.xor(self.s[1], self.s[2])  "   s[1] ^= s[2];
  let self.s[0] = s:B.xor(self.s[0], self.s[3])  "   s[0] ^= s[3];

  let self.s[2] = s:B.xor(self.s[2],         t)  "   s[2] ^= t;

                                                 "   s[3] = rotl(s[3], 11);
  let self.s[3] = s:B.uint32(
        \ s:B.rotate32l(self.s[3], 11)
        \)

   return result                                 "   return result;
 endfunction                                     " }


" /* This is the jump function for the generator. It is equivalent
"    to 2^64 calls to next(); it can be used to generate 2^64
"    non-overlapping subsequences for parallel computations. */
"
function! s:Generator._jump() abort   " void jump(void) {
                                      "   static const uint32_t JUMP[] = { 0x8764000b, 0xf542d2d3, 0x6fa035c3, 0x77f2db5b };
  let jump = [
        \ s:B.or(s:B.lshift(0x8764, 16), 0x000b),
        \ s:B.or(s:B.lshift(0xf542, 16), 0xd2d3),
        \ s:B.or(s:B.lshift(0x6fa0, 16), 0x35c3),
        \ s:B.or(s:B.lshift(0x77f2, 16), 0xdb5b),
        \]

                                      "   uint32_t s0 = 0;
                                      "   uint32_t s1 = 0;
                                      "   uint32_t s2 = 0;
                                      "   uint32_t s3 = 0;
  let s = [0, 0, 0, 0]
  for i in range(len(jump))           "   for(int i = 0; i < sizeof JUMP / sizeof *JUMP; i++)
    for b in range(32)                "     for(int b = 0; b < 32; b++) {
                                      "       if (JUMP[i] & UINT32_C(1) << b) {
      if s:B.and(jump[i],
            \    s:B.uint32(s:B.lshift(1, b)))
                                      "         s0 ^= s[0];
                                      "         s1 ^= s[1];
                                      "         s2 ^= s[2];
                                      "         s3 ^= s[3];
        for n in range(len(s))
          let s[n] = s:B.xor(s[n], self.s[n])
        endfor
      endfor                          "       }
      call self._next()               "       next();
    endfor                            "     }
                                      "   s[0] = s0;
                                      "   s[1] = s1;
                                      "   s[2] = s2;
                                      "   s[3] = s3;
    let self.s[:] = s[:]
endfunction                           " }


" /* This is the long-jump function for the generator. It is equivalent to
"    2^96 calls to next(); it can be used to generate 2^32 starting points,
"    from each of which jump() will generate 2^32 non-overlapping
"    subsequences for parallel distributed computations. */
"
function! s:Generator._longjump() abort      " void long_jump(void) {
                                             "   static const uint32_t LONG_JUMP[] = { 0xb523952e, 0x0b6f099f, 0xccf5a0ef, 0x1c580662 };
  let longjump = [
        \ s:B.or(s:B.lshift(0xb523, 16), 0x952e),
        \ s:B.or(s:B.lshift(0x0b6f, 16), 0x099f),
        \ s:B.or(s:B.lshift(0xccf5, 16), 0xa0ef),
        \ s:B.or(s:B.lshift(0x1c58, 16), 0x0662),
        \]
                                             "   uint32_t s0 = 0;
                                             "   uint32_t s1 = 0;
                                             "   uint32_t s2 = 0;
                                             "   uint32_t s3 = 0;
   let s = [0, 0, 0, 0]
    for i in range(len(longjump))            "   for(int i = 0; i < sizeof LONG_JUMP / sizeof *LONG_JUMP; i++)
      for b in range(32)                     "     for(int b = 0; b < 32; b++) {
                                             "       if (LONG_JUMP[i] & UINT32_C(1) << b) {
        if s:B.and(longjump[i],
              \    s:B.uint32(s:B.lshift(1, b)))

                                             "         s0 ^= s[0];
                                             "         s1 ^= s[1];
                                             "         s2 ^= s[2];
                                             "         s3 ^= s[3];
         for n in range(len(s))
           let s[n] = s:B.xor(s[n], self.s[n])
         endfor
       endfor                                "       }
       call self._next()                     "       next();
     endfor                                  "     }
                                             "   s[0] = s0;
                                             "   s[1] = s1;
                                             "   s[2] = s2;
                                             "   s[3] = s3;
     let self.s[:] = s[:]
endfunction                                  " }

function! s:Generator.next() abort
  if self.longjumpcount == s:mask32bit
        \ && self.jumpcount == s:mask32bit
        \ && self.highcount == s:mask32bit
        \ && self.lowcount == s:mask32bit
    " 2^128 calls overlap
    let self.longjumpcount = 0
    let self.jumpcount = 0
    let self.highcount = 0
    let self.lowcount = 0
  elseif self.jumpcount == s:mask32bit
        \ && self.highcount == s:mask32bit
        \ && self.lowcount == s:mask32bit
    " 2^96 calls long jump
    let self.longjumpcount += 1
    let self.jumpcount = 0
    let self.highcount = 0
    let self.lowcount = 0
    call self._longjump()
  elseif self.highcount == s:mask32bit
        \ && self.lowcount == s:mask32bit
    " 2^64 calls jump
    let self.jumpcount += 1
    let self.highcount = 0
    let self.lowcount = 0
    call self._jump()
  else self.lowcount == s:mask32bit
    " 2^32 calls
    let self.highcount += 1
    let self.lowcount = 0
  else
    " normal calls
    let self.count += 1
  endif

  return self._next()
endfunction

function! s:Generator.min() abort
  return 0
endfunction

function! s:Generator.max() abort
  return s:mask32bit
endfunction

" from vim Xoshiro128StarStar implement seed generation scrambler
function! s:_splitmix32(x) abort
  " #define SPLITMIX32 ( \

  "    z = (x += 0x9e3779b9), \
  let x = s:B.uint32(s:B.or(s:B.lshift(0x9e37, 16), 0x79b9) + a:x)
  let z = x
  "    z = (z ^ (z >> 16)) * 0x85ebca6b, \
  let z = s:B.uint32(s:B.or(s:B.lshift(0x85eb, 16), 0xca6b) * s:B.xor(z, s:B.rshift(z, 16)))
  "    z = (z ^ (z >> 13)) * 0xc2b2ae35, \
  let z = s:B.uint32(s:B.or(s:B.lshift(0xc2b2, 16), 0xae35) * s:B.xor(z, s:B.rshift(z, 13)))
  "    z ^ (z >> 16) \
  let z = s:B.xor(z,s:B.rshift(z, 16))
  "    )

  return [z,x]
endfunction

function! s:Generator.seed(seeds) abort
  let seeds = a:seeds
  for i in range(4)
    let [self.s[i], seeds] = s:_splitmix32(seeds)
  endfor
endfunction

function! s:new_generator() abort
  let gen = deepcopy(s:Generator)
  call gen.seed(0)
  return gen
endfunction

function! s:_common_generator() abort
  if !exists('s:common_generator')
    let s:common_generator = s:new_generator()
  endif
  return s:common_generator
endfunction

function! s:srand(...) abort
  if a:0 == 0
    let x = has('reltime') ? reltime()[1] : localtime()
  elseif a:0 == 1
    let x = a:1
  else
    throw 'vital: Random.Xoshiro128StarStar: srand(): too many arguments'
  endif
  call s:_common_generator().seed(x)
endfunction

function! s:rand() abort
  return s:_common_generator().next()
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
