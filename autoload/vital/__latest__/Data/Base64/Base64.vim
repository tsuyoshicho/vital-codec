" Utilities for Base64.
" RFC 4648 http://tools.ietf.org/html/rfc4648.html

let s:save_cpo = &cpo
set cpo&vim

function! s:b64encode(bytes, table, is_padding, pad) abort
  let b64 = []
  for i in range(0, len(a:bytes) - 1, 3)
    let n = a:bytes[i] * 0x10000
          \ + get(a:bytes, i + 1, 0) * 0x100
          \ + get(a:bytes, i + 2, 0)
    call add(b64, a:table[n / 0x40000])
    call add(b64, a:table[n / 0x1000 % 0x40])
    call add(b64, a:table[n / 0x40 % 0x40])
    call add(b64, a:table[n % 0x40])
  endfor
  if a:is_padding
    if len(a:bytes) % 3 == 1
      let b64[-1] = a:pad
      let b64[-2] = a:pad
    endif
    if len(a:bytes) % 3 == 2
      let b64[-1] = a:pad
    endif
  endif
  return b64
endfunction

function! s:b64decode(b64, map, is_padding, padcheck) abort
  let bytes = []
  for i in range(0, len(a:b64) - 1, 4)
    let n = a:map[a:b64[i]] * 0x40000
          \ + a:map[a:b64[i + 1]] * 0x1000
          \ + (a:b64[i + 2] == a:pad ? 0 : a:map[a:b64[i + 2]]) * 0x40
          \ + (a:b64[i + 3] == a:pad ? 0 : a:map[a:b64[i + 3]])
    call add(bytes, n / 0x10000)
    call add(bytes, n / 0x100 % 0x100)
    call add(bytes, n % 0x100)
    if !a:is_padding && ((len(a:b64) - 1) <  (i + 4))
      " manual nondata byte cut
      let nulldata = (i + 4) - (len(a:b64) - 1)
      if 1 == nulldata
        unlet bytes[-1]
      elseif 2 == nulldata
        unlet bytes[-1]
        unlet bytes[-1]
      endif
    endif
  endfor
  if a:is_padding
    if a:b64[-1] == a:pad
      unlet bytes[-1]
    endif
    if a:b64[-2] == a:pad
      unlet bytes[-1]
    endif
  endif
  return bytes
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
