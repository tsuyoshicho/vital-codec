" random number generator using system source

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Prelude = s:V.import('Prelude')
  let s:Process = s:V.import('System.Process')
  " Fallback
  let s:Xoshiro128StarStar = s:V.import('Random.Xoshiro128StarStar')

  " fallback
  let s:Generator = s:Xoshiro128StarStar.new_generator()
  if s:Prelude.is_windows()
    if executable('cmd')
      let s:Generator = deepcopy(s:Generator_windows_cmd)
    endif
  else
    if executable('bash')
      let s:Generator = deepcopy(s:Generator_unix_bash)
    elseif executable('openssl')
      let s:Generator = deepcopy(s:Generator_unix_openssl)
    elseif executable('od')
      let s:Generator = deepcopy(s:Generator_unix_od)
      if filereadable('/dev/urandom')
        let s:Generator.info.path = '/dev/urandom'
      elseif filereadable('/dev/random')
        let s:Generator.info.path = '/dev/random'
      endif
    endif
  endif

  lockvar 3 s:Generator
endfunction

function! s:_vital_depends() abort
  return ['Prelude', 'System.Process', 'Random.Xoshiro128StarStar']
endfunction

" core
let s:Generator_core = {
      \ 'core' : {
      \   'max' : 0,
      \   'min' : 0,
      \ }
      \}

" next need implement

function! s:Generator_core.max() abort
  return self.core.max
endfunction

function! s:Generator_core.min() abort
  return self.core.min
endfunction

" @vimlint(EVL103, 1, a:seeds)
function! s:Generator_core.seed(seeds) abort
  " not work
endfunction

" Windows cmd
let s:Generator_windows_cmd = extend({
      \ 'core' : {
      \   'max' : 32767,
      \   'min' : 0,
      \ }
      \}, s:Generator_core, 'keep')

function! s:Generator_windows_cmd.next() abort
  let value = 0

  let cmd = ['cmd', '/c', 'echo %random%']
  let result = s:Process.execute(cmd)
  if result.success
    let value = str2nr('0x' . trim(result.content[0]), 10)
  endif
  return value
endfunction

" Unix bash
let s:Generator_unix_bash = extend({
      \ 'core' : {
      \   'max' : 32767,
      \   'min' : 0,
      \ }
      \}, s:Generator_core, 'keep')

function! s:Generator_unix_bash.next() abort
  let value = 0

  let cmd = ['bash', '-c', 'echo $RANDOM']
  let result = s:Process.execute(cmd)
  if result.success
    let value = str2nr('0x' . trim(result.content[0]), 10)
  endif
  return value
endfunction

" Unix openssl
let s:Generator_unix_openssl = extend({
      \ 'core' : {
      \   'max' : 0xffffffff,
      \   'min' : 0,
      \ }
      \}, s:Generator_core, 'keep')

function! s:Generator_unix_openssl.next() abort
  let value = 0

  let cmd = ['openssl', 'rand', '-hex', '4']
  let result = s:Process.execute(cmd)
  if result.success
    let value = str2nr('0x' . trim(result.content[0]), 16)
  endif
  return value
endfunction

" Unix od
let s:Generator_unix_od = extend({
      \ 'core' : {
      \   'max' : 0xffffffff,
      \   'min' : 0,
      \ },
      \ 'info' : {
      \   'path' : '',
      \ }
      \}, s:Generator_core, 'keep')

function! s:Generator_unix_od.next() abort
  let value = 0

  let cmd = ['od', '-vAn', '--width=4', '-tx4', '-N4', self.info.path]
  let result = s:Process.execute(cmd)
  if result.success
    let value = str2nr('0x' . trim(result.content[0]), 16)
  endif
  return value
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
  if a:0 == 0
    let x = has('reltime') ? reltime()[1] : localtime()
  elseif a:0 == 1
    let x = a:1
  else
    throw 'vital: Random.System: srand(): too many arguments'
  endif
  call s:_common_generator().seed([x])
endfunction

function! s:rand() abort
  return s:_common_generator().next()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
