" Utilities for UUID
" RFC 9562 - A Universally Unique IDentifier (UUID) URN Namespace https://www.rfc-editor.org/rfc/rfc9562

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V         = a:V
  let s:Bitwise   = s:V.import('Bitwise')
  let s:List      = s:V.import('Data.List')
  let s:ByteArray = s:V.import('Data.List.Byte')
  let s:MD5       = s:V.import('Hash.MD5')
  let s:SHA1      = s:V.import('Hash.SHA1')
  let s:Random    = s:V.import('Random')
  let s:Type      = s:V.import('Vim.Type')
  let s:DateTime  = s:V.import('DateTime')
  let s:BigNum    = s:V.import('Data.BigNum')

  let s:UUID = extend(s:UUID, {
        \ 'uuid_hex': '',
        \ 'string'  : {
        \   'time_low'            : '',
        \   'time_mid'            : '',
        \   'time_hi_and_version' : '',
        \   'clock'               : '',
        \   'node'                : '',
        \ },
        \ 'endian': 0,
        \ 'bytes' : s:List.new(16, {-> 0}),
        \ 'value'   : {
        \   'time_low'            : s:List.new(4, {-> 0}),
        \   'time_mid'            : s:List.new(2, {-> 0}),
        \   'time_hi_and_version' : s:List.new(2, {-> 0}),
        \   'clk_seq_hi_res'      : s:List.new(1, {-> 0}),
        \   'clk_seq_low'         : s:List.new(1, {-> 0}),
        \   'node'                : s:List.new(6, {-> 0}),
        \ },
        \ 'variant' : -1,
        \ 'version' : -1,
        \})
endfunction

function! s:_vital_depends() abort
  return [
    \ 'Bitwise',
    \ 'Data.List',
    \ 'Data.List.Byte',
    \ 'Hash.MD5',
    \ 'Hash.SHA1',
    \ 'Random',
    \ 'Vim.Type',
    \ 'DateTime',
    \ 'Data.BigNum',
    \]
endfunction

"  UUID
"  0                   1                   2                   3
"  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
" +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
" |                          time_low                             |
" +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
" |       time_mid                |         time_hi_and_version   |
" +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
" |clk_seq_hi_res |  clk_seq_low  |         node (0-1)            |
" +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
" |                         node (2-5)                            |
" +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
"
" hex string xxxxxxxx-xxxx-xxxx-Nxxx-xxxxxxxxxxxx

let s:uuidregex = '\<{\?\x\{8}-\x\{4}-\x\{4}-\x\{4}-\x\{12}}\?\>'
lockvar 3 s:uuidregex
let s:UUID = {}

" variant
"  bit 0xx Network Computing System Compatible
"  bit 10x RFC4122
"  bit 110 Microsoft COM GUID Compatible
"  bit 111 Reserved
"  value 8 no care
" version (RFC4122)
"  bit 0001 v1 MAC and timestamp
"  bit 0010 v2 MAC and DCE local domain/local user, timestamp
"  bit 0011 v3 MD5  Hash
"  bit 0100 v4 Random
"  bit 0101 v5 SHA1 Hash
" endian
"  little 0
"  big    1

function! s:new() abort
  return deepcopy(s:UUID)
endfunction

function! s:decode(uuid) abort
  let uuid = deepcopy(s:UUID)
  let uuid.uuid_hex = a:uuid
  let uuid.endian  = 1

  call uuid.hex_decode()
  return uuid
endfunction

function! s:v1(mac) abort
  let uuid = deepcopy(s:UUID)
  call uuid.generatev1(a:mac)
  return uuid.uuid_hex
endfunction

function! s:v3(ns, data) abort
  let uuid = deepcopy(s:UUID)
  call uuid.generatev3(a:ns, a:data)
  return uuid.uuid_hex
endfunction

function! s:v4(...) abort
  let uuid = deepcopy(s:UUID)
  call call(uuid.generatev4, a:000)
  return uuid.uuid_hex
endfunction

function! s:v5(ns, data) abort
  let uuid = deepcopy(s:UUID)
  call uuid.generatev5(a:ns, a:data)
  return uuid.uuid_hex
endfunction

function! s:v6(mac) abort
  let uuid = deepcopy(s:UUID)
  call uuid.generatev6(a:mac)
  return uuid.uuid_hex
endfunction

function! s:v7(...) abort
  let uuid = deepcopy(s:UUID)
  call call(uuid.generatev7, a:000)
  return uuid.uuid_hex
endfunction

