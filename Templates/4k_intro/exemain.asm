; Compofiller Studio by Yzi 2018
;
; Main program for .exe builds
;
;
; There is room for further size-optimizations. Look at the crinkler_report.html to try and find ways to reduce the final size.
; Try to do anything differently. Inline vs. function call? mov vs. push/pop combinations? different orderings for push/pop if you can?
; Try un-defining SLEEP_TO_LET_MUSIC_THREAD_GET_A_HEAD_START.
; Remove the safety padding at the end of the DEVMODE struct.

; ------------------------------------------------- map individual features to needed USE_... stuff
%include "map_features_to_use_defines.inc"

%define SLEEP_TO_LET_MUSIC_THREAD_GET_A_HEAD_START

%ifdef SLEEP_TO_LET_MUSIC_THREAD_GET_A_HEAD_START
%define USE_SLEEP
%endif

%ifdef USE_TEXTS
%include "timings_and_texts.inc"
%endif

; -------------------------------------------------

%include "glconstants.inc"


; screen related variables
section .scrn0 data align=1

; pixel format descriptor - we save some bytes by overlapping the DEVMODE struct with the PIXELFORMATDESCRIPTOR struct
global pfd
pfd:
    db 0x00, 0x00, 0x00, 0x00, 0x21, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
DMSCREENSETTINGS: ; DEVMODE struct
    db 0x00, 0x00, 0x00, 0x00
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x9C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    dd RESOLUTION_X
    dw RESOLUTION_Y   ; <-- we could cut this to just a word and hope that the highest 2 bytes and the rest of the struct is empty (remove the safety padding below)
    
    ; the resolution bytes are like:
    ; db 0x00, 0x05, 0x00, 0x00 ; 1280
    ; db 0xD0, 0x02 ; 720

; remove this safety padding if you want to try and save a byte or two
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00



; ------------------------------ STUFF FOR PCM/4KLANG MUSIC -------------------------
section .audio1 bss align=1
;section .audio1 data align=1
; .bss declares an uninitialized data section
        
;audio_sampling_rate	equ	44100
;audio_length_seconds	equ	(8*60)
;audio_length_samples	equ	(audio_length_seconds*audio_sampling_rate*2)

global hWaveOut
; HWAVEOUT hWaveOut
hWaveOut:	resd    1

global rendered_audio_data
rendered_audio_data:	resb	(AUDIO_BUFFER_ALLOCATED_LENGTH*4)



section .audio2 data align=1
global WaveHDR
WaveHDR: 
WaveHDR_lpData:             dd	rendered_audio_data
WaveHDR_dwBufferLength:		dd	(AUDIO_BUFFER_ALLOCATED_LENGTH * 4) ; audio buffer length in bytes
WaveHDR_dwBytesRecorded:   	dd  0
WaveHDR_dwUser:   	        dd  0
WaveHDR_dwFlags:   	        dd  0
WaveHDR_dwLoops:   	        dd  0
WaveHDR_lpNext:   	        dd  0
WaveHDR_reserved:   	    dd  0


section .audio3 data align=1
global pcmFormat
pcmFormat:
pcmFormat_wFormatTag:       dw  1   ; format type WAVE_FORMAT_PCM
pcmFormat_nChannels:        dw  2   ; number of channels: stereo
pcmFormat_nSamplesPerSec:   dd  AUDIO_SAMPLING_RATE ; sample rate
pcmFormat_nAvgBytesPerSec:  dd  (AUDIO_SAMPLING_RATE*4) ; for buffer estimation
pcmFormat_nBlockAlign:      dw  4   ; block size of data
pcmFormat_wBitsPerSample:   dw  16 ; number of bits per sample of mono data
pcmFormat_cbSize:           dw  0  


section .audio4 data align=1
global MMTime
; MMTIME is a "union" struct that can be used for many different content types based on the first field
MMTime: 	    dd 2 ; wType: TIME_SAMPLES = 2
MMTime_sample:  dd 0 ; actual position value
                db 0, 0, 0, 0 ; some room for other cases



