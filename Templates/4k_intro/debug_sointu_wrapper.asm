; Adapt Sointu's static song renderer to the audio DLL interface used by the app.

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

section .data
music_sample_rate:
    dd SU_SAMPLE_RATE

music_bpm:
    dd SU_BPM

music_length_samples:
    dd SU_LENGTH_IN_SAMPLES

section .text
%macro EXPORT_FUNC 1
    global _%1
_%1:
%1:
    export %1
%endmacro

EXPORT_FUNC GetMusicSampleRate
    mov eax, dword [music_sample_rate]
    ret

EXPORT_FUNC GetMusicBPM
    fild dword [music_bpm]
    ret

EXPORT_FUNC GetMusicLengthSamples
    mov eax, dword [music_length_samples]
    ret