function! s:_mac_to_node(mac) abort
  let mac_hex = substitute(a:mac, ':', '', 'g')
  if len(mac_hex) != 12 || mac_hex !~? '^[0-9a-f]\{12}$'
    call s:_throw('invalid mac')
  endif
  return s:ByteArray.from_hexstring(mac_hex)
endfunction

" ===== UUID v1..v5 generate
function! s:UUID.generatev1(mac) dict abort
  " MAC
  if type(a:mac) == type("")
    let node = s:_mac_to_node(a:mac)
  elseif (type(a:mac) == type([]))
      \ && (6 == len(a:mac))
      \ && s:ByteArray.validate(a:mac)
    let node = a:mac
  else
    call s:_throw('invalid mac')
  endif

  " timestamp
  let timestamp = s:_generate_timestamp_now()
  let ts_num = str2nr(s:BigNum.to_string(timestamp), 10)

  " split timestamp: 60 bits -> time_low(32), time_mid(16), time_hi(16)
  let time_low = s:Bitwise.and(ts_num, 0xFFFFFFFF)
  let ts_num = s:Bitwise.rshift(ts_num, 32)
  let time_mid = s:Bitwise.and(ts_num, 0xFFFF)
  let ts_num = s:Bitwise.rshift(ts_num, 16)
  let time_hi = s:Bitwise.and(ts_num, 0xFFFF)

  " set version in time_hi_and_version
  let time_hi_and_version = s:Bitwise.or(s:Bitwise.and(time_hi, 0x0FFF), s:Bitwise.lshift(1, 12))

  " clock sequence: 14 bits random
  let r = s:Random.new()
  let clock_seq_bytes = [r.range(256), r.range(256)]
  let clk_seq = s:Bitwise.or(s:Bitwise.lshift(clock_seq_bytes[0], 8), clock_seq_bytes[1])
  let clk_seq_low = s:Bitwise.and(clk_seq, 0xFF)
  let clk_seq_hi_res = s:Bitwise.or(s:Bitwise.and(s:Bitwise.rshift(clk_seq, 8), 0x3F), 0x80)

  let self.value.time_low = s:_num_to_bytes(time_low, 4, 1)
  let self.value.time_mid = s:_num_to_bytes(time_mid, 2, 1)
  let self.value.time_hi_and_version = s:_num_to_bytes(time_hi_and_version, 2, 1)
  let self.value.clk_seq_hi_res = [clk_seq_hi_res]
  let self.value.clk_seq_low = [clk_seq_low]
  let self.value.node = node
  let self.endian  = 1
  let self.variant = 0b100
  let self.version = 1
  call self.value_encode()
endfunction

function! s:UUID.generatev6(mac) dict abort
  " MAC
  if type(a:mac) == type("")
    let node = s:_mac_to_node(a:mac)
  elseif (type(a:mac) == type([]))
      \ && (6 == len(a:mac))
      \ && s:ByteArray.validate(a:mac)
    let node = a:mac
  else
    call s:_throw('invalid mac')
  endif

  " timestamp
  let timestamp = s:_generate_timestamp_now()
  let ts_num = str2nr(s:BigNum.to_string(timestamp), 10)

  " split timestamp: 60 bits -> time_high(32), time_mid(16), time_low(12)
  let time_high = s:Bitwise.rshift(ts_num, 28)  " most significant 32 bits
  let time_mid = s:Bitwise.and(s:Bitwise.rshift(ts_num, 12), 0xFFFF)
  let time_low = s:Bitwise.and(ts_num, 0xFFF)

  " set version in time_low_and_version
  let time_low_and_version = s:Bitwise.or(s:Bitwise.lshift(time_low, 4), 6)  " time_low(12) + ver(4)=6

  " clock sequence: 14 bits random
  let r = s:Random.new()
  let clock_seq_bytes = [r.range(256), r.range(256)]
  let clk_seq = s:Bitwise.or(s:Bitwise.lshift(clock_seq_bytes[0], 8), clock_seq_bytes[1])
  let clk_seq_low = s:Bitwise.and(clk_seq, 0xFF)
  let clk_seq_hi_res = s:Bitwise.or(s:Bitwise.and(s:Bitwise.rshift(clk_seq, 8), 0x3F), 0x80)

  let self.value.time_low = s:_num_to_bytes(time_high, 4, 1)  " time_high as time_low field
  let self.value.time_mid = s:_num_to_bytes(time_mid, 2, 1)
  let self.value.time_hi_and_version = s:_num_to_bytes(time_low_and_version, 2, 1)  " time_low_and_version as time_hi_and_version field
  let self.value.clk_seq_hi_res = [clk_seq_hi_res]
  let self.value.clk_seq_low = [clk_seq_low]
  let self.value.node = node
  let self.endian  = 1
  let self.variant = 0b100
  let self.version = 6
  call self.value_encode()
