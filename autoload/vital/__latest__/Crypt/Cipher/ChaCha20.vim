" ChaCha20: ChaCha20 stream cipher
" RFC 7539 https://www.rfc-editor.org/rfc/rfc7539.html

function! s:_vital_loaded(V) abort
  let s:V = a:V

  let s:Bitwise = s:V.import('Bitwise')
  let s:Type = s:V.import('Vim.Type')
  let s:List = s:V.import('Data.List')
  let s:ByteArray = s:V.import('Data.List.Byte')
endfunction

function! s:_vital_depends() abort
  return ['Bitwise', 'Vim.Type', 'Data.List', 'Data.List.Byte']
endfunction

let s:ChaCha20 = {
      \   '__type__': 'ChaCha20',
      \   '_dict': {
      \     'key': [],
      \     'nonce': [],
      \     'counter': 0,
      \   }
      \ }

" s:new() creates a new instance of ChaCha20 object.
" @param {key bytes list}, {nonce bytes list}
function! s:new(key, nonce) abort
  let chacha20 = deepcopy(s:ChaCha20)
  call call(chacha20.key, [a:key], chacha20)
  call call(chacha20.nonce, [a:nonce], chacha20)
  return chacha20
endfunction

function! s:ChaCha20.key(key) abort
  " TODO: implement key setup
  call s:_throw('not implemented')
endfunction

function! s:ChaCha20.nonce(nonce) abort
  " TODO: implement nonce setup
  call s:_throw('not implemented')
endfunction

function! s:ChaCha20.encrypt(data) abort
  " TODO: implement encryption
  call s:_throw('not implemented')
endfunction

function! s:ChaCha20.decrypt(data) abort
  " TODO: implement decryption (same as encrypt for stream cipher)
  call s:_throw('not implemented')
endfunction

function! s:_throw(message) abort
  throw 'vital: Crypt.Cipher.ChaCha20: ' . a:message
endfunction