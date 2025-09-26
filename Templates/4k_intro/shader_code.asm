; Compofiller Studio by Yzi 2017
;
; This asm file is for making a COFF object file from the GLSL shader code.

; C++ mangled name would be something like this:
;global ?shader_glsl@@3DA
;?shader_glsl@@3DA:

section .shader0 data align=1

global shader_glsl
shader_glsl:

incbin TEMP_PROCESSED_SHADER_FILE
db 0