section .shader1 data align=1

extern	shader_glsl

section .shader2 data align=1

global seireripointteri
seireripointteri:
    dd shader_glsl
    
%ifdef USE_TIME_UNIFORM

%ifdef TIME_DIVIDER_IS_INTEGER
    time_divider: dd (%[TIME_DIVIDER])
%else
    time_divider: dd __float32__(%[TIME_DIVIDER])
%endif    
    ; time_uniform_loc: dd 0
    time_uniform_name: db TIME_UNIFORM_NAME, 0
%endif ; USE_TIME_UNIFORM

%ifdef USE_RESOLUTION_UNIFORM
    resolution_uniform_loc: dd 0
    resolution_uniform_name: db RESOLUTION_UNIFORM_NAME, 0
%endif ; USE_RESOLUTION_UNIFORM

%ifdef USE_UNIFORMS
    gl_program: dd 0
%endif

section .gl1 data align=1

global glUseProgram_string
glUseProgram_string:
    db "glUseProgram", 0

section .gl2 data align=1

global glCreateShaderProgramv_string
glCreateShaderProgramv_string:
    db "glCreateShaderProgramv", 0


%ifdef USE_UNIFORMS
section .gl3 data align=1

global glUniform1f_string
glUniform1f_string: db 'glUniform1f', 0

section .gl4 data align=1

global glUniform2f_string
glUniform2f_string: db 'glUniform2f', 0

section .gl5 data align=1

global glGetUniformLocation_string
glGetUniformLocation_string: db 'glGetUniformLocation', 0

glUniform1i_string: db 'glUniform1i', 0

%endif


%ifdef USE_TEXTURES
  %ifdef USE_MIPMAP  
glGenerateMipmap_string: db 'glGenerateMipmap', 0
  %endif
%endif




%ifdef USE_TEXTURES
section .gl3t data align=1
global glActiveTexture_string
glActiveTexture_string: db 'glActiveTexture', 0
%endif




section .text


extern	_ChangeDisplaySettingsA@8
extern	__imp__ChangeDisplaySettingsA@8
extern	_CreateWindowExA@48
extern	__imp__CreateWindowExA@48
extern	_GetDC@4
extern	__imp__GetDC@4
extern	_ChoosePixelFormat@8
extern	__imp__ChoosePixelFormat@8
extern	_SetPixelFormat@12
extern	__imp__SetPixelFormat@12
extern	_wglCreateContext@4
extern	__imp__wglCreateContext@4
extern	_wglMakeCurrent@8
extern	__imp__wglMakeCurrent@8
extern	_wglGetProcAddress@4
extern	__imp__wglGetProcAddress@4
extern	_PeekMessageA@20
extern	__imp__PeekMessageA@20
extern	_ShowCursor@4
extern	__imp__ShowCursor@4
extern	_midiOutOpen@20
extern	__imp__midiOutOpen@20
extern	_midiOutShortMsg@8
extern	__imp__midiOutShortMsg@8
extern	_timeGetTime@0
extern	__imp__timeGetTime@0
extern	_glRecti@16
extern	__imp__glRecti@16
extern	_glColor3s@12
extern	__imp__glColor3s@12
extern	_glColor3us@12
extern	__imp__glColor3us@12
extern	_SwapBuffers@4
extern	__imp__SwapBuffers@4
extern	_GetAsyncKeyState@4
extern	__imp__GetAsyncKeyState@4
extern	_ExitProcess@4
extern	__imp__ExitProcess@4


%ifdef USE_TEXTURES
extern  _glBindTexture@8
extern  __imp__glBindTexture@8
extern  _glTexParameteri@12
extern  __imp__glTexParameteri@12
extern  _glCopyTexImage2D@32
extern  __imp__glCopyTexImage2D@32
%endif


; %define USE_TEXTS

%ifdef USE_TEXTS

