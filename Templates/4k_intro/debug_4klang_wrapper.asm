; Compofiller Studio by Yzi
; Wrapper for 4klang.asm, so we can get our debug/test DLL to export the constants.

%include "4klang.asm"


music_sample_rate:
    dd SAMPLE_RATE

music_bpm:
    dd __float32__(%[BPM])

music_length_samples:
    dd MAX_SAMPLES

%macro EXPORT_FUNC 1
    export %1
   global _%1
   _%1:
   %1:
%endmacro

EXPORT_FUNC GetMusicSampleRate
        mov eax, dword [music_sample_rate]
        ret

EXPORT_FUNC GetMusicBPM
        ; mov eax, dword [music_bpm]
        fld dword [music_bpm]
        ret

EXPORT_FUNC GetMusicLengthSamples
        mov eax, dword [music_length_samples]
        ret

