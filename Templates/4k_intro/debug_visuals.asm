; yasm -f win32 -o dlltest.obj dlltest.asm
; ld --dll -entry=DllMain@12 -L C:\utils -o dlltest.dll dlltest.obj -l user32 

; Compofiller Studio by Yzi
;
; Debug DLL for visuals
;
; ------------------------------------------------- map individual features to needed USE_... stuff
%include "map_features_to_use_defines.inc"

%include "errormsg.inc"

%ifdef USE_TEXTS
%include "timings_and_texts.inc"
%endif

; ..start:


    extern _Beep@8
    extern __imp__Beep@8

DLL_PROCESS_ATTACH equ 1
DLL_PROCESS_DETACH equ 0
DLL_THREAD_ATTACH equ 2
DLL_THREAD_DETACH equ 3

global  DllMain@12
DllMain@12:		; This code is required in .dll files
        mov eax, 1
        ret 12
        
; debugging code: comment out the above to hear beeps when the dll is loaded and unloaded
        cmp dword [esp+8], DLL_PROCESS_ATTACH
        je msg_DLL_PROCESS_ATTACH
        
        cmp dword [esp+8], DLL_PROCESS_DETACH
        je msg_DLL_PROCESS_DETACH

        cmp dword [esp+8], DLL_THREAD_ATTACH
        je msg_DLL_THREAD_ATTACH

        cmp dword [esp+8], DLL_THREAD_DETACH
        je msg_DLL_THREAD_DETACH

;        push 5000 ; dwDuration
;        push 200 ; dwFreq (Hz)
;        call [__imp__Beep@8]
        

exitDllMain:
; https://msdn.microsoft.com/en-us/library/windows/desktop/ms682583(v=vs.85).aspx
; "When the system calls the DllMain function with the DLL_PROCESS_ATTACH value, 
; the function returns TRUE if it succeeds or FALSE if initialization fails. If the return 
; value is FALSE when DllMain is called because the process uses the LoadLibrary 
; function, LoadLibrary returns NULL. (The system immediately calls your entry-point 
; function with DLL_PROCESS_DETACH and unloads the DLL.)" 
        mov eax, 1
        ret 12

msg_DLL_PROCESS_ATTACH:
; DllMain shouldn't call things in User32, so we're using Beep() from Kernel32
        push 500 ; dwDuration
        push 400 ; dwFreq (Hz)
        call [__imp__Beep@8]

;    push    msgstr_DLL_PROCESS_ATTACH
;    call ShowErrorMessage    
    jmp exitDllMain
        
msg_DLL_PROCESS_DETACH:
;    push    msgstr_DLL_PROCESS_DETACH
;    call ShowErrorMessage    
        push 500 ; dwDuration
        push 100 ; dwFreq (Hz)
        call [__imp__Beep@8]
    jmp exitDllMain
    
msg_DLL_THREAD_ATTACH:
;    push    msgstr_DLL_THREAD_ATTACH
;    call ShowErrorMessage    
        push 50 ; dwDuration
        push 400 ; dwFreq (Hz)
        call [__imp__Beep@8]
    jmp exitDllMain
    
msg_DLL_THREAD_DETACH:
;    push    msgstr_DLL_THREAD_DETACH
;    call ShowErrorMessage    
        push 50 ; dwDuration
        push 100 ; dwFreq (Hz)
        call [__imp__Beep@8]
    jmp exitDllMain


;msgstr_DLL_PROCESS_ATTACH: db "debug_visuals.dll / DllMain(... DLL_PROCESS_ATTACH ...)", 0
;msgstr_DLL_PROCESS_DETACH: db "debug_visuals.dll / DllMain(... DLL_PROCESS_DETACH ...)", 0
;msgstr_DLL_THREAD_ATTACH: db "debug_visuals.dll / DllMain(... DLL_THREAD_ATTACH ...)", 0
;msgstr_DLL_THREAD_DETACH: db "debug_visuals.dll / DllMain(... DLL_THREAD_DETACH ...)", 0


; screenvariables
section .data

PFD_DOUBLEBUFFER equ 0x00000001
PFD_DRAW_TO_WINDOW equ 0x00000004
PFD_DRAW_TO_BITMAP equ 0x00000008
PFD_SUPPORT_OPENGL equ 0x00000020

global pfd
pfd:
    db 0x00, 0x00 ; nSize
    db 0x00, 0x00 ; nVersion
  ; dwFlags:
    db PFD_DOUBLEBUFFER + PFD_SUPPORT_OPENGL + PFD_DRAW_TO_BITMAP ; 0x21
    db 0x00, 0x00, 0x00
    db 0x00, 0x00, 0x00, 0x00
