unit URunThread;
// Compofiller Studio
// by Yzi 2018

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  UAudioDLL, UVisualsDLL,
  UThreadCommand,
  Windows, mmsystem;


const
  NUM_TIMESTAMPS_FOR_FRAME_STATS = 4;

type
  TRunThread = class;
  TRedrawEvent = procedure(ASender : TRunThread) of object;
  TGetTimeMethod = function : Integer of object;

  TRunParamsRec = record
    ShaderFileName : String;
  end;
  PRunParamsRec = ^TRunParamsRec;

  TCommandResultRec = record
    Result : Boolean; // true = OK, false = failure
    Info : String;
  end;
  PCommandResultRec = ^TCommandResultRec;

  TFrameTimestampMilliseconds = Cardinal; // the timestamps just come from timeGetTime(), nothing fancy

  { TRunThreadCommandProxy }

  TRunThreadCommandProxy = class(TThreadCommandProxy)
  protected
    // Cache copies of things
    FTime : Integer;
    FAverageFrameTimeMS : Single;
    FLastOperationResult : Boolean;
    FLastOperationInfo : String;

  public
    function GetTime : Integer;

    procedure SetLastOperationInfo(AResult : Boolean; AInfo : String);

    // The Engine can call this to get latest cached values immediately,
    // instead of calling a command, which will block the Engine's thread
    // i.e. main GUI thread, until the RunThread has completed drawing a frame.
    procedure GetLastOperationInfo(var AResult : Boolean; var AInfo : String);

    property AverageFrameTimeMS : Single read FAverageFrameTimeMS;
  end; // TRunThreadCommandProxy

  { TRunThread }

  TRunThread = class(TThread)
  private
    FVisualsDLL : TVisualsDLL;
    FAudioDLL : TAudioDLL;

    // Engine allocates the audio buffer and sets these before starting the run thread
    FAudioBuffer : PByte;
    FAudioLengthSamples : Integer;

    // Loop parameters
    FLoopEnabled : Boolean;
    FLoopStartAudioPosition, FLoopEndAudioPosition : Integer;

    FCommandProxy : TRunThreadCommandProxy; // the proxy is owned by the Engine

    FStarted : Boolean; // has the thread entered the main .Execute method
    FPlaying : Boolean;
    FPlayingInsideLoop : Boolean; // was playback started from inside loop begin/end points, and with looping enabled

    FTime : Integer; // FTime is always relative to the FULL audio length, in stereo samples, i.e. multiply by 4 to get byte offset in 16bit stereo audio buffer
    FLastTextsUpdateTime : Integer;
    FCurrentPlaybackStartOffsetSamples : Integer;

    FLastFrameResult : Boolean;
    FLastFailedOperation : String;
    FLastFailedOperationInfo : String;
    FLastShaderInfoLog : String;
    FVisualsWindowHandle: HWND;

    FWorkDirectory : String;
    FShaderSourceFileName : String;

    FShaderSource : PChar;
    FShaderSourceSize : Integer;

    FFrameTimestamps : array[0..NUM_TIMESTAMPS_FOR_FRAME_STATS-1] of TFrameTimestampMilliseconds;


    // if an  happens in the Execute method, it sets this flag,
    // tells the command proxy about the crash and exists.
    FCrashed : Boolean;

    function CheckTextBitmapsReady: Boolean;
    function GetLastOperationInfo: String;
    procedure ReloadDLL;
    function ReloadShader : Boolean;
    function ReloadShaderFromGLSLFile: Boolean;
    function ReloadShaderFromString(AString: String): Boolean;
    procedure SetVisualsWindowHandle(AValue: HWND);
    procedure SetVisualsWindowHandleToDLL(AHandle: HWND);
    procedure ShaderCrazinessSafetyAttempt;
    procedure TellTheCommandProxyWhatTimeItIs;
    procedure TellTheProxyTheAverageFrameRate;
    procedure UpdateLastOperationInfo;

  protected
    procedure Execute; override;

    function CheckShaderCompiled : Boolean;
    procedure CheckVisualsDLLLoaded;
    procedure CheckVisualsReady;
    procedure CheckVisualsWindow;

    procedure SetAudioDLL(AAudioDLL : TAudioDLL);
    procedure SetAudioBuffer(AValue: PByte);
    procedure SetAudioLengthSamples(AValue: Integer);


    procedure SetTime(ATime : Integer);

    // The loop parameters are used by the RunThread only, not by the audio DLL.
    procedure SetLoopParameters(ALoopEnabled : Boolean; ALoopStartAudioPosition, ALoopEndAudioPosition : Integer);

    procedure SetPlaying(AValue: Boolean);

    function DrawFrame : Boolean;

    function GetAverageFrameTimeMS : Single;

    property Playing : Boolean read FPlaying write SetPlaying;

    property AudioBuffer : PByte read FAudioBuffer write SetAudioBuffer;
    property AudioLengthSamples : Integer read FAudioLengthSamples write SetAudioLengthSamples;

    property VisualsWindowHandle : HWND read FVisualsWindowHandle write SetVisualsWindowHandle;

  public
    // Commands. For outside threads these are ONLY for function pointers!!! Not for calling!

    // For many commands, we assume that SizeOf(Pointer) = SizeOf(something). Win32 only!
    procedure cmdSetTime(AData: Pointer);
    procedure cmdGetTime(AData: Pointer);
    procedure cmdSetLoopEnabled(AData: Pointer);
    procedure cmdSetLoopStartAudioPosition(AData: Pointer);
    procedure cmdSetLoopEndAudioPosition(AData: Pointer);
    procedure cmdStartPlaying(AData: Pointer);
    procedure cmdStopPlaying(AData: Pointer);
    procedure cmdSetPlaying(AData: Pointer);
    procedure cmdDrawFrame(AData: Pointer);
    procedure cmdTerminate(AData: Pointer);
    procedure cmdSetRunParams(AData: Pointer);
    procedure cmdReloadShader(AData: Pointer);
    procedure cmdGetLastFrameResult(AData: Pointer);
    procedure cmdCopyFrameToBitmap(AData: Pointer); // AData : Graphics.TBitmap
    procedure cmdCopyTextsBitmapToPaintBox(AData: Pointer); // AData : ExtCtrls.TPaintBox
    procedure cmdGetLastTextPtr(AData: Pointer); // AData : PPointer (strings can be Char or WideChar, depending on the configuration)
    procedure cmdGetTextsBitmapInfo(AData: Pointer);

    procedure cmdGetGLInfo(AData: Pointer);
    procedure cmdSetLoopParams(AData: Pointer); // <-- this isn't actually used, todo remove

    constructor Create
      (ACommandProxy : TRunThreadCommandProxy; AWorkDirectory, AShaderSourceFileName : String;
       AVisualsWindowHandle : HWND; AAudioDLL : TAudioDLL; AAudioBuffer : PByte; AAudioLengthSamples : Integer;
       ALoopEnabled : Boolean; ALoopStartAudioPosition, ALoopEndAudioPosition : Integer
      ); virtual;
    destructor Destroy; override;

  end; // TRunThread