endfunction

function! s:UUID.generatev7(...) dict abort
  " Unix timestamp in milliseconds (48 bits)
  let unix_ts_ms = s:_generate_unix_timestamp_ms()

  " rand_a: 12 bits random
  let r = s:Random.new()
  let rand_a = r.range(0x1000)  " 0-4095

  " rand_b: 62 bits random
  let rand_b_bytes = s:List.new(8, { i,v -> r.range(256)})
  let rand_b = 0
  for i in range(8)
    let rand_b = s:Bitwise.or(s:Bitwise.lshift(rand_b, 8), rand_b_bytes[i])
  endfor
  let rand_b = s:Bitwise.and(rand_b, 0x3FFFFFFFFFFFFFFF)  " 62 bits

  " Set fields
  let self.value.time_low = s:_num_to_bytes(s:Bitwise.and(unix_ts_ms, 0xFFFFFFFF), 4, 1)  " low 32 bits of unix_ts_ms
  let unix_ts_mid = s:Bitwise.and(s:Bitwise.rshift(unix_ts_ms, 32), 0xFFFF)  " mid 16 bits
  let rand_a_and_ver = s:Bitwise.or(s:Bitwise.lshift(rand_a, 4), 7)  " rand_a(12) + ver(4)=7
  let self.value.time_mid = s:_num_to_bytes(unix_ts_mid, 2, 1)
  let self.value.time_hi_and_version = s:_num_to_bytes(rand_a_and_ver, 2, 1)

  " variant in clk_seq_hi_res
  let clk_seq_hi_res = s:Bitwise.or(0x80, s:Bitwise.and(s:Bitwise.rshift(rand_b, 56), 0x3F))  " var 0b10 + high 6 bits of rand_b
  let clk_seq_low = s:Bitwise.and(s:Bitwise.rshift(rand_b, 48), 0xFF)
  let node_high = s:Bitwise.and(s:Bitwise.rshift(rand_b, 16), 0xFFFFFFFF)
  let node_low = s:Bitwise.and(rand_b, 0xFFFF)

  let self.value.clk_seq_hi_res = [clk_seq_hi_res]
  let self.value.clk_seq_low = [clk_seq_low]
  let self.value.node = s:_num_to_bytes(node_high, 4, 1) + s:_num_to_bytes(node_low, 2, 1)

  let self.endian  = 1
  let self.variant = 0b100
  let self.version = 7
  call self.value_encode()
endfunction

function! s:UUID.generatev3(ns, data) dict abort
  " NS
  if type(a:ns) == s:Type.types.string
    let ns_uuid = deepcopy(s:UUID)
    let ns_uuid.uuid_hex = a:ns
    let ns_uuid.endian   = 1

    call ns_uuid.hex_decode()
  else
    let ns_uuid = a:ns
  endif

  " MD5 hash
  let data = a:data
  if type(a:data) == s:Type.types.string
    let data = s:ByteArray.from_string(a:data)
  else
    let data = a:data
  endif
  let hash = s:MD5.digest_raw(ns_uuid.bytes + data)

  let self.bytes   = hash[0:15]
  let self.endian  = 1
  let self.variant = 0x4 " 0b100
  let self.version = 3
  call self.byte_encode()
endfunction

function! s:UUID.generatev4(...) dict abort
  " 128bit random
  let r = call(s:Random.new, a:000)
  let randomlist = s:List.new(16, { i,v -> r.range(256)})

  let self.bytes   = randomlist
  let self.endian  = 1
  let self.variant = 0x4 " 0b100
  let self.version = 4
  call self.byte_encode()
endfunction

function! s:UUID.generatev5(ns, data) dict abort
  " NS
  if type(a:ns) == s:Type.types.string
    let ns_uuid = deepcopy(s:UUID)
    let ns_uuid.uuid_hex = a:ns
    let ns_uuid.endian   = 1

    call ns_uuid.hex_decode()
  else
    let ns_uuid = a:ns
  endif

  " SHA1 hash
  let data = a:data
  if type(a:data) == s:Type.types.string
    let data = s:ByteArray.from_string(a:data)
  else
    let data = a:data
  endif
  let hash = s:SHA1.digest_raw(ns_uuid.bytes + data)

  let self.bytes   = hash[0:15]
  let self.endian  = 1
  let self.variant = 0x4 " 0b100
  let self.version = 5
  call self.byte_encode()
endfunction

