" Utilities for UUID
" RFC 4122 - A Universally Unique IDentifier (UUID) URN Namespace https://tools.ietf.org/html/rfc4122

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V    = a:V
  let s:UUID = s:V.import('ID.UUID')
endfunction

function! s:_vital_depends() abort
  return ['ID.UUID']
endfunction

" GUID
" GUID STRUCT
"  Data1 dd
"  Data2 dw
"  Data3 dw
"  Data4 db 8
" GUID ENDS
"
" typedef struct _GUID {
"     unsigned long  Data1;
"     unsigned short Data2;
"     unsigned short Data3;
"     unsigned char  Data4[8];
" } GUID;

function! s:decode(guid) abort
  let uuid = s:UUID.new()

  let uuid.uuid_hex = a:guid
  let uuid.endian  = 0 " little endian

  call uuid.hex_decode()

  let uuid.variant = 8 " no care
  let uuid.version = 0

  return uuid
endfunction

function! s:generate(...) abort
  let uuid = s:UUID.new()
  call call(uuid.generatev4, a:000)

  let uuid.endian  = 0 " little endian
  let uuid.variant = 8 " no care
  let uuid.version = 0

  call uuid.byte_encode()
  return uuid.uuid_hex
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