implementation

uses
  UPreprocessShader,
  GL, GLext,
  Graphics,
  ExtCtrls;

{ TRunThreadCommandProxy }

function TRunThreadCommandProxy.GetTime: Integer;
begin
  Result := FTime;
end;

procedure TRunThreadCommandProxy.SetLastOperationInfo(AResult: Boolean; AInfo: String);
begin
  Self.StartBatch; // this blocks until we have the proxy all to ourselves
  Self.FLastOperationResult := AResult;
  Self.FLastOperationInfo := AInfo;
  Self.EndBatch;
end;

procedure TRunThreadCommandProxy.GetLastOperationInfo(var AResult: Boolean; var AInfo: String);
begin
  Self.StartBatch; // this blocks until we have the proxy all to ourselves
  AResult := Self.FLastOperationResult;
  AInfo := Self.FLastOperationInfo;
  Self.EndBatch;
end;


{ TRunThread }

procedure TRunThread.SetPlaying(AValue: Boolean);
var
  full_audio_buffer : PByte;
  full_length_bytes : Integer;
begin
  if FPlaying=AValue then Exit;

  if FTime < 0 then
    raise Exception.Create('FTime < 0');

  FPlaying:=AValue;
  if FPlaying then
  begin
    if FAudioDLL <> nil then
    begin
      full_audio_buffer := FAudioBuffer; // FAudioDLL.GetFullAudioBufferPtr();
      full_length_bytes := FAudioLengthSamples * 4;
      FCurrentPlaybackStartOffsetSamples := FTime;
      FAudioDLL.SetAudioPlaybackBufferPtr(full_audio_buffer + FTime * 4);
      if FLoopEnabled
      and (FLoopEndAudioPosition > FTime) // if playback is started from after loop end position, don't loop
      then
      begin
        if (FLoopEndAudioPosition > FAudioLengthSamples) then
          FLoopEndAudioPosition := FAudioLengthSamples;
        // We start from FTime, whatever it is set to, and it's the playing loop's
        // job to reset FTime to FAudioLoopStartPosition at end-of-loop.
        FAudioDLL.SetAudioPlaybackBufferLengthBytes((FLoopEndAudioPosition - FTime) * 4);
        FPlayingInsideLoop := true;
      end
      else
      begin
        FAudioDLL.SetAudioPlaybackBufferLengthBytes(full_length_bytes - FTime * 4);
        FPlayingInsideLoop := false;
      end;
      FAudioDLL.StartAudio();
    end;
  end
  else
  begin
    if FAudioDLL <> nil then
      FAudioDLL.StopAudio();
  end;
