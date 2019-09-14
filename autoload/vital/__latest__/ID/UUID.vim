" Utilities for UUID
" RFC 4122 - A Universally Unique IDentifier (UUID) URN Namespace https://tools.ietf.org/html/rfc4122

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V       = a:V
  let s:MD5     = s:V.import('Hash.MD5x')
  let s:SHA1    = s:V.import('Hash.SHA1x')
  let s:Bitwise = s:V.import('Bitwise')
  let s:Random  = s:V.import('Random')
  let s:List    = s:V.import('Data.List')
  let s:ByteArray = s:V.import('Data.List.Byte')

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
  return ['Hash.MD5x', 'Hash.SHA1x', 'Bitwise', 'Random', 'Data.List', 'Data.List.Byte']
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

" ===== UUID v1..v5 generate
function! s:UUID.generatev1(mac) dict abort
  " TODO
endfunction

function! s:UUID.generatev3(ns, data) dict abort
  " NS
  if type(a:ns) == type("")
    let ns_uuid = deepcopy(s:UUID)
    let ns_uuid.uuid_hex = a:ns
    let ns_uuid.endian   = 1

    call ns_uuid.hex_decode()
  else
    let ns_uuid = a:ns
  endif

  " MD5 hash
  let data = a:data
  if type(a:data) == type("")
    let data = s:ByteArray.from_string(a:data)
  else
    let data = a:data
  endif
  let hash = s:MD5.digest_raw(ns_uuid.bytes + data)

  let self.bytes   = hash[0:15]
  let self.endian  = 1
  let self.variant = 0b100
  let self.version = 3
  call self.byte_encode()
endfunction

function! s:UUID.generatev4(...) dict abort
  " 128bit random
  let r = call(s:Random.new, a:000)
  let randomlist = s:List.new(16, { i,v -> r.range(256)})

  let self.bytes   = randomlist
  let self.endian  = 1
  let self.variant = 0b100
  let self.version = 4
  call self.byte_encode()
endfunction

function! s:UUID.generatev5(ns, data) dict abort
  " NS
  if type(a:ns) == type("")
    let ns_uuid = deepcopy(s:UUID)
    let ns_uuid.uuid_hex = a:ns
    let ns_uuid.endian   = 1

    call ns_uuid.hex_decode()
  else
    let ns_uuid = a:ns
  endif

  " SHA1 hash
  let data = a:data
  if type(a:data) == type("")
    let data = s:ByteArray.from_string(a:data)
  else
    let data = a:data
  endif
  let hash = s:SHA1.digest_raw(ns_uuid.bytes + data)

  let self.bytes   = hash[0:15]
  let self.endian  = 1
  let self.variant = 0b100
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
  let variant_mask = 0b00000000
  let value_mask   = 0b11111111
  if 0b000 == s:Bitwise.and(uuid.variant, 0b100)
    "  bit 0xx Network Computing System Compatible
    let variant_mask = 0b10000000
    let value_mask   = 0b01111111
  elseif 0b100 == s:Bitwise.and(uuid.variant, 0b110)
    "  bit 10x RFC4122
    let variant_mask = 0b11000000
    let value_mask   = 0b00111111
  else
    "  bit 110 Microsoft COM GUID Compatible
    "  bit 111 Reserved
    let variant_mask = 0b11100000
    let value_mask   = 0b00011111
  endif
  let uuid.value.clk_seq_hi_res[0] = s:Bitwise.or(
        \ s:Bitwise.and(s:Bitwise.lshift(uuid.variant, 5), variant_mask),
        \ s:Bitwise.and(uuid.value.clk_seq_hi_res[0],      value_mask))

  if 0b100 == s:Bitwise.and(uuid.variant, 0b110)
    " time_hi_and_version high byte 0..4 (4bit >>, remain 4bit)
    let uuid.value.time_hi_and_version[0] = s:Bitwise.or(
          \ s:Bitwise.and(s:Bitwise.lshift(uuid.version, 4), 0b11110000),
          \ s:Bitwise.and(uuid.value.time_hi_and_version[0], 0b00001111))
  endif
endfunction

function! s:_variant_detect(uuid) abort
  let uuid = a:uuid

  " clock high byte msb 0..2 (5bit >>, remain 3bit)
  let variant = s:Bitwise.and(s:Bitwise.rshift(
        \ uuid.value.clk_seq_hi_res[0], 5), 0b111)

  if 0b000 == s:Bitwise.and(variant, 0b100)
    "  bit 0xx Network Computing System Compatible
    let uuid.variant = 0
  elseif 0b100 == s:Bitwise.and(variant, 0b110)
    "  bit 10x RFC4122
    let uuid.variant = 4
  elseif 0b110 == variant
    "  bit 110 Microsoft COM GUID Compatible
    let uuid.variant = 6
  else
    "  bit 111 Reserved
  endif

  if 4 == uuid.variant
    " time_hi_and_version high byte 0..4 (4bit >>, remain 4bit)
    let uuid.version = s:Bitwise.and(s:Bitwise.rshift(
          \ uuid.value.time_hi_and_version[0], 4), 0b1111)
  endif
endfunction

function! s:_throw(msg) abort
  throw 'vital: ID.UUID: ' . a:msg
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
