%if USE_TIME_UNIFORM > 0
  %define USE_UNIFORMS
%else
  %undef USE_TIME_UNIFORM
%endif

%if USE_RESOLUTION_UNIFORM > 0
  %define USE_UNIFORMS
%else
  %undef USE_RESOLUTION_UNIFORM
%endif

%if USE_TEXTS = 0
  %undef USE_TEXTS
%endif

%if USE_WIDECHAR_TEXTS = 0
  %undef USE_WIDECHAR_TEXTS
%endif


%if USE_TEXTS_UNIFORM > 0
  %define USE_UNIFORMS
  %define USE_TEXTURES
%else
  %undef USE_TEXTS_UNIFORM
%endif

%if TWO_PASS_RENDERING > 0
  %define USE_TEXTURES
  %define USE_COPY_FRAMEBUFFER_TO_TEXTURE
  %ifdef USE_TEXTS
    %define MORE_THAN_ONE_TEXTURE
  %endif
%else
%undef TWO_PASS_RENDERING
%endif

%if SECOND_PASS_NEGATIVE_TIME > 0
%else
%undef SECOND_PASS_NEGATIVE_TIME
%endif

%if FRAME_TO_TEXTURE > 0
  %define USE_TEXTURES
  %define USE_COPY_FRAMEBUFFER_TO_TEXTURE
  %ifdef USE_TEXTS
    %define MORE_THAN_ONE_TEXTURE
  %endif
%else 
  %undef FRAME_TO_TEXTURE
%endif

%if USE_MIPMAP = 0
  %undef USE_MIPMAP
%endif

%ifndef USE_TEXTURES
  %undef USE_MIPMAP
%endif

; if there's more than one texture, we have to use uniforms to set the texture names to the samplers, using uniforms
%ifdef MORE_THAN_ONE_TEXTURE
  %define USE_UNIFORMS
  %define USE_TEXTS_UNIFORM
%endif