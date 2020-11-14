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

  " Rational object prototype and default feild
  " 'sign' v:true + / v:false -  / v:none is 0
  " data = numerator / denominator
  " default 0/1 v:none : zero
  let s:Rational = extend(s:R, {
    \  '_dict'       : {
    \    'numerator'   : s:ZERO_NUM,
    \    'denominator' : s:ONE_NUM,
    \    'sign'        : v:none,
    \  }
    \}, 'force')
  lockvar 3 s:Rational

  let s:ZERO = s:Rational
  " lockvar 3 s:ZERO
  " already locked

  let s:ONE = deepcopy(s:Rational)
  let s:ONE._dict['numerator'] = s:ONE_NUM
  let s:ONE._dict['sign']      = v:true
  lockvar 3 s:ONE
endfunction

function! s:_vital_depends() abort
  return ['Prelude', 'Math', 'Data.BigNum']
endfunction

" Rational object method
let s:R = {
  \  '__type__'    : 'Rational',
  \  '_dict'       : {
  \    'numerator'   : v:none,
  \    'denominator' : v:none,
  \    'sign'        : v:none,
  \  },
  \}

" add
function! s:R.add(data) abort
  let data = s:_cast(a:data)

  let selfsign = self.sign()
  let datasign = data.sign()
  " self or other is zero, ret other obj
  if selfsign == 0
    return data
  endif
  if datasign == 0
    return self
  endif

  let selfnum = s:BigNum.mul(self._dict['numerator'], data._dict['denominator'])
  if selfsign < 0
    let selfnum = s:BigNum.neg(selfnum)
  endif

  let datanum = s:BigNum.mul(data._dict['numerator'], self._dict['denominator'])
  if datasign < 0
    let datanum = s:BigNum.neg(datanum)
  endif

  let num = s:BigNum.add(selfnum, datanum)

  let deno = s:BigNum.mul(self._dict['denominator'], data._dict['denominator'])

  return s:_generate(num, deno)
endfunction

" sub
function! s:R.sub(data) abort
  let data = s:_cast(a:data)

  return self.add(data.neg())
endfunction

" mul
function! s:R.mul(data) abort
  let data = s:_cast(a:data)

  let selfsign = self.sign()
  let datasign = data.sign()
  " self or other is zero, ret zero
  if (selfsign * selfsign) == 0
    return s:ZERO
  endif

  let sign = selfsign * datasign
  let num = s:BigNum.mul(self._dict['numerator'], data._dict['numerator'])
  if sign < 0
    let num = s:BigNum.neg(num)
  endif

  let deno = s:BigNum.mul(self._dict['denominator'], data._dict['denominator'])

  return s:_generate(num, deno)
endfunction

" div
function! s:R.div(data) abort
  let data = s:_cast(a:data)

  if data.sign() ==0
    call s:_throw('Divid by Zero Exception')
  endif

  return self.mul(data.rec())
endfunction

" reciprocal
function! s:R.rec() abort
  let data = self

  if self.sign() != 0
    let data = deepcopy(self)
    let [data._dict['numerator'], data._dict['denominator']] = [data._dict['denominator'], data._dict['numerator']]
    lockvar 3 data
  endif

  return data
endfunction

" sign
function! s:R.sign() abort
  let sign = 0
  if self._dict['sign'] isnot v:none
    let sign = self._dict['sign'] ? 1 : -1
  endif

  return sign
endfunction

" neg
function! s:R.neg() abort
  let a = self
  if a._dict['sign'] isnot v:none
    let a = deepcopy(a)
    let a._dict['sign'] = !a._dict['sign']
    lockvar 3 a
  endif

  return a
endfunction

" numerator
function! s:R.numerator() abort
  return self._dict['numerator']
endfunction

" denominator
function! s:R.denominator() abort
  return self._dict['denominator']
endfunction

" to_float
function! s:R.to_float() abort
  let sign = self.sign()
  return s:_div_float(sign, self._dict['numerator'], self._dict['denominator'])