end; // TRunThread.SetPlaying


procedure TRunThread.TellTheCommandProxyWhatTimeItIs;
begin
  FCommandProxy.FTime := Self.FTime; // the move should be atomic...
end;

procedure TRunThread.TellTheProxyTheAverageFrameRate;
begin
  FCommandProxy.FAverageFrameTimeMS := Self.GetAverageFrameTimeMS;
end;

procedure TRunThread.Execute;
var
  audio_position_from_playback_start : Integer;
  ouch_we_crashed : Boolean;
  e : TObject;
  error_info : String;
begin
  FLastTextsUpdateTime := -1;
  error_info := '';
  ouch_we_crashed := false;
  try
    FStarted := true;
    CheckVisualsReady;
    while not Self.Terminated do
    begin
      FCommandProxy.DequeueAndExecute;

      if FPlaying then
      begin
        audio_position_from_playback_start := FAudioDLL.GetCurrentAudioPosition();
        if audio_position_from_playback_start < 0 then audio_position_from_playback_start := 0;
        if FLoopEnabled and FPlayingInsideLoop
        and (audio_position_from_playback_start + FCurrentPlaybackStartOffsetSamples >= FLoopEndAudioPosition)
        then
        begin // end-of-loop: reset audio playback
          SetPlaying(false);
          FTime := FLoopStartAudioPosition;
          SetPlaying(true);
          audio_position_from_playback_start := FAudioDLL.GetCurrentAudioPosition();
        end;

        FTime := FCurrentPlaybackStartOffsetSamples + audio_position_from_playback_start;
        FLastFrameResult := DrawFrame;
      end
      else
        Sleep(1); // this might not be the "best" way to yield time
    end; // while not Self.Terminated
  except
    e := TObject(AcquireExceptionObject);
    // if e is Exception then
    if Assigned(e) then
    begin
      error_info := e.ClassName;
      if e is Exception then
        error_info := error_info + ': ' + Exception(e).Message;
    end;
    ouch_we_crashed := true;
  end;

  try
    if FPlaying then
      FAudioDLL.StopAudio();
    if FVisualsDLL.Loaded then
    begin
      FVisualsDLL.FreeTextDrawingStuff();
      FVisualsDLL.FreeShaderStuff();
      FVisualsDLL.FreeGLContext();
      FVisualsDLL.Unload;
    end;
  except
    e := TObject(AcquireExceptionObject);
    if Assigned(e) then
    begin
      error_info := error_info + '   and ' + e.ClassName;
      if e is Exception then
        error_info := error_info + ': ' + Exception(e).Message;
    end;
  end;

  if error_info <> '' then
    FCommandProxy.MarkThreadAsCrashed(error_info);