DMSCREENSETTINGS:
    db 0x00, 0x00, 0x00, 0x00
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x9C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00
    db 0xD0, 0x02

    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00



global WindowHandle
WindowHandle: dd 0
    
global WindowDC
WindowDC: dd 0
    
global glContext
glContext:  dd  0
    

%include "glconstants.inc"



SHADER_INFO_LOG_MAX_LENGTH equ 1000
shader_info_log_length: dd 0
shader_info_log:    times SHADER_INFO_LOG_MAX_LENGTH dd 0

section .text
EXPORT_FUNC GetShaderInfoLog
    mov eax, shader_info_log
    ret

; getters for those
section .text
    
export GetGLContext
global _GetGLContext
_GetGLContext:
GetGLContext:
        mov eax, [glContext]
        ret

export GetWindowHandle
global _GetWindowHandle
_GetWindowHandle:
GetWindowHandle:
        mov eax, [WindowHandle]
        ret

export GetWindowDC
global _GetWindowDC
_GetWindowDC:
GetWindowDC:
        mov eax, [WindowDC]
        ret


section .data

; extern	shader_glsl

global seireripointteri
; seireripointteri: dd shader_glsl
seireripointteri: dd 0


global glCreateProgram_string
glCreateProgram_string: db 'glCreateProgram', 0

global glDeleteProgram_string
glDeleteProgram_string: db 'glDeleteProgram', 0

global glCreateShader_string
glCreateShader_string: db 'glCreateShader', 0

global glDeleteShader_string
glDeleteShader_string: db 'glDeleteShader', 0

global glDetachShader_string
glDetachShader_string: db 'glDetachShader', 0

global glShaderSource_string
glShaderSource_string: db 'glShaderSource', 0

global glCompileShader_string
glCompileShader_string: db 'glCompileShader', 0
    
global glAttachShader_string
glAttachShader_string: db 'glAttachShader', 0

global glIsShader_string
glIsShader_string: db 'glIsShader', 0

global glGetShaderInfoLog_string
glGetShaderInfoLog_string: db 'glGetShaderInfoLog', 0

global glLinkProgram_string
glLinkProgram_string: db 'glLinkProgram', 0

global glUseProgram_string
glUseProgram_string: db 'glUseProgram', 0
    
global glCreateShaderProgramv_string
glCreateShaderProgramv_string: db 'glCreateShaderProgramv', 0

%ifdef USE_UNIFORMS
global glUniform1f_string
glUniform1f_string: db 'glUniform1f', 0

global glUniform1i_string
glUniform1i_string: db 'glUniform1i', 0

global glUniform2f_string
glUniform2f_string: db 'glUniform2f', 0

global glGetUniformLocation_string
glGetUniformLocation_string: db 'glGetUniformLocation', 0
%endif

global glActiveTexture_string
glActiveTexture_string: db 'glActiveTexture', 0

global glBindTexture_string
glBindTexture_string: db 'glBindTexture', 0

global glTexParameteri_string
glTexParameteri_string: db 'glTexParameteri', 0

global glCopyTexImage2D_string
glCopyTexImage2D_string: db 'glCopyTexImage2D', 0

global glGenerateMipmap_string
glGenerateMipmap_string: db 'glGenerateMipmap', 0

 ; User32
global CreateWindowEx_string 
CreateWindowEx_string db 'CreateWindowEx', 0

; User32
global ChangeDisplaySettings_string 
ChangeDisplaySettings_string db 'ChangeDisplaySettings', 0

; User32
global GetDC_string
GetDC_string db 'GetDC', 0

; User32
global ReleaseDC_string
ReleaseDC_string db 'ReleaseDC', 0

; Gdi32
global ChoosePixelFormat_string 
ChoosePixelFormat_string db 'ChoosePixelFormat', 0

; Gdi32
global SetPixelFormat_string 
SetPixelFormat_string db 'SetPixelFormat', 0

; Opengl32
global wglCreateContext_string 
wglCreateContext_string db 'wglCreateContext', 0

; Opengl32
global wglMakeCurrent_string
wglMakeCurrent_string db 'wglMakeCurrent', 0

; Opengl32
global wglGetProcAddress_string
wglGetProcAddress_string db 'wglGetProcAddress', 0

; Opengl32
global glColor3us_string
glColor3us_string db 'glColor3us', 0

global glColor3s_string
glColor3s_string db 'glColor3s', 0

; Opengl32
global glRecti_string
glRecti_string db 'glRecti', 0

