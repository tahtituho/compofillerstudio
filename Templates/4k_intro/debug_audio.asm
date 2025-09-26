; yasm -f win32 -o dlltest.obj dlltest.asm
; ld --dll -entry=DllMain@12 -L C:\utils -o dlltest.dll dlltest.obj -l user32 

; Compofiller Studio by Yzi
;
; Debug DLL for music stuff
;


%include "errormsg.inc"

section .text

; .start:

global  DllMain@12
DllMain@12:		; This code is required in .dll files
        mov eax,1
        ret 12


; extern	_midiOutOpen@20
; extern	__imp__midiOutOpen@20
; extern	_midiOutShortMsg@8
; extern	__imp__midiOutShortMsg@8
; extern	_timeGetTime@0
; extern	__imp__timeGetTime@0


loppu:
    push	0
    call	[__imp__ExitProcess@4]
    
    ret  

extern _MessageBeep@4
extern __imp__MessageBeep@4
beepquit:
    push  0xFFFFFFFF
    call    [__imp__MessageBeep@4]
    jmp   loppu


; ------------------------------ STUFF FOR PCM/4KLANG MUSIC -------------------------
;section .bss 
; .bss declares an uninitialized data section
section .data

; !!! TODO sampling rate is coded in two places now, here and 4klang.ini
audio_sampling_rate	equ	44100
;audio_length_seconds	equ	(2*60)
;audio_length_samples	equ	(audio_length_seconds*audio_sampling_rate*2)


audio_thread_handle: dd 0

; "rendered audio buffer" means the rendered audio length,
; as opposed to "playback buffer" which might be 
;    - shorter, if we start playback from the middle of rendered audio
;    - longer, if we play all the way from start to end of demo, and there's a positive audio offset/delay
rendered_audio_buffer_ptr: dd 0
 

; loop parameters
audio_loop_enabled: dd 0

 ;   resw	audio_length_samples

global hWaveOut
hWaveOut:	dd 0

; Flags for WaveHDR.dwFlags
WHDR_BEGINLOOP	equ	4
WHDR_ENDLOOP		equ	8

section .data
    
global WaveHDR
WaveHDR: 
audio_playback_buffer_ptr:
WaveHDR_lpData:             dd	0
audio_playback_length_bytes:
WaveHDR_dwBufferLength:		dd	0 ; audio_length_samples*2  ; audio buffer length in bytes
WaveHDR_dwBytesRecorded:   	dd  0
WaveHDR_dwUser:   	        dd  0
WaveHDR_dwFlags:   	        dd  0
WaveHDR_dwLoops:   	        dd  0
WaveHDR_lpNext:   	        dd  0
WaveHDR_reserved:   	    dd  0

; long GetPosition() { 
;  static MMTIME MMTime = { TIME_SAMPLES, 0}; 
;  waveOutGetPosition(hWaveOut, &MMTime, sizeof(MMTIME)); 
;  return (MMTime.u.sample); 
; } 

global pcmFormat
pcmFormat:
pcmFormat_wFormatTag:       dw  1   ; WAVE_FORMAT_PCM
pcmFormat_nChannels:        dw  2   ; stereo
pcmFormat_nSamplesPerSec:   dd  audio_sampling_rate
pcmFormat_nAvgBytesPerSec:  dd  audio_sampling_rate*4 ; for buffer estimation
pcmFormat_nBlockAlign:      dw  4   ; block size of data
pcmFormat_wBitsPerSample:   dw  16
pcmFormat_cbSize:           dw  0
    