end;

function TRunThread.ReloadShaderFromGLSLFile : Boolean;
var
  f : file;
  fname : String;
  l : Int64;
begin
  Result := false;
  fname := FWorkDirectory + FShaderSourceFileName;

  AssignFile(f, fname);
  Reset(f, 1);
  try
    l := FileSize(f);
    if l > 100000 then raise Exception.Create('Shader file size ouch.');

    FShaderSourceSize := l;

    if FShaderSource <> nil then
      FreeMem(FShaderSource);

    GetMem(FShaderSource, FShaderSourceSize + 1);
    FillChar(FShaderSource^, FShaderSourceSize + 1, 0);
    if FShaderSource = nil then raise Exception.Create('Shader memory ouch.');

    BlockRead(f, FShaderSource^, FShaderSourceSize);

  finally
    CloseFile(f);
  end;
  Result := true;
end;

function TRunThread.ReloadShaderFromString(AString : String) : Boolean;
var
  l : Int64;
begin
  Result := false;
  FShaderSourceSize := Length(AString);
  if FShaderSource <> nil then
    FreeMem(FShaderSource);

  GetMem(FShaderSource, FShaderSourceSize + 1);
  FillChar(FShaderSource^, FShaderSourceSize + 1, 0);
  if FShaderSource = nil then raise Exception.Create('Shader memory ouch.');
  Move(AString[1], FShaderSource^, FShaderSourceSize);

  Result := true;
end;

procedure TRunThread.SetVisualsWindowHandle(AValue: HWND);
begin
  if FVisualsWindowHandle=AValue then Exit;
  FVisualsWindowHandle:=AValue;
  if (FVisualsDLL <> nil) and (FVisualsDLL.Loaded) then
    SetVisualsWindowHandleToDLL(AValue);
end;

function TRunThread.ReloadShader : Boolean;
var
  sl : TStringList;
  shader_string, full_shader_path : String;
begin
  Result := false;
  if AnsiLowerCase(ExtractFileExt(FShaderSourceFileName)) = '.h' then
  begin
    sl := TStringList.Create;
    try
      full_shader_path := FWorkDirectory + FShaderSourceFileName;

      if not FileExists(full_shader_path) then
        Exit;
//        raise Exception.CreateFmt('Shader wtf %s', [full_shader_path]);

      sl.LoadFromFile(full_shader_path);
      UPreprocessShader.ShaderMinifierHToPlainString(sl, shader_string, nil);
      Result := ReloadShaderFromString(shader_string);
    finally
      sl.Free;
    end;
  end
  else
    Result := ReloadShaderFromGLSLFile;
end;

procedure TRunThread.SetAudioBuffer(AValue: PByte);
begin
  if FAudioBuffer=AValue then Exit;
  FAudioBuffer:=AValue;
end;

procedure TRunThread.SetAudioLengthSamples(AValue: Integer);
begin
  if FAudioLengthSamples=AValue then Exit;
  FAudioLengthSamples:=AValue;
end;

procedure TRunThread.ShaderCrazinessSafetyAttempt;
var
  i : Integer;
begin
  // replace non-ASCII garbage with spaces
  for i := 1 to Length(FShaderSource) do
  begin
    if Ord(FShaderSource[i]) >= 128 then
      FShaderSource[i] := ' ';
  end;
end;


function TRunThread.CheckTextBitmapsReady : Boolean;
var
  e : Cardinal;
