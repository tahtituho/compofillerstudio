unit UAudioDLL;
// Compofiller Studio
// by Yzi 2017

{$mode objfpc}{$H+}

interface


uses
  Classes, SysUtils,
{$ifdef WINDOWS}
  Windows,
{$endif}
  UBaseDLL;

type
  // Audio DLL functions
//  TPlayFunc = procedure; stdcall;
  TGetWaveOutHandleFunc = function : THandle; stdcall;
//  TGetFullAudioLengthSamplesFunc = function : Integer; stdcall;
  TGetCurrentAudioPositionFunc = function : Integer; stdcall;
  TGetRenderedAudioBufferPtrFunc = function : Pointer; stdcall;
  TSetRenderedAudioBufferPtrFunc = procedure(ABuffer : Pointer); stdcall;
  TGetAudioPlaybackBufferPtrFunc = function : Pointer; stdcall;
  TSetAudioPlaybackBufferPtrFunc = procedure(ABuffer : Pointer); stdcall;
  TGetAudioPlaybackBufferLengthBytesFunc = function : Integer; stdcall;
  TSetAudioPlaybackBufferLengthBytesFunc = procedure(AValue : Integer); stdcall;
  TGetAudioRendererThreadHandleFunc = function : THandle; stdcall;
  TStartAudioRendererThreadFunc = function : THandle; stdcall;
  TKillAudioRendererThreadFunc = procedure; stdcall;
  TStartAudioFunc = procedure; stdcall;
  TStopAudioFunc = procedure; stdcall;
  TGetMusicBPMFunc = function : Single; stdcall;
  TGetMusicLengthSamplesFunc = function : Cardinal; stdcall;
  TGetMusicSampleRateFunc = function : Cardinal; stdcall;

//  TSetAudioLoopEnabledFunc = procedure(ALoopEnabled : Boolean); stdcall;

  { TAudioDLL }

  TAudioDLL = class(TBaseDLL)
  private
//    FPlay : TPlayFunc;
    FGetRenderedAudioBufferPtr : TGetRenderedAudioBufferPtrFunc;
    FSetRenderedAudioBufferPtr : TSetRenderedAudioBufferPtrFunc;
    FGetWaveOutHandle : TGetWaveOutHandleFunc;
    FGetAudioPlaybackBufferPtr : TGetAudioPlaybackBufferPtrFunc;
    FSetAudioPlaybackBufferPtr : TSetAudioPlaybackBufferPtrFunc;
    FGetAudioPlaybackBufferLengthBytes : TGetAudioPlaybackBufferLengthBytesFunc;
    FSetAudioPlaybackBufferLengthBytes : TSetAudioPlaybackBufferLengthBytesFunc;
    FGetAudioRendererThreadHandle : TGetAudioRendererThreadHandleFunc;
    FKillAudioRendererThread : TKillAudioRendererThreadFunc;
    FGetCurrentAudioPosition : TGetCurrentAudioPositionFunc;
    FStartAudioRendererThread : TStartAudioRendererThreadFunc;
    FStartAudio : TStartAudioFunc;
    FStopAudio : TStopAudioFunc;
    FGetMusicBPM : TGetMusicBPMFunc;
    FGetMusicLengthSamples : TGetMusicLengthSamplesFunc;
    FGetMusicSampleRate : TGetMusicSampleRateFunc;

//    FSetAudioLoopEnabled : TSetAudioLoopEnabledFunc;

  public
    function Load : Boolean; override;

    destructor Destroy; override;

    property GetRenderedAudioBufferPtr : TGetRenderedAudioBufferPtrFunc read FGetRenderedAudioBufferPtr;
    property SetRenderedAudioBufferPtr : TSetRenderedAudioBufferPtrFunc read FSetRenderedAudioBufferPtr;
    property GetWaveOutHandle : TGetWaveOutHandleFunc read FGetWaveOutHandle;
    property GetAudioPlaybackBufferPtr : TGetAudioPlaybackBufferPtrFunc read FGetAudioPlaybackBufferPtr;
    property SetAudioPlaybackBufferPtr : TSetAudioPlaybackBufferPtrFunc read FSetAudioPlaybackBufferPtr;
    property GetAudioPlaybackBufferLengthBytes : TGetAudioPlaybackBufferLengthBytesFunc read FGetAudioPlaybackBufferLengthBytes;
    property SetAudioPlaybackBufferLengthBytes : TSetAudioPlaybackBufferLengthBytesFunc read FSetAudioPlaybackBufferLengthBytes;
    property GetAudioRendererThreadHandle : TGetAudioRendererThreadHandleFunc read FGetAudioRendererThreadHandle;
    property KillAudioRendererThread : TKillAudioRendererThreadFunc read FKillAudioRendererThread;
    property StartAudioRendererThread : TStartAudioRendererThreadFunc read FStartAudioRendererThread;
    property GetCurrentAudioPosition : TGetCurrentAudioPositionFunc read FGetCurrentAudioPosition;

    // tähän tarvitaan rutiinit SetLoopStart, SetLoopEnd, SetLoopEnabled
    // audio-DLL:n pitää tietää ne, koska se käynnistää soiton

    property StartAudio : TStartAudioFunc read FStartAudio;
    property StopAudio : TStopAudioFunc read FStopAudio;
    property GetMusicBPM : TGetMusicBPMFunc read FGetMusicBPM;
    property GetMusicLengthSamples : TGetMusicLengthSamplesFunc read FGetMusicLengthSamples;
    property GetMusicSampleRate : TGetMusicSampleRateFunc read FGetMusicSampleRate;

