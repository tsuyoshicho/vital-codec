" random number generator using system source

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Prelude = s:V.import('Prelude')
  let s:Process = s:V.import('System.Process')
endfunction

function! s:_vital_depends() abort
  return ['Prelude', 'System.Process']
endfunction

let s:Generator = {}

function! s:Generator.next() abort
  let cmd = []
  let value = 0

  if s:Prelude.is_windows()
    let cmd = ['echo', '%random%']
    let result = s:Process.execute(cmd)
    if result.success
      let value = str2nr('0x' . trim(split(result.output, '\n')[0]), 10)
    endif
  else
    if executable('openssl')
      let cmd = ['openssl', 'rand', '-hex', '4']
      let result = s:Process.execute(cmd)
    elseif executable('od')
      if filereadable('/dev/urandom')
        let cmd = ['od', '-vAn', '--width=4', '-tx4', '-N4', '/dev/urandom']
        let result = s:Process.execute(cmd)
      elseif filereadable('/dev/random')
        let cmd = ['od', '-vAn', '--width=4', '-tx4', '-N4', '/dev/random']
        let result = s:Process.execute(cmd)
      endif
    endif
    if !empty(cmd)
      if result.success
        let value = str2nr('0x' . trim(split(result.output, '\n')[0]), 16)
      endif
    else
      " error
    endif
  endif
  return value
endfunction

function! s:Generator.min() abort
  if !exists('s:min')
    if s:Prelude.is_windows()
      let s:min = 0
    else
      let s:min = 0
    endif
  endif
  return s:min
endfunction

function! s:Generator.max() abort
  if !exists('s:max')
    if s:Prelude.is_windows()
      let s:max = 32767
    else
      let s:max = 0xffffffff
    endif
  endif
  return s:max
endfunction

function! s:Generator.seed(seeds) abort
  " not work
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
  " not work
endfunction

function! s:rand() abort
  return s:_common_generator().next()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