begin
  Result := false;
  if FVisualsDLL.InitTextDrawingStuff() = 0 then
  begin
    e := Windows.GetLastError;
    Exit;
  end;

  Result := true;
end;

function TRunThread.CheckShaderCompiled : Boolean;
begin
//  FShaderSource := FVisualsDLL.GetShaderSourcePtr();
  Result := false;
  if ReloadShader then
  begin
//  Windows.MessageBox(0, FShaderSource, 'sorsa', MB_OK);
//    if FVisualsDLL.Loaded then
    FVisualsDLL.FreeShaderStuff();
    FVisualsDLL.SetShaderSourcePtr(FShaderSource);
    ShaderCrazinessSafetyAttempt;
    try
      if FVisualsDLL.CompileShader() = 0 then
      begin
      end
      else
        Result := true;

    except
      // UGLY CRASH SAFETY aargh what can we do if the shader is garbage and the compilation crashes
      // .... return false, and that's it?
    end;
  end;
end;

procedure TRunThread.CheckVisualsDLLLoaded;
begin
  if (FVisualsDLL = nil) then
    FVisualsDLL := TVisualsDLL.Create(FWorkDirectory + 'debug_visuals.dll');
  if not FVisualsDLL.Loaded then FVisualsDLL.Load;
end;

procedure TRunThread.CheckVisualsReady;
begin
  CheckVisualsDLLLoaded;
  CheckVisualsWindow;
  CheckTextBitmapsReady;
  CheckShaderCompiled;
end;

procedure TRunThread.ReloadDLL;
begin
  FVisualsDLL.FreeTextDrawingStuff();
  FVisualsDLL.FreeShaderStuff();
  FVisualsDLL.FreeGLContext();
  FVisualsDLL.Unload;
  FreeAndNil(FVisualsDLL);
  CheckVisualsDLLLoaded;
end;

procedure TRunThread.SetVisualsWindowHandleToDLL(AHandle : HWND);
var
  current_handle : HWND;
begin
  current_handle := FVisualsDLL.GetWindowHandle();
  if (current_handle <> 0) and (current_handle <> AHandle) then
  begin
    ReloadDLL;
  end;

  current_handle := FVisualsDLL.GetWindowHandle();
  if current_handle = 0 then
  begin
    if AHandle <> 0 then
      FVisualsDLL.SetWindowHandle(AHandle)
    else
      if FVisualsDLL.CreateWindow() = 0 then
        raise Exception.Create('Could not create window for visuals.');

    if FVisualsDLL.GetGLContext() = 0 then
      if FVisualsDLL.SetUpGLContext() = 0 then
        raise Exception.Create('Could not create GL context for visuals.');
  end;
end;

procedure TRunThread.CheckVisualsWindow;
begin
  CheckVisualsDLLLoaded;
  SetVisualsWindowHandleToDLL(FVisualsWindowHandle);
end;

constructor TRunThread.Create(
   ACommandProxy : TRunThreadCommandProxy; AWorkDirectory, AShaderSourceFileName : String;
   AVisualsWindowHandle : HWND; AAudioDLL : TAudioDLL; AAudioBuffer : PByte; AAudioLengthSamples : Integer;
   ALoopEnabled : Boolean; ALoopStartAudioPosition, ALoopEndAudioPosition : Integer
  );
begin
  FCommandProxy := ACommandProxy;
  FWorkDirectory := AWorkDirectory;
  FShaderSourceFileName := AShaderSourceFileName;
  FVisualsWindowHandle := AVisualsWindowHandle;
  FAudioDLL := AAudioDLL;
  FAudioBuffer := AAudioBuffer;
  FAudioLengthSamples := AAudioLengthSamples;
  FLoopEnabled := ALoopEnabled;
  FLoopStartAudioPosition := ALoopStartAudioPosition;
  FLoopEndAudioPosition := ALoopEndAudioPosition;

  Self.FreeOnTerminate := true;
  inherited Create(true);