extern  _glBindTexture@8
extern  __imp__glBindTexture@8
extern  _glTexParameteri@12
extern  __imp__glTexParameteri@12
extern  _glTexImage2D@36
extern  __imp__glTexImage2D@36

; --- functions ---  Gdi32.Lib
; CreateCompatibleDC@4	HDC CreateCompatibleDC(HDC hdc)
extern _CreateCompatibleDC@4
extern __imp__CreateCompatibleDC@4
; CreateDIBSection@24		HBITMAP CreateDIBSection(HDC hdc, CONST BITMAPINFO *pbmi, UINT usage, VOID **ppvBits, HANDLE hSection, DWORD offset)
extern _CreateDIBSection@24
extern __imp__CreateDIBSection@24
; CreateFontA@56		HFONT CreateFontA(int cHeight, int cWidth, int cEscapement, int cOrientation, int cWeight, DWORD bItalic, DWORD bUnderline, DWORD bStrikeOut, DWORD iCharSet, DWORD iOutPrecision, DWORD iClipPrecision, DWORD iQuality, DWORD iPitchAndFamily, LPCSTR pszFaceName)
extern _CreateFontA@56
extern __imp__CreateFontA@56

; SelectObject@8		HGDIOBJ SelectObject(HDC hdc, HGDIOBJ h)
extern _SelectObject@8
extern __imp__SelectObject@8
; EHKÄ SetBkColor@8		COLORREF SetBkColor(HDC hdc, COLORREF color)
extern _SetBkColor@8
extern __imp__SetBkColor@8
; SetTextColor@8		COLORREF SetTextColor(HDC hdc, COLORREF color)
extern _SetTextColor@8
extern __imp__SetTextColor@8

%if TEXT_CHARACTER_EXTRA_SPACING > 0
; SetTextCharacterExtra@8 	int SetTextCharacterExtra(HDC hdc, int extra)
extern _SetTextCharacterExtra@8
extern __imp__SetTextCharacterExtra@8
%endif

; HGDIOBJ GetStockObject(int i)
extern _GetStockObject@4
extern __imp__GetStockObject@4

; --- functions --- User32.Lib
; DrawText@20			int DrawText(HDC hdc, LPCTSTR lpchText, int cchText, LPRECT lprc, UINT format)
%ifdef USE_WIDECHAR_TEXTS
extern _DrawTextW@20
extern __imp__DrawTextW@20
%else 
extern _DrawTextA@20
extern __imp__DrawTextA@20
%endif

; FillRect@12  	int FillRect(HDC *hDC, const RECT *lprc, HBRUSH hbr)
extern _FillRect@12
extern __imp__FillRect@12


; --- constants ---
; DIB_RGB_COLORS  #define DIB_RGB_COLORS      0 /* color table in RGBs */
; FW_BOLD #define FW_NORMAL           400
; 		#define FW_BOLD             700
; ANSI_CHARSET	#define ANSI_CHARSET            0
; OUT_DEFAULT_PRECIS	#define OUT_DEFAULT_PRECIS          0
; CLIP_DEFAULT_PRECIS	#define CLIP_DEFAULT_PRECIS     0
; ANTIALIASED_QUALITY	#define NONANTIALIASED_QUALITY  3
; 					#define DEFAULT_QUALITY         0
; DEFAULT_PITCH	#define DEFAULT_PITCH           0
;
; --- other ---
; font name e.g. "Times New Roman"

%include "winconstants.inc"

%endif ; USE_TEXTS


section .code1 code align=1

