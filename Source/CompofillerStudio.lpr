program CompofillerStudio;
// Compofiller Studio
// by Yzi 2017

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  SysUtils,
  Forms, UMainForm, UAudioDLL, UVisualsDLL, UEngine, UConfig, URunThread,
  UThreadCommand, UWaveformZoomDisplay, UBuilder, UScriptRunner,
  {$ifndef WINDOWS}FakeWindows,{$endif}
  UVariableNames, UEditorForm, UPreprocessShader, UVisualsForm, UWAVFile,
  UEditTextForm, UTimingsAndTextsEditorForm, UTimingsAndTextsData, UConfigUIMappingHelpers
  ;

type
  TApplicationExceptionLogger = class
    procedure HandleException(Sender: TObject; E: Exception);
  end;

var
  ApplicationExceptionLogger: TApplicationExceptionLogger;

{$R *.res}

procedure TApplicationExceptionLogger.HandleException(Sender: TObject;
  E: Exception);
var
  LogFile: TextFile;
  LogFileName: String;
  FrameCount, i: Integer;
  Frames: PCodePointer;
begin
  LogFileName := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    'CompofillerStudio-errors.log';
  try
    AssignFile(LogFile, LogFileName);
    if FileExists(LogFileName) then
      Append(LogFile)
    else
      Rewrite(LogFile);

    try
      WriteLn(LogFile, FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now));
      if Sender <> nil then
        WriteLn(LogFile, 'Sender: ', Sender.ClassName);
      WriteLn(LogFile, E.ClassName, ': ', E.Message);

      FrameCount := ExceptFrameCount;
      Frames := ExceptFrames;
      if ExceptAddr <> nil then
        WriteLn(LogFile, BackTraceStrFunc(ExceptAddr));
      for i := 0 to FrameCount - 1 do
        WriteLn(LogFile, BackTraceStrFunc(Frames[i]));
      WriteLn(LogFile);
    finally
      CloseFile(LogFile);
    end;
  except
    on LogError: Exception do
      WriteLn(StdErr, 'Could not write exception log: ', LogError.Message);
  end;

  Application.ShowException(E);
end;

begin
  SetHeapTraceOutput(IncludeTrailingPathDelimiter(GetTempDir(False)) +
    'CompofillerStudio-heaptrc.log');
  ApplicationExceptionLogger := TApplicationExceptionLogger.Create;
  Application.OnException := @ApplicationExceptionLogger.HandleException;
  RequireDerivedFormResource:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TEditorForm, EditorForm);
  Application.CreateForm(TVisualsForm, VisualsForm);
  Application.CreateForm(TEditTextForm, EditTextForm);
  Application.CreateForm(TTimingsAndTextsEditorForm, TimingsAndTextsEditorForm);
  try
    Application.Run;
  finally
    Application.OnException := nil;
    ApplicationExceptionLogger.Free;
  end;
end.