end;

destructor TRunThread.Destroy;
begin
  inherited Destroy;
end;

procedure TRunThread.SetAudioDLL(AAudioDLL: TAudioDLL);
begin
  if not AAudioDLL.Loaded then
    raise Exception.Create('No can do! Audio DLL has to be loaded.');

  FAudioDLL := AAudioDLL;
end;

procedure TRunThread.SetTime(ATime: Integer);
var
  maxtime : Integer;
begin
  maxtime := Self.FAudioDLL.GetMusicLengthSamples() - 1;

  if ATime < 0 then
    FTime := 0
  else if ATime > maxtime then
    FTime := maxtime
  else
    FTime := Cardinal(ATime);

  if FPlaying then
  begin  // if we're playing, then let the actual play loop set the time to the proxy
    SetPlaying(false);

    SetPlaying(true);
  end
  else // if we're stopped, then we have to tell the time right away, because the loop is not running
  begin
    if FStarted then
    begin
      DrawFrame; // and update the screen
      TellTheCommandProxyWhatTimeItIs;
    end;
  end;
end;

procedure TRunThread.SetLoopParameters(ALoopEnabled: Boolean;
  ALoopStartAudioPosition, ALoopEndAudioPosition: Integer);
begin
  FLoopEnabled := ALoopEnabled;
  FLoopStartAudioPosition := ALoopStartAudioPosition;
  FLoopEndAudioPosition := ALoopEndAudioPosition;
end;

procedure TRunThread.UpdateLastOperationInfo;
begin
  FLastFailedOperation := StrPas(FVisualsDLL.GetLastFailedOperation());
  FLastFailedOperationInfo := StrPas(FVisualsDLL.GetLastFailedOperationInfo());
  FLastShaderInfoLog := StrPas(FVisualsDLL.GetShaderInfoLog());

  // set the command proxy's cache values
  FCommandProxy.SetLastOperationInfo(FLastFrameResult, GetLastOperationInfo);
end;

function TRunThread.GetLastOperationInfo : String;
begin
  Result :=
    Trim(FLastFailedOperation + ' ' + FLastFailedOperationInfo);
  if (Result <> '') and (FLastShaderInfoLog <> '') then
     Result := Result + #13;
  Result := Result + FLastShaderInfoLog;
end;



function TRunThread.DrawFrame : Boolean;
var
  i : Integer;
  p : PChar;
begin
  if FTime < FLastTextsUpdateTime then
    FVisualsDLL.ResetTimingsCursorToStart();
  FVisualsDLL.UpdateTimingsCursor(FTime);
  FLastTextsUpdateTime := FTime;

  p := FVisualsDLL.GetTextPtr();
  FVisualsDLL.DrawTextBitmap();

  FLastFrameResult := FVisualsDLL.DrawFrame(FTime);
  TellTheCommandProxyWhatTimeItIs;
  UpdateLastOperationInfo;
  Result := FLastFrameResult;

  for i := NUM_TIMESTAMPS_FOR_FRAME_STATS-1 downto 1 do
    FFrameTimestamps[i] := FFrameTimestamps[i-1];
  FFrameTimestamps[0] := timeGetTime;
  TellTheProxyTheAverageFrameRate;
end;

// The cmdSomething routines are command functions that are run in the visuals thread.

// Maybe we should check in every method of TRunThread that it's only run in the correct thread.


procedure TRunThread.cmdGetGLInfo(AData: Pointer);
var
  drawBuffer, encoding : GLint;
  s : String;
begin
  if not GLext.Load_GL_ARB_framebuffer_object then
    raise Exception.Create('no can do load gl arb framebuffer blaa extension');

  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  glGetIntegerv(GL_DRAW_BUFFER, @drawBuffer);
  s := Format('draw buffer: 0x%x', [drawBuffer]);

  encoding := -1;
  glGetFramebufferAttachmentParameteriv(
    GL_FRAMEBUFFER, // target
    GL_BACK_LEFT, // attachment
    GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING, // pname
    @encoding // *params
  );
  s := s + #13#10 + Format('framebuffer attachment color encoding 0x%x: ', [encoding]);
  PString(AData)^ := s;