; our main entry point is called "t"
global t
t:
main:
    push	4
    push	DMSCREENSETTINGS
    call	[__imp__ChangeDisplaySettingsA@8]

    push	0
    push	0
    push	0
    push	0
    push	0
    push	0
    push	0
    push	0
    push	0x91000000
    push	0
    push	0xC018 ; http://www.pouet.net/topic.php?which=9894
    push	0
    call	[__imp__CreateWindowExA@48]


    push	eax
    call	[__imp__GetDC@4]
    
    push	eax
    pop	edi			; edi : HDC
	; all functions we call must preserve the edi register now

    push	pfd
    push	pfd
    push	edi
    call	[__imp__ChoosePixelFormat@8]
    push	eax
    push	edi 
    call	[__imp__SetPixelFormat@12]

    push	edi
    call	[__imp__wglCreateContext@4]
    push	eax
    push	edi
    call	[__imp__wglMakeCurrent@8]

    push	seireripointteri
    push	1
    push	0x00008b30 
    push	glCreateShaderProgramv_string
    call  	[__imp__wglGetProcAddress@4]
    call	eax

%ifdef USE_UNIFORMS
    mov     [gl_program], eax
%endif
    
    push	eax
    push	glUseProgram_string
    call	[__imp__wglGetProcAddress@4]
    call	eax

%ifdef USE_TEXTS
    call InitTextDrawingStuff
%endif
    
    ; play music, running 4klang audio renderer in a separate thread
;    call	Play
    ; create a separate thread for 4klang to render its audio in the background
    push    0
    push    0
    push    rendered_audio_data + (AUDIO_DELAY * 4)
    push    __4klang_render@4
    push    0
    push    0
    call	[__imp__CreateThread@24]
    
%ifdef SLEEP_TO_LET_MUSIC_THREAD_GET_A_HEAD_START
    ; Wait/sleep for 200 milliseconds so that 4klang's renderer thread gets well on its way, before we start playback
    push    200 ; if your music is too CPU heavy, try increasing this number
    call    [__imp__Sleep@4]
%endif    
    
    push    0
    push    0
    push    0
    push    pcmFormat
    push    -1
    push    hWaveOut
    call    [__imp__waveOutOpen@24]
    
    push    32 ; sizeof(WaveHDR)
    push    WaveHDR
    push    DWORD [hWaveOut]
    call    [__imp__waveOutPrepareHeader@12]
    
    push    32 ; sizeof(WaveHDR)
    push    WaveHDR
    push    DWORD [hWaveOut]
    call    [__imp__waveOutWrite@12]        ;  <--- audio starts now

; -------------- main program loop, repeat until we reach the ending time position, or the user presses Esc ----------- LOOP
luuppi:
    ; hide mouse pointer
    push	0
    call	[__imp__ShowCursor@4]
    
    ; pump window message queue (or otherwise Windows will think that our program hung up)
    push	1
    push	0
    push	0
    push	0
    push	0
    call	[__imp__PeekMessageA@20]


%ifdef FRAME_TO_TEXTURE
; --- copy previous frame to texture before running the shader ---
    call copy_framebuffer_to_texture
%endif    

    call 	GetPosition ; <-- get the time to eax

; did we reach the end of the prod?
    cmp     eax, %[PROD_END_TIME] 
    jae     loppu

%ifdef USE_TEXTS
    push eax
%endif

; time is in eax
    call 	set_time_in_EAX_to_shader

%ifdef USE_TEXTS
;    pop eax
    ; check
    call update_texts_time_on_STACK
    pushad
    call DrawTextBitmap
    popad
%endif




%ifdef USE_RESOLUTION_UNIFORM
    push	glGetUniformLocation_string
    call  	[__imp__wglGetProcAddress@4]
    ; FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

    push    resolution_uniform_name
    push    dword [gl_program]
    call    eax
    mov     [resolution_uniform_loc], eax
    ; FAIL_ON_GL_ERROR glGetUniformLocation_string

    push	glUniform2f_string
    call  	[__imp__wglGetProcAddress@4]
    ; FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

    push    __float32__(%[RESOLUTION_Y].0)
    push    __float32__(%[RESOLUTION_X].0)
    push    dword [resolution_uniform_loc]
    call    eax
    ; FAIL_ON_GL_ERROR glUniform2f_string
%endif ; USE_RESOLUTION_UNIFORM  

; draw one full-screen quad
	call draw_full_screen_quad
	