; Gdi32
global SwapBuffers_string
SwapBuffers_string db 'SwapBuffers', 0

; ___ OpenGL object handles ___

section .data
gl_program: dd 0
gl_shader:  dd 0

%ifdef USE_TIME_UNIFORM
time_uniform_loc: dd 0
time_uniform_name: db TIME_UNIFORM_NAME, 0
%endif

%ifdef USE_RESOLUTION_UNIFORM
resolution_uniform_loc: dd 0
resolution_uniform_name: db RESOLUTION_UNIFORM_NAME, 0
%endif

%ifdef USE_TEXTS_UNIFORM
texts_uniform_loc: dd 0
texts_uniform_name: db TEXTS_UNIFORM_NAME, 0
%endif

%ifdef TIME_DIVIDER_IS_INTEGER
    time_divider: dd (%[TIME_DIVIDER])
%else
    time_divider: dd __float32__(%[TIME_DIVIDER])
%endif



section .text

; static GLchar *seireripointteri = &shader_glsl;

    ;extern  _MessageBoxA@16
;%define MessageBox _MessageBoxA@16

; global  DllMain@12

; __imp__

extern	_ChangeDisplaySettingsA@8
extern	__imp__ChangeDisplaySettingsA@8
extern	_CreateWindowExA@48
extern	__imp__CreateWindowExA@48
extern	_GetDC@4
extern	__imp__GetDC@4
extern	_ReleaseDC@8
extern	__imp__ReleaseDC@8
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
extern	_glRecti@16
extern	__imp__glRecti@16
extern	_glColor3us@12
extern	__imp__glColor3us@12
extern	_glColor3s@12
extern	__imp__glColor3s@12
extern	_SwapBuffers@4
extern	__imp__SwapBuffers@4
extern	_GetAsyncKeyState@4
extern  __imp__GetAsyncKeyState@4
extern  _glGetError@0
extern  __imp__glGetError@0

; ---------- textures --------
extern  _glBindTexture@8
extern  __imp__glBindTexture@8
extern  _glTexParameteri@12
extern  __imp__glTexParameteri@12
extern  _glCopyTexImage2D@32
extern  __imp__glCopyTexImage2D@32
; ---------------------------




%ifdef USE_TEXTS
; --- functions ---  Gdi32.Lib
; CreateCompatibleDC@4	HDC CreateCompatibleDC(HDC hdc)
extern _CreateCompatibleDC@4
extern __imp__CreateCompatibleDC@4

; extern __imp__CreateDCA@16

; CreateDIBSection@24		HBITMAP CreateDIBSection(HDC hdc, CONST BITMAPINFO *pbmi, UINT usage, VOID **ppvBits, HANDLE hSection, DWORD offset)
extern _CreateDIBSection@24
extern __imp__CreateDIBSection@24

; CreateFontA@56		HFONT CreateFontA(int cHeight, int cWidth, int cEscapement, int cOrientation, int cWeight, DWORD bItalic, DWORD bUnderline, DWORD bStrikeOut, DWORD iCharSet, DWORD iOutPrecision, DWORD iClipPrecision, DWORD iQuality, DWORD iPitchAndFamily, LPCSTR pszFaceName)
extern _CreateFontA@56
extern __imp__CreateFontA@56

; SelectObject@8		HGDIOBJ SelectObject(HDC hdc, HGDIOBJ h)
extern _SelectObject@8
extern __imp__SelectObject@8


extern _DeleteObject@4
extern __imp__DeleteObject@4


extern _DeleteDC@4
extern __imp__DeleteDC@4


; SetBkColor@8		COLORREF SetBkColor(HDC hdc, COLORREF color)
extern _SetBkColor@8
extern __imp__SetBkColor@8

; SetTextColor@8		COLORREF SetTextColor(HDC hdc, COLORREF color)
extern _SetTextColor@8
extern __imp__SetTextColor@8

; SetTextCharacterExtra@8 	int SetTextCharacterExtra(HDC hdc, int extra)
extern _SetTextCharacterExtra@8
extern __imp__SetTextCharacterExtra@8

; SetTextAlign@8 	UINT SetTextAlign(HDC hdc, UINT align)
extern _SetTextAlign@8
extern __imp__SetTextAlign@8

; SetTextJustification@8	BOOL SetTextJustification(HDC hdc, int extra, int count)
extern _SetTextJustification@12
extern __imp__SetTextJustification@12


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


; ----

extern _glGenTextures@8
extern __imp__glGenTextures@8

extern _glDeleteTextures@8
extern __imp__glDeleteTextures@8

extern _glTexImage2D@36
extern __imp__glTexImage2D@36