end;

procedure TRunThread.cmdTerminate(AData: Pointer);
begin
  Self.Terminate;
end;

procedure TRunThread.cmdSetRunParams(AData: Pointer);
var
  runparams : PRunParamsRec;
begin
  runparams := PRunParamsRec(AData);
  if runparams <> nil then
  begin
    FShaderSourceFileName := runparams^.ShaderFileName;
  end;
end;

procedure TRunThread.cmdReloadShader(AData: Pointer);
var
  res : PCommandResultRec;
  b : Boolean;
begin
  res := PCommandResultRec(AData);

  try
    b := CheckShaderCompiled;
    UpdateLastOperationInfo;

    if res <> nil then
    begin
      res^.Result := b;
      res^.Info := Self.GetLastOperationInfo;
    end;

  except
    on e : Exception do
      if res <> nil then
        res^.Info := e.ClassName + ' ' + e.Message;
  end;
end;

procedure TRunThread.cmdGetLastFrameResult(AData: Pointer);
var
  res : PCommandResultRec;
begin
  res := AData;
  if res <> nil then
  begin
    res^.Result := FLastFrameResult;
    res^.Info := GetLastOperationInfo;
  end;
end;


procedure TRunThread.cmdCopyFrameToBitmap(AData: Pointer);
  procedure CopyRGBtoBGRSwapped(APSrc, APDst : PCardinal; AWidth : Integer);
  var
    c : Cardinal;
  begin
    while (AWidth > 0) do
    begin
      c := APsrc^;
      APDst^ := ((c and $FF) shl 16) + ((c and $FF0000) shr 16) + (c and $FF00FF00);
      Dec(AWidth);
      Inc(APSrc);
      Inc(APDst);
    end;
  end;

var
  bm : Graphics.TBitmap;
  pbuf : PByte;
  psrc, pdst : PCardinal;
  w, h, y, bmsizebytes : Integer;
begin
  if AData = nil then Exit;
  bm := Graphics.TBitmap(AData);
  bm.PixelFormat := pf32bit;
  w := bm.Width;
  h := bm.Height;
  bmsizebytes := w * h * 4;
  GetMem(pbuf, bmsizebytes);

  glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, pbuf);

  for y := 0 to h-1 do
  begin
    CopyRGBtoBGRSwapped(Pointer(pbuf + y * w * 4), bm.ScanLine[h-y-1], w);
  end;

  FreeMem(pbuf);
end;


procedure TRunThread.cmdCopyTextsBitmapToPaintBox(AData: Pointer); // AData : HWND
var
  dest_paintbox : TPaintBox;
  dest_dc : HDC;
  dest_window_handle : HWND;
  dest_rect : TRect;
//  texts_bitmap_handle : THandle;
  texts_bmiptr : PBITMAPINFO;
  texts_bitmap_bits : Pointer;
  temp_bitmapinfo : BITMAPINFO;
  res : Cardinal;

begin
  if AData = nil then Exit;
  dest_paintbox := TPaintBox(AData);
  if (dest_paintbox.Parent = nil) then Exit;

  dest_window_handle := dest_paintbox.Parent.Handle;