endfunction

" floor
function! s:R.floor() abort
  let sign = self.sign()
  return s:_div_rounding(sign, self._dict['numerator'], self._dict['denominator'], function('floor'))
endfunction

" ceil
function! s:R.ceil() abort
  let sign = self.sign()
  return s:_div_rounding(sign, self._dict['numerator'], self._dict['denominator'], function('ceil'))
endfunction

" round
function! s:R.round() abort
  let sign = self.sign()
  return s:_div_rounding(sign, self._dict['numerator'], self._dict['denominator'], function('round'))
endfunction

" to string
function! s:R.to_string() abort
  if 0 == s:BigNum.compare(self._dict['denominator'], s:ONE_NUM)
    " non Rational
    return printf('%s%s',
      \  self._dict['sign'] is v:false ? '-' : '',
      \  s:BigNum.to_string(self._dict['numerator'])
      \)
  else
    return printf('%s%s/%s',
      \  self._dict['sign'] is v:false ? '-' : '',
      \  s:BigNum.to_string(self._dict['numerator']),
      \  s:BigNum.to_string(self._dict['denominator'])
      \)
  endif
endfunction

" inner function
" check type
function! s:_is(r) abort
  return s:P.is_dict(a:r)
    \ && s:P.is_string(get(a:r, '__type__', v:none))
    \ && (s:Rational['__type__'] ==# get(a:r, '__type__', ''))
endfunction

" cast to Rational
function! s:_cast(data) abort
  if s:_is(a:data)
    return a:data
  else
    return s:_generate(a:data, 1)
  endif
endfunction

" throw
function! s:_throw(msg) abort
  throw 'vital: Math.Fraction: ' . a:msg
endfunction

" generate from valid data type data(num,string and BigNum)
function! s:_generate(num, deno) abort
  let r = deepcopy(s:Rational)
  let r._dict['numerator']   = s:_of(a:num)
  let r._dict['denominator'] = s:_of(a:deno)

  return s:_balance(r)
endfunction

" bignum create wrapper
" use add(a, ZERO) add support num,string and BigNum
function! s:_of(data) abort
    return s:BigNum.add(a:data, s:ZERO_NUM)
endfunction

" bignum abs
function! s:_abs(val) abort
  return s:BigNum.sign(a:val) > 0 ? a:val : s:BigNum.neg(a:val)
endfunction

" bignum div to float
function! s:_div_float(s, n, d) abort
  if a:s == 0
    return 0.0
  endif
  let n = str2float(s:BigNum.to_storing(a:n))
  let d = str2float(s:BigNum.to_storing(a:d))
  return (a:s * n / d)
endfunction

" bignum div to round/floor/ceil
function! s:_div_rounding(s, n, d, fn) abort
  if a:s == 0
    return 0
  endif
  return float2nr(a:fn(s:_div_float(a:s, a:n, a:d)))
endfunction

" bignum gcd
" return v:none do not have gcd
"        bignum gcd
" bignum immutable object = do not need copy
function! s:_gcd(a, b) abort
  let gcd = v:none
  let [a, b] = [a:a, a:b]

  if (s:BigNum.sign(a) == 0) || (s:BigNum.sign(b) == 0)
    " 0 and other do not have gcd
    return gcd
  endif

  let a = s:_abs(a)
  let b = s:_abs(b)

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
" d    : if zero divid, return v:none(not Fraction object)
function! s:_balance(r) abort
  if !s:_is(a:r)
    call s:_throw('Not Rational input:' . string(a:r))
  endif

  let n = a:r._dict['numerator']
  let d = a:r._dict['denominator']
  let s = a:r._dict['sign']

  " check zero divid
  if s:BigNum.sign(d) == 0
    " divid by zero
    return v:none
  endif

  " check zero Rational object
  "  0/n +/- -> 0/1 +
  if s:BigNum.sign(n) == 0
    return s:ZERO
  endif

  let oldsign    = s is v:none ? v:true : s
  let detectsign = ((s:BigNum.sign(n) * s:BigNum.sign(d)) > 0) ? v:true : v:false
  let s = (oldsign is detectsign) ? v:true : v:false
  let n = s:_abs(n)
  let d = s:_abs(d)

  " re-balance
  let gcd = s:_gcd(n, d)
  if gcd isnot v:none
    let n = s:BigNum.div(n, gcd)
    let d = s:BigNum.div(d, gcd)
  endif

  let r = deepcopy(s:Rational)
  let r._dict['numerator']   = n
  let r._dict['denominator'] = d
  let r._dict['sign']        = s
  lockvar 3 r
  return r
endfunction

" Constractor
" arg count 0: ZERO Rational
" arg count 1: n/1  Rational
" arg count 2: n/m  Rational
function! s:new(...) abort
  " check 3 or more, support 0,1,2
  if 2 < a:0
    call s:_throw('Unsupport arguments count:' . string(a:0))
  endif

  let r = s:ZERO

  if 0 != a:0
    let n = 0
    let d = 1

    if s:P.is_number(a:1) || s:P.is_string(a:1)
      let n = a:1
    else
      call s:_throw('Unsupport type error arg:1 type:' . string(type(a:1)))
    endif

    if 2 == a:0
      if s:P.is_number(a:2) || s:P.is_string(a:2)
        let d = a:2
      else
        call s:_throw('Unsupport type error arg:2 type:' . string(type(a:2)))
      endif
    endif

    let r = s:_generate(n, d)

    if r is v:none
      call s:_throw('Divid by Zero Exception')
    endif
  endif

  return r
endfunction

function! s:from_string(strf) abort
  if !s:P.is_string(a:strf)
    call s:_throw('Invalid argument type:' . string(type(a:strf)) . '/value:' . string(a:strf))
  endif
  " split
  " 0 total
  " 1 numerator
  " 2 /denominator
  " 3 denominator
  let result = matchlist(a:strf, '\([-+]\?\d\+\)\(/\([-+]\?\d\+\)\)\?')

  " split error check
  if empty(result[1])
    call s:_throw('Invalid format string:' . a:strf)
  endif

  let n = result[1]
  let d = empty(result[3]) ? '1' : result[3]

  " create
  return s:new(n, d)
endfunction

" API
" add
function! s:add(a, b) abort
  let a = s:_cast(a:a)

  return a.add(a:b)
endfunction

" sub
function! s:sub(a, b) abort
  let a = s:_cast(a:a)

  return a.sub(a:b)
endfunction

" mul
function! s:mul(a, b) abort
  let a = s:_cast(a:a)

  return a.mul(a:b)
endfunction

" div
function! s:div(a, b) abort
  let a = s:_cast(a:a)

  return a.div(a:b)
endfunction

" reciprocal
function! s:rec(a) abort
  let a = s:_cast(a:a)

  return a.rec()
endfunction


" sign
function! s:sign(a) abort
  let a = s:_cast(a:a)

  return a.sign()
endfunction

" neg
function! s:neg(a) abort
  let a = s:_cast(a:a)

  return a.neg()
endfunction

" numerator
function! s:numerator(a) abort
  let a = s:_cast(a:a)

  return a.numerator()
endfunction

" denominator
function! s:denominator(a) abort
  let a = s:_cast(a:a)

  return a.denominator()
endfunction

" to_float
function! s:to_float(a) abort
  let a = s:_cast(a:a)

  return a.to_float()
endfunction

" floor
function! s:floor(a) abort
  let a = s:_cast(a:a)

  return a.floor()
endfunction

" ceil
function! s:ceil(a) abort
  let a = s:_cast(a:a)

  return a.ceil()
endfunction

" round
function! s:round(a) abort
  let a = s:_cast(a:a)

  return a.round()
endfunction

" to string
function! s:to_string(a) abort
  let a = s:_cast(a:a)

  return a.to_string()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