; --- other ---
; font name e.g. "Times New Roman"

%include "winconstants.inc"


section .data
hardcoded_font_name: db TEXT_FONT_NAME, 0
	
global text_font_name
text_font_name: dd hardcoded_font_name

; global text_string_ptr
; text_string_ptr: dd 0

%endif


section .text
	
extern	_ExitProcess@4
extern	__imp__ExitProcess@4


export CreateWindow
global _CreateWindow
_CreateWindow:
CreateWindow:

    push	    0
    push	    0
    push	    0
    push	    0
    push	    RESOLUTION_Y
    push	    RESOLUTION_X
    push	    0
    push	    0
    ; see WinUser.h for constant values
    ; push	    (WS_EX_APPWINDOW | WS_VISIBLE | WS_SYSMENU)
    push    0x00040000 | 0x10000000 | 0x00080000
    push	    0	
    push	    0xC018 ; http://www.pouet.net/topic.php?which=9894
    push	    0	
    call	    [__imp__CreateWindowExA@48]
    FAIL_ON_WINDOWS_ERROR CreateWindowEx_string

    mov     [WindowHandle], eax
    ret


export CreateFullscreenWindow
global _CreateFullscreenWindow
CreateFullscreenWindow:
_CreateFullscreenWindow:
    push	4
    push	DMSCREENSETTINGS
    call	[__imp__ChangeDisplaySettingsA@8]
    ; RET_ON_WINDOWS_ERROR ChangeDisplaySettings_string

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
    FAIL_ON_WINDOWS_ERROR CreateWindowEx_string

    mov     [WindowHandle], eax
    ret



export SetWindowHandle
global _SetWindowHandle
_SetWindowHandle:
SetWindowHandle:
    mov eax, [esp+4]
    mov [WindowHandle], eax
    ret 4


export SetWindowDC
global _SetWindowDC
_SetWindowDC:
SetWindowDC:
    mov eax, [esp+4]
    mov [WindowDC], eax
    ret 4


export SetUpGLContext
global _SetUpGLContext
_SetUpGLContext
SetUpGLContext:
    push	dword [WindowHandle]
    call	[__imp__GetDC@4]
    mov     [WindowDC], eax
    FAIL_ON_WINDOWS_ERROR GetDC_string


export SetUpGLContextForDC
global _SetUpGLContextForDC
_SetUpGLContextForDC
SetUpGLContextForDC:
    push	pfd
    push	dword [WindowDC]
    call	[__imp__ChoosePixelFormat@8]
    FAIL_ON_WINDOWS_ERROR ChoosePixelFormat_string

    push	pfd
    push	eax
    push	dword [WindowDC]
    call	[__imp__SetPixelFormat@12]
    FAIL_ON_WINDOWS_ERROR SetPixelFormat_string

    push	dword [WindowDC]
    call	[__imp__wglCreateContext@4]        
    mov     [glContext], eax
    FAIL_ON_WINDOWS_ERROR wglCreateContext_string
    
    push	dword [glContext]
    push	dword [WindowDC]
    call	[__imp__wglMakeCurrent@8]
    FAIL_ON_WINDOWS_ERROR wglMakeCurrent_string

    mov eax, 1
    ret

export FreeGLContext
global _FreeGLContext
_FreeGLContext
FreeGLContext:

    push	0
    push	0
    call	[__imp__wglMakeCurrent@8]
    FAIL_ON_WINDOWS_ERROR wglMakeCurrent_string

    push	dword [WindowDC]
    push	dword [WindowHandle]
    call	[__imp__ReleaseDC@8]
    FAIL_ON_WINDOWS_ERROR ReleaseDC_string

    mov eax, 1
    ret



export SetShaderSourcePtr
global _SetShaderSourcePtr
_SetShaderSourcePtr
SetShaderSourcePtr:
    mov eax, [esp+4]
    
;    push    eax ; dword [seireripointteri]
;    call    ShowErrorMessage
    
    mov [seireripointteri], eax
    
    mov eax, 1
    ret 4

export GetShaderSourcePtr
global _GetShaderSourcePtr
_GetShaderSourcePtr
GetShaderSourcePtr:    
    mov eax, [seireripointteri]
    ret

    
CheckShaderInfoLog:

    push	glGetShaderInfoLog_string
    call  	[__imp__wglGetProcAddress@4]
    FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

    push    shader_info_log
    push    shader_info_log_length
    push    SHADER_INFO_LOG_MAX_LENGTH
    push    dword [gl_shader]
    call    eax
    
    cmp     dword [shader_info_log_length], 0    
    je      no_shader_error_log
    
