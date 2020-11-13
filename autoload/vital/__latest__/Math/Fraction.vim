" Utilities for Fraction

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V      = a:V
  let s:P      = s:V.import('Prelude')
  let s:Math   = s:V.import('Math')
  let s:BigNum = s:V.import('Data.BigNum')

  let s:ZERO_NUM = s:BigNum.from_num(0)
  let s:ONE_NUM  = s:BigNum.from_num(1)

  " 'sign' v:true + / v:false -  / v:none is 0
  " data = numerator / denominator
  " default 0/1 v:none : zero
  let s:Fraction = {
    \  'numerator'   : deepcopy(s:ZERO_NUM),
    \  'denominator' : deepcopy(s:ONE_NUM),
    \  'sign'        : v:none,
    \}
endfunction

function! s:_vital_depends() abort
  return ['Prelude', 'Math', 'Data.BigNum']
endfunction

" inner function
" generate from valid data type data
function! s:_generate(num, deno) abort
  let f = deepcopy(s:Fraction)
  let f.numerator   = s:_of(a:num)
  let f.denominator = s:_of(a:deno)

  return s:_balance(f)
endfunction

" bignum wrapper
function! s:_of(data) abort
    return s:BigNum.add(a:data, s:ZERO_NUM)
endfunction

" bignum abs
function! s:_bignum_abs(val) abort
  return s:BigNum.sign(a:val) > 0 ? a:val : s:BigNum.neg(a:val)
endfunction

" bignum gcd
" return v:none do not have gcd
"        bignum gcd
" bignum immutable object = do not need copy
function! s:_bignum_gcd(a, b) abort
  let gcd = v:none
  let [a, b] = [a:a, a:b]

  if (s:BigNum.sign(a) == 0) || (s:BigNum.sign(b) == 0)
    " 0 and other do not have gcd
    return gcd
  endif

  let a = s:_bignum_abs(a)
  let b = s:_bignum_abs(b)

  if 1 == s:BigNum.compare(a, b)
    " 1 is a < b, swap it
    let [b, a] = [a, b]
  endif

  " Euclidean Algorithm
  while (s:BigNum.sign(b) != 0)
    let [a, b] = [b, s:BigNum.mod(a, b)]
  endwhile

  " sanity result check
  if (s:BigNum.sign(a) != 0)
    let gcd = a
  endif

  return gcd
endfunction

" fraction re-balance
" sign : first allocation time as v:none
" d    : if zero divid, return v:none(not Fraction object)
function! s:_balance(fraction) abort
  let f = deepcopy(s:Fraction)
  let n = a:fraction.numerator
  let d = a:fraction.denominator
  let s = a:fraction.sign

  " check zero divid
  if s:BigNum.sign(d) == 0
    " divid by zero
    return v:none
  endif

  " check zero Fraction object
  "  0/n +/- -> 0/1 +
  " sign is able to v:none for first allocation time
  if s:BigNum.sign(n) == 0
    return f
  endif

  " sign detect
  if s is v:none
    " base set
    let s = v:true
  endif

  let s = (s:BigNum.sign(n) * s:BigNum.sign(d)) > 0 ? s : !s
  let n = s:_bignum_abs(n)
  let d = s:_bignum_abs(d)

  " re-balance
  let gcd = s:_bignum_gcd(n, d)
  if gcd isnot v:none
    let n =  s:BigNum.div(n, gcd)
    let d =  s:BigNum.div(d, gcd)
  endif

  let f.numerator   = n
  let f.denominator = d
  let f.sign        = s
  return f
endfunction

" Constractor
function! s:new(...) abort
  " check 3 or more, support 0,1,2
  if 2 < a:0
    call s:_throw('Unsupport arguments count:' . string(a:0))
  endif

  let n = 1
  let d = 1

  if 0 != a:0
    if s:P.is_number(a:1) || s:P.is_string(a:1)
      let n = a:1
    else
      call s:_throw('Unsupport type error arg:1 type:' . string(type(a:1)))
    endif

    if 1 == a:0
      let d = 1
    else
      if s:P.is_number(a:2) || s:P.is_string(a:2)
        let d = a:2
      else
        call s:_throw('Unsupport type error arg:2 type:' . string(type(a:2)))
      endif
    endif
  endif

  let f = s:_generate(n, d)

  if f is v:none
    call s:_throw('Divid Zero Exception')
  endif

  return f
endfunction

function! s:from_string(strf) abort
  if !s:P.is_string(a:strf)
    call s:_throw('Invalid argument type:' . string(type(a:strf)) . '/value:' . string(a:strf))
  endif
  " split
  let result = matchlist(a:strf, '\([-+]\?\d\+\)/\([-+]\?\d\+\)')

  " split error check
  if empty(result[1]) || empty(result[2])
    call s:_throw('Invalid format string:' . a:strf)
  endif

  let n = result[1]
  let d = result[2]

  " create
  return s:new(n, d)
endfunction

function! s:_throw(msg) abort
  throw 'vital: Math.Fraction: ' . a:msg
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
