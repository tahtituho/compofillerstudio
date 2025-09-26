; timings_and_texts.inc
; Compofiller Studio project text strings and timings

section .textstr0 data

%ifdef USE_WIDECHAR_TEXTS
%define DEFINE_STRING dw
%else
%define DEFINE_STRING db
%endif

%define END_STRING , 0
%define SHADER_SOURCE_TEXT

; each timing entry is a bunch of dwords
%define DEFINE_TIMING dd

%ifndef TIME_DIVIDER_INT
error! TIME_DIVIDER_INT MUST BE DEFINED!!!
%endif

; Kludge Construction Kit: x and y are floating point values used by the IDE's timings and texts editor, 
; and z is the final integer value that has x, y and TIME_DIVIDER_INT baked into it. :/ This is needed
; because NASM is apparently unable to do the calculation and float-to-int conversion at compile time.
%define TIMING_TIME(x,y,z) (z)
REC_TIMINGS_TIME_FIELD_SIZE equ 4
; alias is only used by the IDE, not actually assembled into any sort of data
%define TIMING_ALIAS(x)

%ifdef USE_CUSTOM_UNIFORM
%define TIMING_CUSTOM(x) , x
REC_TIMINGS_CUSTOM_FIELD_SIZE equ 4
%else
%define TIMING_CUSTOM(x)
REC_TIMINGS_CUSTOM_FIELD_SIZE equ 0
%endif

%define TIMING_STRING(x, y) , y
REC_TIMINGS_STRING_PTR_FIELD_SIZE equ 4

TIMINGS_REC_SIZE equ (REC_TIMINGS_TIME_FIELD_SIZE + REC_TIMINGS_CUSTOM_FIELD_SIZE + REC_TIMINGS_STRING_PTR_FIELD_SIZE)
TIMINGS_REC_STRING_PTR_FIELD_OFS equ (REC_TIMINGS_TIME_FIELD_SIZE + REC_TIMINGS_CUSTOM_FIELD_SIZE)

; Separating the timings and actual string data enables us to do things

section .textstr1 data
;______STRINGS_START______
_string0: DEFINE_STRING 'Hello World' END_STRING
_string1: DEFINE_STRING 'now you can have' END_STRING
_string2: DEFINE_STRING 'TEXTS' END_STRING
_string3: DEFINE_STRING 'yeah' END_STRING
_string4: DEFINE_STRING 'abcd' END_STRING
_string5: DEFINE_STRING '12345678' END_STRING
;______STRINGS_END______

section .textstr2 data
text_string_timings:
;______TIMINGS_START______
DEFINE_TIMING TIMING_TIME(0,0.00000,0) TIMING_ALIAS('START_TIME') TIMING_CUSTOM(0) TIMING_STRING(0,_string0)  ;    this is a comment
DEFINE_TIMING TIMING_TIME(2,0.00000,176400) TIMING_ALIAS('') TIMING_CUSTOM(0) TIMING_STRING(0,_string1)  ;    another comment
DEFINE_TIMING TIMING_TIME(5,0.00000,441000) TIMING_ALIAS('') TIMING_CUSTOM(0) TIMING_STRING(0,_string2)  ;    this is a komment
; DEFINE_TIMING TIMING_TIME(6,0.00000,529200) TIMING_ALIAS('') TIMING_CUSTOM(0) TIMING_STRING(0,_string3)  ;    this timing line is not active at all
DEFINE_TIMING TIMING_TIME(7,0.00000,617400) TIMING_ALIAS('') TIMING_CUSTOM(0) TIMING_STRING(0,_string4)  ;    
DEFINE_TIMING TIMING_TIME(8,0.00000,705600) TIMING_ALIAS('') TIMING_CUSTOM(0) TIMING_STRING(0,_string5)  ;    abcd
DEFINE_TIMING TIMING_TIME(10,0.00000,882000) TIMING_ALIAS('') TIMING_CUSTOM(0) TIMING_STRING(0,_string3)  ;    efgh
; DEFINE_TIMING TIMING_TIME(11,0.00000,970200) TIMING_ALIAS('END_TIME') TIMING_CUSTOM(0) TIMING_STRING(0,_string5)  ;    this timing line is not active at all
;______TIMINGS_END______
    dd 0xFFFFFFFF ; end-of-time