;    push    shader_info_log
;    call    ShowErrorMessage

;    push	0
;    call	[__imp__ExitProcess@4]

no_shader_error_log:   
    ret

export CompileShader
global _CompileShader
_CompileShader
CompileShader:
    mov  dword [shader_info_log_length], 0
    mov  byte [shader_info_log], 0

    CLEAR_LAST_FAILED_OPERATION_INFO

    push	glCreateProgram_string
    call  	[__imp__wglGetProcAddress@4]
    FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

    call    eax
    mov     [gl_program], eax
    FAIL_ON_GL_ERROR glCreateProgram_string

    push	glCreateShader_string
    call  	[__imp__wglGetProcAddress@4]
    FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

    push    0x8B30 ; GL_FRAGMENT_SHADER
    call    eax

    mov     [gl_shader], eax
    FAIL_ON_GL_ERROR glCreateShader_string


    push	glShaderSource_string
    call  	[__imp__wglGetProcAddress@4]
    FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

    push    0
    push    seireripointteri
    push    1
    push    dword [gl_shader]

    call    eax
    FAIL_ON_GL_ERROR glShaderSource_string

    push	glCompileShader_string
    call  	[__imp__wglGetProcAddress@4]
    FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string
      
    push    dword [gl_shader]
    call    eax
    JUMP_ON_GL_ERROR .fail_and_infolog, glCompileShader_string

    call    CheckShaderInfoLog

    push	glAttachShader_string
    call  	[__imp__wglGetProcAddress@4]
    FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

    push    dword [gl_shader]
    push    dword [gl_program]
    call    eax
    FAIL_ON_GL_ERROR glAttachShader_string

    push	glLinkProgram_string
    call  	[__imp__wglGetProcAddress@4]
    FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

    push    dword [gl_program]
    call    eax
    FAIL_ON_GL_ERROR glLinkProgram_string

    push	glUseProgram_string
    call	[__imp__wglGetProcAddress@4]
    FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string


    push    dword [gl_program]
    call	eax
    JUMP_ON_GL_ERROR .fail, glUseProgram_string

    mov eax, 1
    ret

.fail_and_infolog:
    call    CheckShaderInfoLog

.fail
    mov eax, 0
    ret


; Free all the GL resources allocated by CompileShader
export FreeShaderStuff
global _FreeShaderStuff
_FreeShaderStuff
FreeShaderStuff:

; shader
    cmp dword [gl_shader], 0
    je .skipdeleteshader

    ; glDetachShader
    push	glDetachShader_string
    call  	[__imp__wglGetProcAddress@4]
    FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

    push    dword [gl_shader]
    push    dword [gl_program]
    call    eax
    FAIL_ON_GL_ERROR glDetachShader_string
    

    ; glDeleteShader
    push	glDeleteShader_string
    call  	[__imp__wglGetProcAddress@4]
    FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

    push    dword [gl_shader]
    call    eax
    FAIL_ON_GL_ERROR glDeleteShader_string

    mov dword [gl_shader], 0
.skipdeleteshader:


; program 
    cmp dword [gl_program], 0
    je .skipdeleteprogram

    push	glDeleteProgram_string
    call  	[__imp__wglGetProcAddress@4]
    FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

    push    dword [gl_program]
    call    eax
    FAIL_ON_GL_ERROR glDeleteProgram_string

    mov dword [gl_program], 0    
.skipdeleteprogram:

    mov eax, 1
    ret

; --------- texts


export SetTextFontName
global _SetTextFontName
_SetTextFontName:
SetTextFontName:
%ifdef USE_TEXTS
    mov eax, [esp+4]
    mov [text_font_name], eax
%endif
    ret 4




%ifdef USE_TEXTS


section .data
%ifdef GEN_TEXTURES	
texts_gl_texture_name: dd 0
%endif

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
%endif


section .text

; this is for testing only really! for setting the text to something that's not even in the timings/strings arrays
export SetTextPtr
global _SetTextPtr
_SetTextPtr:
SetTextPtr:
%ifdef USE_TEXTS
    mov eax, [esp+4]
    mov [current_text_ptr], eax
%endif
    ret 4


export GetTextPtr
global _GetTextPtr
_GetTextPtr:
GetTextPtr:
%ifdef USE_TEXTS
    mov eax, [current_text_ptr]
%else
    mov eax, 0
%endif
    ret


export GetTextsBitmapHandle
global _GetTextsBitmapHandle
_GetTextsBitmapHandle
GetTextsBitmapHandle:
%ifdef USE_TEXTS
	mov eax, [textsBitmapHandle]
