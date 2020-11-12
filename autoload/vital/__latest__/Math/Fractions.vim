" Utilities for Fraction

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V      = a:V
  let s:P      = s:V.import('Prelude')
  let s:Math   = s:V.import('Math')
  let s:BigNum = s:V.import('Data.BigNum')
endfunction

function! s:_vital_depends() abort
  return ['Prelude', 'Math', 'Data.BigNum']
endfunction

" 'sign' v:true + / v:false -  / v:none is 0
" data = numerator / denominator
let s:Fractions = {
  \  'numerator'   : v:none,
  \  'denominator' : v:none,
  \  'sign'        : v:none,
  \}

" inner function
" generate from valid data type data
function s:_generate(num, deno) abort
  let f = deepcopy(s:Fractions)
  let f.numerator   = s:_bignum(a:num)
  let f.denominator = s:_bignum(a:deno)

  return s:_balance(f)
endfunction

" bignum wrapper
function s:_bignum(data) abort
    return s:P.is_number(a:data)
      \ ? s:BigNum.from_num(a:data)
      \ : s:BigNum.from_string(a:data)
endfunction

" bignum gcd
" TODO: need bigdicimal and move to
" return v:none do not have gcd
"        bignum gcd
" bignum immutable object = do not need copy
function s:_bignum_gcd(a, b) abort
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

  while (s:BigNum.sign(b) != 0)
    let [a, b] = [b, s:BigNum.mod(a, b)]
  endwhile

  " sanity result check
  if (s:BigNum.sign(a) != 0)
    let gcd = a
  endif

  return gcd
endfunction

function s:_bignum_abs(val) abort
  return s:BigNum.sign(a:val) > 0 ? a:val : s:BigNum.neg(a:val)
endfunction

" fraction re-balance
" sign : first allocation time as v:none
" d    : if zero divid, return v:none(not Fraction object)
function s:_balance(fraction) abort
  let f = deepcopy(s:Fractions)
  let n = a:fraction.numerator
  let d = a:fraction.denominator
  let s = a:fraction.sign

  " check zero Fraction object
  " sign is able to v:none for first allocation time
  if (n is v:none) || (d is v:none)
    " sanity assign
    let f.numerator   = v:none
    let f.denominator = v:none
    let f.sign        = v:none

    return f
  endif

  " check zero divid
  if s:BigNum.sign(d) == 0
    " divid by zero
    return v:none
  endif

  " sign detect
  if s is v:none
    let s = (s:BigNum.sign(n) * s:BigNum.sign(d)) > 0 ? v:true : v:false
    let n = s:_bignum_abs(n)
    let d = s:_bignum_abs(d)
  endif

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
  let result = matchlist(a:strf, '\([-+0-9]\+\)/\([0-9]\+\)')

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
  throw 'vital: Math.Fractions: ' . a:msg
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
