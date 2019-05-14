" Utilities for Base32.
" RFC 4648 http://tools.ietf.org/html/rfc4648.html

let s:save_cpo = &cpo
set cpo&vim

function! s:b32encode(bytes, table, is_padding, pad) abort
  let b32 = []
  for i in range(0, len(a:bytes) - 1, 5)
    if 5 <= ((len(a:bytes) - 1) - i)
      let n = a:bytes[i]               * 0x100000000
            \ + get(a:bytes, i + 1, 0) *   0x1000000
            \ + get(a:bytes, i + 2, 0) *     0x10000
            \ + get(a:bytes, i + 3, 0) *       0x100
            \ + get(a:bytes, i + 4, 0)
      let bitstring = printf('%040b',n)
    else
      let length = len(a:bytes) - i
      let n = a:bytes[i]
      for x in range(i + 1,(len(a:bytes) - 1))
        let n = (n * 0x100) + a:bytes[x]
      endfor
      let bitstring = printf('%0'. string(length*8) .'b',n)
      let zerocount = 5 - (len(bitstring) % 5)
      if 5 != zerocount
        for x in range(0, zerocount-1)
          let bitstring = bitstring . '0'
        endfor
      endif
    endif
    call map(split(bitstring, '.....\zs'),'add(b32, a:table[str2nr(v:val, 2)])')
  endfor
  if a:is_padding
    if 0 != len(b32) % 8
      let padlen = 8 - (len(b32) % 8)
      for i in range(0, padlen - 1)
        call add(b32, a:pad)
      endfor
    endif
  endif
  return b32
endfunction

function! s:b32decode(b32, map, is_padding, padcheck) abort
  let bytes = []
  for i in range(0, (len(a:b32) - 1), 8)
    let pack = repeat([0], 8)
    for j in range(8)
      if (len(a:b32) > (i + j)) && !a:padcheck(a:b32[i + j])
        let pack[j] = a:map[a:b32[i + j]]
      endif
    endfor
    let n = pack[0]   * 0x800000000
          \ + pack[1] *  0x40000000
          \ + pack[2] *   0x2000000
          \ + pack[3] *    0x100000
          \ + pack[4] *      0x8000
          \ + pack[5] *       0x400
          \ + pack[6] *        0x20
          \ + pack[7]
    call add(bytes, n / 0x100000000        )
    call add(bytes, n /   0x1000000 % 0x100)
    call add(bytes, n /     0x10000 % 0x100)
    call add(bytes, n /       0x100 % 0x100)
    call add(bytes, n               % 0x100)
    if !a:is_padding && ((len(a:b32) - 1) <  (i + 8))
      " manual nondata byte cut
      let nulldata = (i + 8) - (len(a:b32) - 1)
      if 1 == nulldata
        unlet bytes[-1]
      elseif 3 == nulldata
        unlet bytes[-1]
        unlet bytes[-1]
      elseif 4 == nulldata
        unlet bytes[-1]
        unlet bytes[-1]
        unlet bytes[-1]
      elseif 6 == nulldata
        unlet bytes[-1]
        unlet bytes[-1]
        unlet bytes[-1]
        unlet bytes[-1]
      endif
    endif
  endfor
  if a:is_padding
    if a:padcheck(a:b32[-1])
      unlet bytes[-1]
    endif
    if a:padcheck(a:b32[-3])
      unlet bytes[-1]
    endif
    if a:padcheck(a:b32[-4])
      unlet bytes[-1]
    endif
    if a:padcheck(a:b32[-6])
      unlet bytes[-1]
    endif
  endif
  return bytes
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