%else
        mov eax, 0
%endif
	ret


export GetTextsBitmapBitsPtr
global _GetTextsBitmapBitsPtr
_GetTextsBitmapBitsPtr
GetTextsBitmapBitsPtr:
%ifdef USE_TEXTS
	mov eax, [textsBitmapBitsPtr]
%else
        mov eax, 0
%endif
	ret

export GetTextsBitmapInfo
global _GetTextsBitmapInfo
_GetTextsBitmapInfo
GetTextsBitmapInfo:
%ifdef USE_TEXTS
; return pointer to the BITMAPINFO struct that describes the texts bitmap
	mov eax, BitmapInfo
%else
        mov eax, 0
%endif
	ret



export ResetTimingsCursorToStart
global _ResetTimingsCursorToStart
_ResetTimingsCursorToStart
ResetTimingsCursorToStart:
%ifdef USE_TEXTS
	mov eax, text_string_timings
	mov [current_timing_ptr], eax
	mov eax, [eax+TIMINGS_REC_STRING_PTR_FIELD_OFS]
	mov [current_text_ptr], eax
%endif
	ret

; Update current_timing_ptr and current_text_ptr to current position
; Parameter : current time
export UpdateTimingsCursor
global _UpdateTimingsCursor
_UpdateTimingsCursor
UpdateTimingsCursor:	
%ifdef USE_TEXTS
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
%endif
	ret 4



export InitTextDrawingStuff
global _InitTextDrawingStuff
_InitTextDrawingStuff
InitTextDrawingStuff:
%ifdef USE_TEXTS
  %ifdef GEN_TEXTURES
	push texts_gl_texture_name
	push 1
	call  [__imp__glGenTextures@8]
  %endif
	
	push 0
	call [__imp__CreateCompatibleDC@4]
	mov [textsDC], eax
	test eax, eax
	jz .fail


	push TEXT_CHARACTER_EXTRA_SPACING
	push eax
	call [__imp__SetTextCharacterExtra@8]


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
	test eax, eax
	jz .fail
	
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

%endif
.fail:
	ret


export FreeTextDrawingStuff
global _FreeTextDrawingStuff
_FreeTextDrawingStuff
FreeTextDrawingStuff:
%ifdef USE_TEXTS
  %ifdef GEN_TEXTURES
	push texts_gl_texture_name
	push 1
	call  [__imp__glDeleteTextures@8]
  %endif
	push dword [textsFontHandle]
	call [__imp__DeleteObject@4]
	
	push dword [textsBitmapHandle]
	call [__imp__DeleteObject@4]
	
	push dword [textsDC]
	call [__imp__DeleteDC@4]
%endif ; USE_TEXTS
	ret


export DrawTextBitmap
global _DrawTextBitmap
_DrawTextBitmap
DrawTextBitmap:

%ifdef USE_TEXTS
	
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
	FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

	; use texture unit 1 for texts, if there's more than one texture
	push GL_TEXTURE1
	call    eax
	JUMP_ON_GL_ERROR .fail, glActiveTexture_string
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
    JUMP_ON_GL_ERROR .fail, glTexParameteri_string


; "Texture names are unsigned integers with the value zero reserved to represent the default texture for each texture target."


%ifdef MORE_THAN_ONE_TEXTURE

%ifdef GEN_TEXTURES
	push dword [texts_gl_texture_name]
%else
	; use texture name 1 for texts, if there are more than one
	push 1
	; push TEXTS_TEXTURE_UNIT_NUMBER
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
    FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

    push    texts_uniform_name
    push    dword [gl_program]
    call    eax
    mov     [texts_uniform_loc], eax
    JUMP_ON_GL_ERROR_EXT .fail, glGetUniformLocation_string, texts_uniform_name

    push	glGetUniformLocation_string
    call  	[__imp__wglGetProcAddress@4]
    FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string
    
    push	glUniform1i_string
    call  	[__imp__wglGetProcAddress@4]
    FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

%ifdef GEN_TEXTURES
      push dword [texts_gl_texture_name]
%else
      push 1
%endif
      push    dword [texts_uniform_loc]
      call    eax
      JUMP_ON_GL_ERROR .fail, glUniform1i_string

%endif ; USE_TEXTS_UNIFORM

%endif ; USE_TEXTS


    ret

.fail
    mov eax, 0
    ret

; --------

