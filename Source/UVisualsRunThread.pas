unit UVisualsRunThread;
// Compofiller Studio
// by Yzi 2017

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  UAudioDLL, UVisualsDLL,
  UThreadCommand;


{ TVisualsThread }
type
  TVisualsRunThread = class;
  TRedrawEvent = procedure(ASender : TVisualsRunThread) of object;
  TGetTimeMethod = function : Integer of object;


  { TVisualsRunThread }

  TVisualsRunThread = class(TThread)
  private
    FOnRedraw: TRedrawEvent;
    FVisualsDLL : TVisualsDLL;
    FAudioDLL : TAudioDLL;
    FCommandQueue : TThreadCommandQueue;

    FPlaying : Boolean;

    FGetTimeMethod : TGetTimeMethod;

    FTime : Cardinal;

    procedure CallRedraw;
    procedure SetOnRedraw(AValue: TRedrawEvent);
  protected
    procedure Execute; override;

    procedure CheckShaderCompiled;
    procedure CheckVisualsDLLLoaded;
    procedure CheckVisualsReady;
    procedure CheckVisualsWindow;

  public
    constructor Create(ACommandQueue : TThreadCommandQueue); virtual;
    destructor Destroy; override;

    procedure SetAudioDLL(AAudioDLL : TAudioDLL);

    procedure SetTime(ATime : Integer);

    procedure SetGetTimeMethod(AMethod : TGetTimeMethod);
    procedure SetPlaying(AValue: Boolean);

    procedure DrawFrame;

    // Commands
    procedure cmdUpdateTime(AData: Pointer);
    procedure cmdStartPlaying(AData: Pointer);
    procedure cmdSetPlaying(AData: Pointer);
    procedure cmdDrawFrame(AData: Pointer);
    procedure cmdSetTimeFunc(AData: Pointer);
    procedure cmdTerminate(AData: Pointer);

    property OnRedraw : TRedrawEvent read FOnRedraw write SetOnRedraw;
    property Playing : Boolean read FPlaying write SetPlaying;
  end;



implementation


{ TVisualsRunThread }

procedure TVisualsRunThread.CallRedraw;
begin

end;

procedure TVisualsRunThread.SetOnRedraw(AValue: TRedrawEvent);
begin
  FOnRedraw := AValue;
end;

procedure TVisualsRunThread.SetPlaying(AValue: Boolean);
begin
  if FPlaying=AValue then Exit;
  FPlaying:=AValue;
end;

procedure TVisualsRunThread.Execute;
begin
  CheckVisualsReady;
  while not Self.Terminated do
  begin
    FCommandQueue.ExecuteAndDequeue(Self);
    if FPlaying then
    begin
      if FGetTimeMethod <> nil then
        FTime := FGetTimeMethod();
      DrawFrame;
    end;
  end;
end;

procedure TVisualsRunThread.CheckShaderCompiled;
begin
  FVisualsDLL.CompileShader();
end;

procedure TVisualsRunThread.CheckVisualsDLLLoaded;
begin
  FVisualsDLL := TVisualsDLL.Create('objects\debug_visuals.dll');
  if not FVisualsDLL.Loaded then FVisualsDLL.Load;
end;

procedure TVisualsRunThread.CheckVisualsReady;
begin
  CheckVisualsDLLLoaded;
  CheckVisualsWindow;
  CheckShaderCompiled;
end;

procedure TVisualsRunThread.CheckVisualsWindow;
begin
  CheckVisualsDLLLoaded;

  if FVisualsDLL.GetWindowHandle() = 0 then
    if FVisualsDLL.CreateWindow() = 0 then
      raise Exception.Create('Could not create window for visuals.');

  if FVisualsDLL.GetGLContext() = 0 then
    if FVisualsDLL.SetUpGLContext() = 0 then
      raise Exception.Create('Could not create GL context for visuals.');
end;

constructor TVisualsRunThread.Create(ACommandQueue: TThreadCommandQueue);
begin
  FCommandQueue := ACommandQueue;

  Self.FreeOnTerminate := true;
  inherited Create(true);
end;

destructor TVisualsRunThread.Destroy;
begin
  inherited Destroy;
end;

procedure TVisualsRunThread.SetAudioDLL(AAudioDLL: TAudioDLL);
begin
  FAudioDLL := AAudioDLL;
end;

procedure TVisualsRunThread.SetTime(ATime: Integer);
begin
  if ATime < 0 then
    FTime := 0
  else
    FTime := Cardinal(ATime);
end;

procedure TVisualsRunThread.SetGetTimeMethod(AMethod: TGetTimeMethod);
begin
  FGetTimeMethod := AMethod;
end;

procedure TVisualsRunThread.DrawFrame;
begin
  FVisualsDLL.DrawFrame(FTime);
end;

// These command functions are run in the visuals thread, so any TEngine methods
// we call must be thread-safe and re-entrant.

procedure TVisualsRunThread.cmdTerminate(AData: Pointer);
begin
  Self.Terminate;
end;

procedure TVisualsRunThread.cmdSetTimeFunc(AData: Pointer);
begin
  // SetGetTimeMethod(@TEngine(AData).GetCurrentAudioPosition);
  raise Exception.Create('pois');
end;

procedure TVisualsRunThread.cmdDrawFrame(AData: Pointer);
begin
  Self.DrawFrame;
end;

procedure TVisualsRunThread.cmdSetPlaying(AData: Pointer);
begin
  Self.SetPlaying(Boolean(AData));
end;

procedure TVisualsRunThread.cmdStartPlaying(AData: Pointer);
begin
  Self.SetPlaying(Boolean(AData));
end;

procedure TVisualsRunThread.cmdUpdateTime(AData: Pointer);
 var
  t : Integer;
//  e : TEngine;
begin
//  e := TEngine(AData);
  t := Integer(AData); // e.GetCurrentAudioPosition;
  if t >= 0 then
    Self.SetTime(Cardinal(t));
end;


end.

