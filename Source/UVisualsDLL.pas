unit UVisualsDLL;
// Compofiller Studio
// by Yzi 2017

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows,
  UBaseDLL;

// Visuals DLL functions
type
  TCreateWindowFunc = function : Cardinal; stdcall;
  TCreateFullscreenWindowFunc = function : Cardinal; stdcall;
  TGetWindowHandleFunc = function : HWND; stdcall;
  TSetWindowHandleFunc = procedure(AHandle : THandle); stdcall;
  TGetWindowDCFunc = function : HDC; stdcall;
  TSetWindowDCFunc = procedure(ADC : HDC); stdcall;
  TGetGLContextFunc = function : Cardinal; stdcall;
  TSetUpGLContextFunc = function : Cardinal; stdcall;
  TSetUpGLContextForDCFunc = function : Cardinal; stdcall;
  TFreeGLContextFunc = function : Cardinal; stdcall;

  TSetShaderSourcePtrFunc = function(APtr : PChar) : Cardinal; stdcall;
  TGetShaderSourcePtrFunc = function : PChar; stdcall;
  TCompileShaderFunc = function : Cardinal; stdcall;
  TFreeShaderStuffFunc = function : Cardinal; stdcall;
  TCompileShaderNoDebugFunc = function : Cardinal; stdcall;
  TDrawFrameFunc = function(AFrameTime : Integer) : Boolean; stdcall;

  TGetLastFailedOperationFunc = function : PChar; stdcall; // name of operation that failed, if a function returned 0 i.e. failure
  TGetLastFailedOperationInfoFunc = function : PChar; stdcall; // more information about the failed operation
  TGetShaderInfoLogFunc = function : PChar; stdcall;

  TInitTextDrawingStuffFunc = function : Cardinal; stdcall;
  TFreeTextDrawingStuffFunc = function : Cardinal; stdcall;
  TSetTextFontNameFunc = function(APtr : PChar) : Cardinal; stdcall;
  TSetTextPtrFunc = function(APtr : PChar) : Cardinal; stdcall;
  TGetTextPtrFunc = function : PChar; stdcall;
  TDrawTextBitmapFunc = function : Cardinal; stdcall;
  TGetTextsBitmapBitsPtrFunc = function : Pointer; stdcall;
  TGetTextsBitmapHandleFunc = function : THandle; stdcall;
  TGetTextsBitmapInfoFunc = function : PBITMAPINFO; stdcall;

  TUpdateTimingsCursorFunc = function(AFrameTime : Integer) : Boolean; stdcall;
  TResetTimingsCursorToStartFunc = function : Integer; stdcall;



  { TVisualsDLL }

  TVisualsDLL = class(TBaseDLL)
  private
    FCreateWindow : TCreateWindowFunc;
    FCreateFullscreenWindow : TCreateFullscreenWindowFunc;
    FGetWindowHandle : TGetWindowHandleFunc;
    FSetWindowHandle : TSetWindowHandleFunc;
    FGetGLContext : TGetGLContextFunc;
    FGetWindowDC : TGetWindowDCFunc;
    FSetWindowDC : TSetWindowDCFunc;
    FSetUpGLContext : TSetUpGLContextFunc;
    FSetUpGLContextForDC : TSetUpGLContextForDCFunc;
    FFreeGLContext : TFreeGLContextFunc;
    FSetShaderSourcePtr : TSetShaderSourcePtrFunc;
    FGetShaderSourcePtr : TGetShaderSourcePtrFunc;
    FCompileShader : TCompileShaderFunc;
    FFreeShaderStuff : TFreeShaderStuffFunc;
    FDrawFrame : TDrawFrameFunc;

    FGetLastFailedOperation : TGetLastFailedOperationFunc;
    FGetLastFailedOperationInfo : TGetLastFailedOperationInfoFunc;
    FGetShaderInfoLog : TGetShaderInfoLogFunc;

    FInitTextDrawingStuff : TInitTextDrawingStuffFunc;
    FFreeTextDrawingStuff : TFreeTextDrawingStuffFunc;
    FSetTextFontName : TSetTextFontNameFunc;
    FSetTextPtr : TSetTextPtrFunc;
    FGetTextPtr : TGetTextPtrFunc;
    FDrawTextBitmap : TDrawTextBitmapFunc;
    FGetTextsBitmapBitsPtr : TGetTextsBitmapBitsPtrFunc;
    FGetTextsBitmapHandle : TGetTextsBitmapHandleFunc;
    FGetTextsBitmapInfo : TGetTextsBitmapInfoFunc;
    FUpdateTimingsCursor : TUpdateTimingsCursorFunc;
    FResetTimingsCursorToStart : TResetTimingsCursorToStartFunc;

  public
    function Load : Boolean; override;

    property Handle : THandle read FHandle;
    property CreateWindow : TCreateWindowFunc read FCreateWindow;
    property CreateFullscreenWindow : TCreateFullscreenWindowFunc read FCreateFullscreenWindow;
    property GetWindowHandle : TGetWindowHandleFunc read FGetWindowHandle;
    property SetWindowHandle : TSetWindowHandleFunc read FSetWindowHandle;
    property GetGLContext : TGetGLContextFunc read FGetGLContext;
    property GetWindowDC : TGetWindowDCFunc read FGetWindowDC;
    property SetWindowDC : TSetWindowDCFunc read FSetWindowDC;
    property SetUpGLContext : TSetUpGLContextFunc read FSetUpGLContext;
    property SetUpGLContextForDC : TSetUpGLContextForDCFunc read FSetUpGLContextForDC;
    property FreeGLContext : TFreeGLContextFunc read FFreeGLContext;

    property SetShaderSourcePtr : TSetShaderSourcePtrFunc read FSetShaderSourcePtr;
    property GetShaderSourcePtr : TGetShaderSourcePtrFunc read FGetShaderSourcePtr;
    property CompileShader : TCompileShaderFunc read FCompileShader;
    property FreeShaderStuff : TFreeShaderStuffFunc read FFreeShaderStuff;
    property DrawFrame : TDrawFrameFunc read FDrawFrame;

    property GetLastFailedOperation : TGetLastFailedOperationFunc read FGetLastFailedOperation;
    property GetLastFailedOperationInfo : TGetLastFailedOperationInfoFunc read FGetLastFailedOperationInfo;
    property GetShaderInfoLog : TGetShaderInfoLogFunc read FGetShaderInfoLog;

    property InitTextDrawingStuff : TInitTextDrawingStuffFunc read FInitTextDrawingStuff;
    property FreeTextDrawingStuff : TFreeTextDrawingStuffFunc read FFreeTextDrawingStuff;
    property SetTextFontName : TSetTextFontNameFunc read FSetTextFontName;
    property SetTextPtr : TSetTextPtrFunc read FSetTextPtr;
    property GetTextPtr : TGetTextPtrFunc read FGetTextPtr;
    property DrawTextBitmap : TDrawTextBitmapFunc read FDrawTextBitmap;
    property GetTextsBitmapBitsPtr : TGetTextsBitmapBitsPtrFunc read FGetTextsBitmapBitsPtr;
    property GetTextsBitmapHandle : TGetTextsBitmapHandleFunc read FGetTextsBitmapHandle;
    property GetTextsBitmapInfo : TGetTextsBitmapInfoFunc read FGetTextsBitmapInfo;


    property UpdateTimingsCursor : TUpdateTimingsCursorFunc read FUpdateTimingsCursor;
    property ResetTimingsCursorToStart : TResetTimingsCursorToStartFunc read FResetTimingsCursorToStart;

  end; // class TVisualsDLL