global CompileShader_NoDebug
CompileShader_NoDebug:

    push	glCreateShaderProgramv_string
    call  	[__imp__wglGetProcAddress@4]
    FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

    push	seireripointteri ; strings
    push	1       ; count
    push	0x00008b30  ; type
    call	eax
    ; RET_ON_WINDOWS_ERROR 0
    
    push	eax ; <-- this push goes to glUseProgram
    push	glUseProgram_string
    call	[__imp__wglGetProcAddress@4]

    FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string
    
    call	eax
    ; RET_ON_WINDOWS_ERROR 0    
    mov eax, 1
    ret


; parameter on stack : frame time position in audio samples (dword)
export DrawFrame
global _DrawFrame
_DrawFrame:
DrawFrame:
    CLEAR_LAST_FAILED_OPERATION_INFO


%ifdef FRAME_TO_TEXTURE    ; ----------------------- IF USING PREV FRAME TO TEXTURE -----------------------

; --- copy previous frame to texture before running the shader ---

%ifdef MORE_THAN_ONE_TEXTURE
      push	glActiveTexture_string
      call  	[__imp__wglGetProcAddress@4]
      FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

      push    GL_TEXTURE0
      call    eax
      JUMP_ON_GL_ERROR .fail, glActiveTexture_string

    push    0 
    push    GL_TEXTURE_2D
    call    [__imp__glBindTexture@8]
    JUMP_ON_GL_ERROR .fail, glBindTexture_string
%endif ; MORE_THAN_ONE_TEXTURE
    

%ifdef USE_MIPMAP
    push    GL_LINEAR_MIPMAP_LINEAR
%else
    push    GL_LINEAR
%endif
    push    GL_TEXTURE_MIN_FILTER
    push    GL_TEXTURE_2D
    call    [__imp__glTexParameteri@12]
    JUMP_ON_GL_ERROR .fail, glTexParameteri_string


    push    0               ; border
    push    RESOLUTION_Y    ; height
    push    RESOLUTION_X    ; width
    push    0               ; y
    push    0               ; x
    push    GL_RGBA8        ; internalformat
    push    0               ; level, mipmap level-of-detail number
    push    GL_TEXTURE_2D   ; target
    call    [__imp__glCopyTexImage2D@32]
    JUMP_ON_GL_ERROR .fail, glCopyTexImage2D_string


%ifdef USE_MIPMAP
    push	glGenerateMipmap_string
    call	[__imp__wglGetProcAddress@4]
    push	GL_TEXTURE_2D
    call	eax
%endif


%ifdef MORE_THAN_ONE_TEXTURE
    push	glActiveTexture_string
    call  	[__imp__wglGetProcAddress@4]
    FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

    push    GL_TEXTURE0
    call    eax
    JUMP_ON_GL_ERROR .fail, glActiveTexture_string
%endif ; MORE_THAN_ONE_TEXTURE

    
%endif ; FRAME_TO_TEXTURE     ; ----------------------- ^^^IF USING TEXTURES "PREV FRAME TO TEXTURE" ^^^-----------------------


%ifdef USE_TIME_UNIFORM
    push	glGetUniformLocation_string
    call  	[__imp__wglGetProcAddress@4]
    FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

    push    time_uniform_name
    push    dword [gl_program]
    call    eax
    mov     [time_uniform_loc], eax
    JUMP_ON_GL_ERROR_EXT .fail, glGetUniformLocation_string, time_uniform_name
%endif ; USE_TIME_UNIFORM

%ifdef USE_RESOLUTION_UNIFORM
    push	glGetUniformLocation_string
    call  	[__imp__wglGetProcAddress@4]
    FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

    push    resolution_uniform_name
    push    dword [gl_program]
    call    eax
    mov     [resolution_uniform_loc], eax
    JUMP_ON_GL_ERROR_EXT .fail, glGetUniformLocation_string, resolution_uniform_name
%endif ; USE_RESOLUTION_UNIFORM

%ifdef USE_TIME_UNIFORM
    push	glUniform1f_string
    call  	[__imp__wglGetProcAddress@4]
    FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

    fild    dword [esp+4] ; ------ current audio position is at [esp+4] (and function return address is [esp], the stack grows "downwards")
    push    0 ; dummy number, just a "stack allocation", to be overwritten by the "fstp dword[esp]" instruction  below

%ifdef TIME_DIVIDER_IS_INTEGER
    fidiv dword [time_divider]
%else
    fdiv dword [time_divider]
%endif

    fstp    dword [esp]
    push    dword [time_uniform_loc]
    call    eax
    JUMP_ON_GL_ERROR .fail, glUniform1f_string
%endif ; USE_TIME_UNIFORM

