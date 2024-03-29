" HMAC: Keyed-Hashing for Message Authentication
" RFC 2104 https://tools.ietf.org/html/rfc2104

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

let s:HMAC = {
      \   '__type__': 'HMAC',
      \   '_dict': {
      \     'hash': {},
      \     'key' : [],
      \   }
      \ }

" s:new() creates a new instance of HMAC object.
" @param {hash object},{key string|bytes list}
function! s:new(...) abort
  if a:0 > 2
    call s:_throw(printf('.new() expected at most 2 arguments, got %d', a:0))
  endif
  let hmac = deepcopy(s:HMAC)
  if a:0 is# 1
    call call(hmac.hash, [a:1], hmac)
  elseif a:0 is# 2
    call call(hmac.hash, [a:1], hmac)
    call call(hmac.key,  [a:2], hmac)
  endif
  return hmac
endfunction

function! s:HMAC.key(key) abort
  let keytype = type(a:key)

  if keytype == s:Type.types.list
    let self._dict.key = a:key
  elseif keytype == s:Type.types.string
    let self._dict.key = s:ByteArray.from_string(a:key)
  elseif keytype == s:Type.types.blob
    let self._dict.key = s:ByteArray.from_blob(a:key)
  else
    call s:_throw('given argument is not key data')
  endif
endfunction

function! s:HMAC.hash(hashobj) abort
  if type(a:hashobj) == s:Type.types.dict
        \ && has_key(a:hashobj,'digest_raw')
        \ && type(a:hashobj.digest_raw) == s:Type.types.func
    let self._dict.hash = a:hashobj
  else
    call s:_throw('given argument is not HASH API object')
  endif
endfunction

function! s:HMAC.calc(data) abort
  let datatype = type(a:data)

  if datatype == s:Type.types.list
    let data = a:data
  elseif datatype == s:Type.types.string
    let data = s:ByteArray.from_string(a:data)
  elseif datatype == s:Type.types.blob
    let data = s:ByteArray.from_blog(a:data)
  else
    call s:_throw('given argument is not valid data')
  endif

  let key  = self._dict.key
  let hash = self._dict.hash

  if empty(key) || empty(hash)
    call s:_throw('setup invalid key or hashobj')
  endif

  if len(key) > 64
    let key = hash.digest_raw(key)
  endif

  let ipad = s:List.new(64, {-> 0})
  let opad = s:List.new(64, {-> 0})

  for i in range(len(key))
    let ipad[i] = key[i]
    let opad[i] = key[i]
  endfor

  for i in range(64)
    let ipad[i] = s:Bitwise.xor(ipad[i],0x36)
    let opad[i] = s:Bitwise.xor(opad[i],0x5c)
  endfor

  let digest = hash.digest_raw(ipad + data)
  let digest = hash.digest_raw(opad + digest)

  return digest
endfunction

function! s:HMAC.mac(data) abort
  return s:ByteArray.to_hexstring(self.calc(a:data))
endfunction

function! s:HMAC.hmac(data) abort
  return self.mac(a:data)
endfunction

function! s:_throw(message) abort
  throw 'vital: Crypt.MAC.HMAC: ' . a:message
endfunction
