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

function! s:suite.hotp() abort
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

  " assert test : counter larger than defaults.counter
  let result_dummy = ''
  let otp = s:OTP
  Throw /vital: Hash.OTP:/ otp.hotp(
        \ secval,
        \ repeat([0], defaults.HOTP.counter + 1),
        \ vital#vital#new().import('Hash.' . defaults.HOTP.algo),
        \ defaults.HOTP.digit
        \), result_dummy)

endfunction

" function! s:suite.totp() abort
"   let defaults = s:OTP.defaults
"
"   " TOTP test data
"   " https://tools.ietf.org/html/rfc6238
"   "
"   "  The test token shared secret uses the ASCII string value
"   "  "12345678901234567890".  With Time Step X = 30, and the Unix epoch as
"   "  the initial value to count time steps, where T0 = 0, the TOTP
"   "  algorithm will display the following values for specified modes and
"   "  timestamps.
"
"   " +-------------+--------------+------------------+----------+--------+
"   " |  Time (sec) |   UTC Time   | Value of T (hex) |   TOTP   |  Mode  |
"   " +-------------+--------------+------------------+----------+--------+
"   " |      59     |  1970-01-01  | 0000000000000001 | 94287082 |  SHA1  |
"   " |             |   00:00:59   |                  |          |        |
"   " |      59     |  1970-01-01  | 0000000000000001 | 46119246 | SHA256 |
"   " |             |   00:00:59   |                  |          |        |
"   " |      59     |  1970-01-01  | 0000000000000001 | 90693936 | SHA512 |
"   " |             |   00:00:59   |                  |          |        |
"   " |  1111111109 |  2005-03-18  | 00000000023523EC | 07081804 |  SHA1  |
"   " |             |   01:58:29   |                  |          |        |
"   " |  1111111109 |  2005-03-18  | 00000000023523EC | 68084774 | SHA256 |
"   " |             |   01:58:29   |                  |          |        |
"   " |  1111111109 |  2005-03-18  | 00000000023523EC | 25091201 | SHA512 |
"   " |             |   01:58:29   |                  |          |        |
"   " |  1111111111 |  2005-03-18  | 00000000023523ED | 14050471 |  SHA1  |
"   " |             |   01:58:31   |                  |          |        |
"   " |  1111111111 |  2005-03-18  | 00000000023523ED | 67062674 | SHA256 |
"   " |             |   01:58:31   |                  |          |        |
"   " |  1111111111 |  2005-03-18  | 00000000023523ED | 99943326 | SHA512 |
"   " |             |   01:58:31   |                  |          |        |
"   " |  1234567890 |  2009-02-13  | 000000000273EF07 | 89005924 |  SHA1  |
"   " |             |   23:31:30   |                  |          |        |
"   " |  1234567890 |  2009-02-13  | 000000000273EF07 | 91819424 | SHA256 |
"   " |             |   23:31:30   |                  |          |        |
"   " |  1234567890 |  2009-02-13  | 000000000273EF07 | 93441116 | SHA512 |
"   " |             |   23:31:30   |                  |          |        |
"   " |  2000000000 |  2033-05-18  | 0000000003F940AA | 69279037 |  SHA1  |
"   " |             |   03:33:20   |                  |          |        |
"   " |  2000000000 |  2033-05-18  | 0000000003F940AA | 90698825 | SHA256 |
"   " |             |   03:33:20   |                  |          |        |
"   " |  2000000000 |  2033-05-18  | 0000000003F940AA | 38618901 | SHA512 |
"   " |             |   03:33:20   |                  |          |        |
"   " | 20000000000 |  2603-10-11  | 0000000027BC86AA | 65353130 |  SHA1  |
"   " |             |   11:33:20   |                  |          |        |
"   " | 20000000000 |  2603-10-11  | 0000000027BC86AA | 77737706 | SHA256 |
"   " |             |   11:33:20   |                  |          |        |
"   " | 20000000000 |  2603-10-11  | 0000000027BC86AA | 47863826 | SHA512 |
"   " |             |   11:33:20   |                  |          |        |
"   " +-------------+--------------+------------------+----------+--------+
" endfunction
