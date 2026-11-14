; Adapt Sointu's static song renderer to the entry point expected by exemain.asm.

section .text
%define MANGLED
%ifndef SOINTU_INCLUDE_FILE
%define SOINTU_INCLUDE_FILE "__sointu_song.inc"
%endif
%include SOINTU_INCLUDE_FILE
%ifdef SU_SAMPLE_FLOAT
%error "Sointu output must be compiled as 16-bit PCM"
%endif
%ifndef SU_SAMPLE_PCM16
%error "Sointu include must declare 16-bit PCM output"
%endif

global __4klang_render@4
__4klang_render@4:
%ifdef SU_LOAD_GMDLS
    extern _su_load_gmdls@0
    call _su_load_gmdls@0
%endif
    jmp _su_render_song@4