//  texts_bitmap_handle := FVisualsDLL.GetTextsBitmapHandle();
  texts_bmiptr := FVisualsDLL.GetTextsBitmapInfo();
  texts_bitmap_bits := FVisualsDLL.GetTextsBitmapBitsPtr();

  if (texts_bmiptr <> nil) and (texts_bitmap_bits <> nil) then
  begin
    temp_bitmapinfo := texts_bmiptr^;
    temp_bitmapinfo.bmiHeader.biSize := 40; // the biSize field has been overwritten because of 1337 hax0ring
    dest_dc := dest_paintbox.Canvas.Handle; // GetDC(dest_window_handle);
    dest_rect := dest_paintbox.BoundsRect;

    res := StretchDIBits(
      dest_dc,
      0, // dest_rect.Left   // for some reason, (0,0) must be given as the top-left... maybe there's a coordinate translation somewhere
      0, // dest_rect.Top,
      dest_rect.Width,
      dest_rect.Height,
      0,
      0,
      texts_bmiptr^.bmiHeader.biWidth,
      texts_bmiptr^.bmiHeader.biHeight,
      texts_bitmap_bits,
      temp_bitmapinfo,
      DIB_RGB_COLORS,
      SRCCOPY
    );

    ReleaseDC(dest_window_handle, dest_dc);
  end;
end;

procedure TRunThread.cmdGetTextsBitmapInfo(AData: Pointer); // AData : ^PBITMAPINFO
var
  r : ^PBITMAPINFO;
  texts_bmiptr : PBITMAPINFO;
begin
  if AData = nil then Exit;
  texts_bmiptr := FVisualsDLL.GetTextsBitmapInfo();
  r := AData;
  r^ := texts_bmiptr;
end;

procedure TRunThread.cmdGetLastTextPtr(AData: Pointer);
var
  pp : PPointer;
begin
  pp := AData;
  if (pp <> nil) then
  begin
    if FVisualsDLL <> nil then
      pp^ := FVisualsDLL.GetTextPtr()
    else
      pp^ := nil;
  end;
end;

function TRunThread.GetAverageFrameTimeMS : Single;
begin
  Result := (FFrameTimestamps[0]-FFrameTimestamps[NUM_TIMESTAMPS_FOR_FRAME_STATS-1]) / (NUM_TIMESTAMPS_FOR_FRAME_STATS-1);
end;

procedure TRunThread.cmdDrawFrame(AData: Pointer);
begin
  FLastFrameResult := Self.DrawFrame;
  Self.cmdGetLastFrameResult(AData);
end;

procedure TRunThread.cmdSetPlaying(AData: Pointer);
begin
  Self.SetPlaying(AData <> nil);
end;

procedure TRunThread.cmdStartPlaying(AData: Pointer);
var
  res : PCommandResultRec;
begin
  res := PCommandResultRec(AData);
  Self.SetPlaying(true);
  if res <> nil then
  begin
    res^.Result := Self.FPlaying;
    res^.Info := '';
  end;
end;

procedure TRunThread.cmdStopPlaying(AData: Pointer);
var
  res : PCommandResultRec;
begin
  res := PCommandResultRec(AData);
  Self.SetPlaying(false);
  if res <> nil then
  begin
    res^.Result := not Self.FPlaying;
    res^.Info := '';
  end;
end;

procedure TRunThread.cmdSetTime(AData: Pointer);
begin
  Self.SetTime(Integer(AData)); // SetTime clips the value to song length
end;

procedure TRunThread.cmdSetLoopParams(AData: Pointer);
var
  res : PCommandResultRec;
begin
  res := PCommandResultRec(AData);
end;

procedure TRunThread.cmdGetTime(AData: Pointer);
begin
  if (AData <> nil) then
    PInteger(AData)^ := FTime;
end;

procedure TRunThread.cmdSetLoopEnabled(AData: Pointer);
begin
  FLoopEnabled := Boolean(AData);
  if FPlaying then
  begin
    SetPlaying(false);
    SetPlaying(true);
  end;
end;

procedure TRunThread.cmdSetLoopStartAudioPosition(AData: Pointer);
begin
  FLoopStartAudioPosition := Integer(AData);
  if FPlaying then
  begin
    SetPlaying(false);
    SetPlaying(true);
  end;
end;

procedure TRunThread.cmdSetLoopEndAudioPosition(AData: Pointer);
begin
  FLoopEndAudioPosition := Integer(AData);
  if FPlaying then
  begin
    SetPlaying(false);
    SetPlaying(true);
  end;
end;

end.

