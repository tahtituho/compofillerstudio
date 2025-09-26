section .text
align 16

%macro EXPORT_FUNC 1
    export %1
   global _%1
   _%1:
   %1:
%endmacro


; ---------------------------- Error message stuff ------------------------

    extern  _MessageBoxA@16
    extern  __imp__MessageBoxA@16
    extern _GetLastError@0
    extern  __imp__GetLastError@0
    extern _FormatMessageA@28
    extern __imp__FormatMessageA@28
    extern _LocalFree@4
    extern __imp__LocalFree@4
    
section .data

GL_FALSE equ 0
GL_NO_ERROR equ 0
MMSYSERR_NOERROR equ 0
LANG_NEUTRAL equ    0
FORMAT_MESSAGE_ALLOCATE_BUFFER  equ 0x00000100
FORMAT_MESSAGE_FROM_SYSTEM      equ 0x00001000 

error_message_buffer_ptr:   dd  0
error_message_id: dd 0

error_message_caption:
    db  'Errare humanum est', 0
    
last_failed_operation: dd 0
last_failed_operation_info: dd 0


EXPORT_FUNC GetLastFailedOperation
  mov eax, [last_failed_operation]
  ret

EXPORT_FUNC GetLastFailedOperationInfo
  mov eax, [last_failed_operation_info]
  ret

section .text
    
; IN: eax : message id from GetLastError
; IN: on stack : caption string
global ShowLastWindowsErrorMessageWithCaption
ShowLastWindowsErrorMessageWithCaption:
    mov [error_message_id], eax
    mov eax, [esp+4]

    push    0   ; _In_opt_ va_list *Arguments
    push    0   ; _In_     DWORD   nSize,
    push    error_message_buffer_ptr   ; _Out_    LPTSTR  lpBuffer
    push    LANG_NEUTRAL   ; _In_     DWORD   dwLanguageId
    push    dword [error_message_id]   ; _In_     DWORD   dwMessageId
    push    0   ; _In_opt_ LPCVOID lpSource
    push    FORMAT_MESSAGE_ALLOCATE_BUFFER+FORMAT_MESSAGE_FROM_SYSTEM   ; _In_     DWORD   dwFlags
    call    [__imp__FormatMessageA@28]

    push    0
    push    eax
    push    dword [error_message_buffer_ptr]
    push    0
    call    [__imp__MessageBoxA@16]
    
    push    dword [error_message_buffer_ptr]
    call [__imp__LocalFree@4]

    ret 4

   

; IN: on stack : caption string
global ShowErrorMessage
ShowErrorMessage:
    mov eax, [esp+4]

    push    0
    push    error_message_caption
    push    eax
    push    0
    call    [__imp__MessageBoxA@16]
    
    ret 4


______

; --- This is for WinAPI stuff. Return value 0 means success.
;%macro  RET_ON_WINDOWS_ERROR 1
    ;cmp eax, 0
    ;jne %%skip
    ;call _GetLastError@0
    ;cmp eax, 0
    ;jne %%skip_message
    
    ;push    %1
    ;call ShowLastWindowsErrorMessageWithCaption
;%%skip_message:
    ;ret
;%%skip:
;%endmacro

%macro  FAIL_ON_WINDOWS_ERROR 1
    cmp eax, 0
    jne %%skip
    call _GetLastError@0
    cmp eax, 0
    jne %%skip_message
    
    push    %1
    call ShowLastWindowsErrorMessageWithCaption
%%skip_message:

    push	0
    call	[__imp__ExitProcess@4]

%%skip:
%endmacro


%macro  CLEAR_LAST_FAILED_OPERATION_INFO 0
    mov dword [last_failed_operation], 0
    mov dword [last_failed_operation_info], 0
%endmacro



; --- For OpenGL stuff. glGetError() return value 0 i.e. GL_NO_ERROR means no error.

; param 1: where to jump, 
; param 2: what address to set to last_failed_operation
%macro  JUMP_ON_GL_ERROR 2
    call [__imp__glGetError@0]
    cmp eax, GL_NO_ERROR
    je %%skip
    
    mov dword [last_failed_operation], %2
    mov dword [last_failed_operation_info], 0
    jmp %1

%%skip:
%endmacro


; param 1: where to jump, 
; param 2: address (string pointer) to set to last_failed_operation
; param 3: address (string pointer) to set to last_failed_operation_info
%macro  JUMP_ON_GL_ERROR_EXT 3
    call [__imp__glGetError@0]
    cmp eax, GL_NO_ERROR
    je %%skip
    
    mov dword [last_failed_operation], %2
    mov dword [last_failed_operation_info], %3
    jmp %1

%%skip:
%endmacro


%macro  FAIL_ON_GL_ERROR 1
    call [__imp__glGetError@0]
    cmp eax, GL_NO_ERROR
    je %%skip
;    call _GetLastError@0
;    cmp eax, 0
;    jne %%skip_message
    
    push    %1
    call ShowErrorMessage

    push	0
    call	[__imp__ExitProcess@4]

%%skip:
%endmacro





; --- For Windows Multimedia stuff. Return value 0 i.e. MMSYSERR_NOERROR means no error.
%macro  FAIL_ON_WINMM_ERROR 1
    cmp eax, MMSYSERR_NOERROR
    je %%skip
;    call _GetLastError@0
;    cmp eax, 0
;    jne %%skip_message
    
    push    %1
    call ShowErrorMessage

    push	0
    call	[__imp__ExitProcess@4]
%%skip:
%endmacro

; %macro  _FAIL_ON_WINMM_ERROR 1
; %endmacro


