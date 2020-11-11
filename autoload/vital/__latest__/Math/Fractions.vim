" Utilities for UUID
" RFC 4122 - A Universally Unique IDentifier (UUID) URN Namespace https://tools.ietf.org/html/rfc4122

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

" Constractor
function! s:new(...) abort
  " check 3 or more, support 0,1,2
  if 2 < a:0
    call s:_throw('Unsupport arguments count:' . string(a:0))
  endif

  let f = deepcopy(s:Fractions)
  if 0 == a:0
    let n = s:BigNum.from_num(1)
    let d = s:BigNum.from_num(1)
    let s = v:true
  else
    if s:P.is_number(a:1)
      let n = s:BigNum.from_num(a:1)
    elseif s:P.is_string(a:1)
      let n = s:BigNum.from_string(a:1)
    else
      call s:_throw('Unsupport type error arg:1 type:' . string(type(a:1)))
    endif
    if 1 == a:0
      let d = s:BigNum.from_num(1)
    elseif 2 == a:0
      if s:P.is_number(a:2)
        let n = s:BigNum.from_num(a:2)
      elseif s:P.is_string(a:2)
        let n = s:BigNum.from_string(a:2)
      else
        call s:_throw('Unsupport type error arg:2 type:' . string(type(a:2)))
      endif

      if 0 == s:BigNum.sign(d)
        call s:_throw('Divid Zero Exception')
      endif
      if 0 == s:BigNum.sign(n)
        let n = v:none
        let d = v:none
      endif
    endif

    if (n isnot v:none) && (d isnot v:none)
      let s = (s:BigNum.sign(n) * s:BigNum.sign(d)) ? v:true : v:false
      let n = s:BigNum.sign(n) ? n : s:BigNum.neg(n)
      let d = s:BigNum.sign(d) ? d : s:BigNum.neg(d)
    else
      let s = v:none
    endif
  endif

  f.numerator   = n
  f.denominator = d
  f.sign        = s
  return f
endfunction

function! s:from_string(strf) abort
  if !s:P.is_string(a:strf)
    call s:_throw('Invalid argument type:' . string(type(a:strf)) . '/value:' . string(a:strf))
  endif
  " split
  let result = matchlist(a:strf, '\([-+0-9]\+\)/\([0-9]\+\)')

  " split error check
  if !empty(result[1]) && !empty(result[2])
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
