" random number generator using system source

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Prelude = s:V.import('Prelude')
  let s:Process = s:V.import('System.Process')
  let s:Type     = s:V.import('Vim.Type')
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
      let od = deepcopy(s:Generator_unix_od)
      if filereadable('/dev/urandom')
        let od.info.path = '/dev/urandom'
      elseif filereadable('/dev/random')
        let od.info.path = '/dev/random'
      endif
      if !empty(od.info.path)
        let s:Generator = od
      endif
    endif
  endif

  lockvar 3 s:Generator
  unlet! s:Prelude
endfunction

function! s:_vital_depends() abort
  return ['Prelude', 'Vim.Type', 'System.Process', 'Random.Xoshiro128StarStar']
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
" @vimlint(EVL103, 0, a:seeds)

function! s:Generator_core._exec(cmd, hexcount) abort
  let value = 0

  let result = s:Process.execute(a:cmd)
  if result.success
    let value = str2nr('0x' . trim(result.content[0]), a:hexcount)
  endif
  return value
endfunction

" Windows cmd
let s:Generator_windows_cmd = extend({
      \ 'core' : {
      \   'max' : 32767,
      \   'min' : 0,
      \ }
      \}, s:Generator_core, 'keep')

function! s:Generator_windows_cmd.next() abort
  return self._exec(['cmd', '/c', 'echo %random%'], 10)
endfunction

" Unix bash
let s:Generator_unix_bash = extend({
      \ 'core' : {
      \   'max' : 32767,
      \   'min' : 0,
      \ }
      \}, s:Generator_core, 'keep')

function! s:Generator_unix_bash.next() abort
  return self._exec(['bash', '-c', 'echo $RANDOM'], 10)
endfunction

" Unix openssl
let s:Generator_unix_openssl = extend({
      \ 'core' : {
      \   'max' : 0xffffffff,
      \   'min' : 0,
      \ }
      \}, s:Generator_core, 'keep')

function! s:Generator_unix_openssl.next() abort
  return self._exec(['openssl', 'rand', '-hex', '4'], 16)
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
  return self._exec(['od', '-vAn', '--width=4', '-tx4', '-N4', self.info.path], 16)
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
    let arg = [x]
  elseif a:0 == 1
    let x = a:1
    if type(x) == s:Type.types.list
      let arg = x
    else
      let arg = [x]
    endif
  else
    throw 'vital: Random.System: srand(): too many arguments'
  endif
  call s:_common_generator().seed(arg)
endfunction

function! s:rand() abort
  return s:_common_generator().next()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