; void Play() { 
;  static WAVEHDR WaveHDR = { (LPSTR)(myMuzik),  MZK_NUMSAMPLESC * 2}; 
  
;  // Define output format 
;  static WAVEFORMATEX pcmFormat = { 
;   WAVE_FORMAT_PCM, // WORD        wFormatTag;         /* format type */ 
;   2,     // WORD        nChannels;          /* number of channels (i.e. mono, stereo...) */ 
;   44100,    // DWORD       nSamplesPerSec;     /* sample rate */ 
;   4 * 44100,   // DWORD       nAvgBytesPerSec;    /* for buffer estimation */ 
;   4,     // WORD        nBlockAlign;        /* block size of data */ 
;   16,     // WORD        wBitsPerSample;     /* number of bits per sample of mono data */ 
;   0,     // WORD        cbSize;             /* the count in bytes of the size of */ 
;  }; 

global MMTime
; MMTIME is a "union" struct that can be used for many different contents based on the first 
MMTime: 	    dd 2 ; wType: TIME_SAMPLES = 2
MMTime_sample:  dd 0 ; actual position value
                db 0, 0, 0, 0 ; some room for other cases



; -----------------

section .text
; the __imp__ versions refer to the corresponding import address table entries

; 4klang
extern  __4klang_render@4

; General Windows stuff
extern	_ExitProcess@4
extern	__imp__ExitProcess@4
extern  _CreateThread@24
extern __imp__CreateThread@24
extern  _TerminateThread@8
extern __imp__TerminateThread@8
extern  _Sleep@4
extern  __imp__Sleep@4
extern _WaitForSingleObject@8
extern __imp_WaitForSingleObject@8

; Windows Multimedia
extern  _waveOutOpen@24
extern  __imp__waveOutOpen@24
extern  _waveOutPrepareHeader@12
extern  __imp__waveOutPrepareHeader@12
extern  _waveOutWrite@12
extern  __imp__waveOutWrite@12
extern  _waveOutGetPosition@12
extern  __imp__waveOutGetPosition@12
extern  _waveOutReset@4
extern  __imp__waveOutReset@4
extern  _waveOutClose@4
extern  __imp__waveOutClose@4

export GetRenderedAudioBufferPtr
global _GetRenderedAudioBufferPtr
_GetRenderedAudioBufferPtr:
GetRenderedAudioBufferPtr:
        mov eax, dword [rendered_audio_buffer_ptr]
        ret


export SetRenderedAudioBufferPtr
global _SetRenderedAudioBufferPtr
_SetRenderedAudioBufferPtr:
SetRenderedAudioBufferPtr:
        mov eax, [esp+4]
        mov [rendered_audio_buffer_ptr], eax
        ret 4

export StartAudioRendererThread
global _StartAudioRendererThread
_StartAudioRendererThread
StartAudioRendererThread:
    push    0
    push    0
    push    dword [rendered_audio_buffer_ptr]
    push    __4klang_render@4
    push    0
    push    0
    ;call    _CreateThread@24
    call	[__imp__CreateThread@24]
    mov	[audio_thread_handle], eax
    FAIL_ON_WINDOWS_ERROR CreateThread_string
    
    ret


export KillAudioRendererThread
global _KillAudioRendererThread
_KillAudioRendererThread
KillAudioRendererThread:

    ; already killed by this function, or never even started?
    cmp     dword [audio_thread_handle], 0
    je          noeijuu

    push    0
    push    dword [audio_thread_handle]
    call    _WaitForSingleObject@8
    cmp eax, 0 ; WAIT_OBJECT_0 = 0
    je  already_died
; now we hope that the thread doesn't finish after windows told us it's "still alive"
; but before we get to call TerminateThread
    
    push    0
    push    dword [audio_thread_handle]
    call	    [__imp__TerminateThread@8]
    FAIL_ON_WINDOWS_ERROR TerminateThread_string
    
    ; short sleep and let's hope for the best
    push    50
    call    [__imp__Sleep@4]

already_died:    
    mov	dword [audio_thread_handle], 0
noeijuu:    
    ret


export GetWaveOutHandle
global _GetWaveOutHandle
_GetWaveOutHandle
GetWaveOutHandle:
    mov	eax, [hWaveOut]   
    ret

export GetAudioRendererThreadHandle
global _GetAudioRendererThreadHandle
_GetAudioRendererThreadHandle
GetAudioRendererThreadHandle:
    mov	eax, [audio_thread_handle]   
    ret


export GetAudioPlaybackBufferPtr
global _GetAudioPlaybackBufferPtr
_GetAudioPlaybackBufferPtr:
GetAudioPlaybackBufferPtr:
        mov eax, dword [audio_playback_buffer_ptr]
        ret


export SetAudioPlaybackBufferPtr
global _SetAudioPlaybackBufferPtr
_SetAudioPlaybackBufferPtr:
SetAudioPlaybackBufferPtr:
        mov eax, [esp+4]
        mov [audio_playback_buffer_ptr], eax
        ret 4


export GetAudioPlaybackBufferLengthBytes
global _GetAudioPlaybackBufferLengthBytes
_GetAudioPlaybackBufferLengthBytes:
GetAudioPlaybackBufferLengthBytes:
        mov eax, [audio_playback_length_bytes]
        ret

export SetAudioPlaybackBufferLengthBytes
global _SetAudioPlaybackBufferLengthBytes
_SetAudioPlaybackBufferLengthBytes:
SetAudioPlaybackBufferLengthBytes:
        mov eax, [esp+4]
        mov [audio_playback_length_bytes], eax
        ret 4


; For GNU ld to be able to create a DLL from our object code, it has to 
; have both _Play and Play symbols and _Play as global.
;export Play
;global _Play
; _Play:
;Play:    
    ;call StartAudioRendererThread


    ; Wait a bit so that the 4klang's renderer thread gets well ahead of playback position
;    push    200
;    call    [__imp__Sleep@4]

    ;call StartAudio

;    mov eax, 1
;    ret


section .data


global CreateThread_string 
CreateThread_string db 'CreateThread', 0

global TerminateThread_string 
TerminateThread_string db 'TerminateThread', 0

global waveOutOpen_string 
waveOutOpen_string db 'waveOutOpen', 0

global waveOutPrepareHeader_string
waveOutPrepareHeader_string db 'waveOutPrepareHeader', 0

global waveOutWrite_string
waveOutWrite_string db 'waveOutWrite', 0

global waveOutReset_string
waveOutReset_string db 'waveOutReset', 0

global waveOutClose_string
waveOutClose_string db 'waveOutClose', 0

global waveOutGetPosition_string
waveOutGetPosition_string db 'waveOutGetPosition', 0


section .text
    
export StartAudio
global _StartAudio
_StartAudio:
StartAudio:
    mov    dword [WaveHDR_dwFlags], 0
    mov    dword [WaveHDR_dwLoops], 0
    
    cmp     dword [audio_loop_enabled], 0
    je         no_looping

    mov    dword [WaveHDR_dwFlags], WHDR_BEGINLOOP +  WHDR_ENDLOOP
    mov    dword [WaveHDR_dwLoops], -1
no_looping:

    push    0
    push    0
    push    0
    push    pcmFormat
    push    -1
    push    hWaveOut
    call    [__imp__waveOutOpen@24] 
    FAIL_ON_WINMM_ERROR waveOutOpen_string
  
    push    32 ; sizeof(WaveHDR)
    push    WaveHDR
    push    DWORD [hWaveOut]
    call    [__imp__waveOutPrepareHeader@12]
    FAIL_ON_WINMM_ERROR waveOutPrepareHeader_string

    push    32 ; sizeof(WaveHDR)
    push    WaveHDR
    push    DWORD [hWaveOut]
    call    [__imp__waveOutWrite@12]
    FAIL_ON_WINMM_ERROR waveOutWrite_string

    mov eax, 1
    ret


export StopAudio
global _StopAudio
_StopAudio:
StopAudio:
    push    DWORD [hWaveOut]
    call    [__imp__waveOutReset@4]
    FAIL_ON_WINMM_ERROR waveOutReset_string

    push    DWORD [hWaveOut]
    call    [__imp__waveOutClose@4]
    FAIL_ON_WINMM_ERROR waveOutClose_string

    mov DWORD [hWaveOut], 0
    
    mov eax, 1
    ret

    
;  // _4klang_render(myMuzik);
;  CreateThread(0, 0, (LPTHREAD_START_ROUTINE)_4klang_render, myMuzik, 0, 0);

;  Sleep(200);
;  waveOutOpen( &hWaveOut, WAVE_MAPPER, &pcmFormat, NULL, 0, CALLBACK_NULL ); 
;  waveOutPrepareHeader( hWaveOut, &WaveHDR, sizeof(WaveHDR) ); 
;  waveOutWrite  ( hWaveOut, &WaveHDR, sizeof(WaveHDR) ); 
;}

; ---- GetPosition returns the current audio playback position ----
export GetCurrentAudioPosition
global _GetCurrentAudioPosition
_GetCurrentAudioPosition:
GetCurrentAudioPosition:
    push    12  ; sizeof MMTIME struct
    push    MMTime
    push    DWORD [hWaveOut]
    call    [__imp__waveOutGetPosition@12]
    
    FAIL_ON_WINMM_ERROR waveOutGetPosition_string
    
    mov     eax, [MMTime_sample]
    ret

;export SetPosition
;global _SetPosition
;_SetPosition:
;SetPosition:
; TODO
    
;    ret 4

; This isn't actually used, using Winmm audio for seamless looping is too much trouble

export SetAudioLoopEnabled
global _SetAudioLoopEnabled
_SetAudioLoopEnabled:
SetAudioLoopEnabled:
        mov eax, [esp+4]
        mov [audio_loop_enabled], eax
        ret 4
        
        
; -------------------- ^^^^^ END OF MUSIC / AUDIO DATA STUFF ^^^^^ --------------------
