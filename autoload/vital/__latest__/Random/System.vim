" random number generator using system source

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Prelude = s:V.import('Prelude')
  let s:Bitwise = s:V.import('Bitwise')
  let s:Process = s:V.import('System.Process')
  " Fallback
  let s:Mt      = s:V.import('Random.Mt19937ar')

  let s:allf32bit = s:Bitwise.or(
        \ s:Bitwise.lshift(0xFFFF, 16),
        \                  0xFFFF
        \)

  if exists('*rand')
      let s:Generator = deepcopy(s:Generator_vim_rand)
      let s:Generator.info.seed = srand()
  elseif s:Prelude.is_windows()
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
      else
        " nothing source
        let s:Generator = {}
      endif
    endif
  endif

  if empty(s:Generator)
    let s:Generator = s:Mt.new_generator()
  endif

  lockvar 3 s:Generator
endfunction

function! s:_vital_depends() abort
  return ['Prelude', 'Bitwise', 'System.Process', 'Random.Mt19937ar']
endfunction

let s:Generator = {}

" core
let s:Generator_core = {
      \ 'info' : {
      \   'max' : 0,
      \   'min' : 0,
      \ }
      \}

" next need implement

function! s:Generator_core.max() abort
  return self.info.max
endfunction

function! s:Generator_core.min() abort
  return self.info.min
endfunction

function! s:Generator_core.seed(...) abort
  " not work
endfunction

" Vim native implement
" max delay setup
" seed initial setup
let s:Generator_vim_rand = extend({
      \ 'info' : {
      \   'max' : 0,
      \   'min' : 0,
      \   'seed': [0, 0, 0, 0],
      \ }
      \}, s:Generator_core, 'keep')

function! s:Generator_vim_rand.next() abort
  return rand(self.info.seed)
endfunction

function! s:Generator_vim_rand.max() abort
  " delay setup
  if 0 == self.info.max
    " replace core method
    unlockvar 3 self
    let self.info.max = s:allf32bit
    let self.max = s:Generator_core.max
    lockvar 3 self
  endif
  return self.info.max
endfunction

function! s:Generator_vim_rand.seed(...) abort
  unlockvar 3 self
  if a:0 > 0
    let seeds = a:1
    if s:Prelude.is_number(seeds)
      let self.info.seed = srand(seeds)
    else " as List
      let self.info.seed = copy(seeds)
    endif
  else
    let self.info.seed = srand()
  endif
  lockvar 3 self
endfunction

" Windows cmd
let s:Generator_windows_cmd = extend({
      \ 'info' : {
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
      \ 'info' : {
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
      \ 'info' : {
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
      \ 'info' : {
      \   'path' : '',
      \   'max' : 0xffffffff,
      \   'min' : 0,
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
  call gen.seed()
  return gen
endfunction

function! s:_common_generator() abort
  if !exists('s:common_generator')
    let s:common_generator = s:new_generator()
  endif
  return s:common_generator
endfunction

function! s:srand(...) abort
  if a:0 > 0
    call s:_common_generator().seed(a:1)
  endif
endfunction

function! s:rand() abort
  return s:_common_generator().next()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