; ________ IF TWO_PASS_RENDERING DRAW ONCE MORE, WITH TIME = 0 _______
%ifdef TWO_PASS_RENDERING
	call copy_framebuffer_to_texture

%ifdef SECOND_PASS_NEGATIVE_TIME
	call 	GetPosition ; <-- get the time to eax
	neg eax
%else
	xor eax, eax ; push 0; pop eax might be smaller
%endif	
	call set_time_in_EAX_to_shader

; draw another full-screen quad
        call draw_full_screen_quad
      ; ----------------------- ^^^TWO-PASS RENDERING^^^-----------------------
%endif ; TWO_PASS_RENDERING




; ------------------------------------------- SWAP BUFFERS -------------------------------------

    push	edi
    call	[__imp__SwapBuffers@4]


    ; Esc pressed?
    push	27					; 0000001bH
    call	[__imp__GetAsyncKeyState@4]
    test	eax, eax

%ifdef USE_UNIFORMS
    je	luuppi
%else
    je	SHORT luuppi
%endif

loppu:
    push	0
    call	[__imp__ExitProcess@4]    ; <--- end program execution


section .cdennn


section .text

; the __imp__ versions refer to the corresponding import address table entries
extern  __4klang_render@4
extern  _CreateThread@24
extern __imp__CreateThread@24

%ifdef USE_SLEEP
extern  _Sleep@4
extern  __imp__Sleep@4
%endif

extern  _waveOutOpen@24
extern  __imp__waveOutOpen@24
extern  _waveOutPrepareHeader@12
extern  __imp__waveOutPrepareHeader@12
extern  _waveOutWrite@12
extern  __imp__waveOutWrite@12
extern  _waveOutGetPosition@12
extern  __imp__waveOutGetPosition@12
    
section .code2 code align=1

;global Play
;Play:
    
;    ret


; ---- GetPosition returns the current audio playback position ----
section .code3 code align=1
global GetPosition
GetPosition:
    push    12  ; sizeof MMTIME struct
    push    MMTime
    push    DWORD [hWaveOut]
    call    [__imp__waveOutGetPosition@12]
    mov     eax, [MMTime_sample]
    ret


%ifdef USE_COPY_FRAMEBUFFER_TO_TEXTURE
section .cde231 code align=1
global copy_framebuffer_to_texture
copy_framebuffer_to_texture:
%ifdef MORE_THAN_ONE_TEXTURE
    push	glActiveTexture_string
    call  	[__imp__wglGetProcAddress@4]
;    FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string
    push    GL_TEXTURE0
    call    eax
;    JUMP_ON_GL_ERROR .fail, glActiveTexture_string

; --- copy previous frame to texture before running the shader ---
    push    0
    push    GL_TEXTURE_2D
    call    [__imp__glBindTexture@8]
;    JUMP_ON_GL_ERROR .fail, glBindTexture_string
%endif ; MORE_THAN_ONE_TEXTURE

%ifdef USE_MIPMAP
    push    GL_LINEAR_MIPMAP_LINEAR
%else
    push    GL_LINEAR
%endif
    push    GL_TEXTURE_MIN_FILTER
    push    GL_TEXTURE_2D
    call    [__imp__glTexParameteri@12]
;    JUMP_ON_GL_ERROR .fail, glTexParameteri_string

    push    0               ; border
    push    RESOLUTION_Y    ; height
    push    RESOLUTION_X    ; width
    push    0               ; y
    push    0               ; x
    push    GL_RGBA8        ; internalformat
    push    0               ; level, mipmap level-of-detail number
    push    GL_TEXTURE_2D   ; target
    call    [__imp__glCopyTexImage2D@32]
;    JUMP_ON_GL_ERROR .fail, glCopyTexImage2D_string


%ifdef USE_MIPMAP
    push	glGenerateMipmap_string
    call	[__imp__wglGetProcAddress@4]
    push	GL_TEXTURE_2D
    call	eax
%endif

    ret
%endif