//    property SetAudioLoopEnabled : TSetAudioLoopEnabledFunc read FSetAudioLoopEnabled;
//    property GetAudioLoopEnabled : TGetAudioLoopEnabledFunc read FGetAudioLoopEnabled;

  end; // class TAudioDLL


implementation

{ TAudioDLL }

function TAudioDLL.Load : Boolean;
begin
  Result :=
    inherited; // <--- this will LoadLibrary()

  if Self.Loaded then
  begin // Set function pointers
    FGetRenderedAudioBufferPtr := TGetRenderedAudioBufferPtrFunc(CheckGetProcAddress(FHandle, 'GetRenderedAudioBufferPtr'));
    FSetRenderedAudioBufferPtr := TSetRenderedAudioBufferPtrFunc(CheckGetProcAddress(FHandle, 'SetRenderedAudioBufferPtr'));
    FGetWaveOutHandle := TGetWaveOutHandleFunc(CheckGetProcAddress(FHandle, 'GetWaveOutHandle'));
    FGetCurrentAudioPosition := TGetCurrentAudioPositionFunc(CheckGetProcAddress(FHandle, 'GetCurrentAudioPosition'));
    FGetAudioPlaybackBufferPtr := TGetAudioPlaybackBufferPtrFunc(CheckGetProcAddress(FHandle, 'GetAudioPlaybackBufferPtr'));
    FSetAudioPlaybackBufferPtr := TSetAudioPlaybackBufferPtrFunc(CheckGetProcAddress(FHandle, 'SetAudioPlaybackBufferPtr'));
    FGetAudioPlaybackBufferLengthBytes := TGetAudioPlaybackBufferLengthBytesFunc(CheckGetProcAddress(FHandle, 'GetAudioPlaybackBufferLengthBytes'));
    FSetAudioPlaybackBufferLengthBytes := TSetAudioPlaybackBufferLengthBytesFunc(CheckGetProcAddress(FHandle, 'SetAudioPlaybackBufferLengthBytes'));
    FStartAudioRendererThread := TStartAudioRendererThreadFunc(CheckGetProcAddress(FHandle, 'StartAudioRendererThread'));
    FGetAudioRendererThreadHandle := TGetAudioRendererThreadHandleFunc(CheckGetProcAddress(FHandle, 'GetAudioRendererThreadHandle'));
    FKillAudioRendererThread := TKillAudioRendererThreadFunc(CheckGetProcAddress(FHandle, 'KillAudioRendererThread'));
    FStartAudio := TStartAudioFunc(CheckGetProcAddress(FHandle, 'StartAudio'));
    FStopAudio := TStopAudioFunc(CheckGetProcAddress(FHandle, 'StopAudio'));
    FGetMusicBPM := TGetMusicBPMFunc(CheckGetProcAddress(FHandle, 'GetMusicBPM'));
    FGetMusicLengthSamples := TGetMusicLengthSamplesFunc(CheckGetProcAddress(FHandle, 'GetMusicLengthSamples'));
    FGetMusicSampleRate := TGetMusicSampleRateFunc(CheckGetProcAddress(FHandle, 'GetMusicSampleRate'));

//    FSetAudioLoopEnabled := TSetAudioLoopEnabledFunc(CheckGetProcAddress(FHandle, 'SetAudioLoopEnabled'));
//    FGetAudioLoopEnabled := TGetAudioLoopEnabledFunc(CheckGetProcAddress(FHandle, 'GetAudioLoopEnabled'));

    Result := true;
  end;
end; // TAudioDLL.Load

destructor TAudioDLL.Destroy;
begin

  if Self.Loaded and (Self.GetAudioRendererThreadHandle() <> 0) then
    Self.KillAudioRendererThread;

  inherited Destroy;
end;

end.

