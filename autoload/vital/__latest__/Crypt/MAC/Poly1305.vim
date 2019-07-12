" Poly1305
" RFC 7539 - ChaCha20 and Poly1305 for IETF Protocols https://tools.ietf.org/html/rfc7539

function! s:_vital_loaded(V) abort
  let s:V = a:V

  let s:bitwise = s:V.import('Bitwise')
  let s:List = s:V.import('Data.List')
  let s:ByteArray = s:V.import('Data.List.Byte')
endfunction

function! s:_vital_depends() abort
  return ['Bitwise', 'Data.List', 'Data.List.Byte']
endfunction

let s:Poly1305 = {
      \   '__type__': 'Poly1305',
      \   '_dict': {
      \     'crypt' : v:null,
      \     'key'   : v:null,
      \   }
      \ }

" s:new() creates a new instance of Poly1305 object.
" @param {crypt object},{key string|bytes list}
function! s:new(...) abort
  if a:0 > 2
    call s:_throw(printf('.new() expected at most 2 arguments, got %d', a:0))
  endif
  let poly1305 = deepcopy(s:Poly1305)
  if a:0 is# 1
    call call(poly1305.crypt, [a:1], poly1305)
  elseif a:0 is# 2
    call call(poly1305.crypt, [a:1], poly1305)
    call call(poly1305.key,   [a:2], poly1305)
  endif
  return poly1305
endfunction

function! s:Poly1305.key(key) abort
  if type(a:key) is# type([])
    let self._dict['key'] = a:key
  elseif type(a:key) is# type('')
    let self._dict['key'] = s:ByteArray.from_string(a:key)
  else
    call s:_throw('given argument is not key data')
  endif
endfunction

function! s:Poly1305.crypt(obj) abort
  if type(a:obj) is# type({})
        \ && has_key(a:obj,'encrypt')
        \ && type(a:obj.encrypt) is# type(function('tr'))
    let self._dict['crypt'] = a: obj
  else
    call s:_throw('given argument is not Crypt API object')
  endif
endfunction

function! s:Poly1305.calc(data) abort
  return digest
endfunction

function! s:Poly1305.mac(data) abort
  return s:ByteArray.to_hexstring(self.calc(a:data))
endfunction

function! s:Poly1305.poly1305(data) abort
  return self.mac(a:data)
endfunction

function! s:_throw(message) abort
  throw 'vital: Crypt.MAC.HMAC: ' . a:message
endfunction