; set_time_in_EAX_to_shader(time), as parameter: eax = time
section .cde232 code align=1
set_time_in_EAX_to_shader:

%ifdef USE_TIME_UNIFORM
    push    eax
    fild    dword [esp]   ; load the audio position to FPU stack (0) so we can divide it

%ifdef TIME_DIVIDER_IS_INTEGER
    fidiv dword [time_divider]
%else
    fdiv dword [time_divider]
%endif
    fstp    dword [esp] ; store from FPU stack to top of CPU stack, replacing it with the divided floating point time value
    
    ; on top of stack i.e. [esp] is now the SECOND parameter (pushed first in stdcall) to glUniform1f()
    
    push	glGetUniformLocation_string
    call  	[__imp__wglGetProcAddress@4]

    push    time_uniform_name
    push    dword [gl_program]
    call    eax ; call glGetUniformLocation
;    mov     [time_uniform_loc], eax
    push	eax ; <-- FIRST parameter (pushed last) to glUniform1f()
    
; set the shader uniform variables
    push	glUniform1f_string
    call  	[__imp__wglGetProcAddress@4]
    ; eax = pointer to glUniform1f() function
    call    eax		; call glUniform1f()

%else
; ---- NOT USE_TIME_UNIFORM ---
; green color is (time position >> 8), meaning the color value grows by 1/65536 every 256/44100 seconds (if we have 44100 Hz audio sample rate)
    ;shr	eax, 8
    sar	eax, 8
    push	0
    push	eax	; green color is (time position >> 8), meaning the color value grows by 1/65536 every 256/44100 seconds (if we have 44100 Hz audio sample rate)
    push	0
    call	[__imp__glColor3s@12]
%endif ; (not) USE_TIME_UNIFORM
    ret

section .cde233 code align=1
draw_full_screen_quad:
    push	-1
    push	-1
    push	1
    push	1
    call	[__imp__glRecti@16]
    ret
    
    
%ifdef USE_TEXTS

section .data
%ifdef GEN_TEXTURES	
texts_gl_texture_name: dd 0
%endif


hardcoded_font_name: db TEXT_FONT_NAME, 0
text_font_name: dd hardcoded_font_name


current_text_ptr: dd _string0
current_timing_ptr: dd text_string_timings

textsDC:	dd 0
textsBitmapHandle: dd 0
textsBitmapBitsPtr: dd 0
textsFontHandle: dd 0

TextRectangle: ; we overlap this with BitmapInfo
	dd 0
	; , 0, TEXT_BITMAP_RESOLUTION_X, TEXT_BITMAP_RESOLUTION_Y

BitmapInfo: ; bmiHeader
	dd 40 ; biSize, it doesn't seem to work if you give 0 in this field
BitmapInfo_biWidth: dd TEXT_BITMAP_RESOLUTION_X ; biWidth
BitmapInfo_biHeight: dd TEXT_BITMAP_RESOLUTION_Y ; biHeight
BitmapInfo_biPlanes: dw 1 ; biPlanes
        dw 32 ; biBitCount
	dd 0 ; biCompression
	dd 0 ; biSizeImage
	dd 0 ; biXPelsPerMeter
	dd 0 ; biYPelsPerMeter
	dd 0 ; biClrUsed
	dd 0 ; biClrImportant
	dd 0 ; bmiColors

texts_uniform_loc: dd 0
texts_uniform_name: db TEXTS_UNIFORM_NAME, 0

section .cdet33 code align=1
;update_texts_time_in_EAX:
update_texts_time_on_STACK:
    ;    if current time >= current_text->time
    ;    	draw text to buffer
    ;    	move current_text pointer to next text

.seek_loop
	mov eax, [current_timing_ptr]
	mov ecx, dword [eax] ; get time value from the timings
	cmp ecx, [esp+4]
	ja	.skip
	; set current string pointer
	mov ecx, [eax+TIMINGS_REC_STRING_PTR_FIELD_OFS]
	mov [current_text_ptr], ecx	
	; move timing pointer to next timing rec
	add eax, TIMINGS_REC_SIZE
	mov [current_timing_ptr], eax 
	jmp .seek_loop
