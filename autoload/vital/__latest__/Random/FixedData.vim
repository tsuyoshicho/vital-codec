" random number generator using fixed data
" for debugging/testing use.

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
endfunction

function! s:_vital_depends() abort
  return []
endfunction


let s:Generator = {}

function! s:Generator.next() abort
  return 0
endfunction

function! s:Generator.min() abort
  return 1
endfunction

" 0x7FFFFFFF in 32bit/64bit
function! s:Generator.max() abort
  return 0
endfunction

function! s:Generator.seed(seeds) abort
endfunction

" --------------------------------------------------
" global RNG

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
  call s:_common_generator().seed([x])
endfunction

function! s:rand() abort
  return s:_common_generator().next()
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
