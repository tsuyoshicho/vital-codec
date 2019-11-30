" random number generator using xoshiro128**
" http://prng.di.unimi.it/
" base code)(xoshiro128** 32bit)
"  http://prng.di.unimi.it/xoshiro128starstar.c

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:B = a:V.import('Bitwise')
endfunction

function! s:_vital_depends() abort
  return ['Bitwise']
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
" -> B.rotate32l()

" static uint32_t s[4];
let s:Generator = {
      \ 's'         : [0, 0, 0, 0]
      \ 'count'     : 0,
      \ 'longcount' : 0
      \}

function! s:Generator.next() abort               " uint32_t next(void) {
                                                 "   const uint32_t result = rotl(s[1] * 5, 7) * 9;
  let result = B.uint32(
        \ B.rotate32l(self.s[1] * 5, 7) * 9
        \)
                                                 "
  let t = B.uint32(B.lshift(self.s[1], 9))       "   const uint32_t t = s[1] << 9;
                                                 "
  let self.s[2] = B.xor(self.s[2], self.s[0])    "   s[2] ^= s[0];
  let self.s[3] = B.xor(self.s[3], self.s[1])    "   s[3] ^= s[1];
  let self.s[1] = B.xor(self.s[1], self.s[2])    "   s[1] ^= s[2];
  let self.s[0] = B.xor(self.s[0], self.s[3])    "   s[0] ^= s[3];
                                                 "
  let self.s[2] = B.xor(self.s[2],         t)    "   s[2] ^= t;
                                                 "
                                                 "   s[3] = rotl(s[3], 11);
  let self.s[3] = B.uint32(
        \ B.rotate32l(self.s[3], 11)
        \)
                                                 "
   return result                                 "   return result;
 endfunction                                     " }


" /* This is the jump function for the generator. It is equivalent
"    to 2^64 calls to next(); it can be used to generate 2^64
"    non-overlapping subsequences for parallel computations. */
"
function! s:Generator._jump() abort                 " void jump(void) {
                                                    "   static const uint32_t JUMP[] = { 0x8764000b, 0xf542d2d3, 0x6fa035c3, 0x77f2db5b };
  let jump = [0x8764000b, 0xf542d2d3, 0x6fa035c3, 0x77f2db5b]

                                                    "   uint32_t s0 = 0;
                                                    "   uint32_t s1 = 0;
                                                    "   uint32_t s2 = 0;
                                                    "   uint32_t s3 = 0;
  let s = [0, 0, 0, 0]
  for i in range(len(jump))                         "   for(int i = 0; i < sizeof JUMP / sizeof *JUMP; i++)
    for b in range(32)                              "     for(int b = 0; b < 32; b++) {
      if B.and(jump[i], B.uint32(B.lshift(1, b)))   "       if (JUMP[i] & UINT32_C(1) << b) {
                                                    "         s0 ^= s[0];
                                                    "         s1 ^= s[1];
                                                    "         s2 ^= s[2];
                                                    "         s3 ^= s[3];
        for n in range(len(s))
          let s[n] = B.xor(s[n], self.s[n])
        endfor
      endfor                                        "       }
      call self.next()                              "       next();
    endfor                                          "     }
                                                    "
                                                    "   s[0] = s0;
                                                    "   s[1] = s1;
                                                    "   s[2] = s2;
                                                    "   s[3] = s3;
    let self.s[:] = s[:]
endfunction                                         " }


" /* This is the long-jump function for the generator. It is equivalent to
"    2^96 calls to next(); it can be used to generate 2^32 starting points,
"    from each of which jump() will generate 2^32 non-overlapping
"    subsequences for parallel distributed computations. */
"
function! s:Generator._longjump() abort                 " void long_jump(void) {
                                                        "   static const uint32_t LONG_JUMP[] = { 0xb523952e, 0x0b6f099f, 0xccf5a0ef, 0x1c580662 };
   let longjump = [0xb523952e, 0x0b6f099f, 0xccf5a0ef, 0x1c580662]
                                                        "   uint32_t s0 = 0;
                                                        "   uint32_t s1 = 0;
                                                        "   uint32_t s2 = 0;
                                                        "   uint32_t s3 = 0;
   let s = [0, 0, 0, 0]
    for i in range(len(longjump))                       "   for(int i = 0; i < sizeof LONG_JUMP / sizeof *LONG_JUMP; i++)
      for b in range(32)                                "     for(int b = 0; b < 32; b++) {
        if B.and(longjump[i], B.uint32(B.lshift(1, b))) "       if (LONG_JUMP[i] & UINT32_C(1) << b) {
                                                        "         s0 ^= s[0];
                                                        "         s1 ^= s[1];
                                                        "         s2 ^= s[2];
                                                        "         s3 ^= s[3];
         for n in range(len(s))
           let s[n] = B.xor(s[n], self.s[n])
         endfor
       endfor                                           "       }
       call self.next()                                 "       next();
     endfor                                             "     }
                                                        "   s[0] = s0;
                                                        "   s[1] = s1;
                                                        "   s[2] = s2;
                                                        "   s[3] = s3;
     let self.s[:] = s[:]
 endfunction                                            " }


function! s:Generator.min() abort
  return 0
endfunction

function! s:Generator.max() abort
  return 1
endfunction


function! s:Generator.seed(seeds) abort
endfunction

function! s:new_generator() abort
  let gen = deepcopy(s:Generator)
  call gen.seed([])
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
  call s:_common_generator().seed([x])
endfunction

function! s:rand() abort
  return s:_common_generator().next()
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