.skip:	    
    ret


section .cde3133 code align=1
InitTextDrawingStuff:
  %ifdef GEN_TEXTURES
	push texts_gl_texture_name
	push 1
	call  [__imp__glGenTextures@8]
  %endif
	
	push 0
	call [__imp__CreateCompatibleDC@4]
	mov [textsDC], eax
	; test eax, eax
	; jz .fail

%if TEXT_CHARACTER_EXTRA_SPACING > 0
	push TEXT_CHARACTER_EXTRA_SPACING
	push eax
	call [__imp__SetTextCharacterExtra@8]
%endif

; CreateDIBSection@24		
; HBITMAP CreateDIBSection(HDC hdc, CONST BITMAPINFO *pbmi, UINT usage, VOID **ppvBits, HANDLE hSection, DWORD offset)
	push 0 ; offset
	push 0 ; hSection
	push	textsBitmapBitsPtr ; ppvBits
	push DIB_RGB_COLORS ; usage
	push BitmapInfo ; BITMAPINFO *pbmi
	push	dword [textsDC] ; hdc
	call [__imp__CreateDIBSection@24]
	mov [textsBitmapHandle], eax	
	; test eax, eax
	; jz .fail
	
	mov dword [BitmapInfo], 0 ; clear the first field of BitmapInfo, so we can use it as part of the RECT structure
	
; CreateFontA@56		HFONT CreateFontA(int cHeight, int cWidth, int cEscapement, int cOrientation, int cWeight, DWORD bItalic, DWORD bUnderline, 
;     DWORD bStrikeOut, DWORD iCharSet, DWORD iOutPrecision, DWORD iClipPrecision, DWORD iQuality, DWORD iPitchAndFamily, LPCSTR pszFaceName)	
	push	dword [text_font_name] ; font name
	push 0 ; iPitchAndFamily
	push ANTIALIASED_QUALITY ; iQuality
	push CLIP_DEFAULT_PRECIS ; iClipPrecision
	push OUT_DEFAULT_PRECIS ; iOutPrecision
	push ANSI_CHARSET ; iCharSet
	push TEXT_FONT_STRIKEOUT ; bStrikeOut
	push TEXT_FONT_UNDERLINE ; bUnderline
	push TEXT_FONT_ITALIC ; bItalic
	push TEXT_FONT_WEIGHT ; cWeight     FW_BOLD = 700
	push TEXT_FONT_ORIENTATION ; cOrientation
	push TEXT_FONT_ESCAPEMENT ; cEscapement
	push TEXT_FONT_WIDTH ; cWidth
	push -TEXT_FONT_SIZE ; cHeight
	call [__imp__CreateFontA@56]
	
	mov [textsFontHandle], eax	

.fail:
	ret
	
	
DrawTextBitmap:
; SelectObject@8		HGDIOBJ SelectObject(HDC hdc, HGDIOBJ h)
	push dword [textsBitmapHandle]
	push dword [textsDC]
	call [__imp__SelectObject@8]

	push dword [textsFontHandle]
	push dword [textsDC]
	call [__imp__SelectObject@8]

; SetBkColor@8		COLORREF SetBkColor(HDC hdc, COLORREF color)
	
	push 0x000000 ; black color
	push dword [textsDC]
	call [__imp__SetBkColor@8]

; SetTextColor@8		COLORREF SetTextColor(HDC hdc, COLORREF color)
	push 0x00FFFFFF ; black color
	push dword [textsDC]
	call [__imp__SetTextColor@8]

; some stock object constants
WHITE_BRUSH equ 0
BLACK_BRUSH equ 4
DC_BRUSH equ 18



	push BLACK_BRUSH
	call [__imp__GetStockObject@4] ; wingdi.h / Gdi32.lib / Gdi32.dll
	
	push eax ; HBRUSH hbr
	push TextRectangle ; RECT *lprc
	push dword [textsDC] ; HDC hDC
	call [__imp__FillRect@12] ; winuser.h / User32.lib
	
