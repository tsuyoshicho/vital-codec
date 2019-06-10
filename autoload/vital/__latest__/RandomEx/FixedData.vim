" random number generator using fixed data
" for debugging/testing use.

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V    = a:V
  let s:type = s:V.import('Vim.Type')
endfunction

function! s:_vital_depends() abort
  return ['Vim.Type']
endfunction

let s:Generator = {
      \ 'data' : [0],
      \ 'index': 0,
      \ 'len'  : 1,
      \ 'max'  : 0,
      \ 'min'  : 0,
      \}

function! s:Generator.next() dict abort
  " current index
  let index = self.index

  " next index
  let self.index = (index + 1) % self.len

  return self.index[index]
endfunction

function! s:Generator.min() dict abort
  return self.min
endfunction

function! s:Generator.max() dict abort
  return self.max
endfunction

function! s:Generator.seed(...) dict abort
  if a:0 > 0
    let typeval = type(a:1)
    if typeval == s:type.types.number
      let data = [a:1]
    elseif typeval == s:type.types.list
      let data = a:1
    endif
  endif

  if !exists('data') || 0 == len(data)
    let data = [0]
  endif

  let self.data = data
  let self.index = 0
  let self.len = len(data)
  let self.max = max(data)
  let self.min = min(data)
endfunction

" --------------------------------------------------
" global RNG

function! s:new_generator() abort
  let gen = deepcopy(s:Generator)
  call gen.seed([0])
  return gen
endfunction

function! s:_common_generator() abort
  if !exists('s:common_generator')
    let s:common_generator = s:new_generator()
  endif
  return s:common_generator
endfunction

function! s:srand(...) abort
  call s:_common_generator().seed(a:000)
endfunction

function! s:rand() abort
  return s:_common_generator().next()
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