%ifdef USE_RESOLUTION_UNIFORM
    push	glUniform2f_string
    call  	[__imp__wglGetProcAddress@4]
    FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

    push    dword __float32__(%[RESOLUTION_Y].0)
    push    dword __float32__(%[RESOLUTION_X].0)
    push    dword [resolution_uniform_loc]
    call    eax
    JUMP_ON_GL_ERROR .fail, glUniform2f_string
%endif ; USE_RESOLUTION_UNIFORM

; ---------- feed in the time into green color 
    mov eax, [esp+4] ; time (from paramters)
    shr	    eax, 8
    push	0
    push	eax	
    push	0
    call	[__imp__glColor3us@12]
    JUMP_ON_GL_ERROR .fail, glColor3us_string
; ---------- 


    push	-1
    push	-1
    push	1
    push	1
    call	[__imp__glRecti@16]
    ; call	_glRecti@16
    JUMP_ON_GL_ERROR .fail, glRecti_string


; ________ IF TWO_PASS_RENDERING DRAW ONCE MORE, WITH TIME ZERO OR NEGATIVE TIME  _______
%ifdef TWO_PASS_RENDERING

%ifdef MORE_THAN_ONE_TEXTURE
	push	glActiveTexture_string
	call  	[__imp__wglGetProcAddress@4]
	FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

	push GL_TEXTURE0
	call    eax
	JUMP_ON_GL_ERROR .fail, glActiveTexture_string

      push    0
      push    GL_TEXTURE_2D
      call    [__imp__glBindTexture@8]
      JUMP_ON_GL_ERROR .fail, glBindTexture_string
%endif ; MORE_THAN_ONE_TEXTURE


%ifdef USE_MIPMAP
      push    GL_LINEAR_MIPMAP_LINEAR
%else
      push    GL_LINEAR
%endif
      push    GL_TEXTURE_MIN_FILTER
      push    GL_TEXTURE_2D
      call    [__imp__glTexParameteri@12]
      JUMP_ON_GL_ERROR .fail, glTexParameteri_string

      push    0               ; border
      push    RESOLUTION_Y    ; height
      push    RESOLUTION_X    ; width
      push    0               ; y
      push    0               ; x
      push    GL_RGBA8        ; internalformat
      push    0               ; level, mipmap level-of-detail number
      push    GL_TEXTURE_2D   ; target
      call    [__imp__glCopyTexImage2D@32]
      JUMP_ON_GL_ERROR .fail, glCopyTexImage2D_string


%ifdef USE_MIPMAP
      push	glGenerateMipmap_string
      call	[__imp__wglGetProcAddress@4]
      push	GL_TEXTURE_2D
      call	eax
%endif

%ifdef USE_TIME_UNIFORM 
      push	glUniform1f_string
      call  	[__imp__wglGetProcAddress@4]
      FAIL_ON_WINDOWS_ERROR wglGetProcAddress_string

%ifdef SECOND_PASS_NEGATIVE_TIME
    fild    dword [esp+4]
    push    0
    
%ifdef TIME_DIVIDER_IS_INTEGER
    fidiv dword [time_divider]
%else
    fdiv dword [time_divider]
%endif
     fchs	; change sign
    fstp    dword [esp]
%else
      push    0    ; the second pass is the same shader, but run with time = 0
%endif ; (not) SECOND_PASS_NEGATIVE_TIME
      
     
      push    dword [time_uniform_loc]
      call    eax
      JUMP_ON_GL_ERROR .fail, glUniform1f_string
%endif ; USE_TIME_UNIFORM

    mov eax, [esp+4] ; time (from function parameters)
%ifdef SECOND_PASS_NEGATIVE_TIME
    neg  eax
    sar    eax, 8
      push	0
      push	eax
      push	0
      call	[__imp__glColor3s@12]
      JUMP_ON_GL_ERROR .fail, glColor3s_string
%else	
      push	0
      push	0 ; this is SECOND PASS i.e. post-processing, so zero as time
      push	0
      call	[__imp__glColor3us@12]
      JUMP_ON_GL_ERROR .fail, glColor3us_string
%endif

      push	-1
      push	-1
      push	1
      push	1
      call	[__imp__glRecti@16]
      ; call	_glRecti@16
      JUMP_ON_GL_ERROR .fail, glRecti_string

%endif ; TWO_PASS_RENDERING		 ; ----------------------- ^^^TWO-PASS RENDERING^^^-----------------------

; ________________________________________

    push	dword [WindowDC]
    call	[__imp__SwapBuffers@4]
    FAIL_ON_WINDOWS_ERROR SwapBuffers_string

    ; jmp beepquit

    mov eax, 1
    ret 4

.fail:
    mov eax, 0
    ret 4
    
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