" ===== UUID data operator / generic encode/decode
function! s:UUID.hex_decode() dict abort
  if self.uuid_hex !~? s:uuidregex
    call s:_throw('format unmatch error')
  endif

  let self.string.time_low             = self.uuid_hex[0:7]
  " self.uuid_hex[8] = '-'
  let self.string.time_mid             = self.uuid_hex[9:12]
  " self.uuid_hex[13] = '-'
  let self.string.time_hi_and_version  = self.uuid_hex[14:17]
  " self.uuid_hex[18] = '-'
  let self.string.clock                = self.uuid_hex[19:22]
  " self.uuid_hex[23] = '-'
  let self.string.node                 = self.uuid_hex[24:36]

  let self.value.time_low             = s:ByteArray.from_hexstring(self.string.time_low)
  let self.value.time_mid             = s:ByteArray.from_hexstring(self.string.time_mid)
  let self.value.time_hi_and_version  = s:ByteArray.from_hexstring(self.string.time_hi_and_version)
  if 0 == self.endian
    " little endian data: swap
    let self.value.time_low             = s:ByteArray.endian_convert(self.value.time_low)
    let self.value.time_mid             = s:ByteArray.endian_convert(self.value.time_mid)
    let self.value.time_hi_and_version  = s:ByteArray.endian_convert(self.value.time_hi_and_version)
  endif

  let self.value.clk_seq_hi_res = s:ByteArray.from_hexstring(self.string.clock[0:1])
  let self.value.clk_seq_low    = s:ByteArray.from_hexstring(self.string.clock[2:3])
  let self.value.node           = s:ByteArray.from_hexstring(self.string.node)

  call s:_generate_bytes(self)

  call s:_variant_detect(self)
endfunction

function! s:UUID.build() dict abort
  if 0 == self.endian
    " little endian string: swapped data
    let self.string.time_low             = s:ByteArray.to_hexstring(s:ByteArray.endian_convert(self.value.time_low))
    let self.string.time_mid             = s:ByteArray.to_hexstring(s:ByteArray.endian_convert(self.value.time_mid))
    let self.string.time_hi_and_version  = s:ByteArray.to_hexstring(s:ByteArray.endian_convert(self.value.time_hi_and_version))
  else
    " big endian string
    let self.string.time_low             = s:ByteArray.to_hexstring(self.value.time_low)
    let self.string.time_mid             = s:ByteArray.to_hexstring(self.value.time_mid)
    let self.string.time_hi_and_version  = s:ByteArray.to_hexstring(self.value.time_hi_and_version)
  endif
  let self.string.clock = s:ByteArray.to_hexstring(self.value.clk_seq_hi_res
        \ + self.value.clk_seq_low)
  let self.string.node  = s:ByteArray.to_hexstring(self.value.node)

  let self.uuid_hex  = self.string.time_low . '-'
        \ . self.string.time_mid            . '-'
        \ . self.string.time_hi_and_version . '-'
        \ . self.string.clock               . '-'
        \ . self.string.node
endfunction

function! s:UUID.byte_encode() dict abort
  if 16 != len(self.bytes)
    call s:_throw('bytes length error')
  endif

  call s:_generate_value(self)

  call s:_variant_embedded(self)
  " regenerate bytes
  call s:_generate_bytes(self)

  call self.build()
endfunction

function! s:UUID.value_encode() dict abort
  call s:_variant_embedded(self)
  call s:_generate_bytes(self)

  call self.build()
endfunction

" ===== UUID data operation utility
function! s:_generate_bytes(uuid) abort
  let uuid = a:uuid

  let uuid.bytes = uuid.value.time_low
        \ + uuid.value.time_mid
        \ + uuid.value.time_hi_and_version
        \ + uuid.value.clk_seq_hi_res
        \ + uuid.value.clk_seq_low
        \ + uuid.value.node
endfunction

function! s:_generate_value(uuid)  abort
  let uuid = a:uuid

  let uuid.value.time_low             = uuid.bytes[0:3]
  let uuid.value.time_mid             = uuid.bytes[4:5]
  let uuid.value.time_hi_and_version  = uuid.bytes[6:7]
  let uuid.value.clk_seq_hi_res       = uuid.bytes[8:8]
  let uuid.value.clk_seq_low          = uuid.bytes[9:9]
  let uuid.value.node                 = uuid.bytes[10:15]
endfunction