; --- functions --- User32.Lib
; DrawText@20			int DrawText(HDC hdc, LPCTSTR lpchText, int cchText, LPRECT lprc, UINT format)
	push DT_CENTER ; format
	push TextRectangle ; lprc	
	push -1 ; cchText, -1 means null-terminated
	
	push dword [current_text_ptr] ; lpchText
	
	push dword [textsDC]
%ifdef USE_WIDECHAR_TEXTS
	call  [__imp__DrawTextW@20]
%else 
	call  [__imp__DrawTextA@20]
%endif	

%ifdef MORE_THAN_ONE_TEXTURE
	push	glActiveTexture_string
	call  	[__imp__wglGetProcAddress@4]
	; FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

	; use texture unit 1 for texts, if there's more than one texture
	push GL_TEXTURE1
	call    eax
	;JUMP_ON_GL_ERROR .fail, glActiveTexture_string
%endif

; do we want to mipmap the texts too?
;%ifdef USE_MIPMAP
    ;push    GL_LINEAR_MIPMAP_LINEAR
;%else
    push    GL_LINEAR
;%endif
    push    GL_TEXTURE_MIN_FILTER
    push    GL_TEXTURE_2D
    call    [__imp__glTexParameteri@12]
    ; JUMP_ON_GL_ERROR .fail, glTexParameteri_string


; "Texture names are unsigned integers with the value zero reserved to represent the default texture for each texture target."
%ifdef MORE_THAN_ONE_TEXTURE

%ifdef GEN_TEXTURES
	push dword [texts_gl_texture_name]
%else
	push 1
%endif
	push GL_TEXTURE_2D
	call [__imp__glBindTexture@8]
%endif ; MORE_THAN_ONE_TEXTURE


	push dword [textsBitmapBitsPtr] ; pixels 
	push GL_UNSIGNED_BYTE ; type
	push GL_RGBA ; format
	push 0 ; border
	push TEXT_BITMAP_RESOLUTION_Y ; height
	push TEXT_BITMAP_RESOLUTION_X ; width
	push GL_RGBA ; internal format
	push 0 ; level of detail
	push GL_TEXTURE_2D
	call [__imp__glTexImage2D@36]
	
	;glGenTextures(1, &texture);
	;glActiveTexture(GL_TEXTURE1);
	;glBindTexture(GL_TEXTURE_2D, texture); // activate first texture
;	glTexImage2D( GL_TEXTURE_2D, 0 /* level of detail */ , GL_RGBA, TEXTDISPLAY_XRES/*width*/, TEXTDISPLAY_YRES/*height*/, 0/*border*/, GL_RGBA, GL_UNSIGNED_BYTE, TextBitmaps[textindex]); 
	 ;void glTexImage2D (GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
; --- other ---
; font name e.g. "Times New Roman"

%ifdef USE_TEXTS_UNIFORM
    push	glGetUniformLocation_string
    call  	[__imp__wglGetProcAddress@4]
    ; FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

    push    texts_uniform_name
    push    dword [gl_program]
    call    eax
    mov     [texts_uniform_loc], eax
    ; JUMP_ON_GL_ERROR_EXT .fail, glGetUniformLocation_string, texts_uniform_name

    push	glGetUniformLocation_string
    call  	[__imp__wglGetProcAddress@4]
    ; FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string
    
    push	glUniform1i_string
    call  	[__imp__wglGetProcAddress@4]
    ; FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

%ifdef GEN_TEXTURES
      push dword [texts_gl_texture_name]
%else
      push 1
%endif
      push    dword [texts_uniform_loc]
      call    eax
      ; JUMP_ON_GL_ERROR .fail, glUniform1i_string
%endif ; USE_TEXTS_UNIFORM
    ret

%endif ; USE_TEXTS

; end-of-file