implementation

{ TVisualsDLL }

function TVisualsDLL.Load: Boolean;
begin
  Result := inherited; // <--- this will LoadLibrary()

  if Self.Loaded then
  begin // Set function pointers
    FCreateWindow := TCreateWindowFunc(CheckGetProcAddress(FHandle, 'CreateWindow'));
    FCreateFullscreenWindow := TCreateFullscreenWindowFunc(CheckGetProcAddress(FHandle, 'CreateFullscreenWindow'));
    FGetWindowHandle := TGetWindowHandleFunc(CheckGetProcAddress(FHandle, 'GetWindowHandle'));
    FSetWindowHandle := TSetWindowHandleFunc(CheckGetProcAddress(FHandle, 'SetWindowHandle'));
    FGetWindowDC := TGetWindowDCFunc(CheckGetProcAddress(FHandle, 'GetWindowDC'));
    FSetWindowDC := TSetWindowDCFunc(CheckGetProcAddress(FHandle, 'SetWindowDC'));
    FGetGLContext := TGetGLContextFunc(CheckGetProcAddress(FHandle, 'GetGLContext'));
    FSetUpGLContext := TSetUpGLContextFunc(CheckGetProcAddress(FHandle, 'SetUpGLContext'));
    FSetUpGLContextForDC := TSetUpGLContextForDCFunc(CheckGetProcAddress(FHandle, 'SetUpGLContextForDC'));
    FFreeGLContext := TFreeGLContextFunc(CheckGetProcAddress(FHandle, 'FreeGLContext'));

    FCompileShader := TCompileShaderFunc(CheckGetProcAddress(FHandle, 'CompileShader'));
    FSetShaderSourcePtr := TSetShaderSourcePtrFunc(CheckGetProcAddress(FHandle, 'SetShaderSourcePtr'));
    FGetShaderSourcePtr := TGetShaderSourcePtrFunc(CheckGetProcAddress(FHandle, 'GetShaderSourcePtr'));
    FFreeShaderStuff := TFreeShaderStuffFunc(CheckGetProcAddress(FHandle, 'FreeShaderStuff'));
    FDrawFrame := TDrawFrameFunc(CheckGetProcAddress(FHandle, 'DrawFrame'));
    CheckFunc(FDrawFrame, 'DrawFrame');

    FGetLastFailedOperation := TGetLastFailedOperationFunc(CheckGetProcAddress(FHandle, 'GetLastFailedOperation'));
    FGetLastFailedOperationInfo := TGetLastFailedOperationInfoFunc(CheckGetProcAddress(FHandle, 'GetLastFailedOperationInfo'));
    FGetShaderInfoLog := TGetShaderInfoLogFunc(CheckGetProcAddress(FHandle, 'GetShaderInfoLog'));

    FInitTextDrawingStuff := TInitTextDrawingStuffFunc(CheckGetProcAddress(FHandle, 'InitTextDrawingStuff'));
    FFreeTextDrawingStuff := TFreeTextDrawingStuffFunc(CheckGetProcAddress(FHandle, 'FreeTextDrawingStuff'));
    FDrawTextBitmap := TDrawTextBitmapFunc(CheckGetProcAddress(FHandle, 'DrawTextBitmap'));
    FSetTextFontName := TSetTextFontNameFunc(CheckGetProcAddress(FHandle, 'SetTextFontName'));
    FSetTextPtr := TSetTextPtrFunc(CheckGetProcAddress(FHandle, 'SetTextPtr'));
    FGetTextPtr := TGetTextPtrFunc(CheckGetProcAddress(FHandle, 'GetTextPtr'));
    FGetTextsBitmapBitsPtr := TGetTextsBitmapBitsPtrFunc(CheckGetProcAddress(FHandle, 'GetTextsBitmapBitsPtr'));
    FGetTextsBitmapHandle := TGetTextsBitmapHandleFunc(CheckGetProcAddress(FHandle, 'GetTextsBitmapHandle'));
    FGetTextsBitmapInfo := TGetTextsBitmapInfoFunc(CheckGetProcAddress(FHandle, 'GetTextsBitmapInfo'));

    FUpdateTimingsCursor := TUpdateTimingsCursorFunc(CheckGetProcAddress(FHandle, 'UpdateTimingsCursor'));
    FResetTimingsCursorToStart := TResetTimingsCursorToStartFunc(CheckGetProcAddress(FHandle, 'ResetTimingsCursorToStart'));

    Result := true;
  end;
end; // TVisualsDLL.Load

end.