function! s:_variant_embedded(uuid) abort
  let uuid = a:uuid

  if 0 > uuid.variant
    call s:_throw('undefined variant')
  endif
  if 8 == uuid.variant
    " no care
    return
  endif

  " clock high byte msb 0..2 (5bit >>, remain 3bit)
  let variant_mask = 0x00 " 0b00000000
  let value_mask   = 0xff " 0b11111111
  if 0x0 == s:Bitwise.and(uuid.variant, 0x4) " test 0b000, mask 0b100
    "  bit 0xx Network Computing System Compatible
    let variant_mask = 0x80 " 0b10000000
    let value_mask   = 0x7f " 0b01111111
  elseif 0x4 == s:Bitwise.and(uuid.variant, 0x6) " test 0b100, mask 0b110
    "  bit 10x RFC4122
    let variant_mask = 0xc0 " 0b11000000
    let value_mask   = 0x3f " 0b00111111
  else
    "  bit 110 Microsoft COM GUID Compatible
    "  bit 111 Reserved
    let variant_mask = 0xe0 " 0b11100000
    let value_mask   = 0x1f " 0b00011111
  endif
  let uuid.value.clk_seq_hi_res[0] = s:Bitwise.or(
        \ s:Bitwise.and(s:Bitwise.lshift(uuid.variant, 5), variant_mask),
        \ s:Bitwise.and(uuid.value.clk_seq_hi_res[0],      value_mask))

  if 0x4 == s:Bitwise.and(uuid.variant, 0x6) " test 0b100, mask 0b110
    " time_hi_and_version high byte 0..4 (4bit >>, remain 4bit)
    let uuid.value.time_hi_and_version[0] = s:Bitwise.or(
          \ s:Bitwise.and(s:Bitwise.lshift(uuid.version, 4), 0xf0),
          \ s:Bitwise.and(uuid.value.time_hi_and_version[0], 0x0f))
    " 0xf0 0b11110000
    " 0x0f 0b00001111
  endif
endfunction

function! s:_variant_detect(uuid) abort
  let uuid = a:uuid

  " clock high byte msb 0..2 (5bit >>, remain 3bit)
  let variant = s:Bitwise.and(s:Bitwise.rshift(
        \ uuid.value.clk_seq_hi_res[0], 5), 0x7)
  " 0x7 0b111

  if 0x0 == s:Bitwise.and(variant, 0x4) " test 0b000, mask 0b100
    "  bit 0xx Network Computing System Compatible
    let uuid.variant = 0
  elseif 0x4 == s:Bitwise.and(variant, 0x6) " test 0b100, mask 0b110
    "  bit 10x RFC4122
    let uuid.variant = 4
  elseif 0x6 == variant " test 0b110
    "  bit 110 Microsoft COM GUID Compatible
    let uuid.variant = 6
  else
    "  bit 111 Reserved
  endif

  if 4 == uuid.variant
    " time_hi_and_version high byte 0..4 (4bit >>, remain 4bit)
    let uuid.version = s:Bitwise.and(s:Bitwise.rshift(
          \ uuid.value.time_hi_and_version[0], 4), 0xf)
    " 0xf 0b1111
  endif
endfunction

" time code  1582/10/15 00:00:00 UTC start : 100ns unit
" unix epoch 1970/01/01 00:00:00 UTC start : 1sec  unit
" diff 141427 days = 141427 * 24 * 60 * 60 sec = 12219292800 sec
let s:_epoch_offset_sec = '12219292800'
lockvar s:_epoch_offset_sec
function! s:_generate_timestamp_now()  abort
  let timestamp_sec = s:BigNum.add(
    \ s:_epoch_offset_sec,
    \ s:DateTime.now().unix_time())
  " unit convert sec to 100ns(1sec = 1000(ms to s) * 1000(us to ms) * 10(us to 100ns)
  let timestamp_ms   = s:BigNum.mul(timestamp_sec, s:BigNum.from_num(1000))
  let timestamp_us   = s:BigNum.mul(timestamp_ms,  s:BigNum.from_num(1000))
  let timestamp_unit = s:BigNum.mul(timestamp_us,  s:BigNum.from_num(10)  )

  return  timestamp_unit
endfunction

function! s:_generate_unix_timestamp_ms() abort
  let unix_time = s:DateTime.now().unix_time()
  " Convert to milliseconds
  let unix_ts_ms = s:BigNum.mul(s:BigNum.from_num(unix_time), s:BigNum.from_num(1000))
  " Add milliseconds fraction if available, but for simplicity, use seconds * 1000
  return str2nr(s:BigNum.to_string(unix_ts_ms), 10)
endfunction

function! s:_num_to_bytes(num, len, big_endian) abort
  let bytes = []
  let n = a:num
  for i in range(a:len)
    call add(bytes, n % 256)
    let n = n / 256
  endfor
  if a:big_endian
    call reverse(bytes)
  endif
  return bytes
endfunction

function! s:_throw(msg) abort
  throw 'vital: ID.UUID: ' . a:msg
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
