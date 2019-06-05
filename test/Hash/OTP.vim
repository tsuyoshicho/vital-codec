let s:suite = themis#suite('Hash.OTP')
let s:assert = themis#helper('assert')

function! s:suite.before()
  let s:OTP  = vital#vital#new().import('Hash.OTP')
  let s:SHA1 = vital#vital#new().import('Hash.SHA1')
endfunction

function! s:suite.after()
  unlet s:OTP
  unlet s:SHA1
endfunction

function! s:suite.htop() abort
  let defaults = s:OTP.defaults

  " HOTP test data
  " https://tools.ietf.org/html/rfc4226
  " Secret = 0x3132333435363738393031323334353637383930
  let secval = [
       \ 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30,
       \ 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30,
       \ ]
  "                        Truncated
  "  Count    Hexadecimal    Decimal        HOTP
  "  0        4c93cf18       1284755224     755224
  "  1        41397eea       1094287082     287082
  "  2         82fef30        137359152     359152
  "  3        66ef7655       1726969429     969429
  "  4        61c5938a       1640338314     338314
  "  5        33c083d4        868254676     254676
  "  6        7256c032       1918287922     287922
  "  7         4e5b397         82162583     162583
  "  8        2823443f        673399871     399871
  "  9        2679dc69        645520489     520489

  let result = [
        \ '755224',
        \ '287082',
        \ '359152',
        \ '969429',
        \ '338314',
        \ '254676',
        \ '287922',
        \ '162583',
        \ '399871',
        \ '520489',
        \]

  for i in range(10)
    call s:assert.equal(s:OTP.hotp(
          \ secval,
          \ [i],
          \ vital#vital#new().import('Hash.' . defaults.HOTP.algo),
          \ defaults.HOTP.digit
          \), result[i])
  endfor

endfunction

