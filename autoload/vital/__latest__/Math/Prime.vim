" Prime

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:B = s:V.import('Bitwise')
endfunction

function! s:_vital_depends() abort
  return ['Bitwise']
endfunction

" public API
function! s:is_prime(val) abort
  call s:_Sieve_of_Eratosthenes(a:val)
  return s:_is_prime(a:val)
endfunction

function! s:prime_list(max) abort
  call s:_Sieve_of_Eratosthenes(a:max)
  return s:_prime_list(a:max)
endfunction

" Sieve of Eratosthenes
let s:calculated_maximum = 0
" max is 2^3 x n size limiting, there are status already calculated.
let s:calculated_status  = []
" status list
"  [0] = 0b00000000 1 byte data that is num idx 0-7 prime flag 1 is prmime/0 is not prime
"  [1]
"  ...
"  [n]
let s:BOX_SIZE = 8    " bit length
let s:BOX_MASK = 0xff " 0b11111111  mask and fill value
lockvar 1 s:BOX_SIZE
lockvar 1 s:BOX_MASK

function! s:_Sieve_of_Eratosthenes(max) abort
  if a:max < 0
    call s:_throw('work only positive value')
  endif
  let max = s:_int_ceil(a:max, s:BOX_SIZE)
  let min = s:calculated_maximum

  " fill s:BOX_MASK to max
  if (max - min) > 0
    call extend(s:calculated_status, repeat([s:BOX_MASK], (max - min + 1) / s:BOX_SIZE))
    if min == 0
      call s:_set_prime(0, v:false)
      call s:_set_prime(1, v:false)
    endif
  else
    return
  endif

  " 1. 0 to min already calculated, check multiple for min - max values.
  for idx in range(0, max - 1, s:BOX_SIZE)
    for i in range(s:BOX_SIZE)
      let now = idx + i
      if s:_is_prime(now)
        if (now * now) < (max - 1)
          for v in range(now * now, max - 1, now)
            if v < min
              " skip
            else
              " set non prime
              call s:_set_prime(v, v:false)
            endif
          endfor
        endif
      endif
    endfor
  endfor

  let s:calculated_maximum = max
endfunction

" inner function
function! s:_is_prime(val) abort
  if 0 == a:val || 1 == a:val
    return v:false
  endif

  let idx = a:val / s:BOX_SIZE
  let offset = a:val % s:BOX_SIZE

  let box = get(s:calculated_status, idx, v:none)
  if box is v:none
    call s:_throw('Do not calculated')
    " call s:_throw(join(['Do not calculated', string(a:val), string(idx), string(offset), string(s:calculated_maximum), string(s:calculated_status)], ' '))
  endif

  return s:B.and(box, s:B.lshift(1, offset)) ? v:true : v:false
endfunction

function! s:_set_prime(val, is_prime) abort
  let idx = a:val / s:BOX_SIZE
  let offset = a:val % s:BOX_SIZE

  let box = get(s:calculated_status, idx, v:none)
  if box is v:none
    call s:_throw('Do not calculated')
    " call s:_throw(join(['Do not calculated', string(a:val), string(idx), string(offset), string(s:calculated_maximum), string(s:calculated_status)], ' '))
  endif

  if a:is_prime
    " s:BOX_MASK & (box | 0x..1..)
    let s:calculated_status[idx] = s:B.and(s:BOX_MASK, s:B.or(box, s:B.lshift(1, offset)))
  else
    " s:BOX_MASK & (box & not 0x..1..)
    let s:calculated_status[idx] = s:B.and(s:BOX_MASK, s:B.and(box, s:B.invert(s:B.lshift(1, offset))))
  endif
endfunction

function! s:_prime_list(max) abort
  let prime_list = []
  call map(range(len(s:calculated_status)), { k,v -> extend(prime_list, s:_box_list(k))})
  call filter(prime_list, { k,v -> v <= a:max })
  return prime_list
endfunction

function! s:_box_list(k) abort
  let sub_prime_list = []
  let box = s:calculated_status[a:k]
  for i in range(s:BOX_SIZE)
    if s:B.and(box, s:B.lshift(1, i))
      call add(sub_prime_list,  a:k * s:BOX_SIZE + i)
    endif
  endfor
  return sub_prime_list
endfunction

function! s:_int_ceil(val, step) abort
  if a:val < 0
    throw 'under zero'
  endif
  if a:val == 0
    return 0
  endif
  return a:step * ((a:val / a:step) + 1)
endfunction

" throw
function! s:_throw(msg) abort
  throw 'vital: Math.Prime: ' . a:msg
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:

