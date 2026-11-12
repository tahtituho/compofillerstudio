unit UEngine;
// Compofiller Studio
// by Yzi 2018
//
// Build & Run Engine
//


{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  Windows,
  Graphics, // for TBitmap
  ExtCtrls, // for TPaintBox
  UScriptRunner,
  UAudioDLL,
  UThreadCommand,
  URunThread;

type

  { TEngine }
  TEngine = class;
  TBuildEvent = procedure(ASender : TEngine; ADescription : String) of object;
  TShaderErrorsEvent = procedure(ASender : TEngine; AFileName : String; AErrors: TStrings) of object;

  TEngine = class(TObject)
  private
    FOnAddProcessOutputLine : TAddProcessOutputLineEvent;
    FOnBuildStart : TBuildEvent;
    FOnBuildEnd : TBuildEvent;
    FOnPlaybackStateChanged : TBuildEvent;
    FOnShaderErrors: TShaderErrorsEvent;

    FProjectDirectory : String;
    FProjectFile : String;
    FActiveConfig : String;
    FParentConfig : String;
    FProgramPath : String; // where CompofillerStudio.exe is located
    FTimeDivider: Single;


    // The updating order with these is
    //
    //    (config/project) musical time : only changed when the USER manipulates them via the user interface (or when loading the project)
    //      --> to DLL (refresh to DLL)
    //       --> refresh from DLL
    //        --> audio position
    //
    // So, the musical time values should only ever be written from the configuration ...
    FLoopStartMusicalTime, FLoopEndMusicalTime : Single;
    FLoopStartAudioPosition, FLoopEndAudioPosition : Integer;
    FLoopEnabled : Boolean;

    FVisualsWindowHandle: HWND;
    procedure AddLogMessage(AMessage: String);
    function CheckThreadCommand(
      AThreadCommandQueueResult: TThreadCommadQueueResult): Boolean;
    procedure FreeAudioBuffer;
    function GetAudioReady: Boolean;
    function GetAutoRebuild: Boolean;
    function GetBuildVariableScriptRows: String;
    function GetLoopEnabled: Boolean;
    function GetRunThreadIsRunning: Boolean;
    procedure HighlightShaderErrors(AFileName : String; AErrors: String);

    procedure SetAutoRebuild(AValue: Boolean);
    procedure SetKeepAudio(AValue: Boolean);
    procedure SetLoopEnabled(AValue: Boolean);
    procedure SetOnAddProcessOutputLine(AValue: TAddProcessOutputLineEvent);
    procedure SetOnShaderErrors(AValue: TShaderErrorsEvent);
    procedure SetProgramPath(AValue: String);
    procedure SetProjectDirectory(AValue: String);
    procedure SetProjectFile(AValue: String);
    procedure SetTimeDivider(AValue: Single);

    // Sets the project's basic information like work directory and project
    // file name to AScript, as variables and instance variables (if applicable).
    // This has to be done for each new created (config or build) script object,
    // because the scripts don't magically know what project they're being run in.
    procedure SetUpScriptObject(AScript : TScriptRunner);
    procedure SetVisualsWindowHandle(AValue: HWND);
    procedure StopAndTerminateRunThread;

  protected
    FRunThread : TRunThread; // the run thread loads the visuals DLL
    FRunThreadCommandProxy : TRunThreadCommandProxy;

    FRunning : Boolean;
    FAudioBuffer : Pointer;
    FAudioBufferLengthSamples : Integer;
    FAudioBufferAllocatedLengthBytes : Integer;
    FAudioDLL : TAudioDLL; // Engine loads the audio DLL, but gives the run thread a reference to it

    FAudioDelayLength : Integer; // in stereo samples

    FKeepAudio : Boolean;

    // We keep the shader file name in a "cache" copy, so the CheckShaderChanged
    // routine doesn't have to re-run the script every time.
    FShaderSourceFileName : String;
    FShaderSourceFileAge : LongInt;
    FLastLoadedShaderSourceFileName : String;

    function CheckAudioDLLLoaded : Boolean;
    function CheckAudioReady : Boolean;

  public
    constructor Create; virtual;
    destructor Destroy; override;

    function LoadProject(AProjectFile : String) : Boolean;

    procedure RebuildDLLs;
    procedure RebuildEXE;
    procedure RunEXE;

//    procedure ExecuteCommandAsync(ACommand : String);

// ----------------------------------------------------------------------------
    property FullAudioBuffer : Pointer read FAudioBuffer;
    function GetAudioPlaybackBufferPtr : Pointer;
    procedure SetAudioPlaybackBufferPtr(AValue : Pointer);

    procedure RestartAudioFromPosition(APosition: Integer);
    procedure SetAudioPosition(APosition: Integer);

    function ConvertMusicalTimeToAudioPosition(AMusicalTime : Single) : Integer;
    function ConvertAudioPositionToMusicalTime(AAudioPosition : Integer) : Single;

    function GetLoopStartMusicalTime : Single;
    procedure SetLoopStartMusicalTime(AValue : Single);
    function GetLoopEndMusicalTime : Single;
    procedure SetLoopEndMusicalTime(AValue : Single);
    function GetLoopStartAudioPosition : Integer;
    function GetLoopEndAudioPosition : Integer;

    // this is in "mono samples", and we might pad it to get some extra silence at the end
    function GetAllocatedAudioLengthInMonoSamples : Cardinal;
    function GetMusicBPM: Single;
    function GetMusicLengthSamples: Cardinal; // this should be the actual musical length, in "stereo samples", as specified in 4klang.inc
    function GetMusicSampleRate: Cardinal;

    procedure RefreshAudioThings;

    // Note: this is relative to full audio timeline (not the snippet where playback happened to be started from)
    function GetCurrentAudioPosition : Integer; // returns negative value on error

    // Returns true only if the RunThread is in Play/Pause (i.e. we are not stopped),
    // and if the audio rendering thread is in a signaled state.
    function GetAudioRenderingIsFinished: Boolean;

// ----------------------------------------------------------------------------


    procedure Play(AStartTime : Integer);
    procedure Stop;

    procedure StopAndUnloadDLLs;

    procedure RefreshShaderFileName;
    function CheckShaderChanged : Boolean;

    procedure SetVariableValueInConfig(AConfigFile, AVariableName, AVariableValue: String);
    function GetEffectiveVariableValueInConfig(AConfigFile, AVariableName : String) : String;

    // Returns value of AVariableName in AConfigFile without including anything.
    function GetVariableValueInConfig_NO_INCLUDE(AConfigFile, AVariableName : String) : String;

    procedure SetProjectVariableValue(AVariableName, AVariableValue: String);
    function GetProjectVariableValue(AVariableName : String): String;

    procedure SetVariableValueInActiveConfig(AVariableName, AVariableValue: String);

    // "Effective" value means the final value after running all the scripts,
    // with included scripts and variable expansions.
    function GetEffectiveVariableValueInActiveConfig(const AVariableName : String) : String;

    // The "Ex" (for Extended) routine has more parameters
    procedure GetEffectiveVariableValueInActiveConfigEx(const AVariableName : String; var AFoundValue, AFoundInScript : String);

    // Returns the name of the config where the effective value of AVariableName is defined
    function GetConfigNameOfEffectiveValueForVariable(const AVariableName : String) : String;

    procedure GetConfigVariableInheritedValueAndConfig(AVariableName: String; var AInheritedValue, AInheritedValueConfig : String);
    function ConfigVariableInheritedValue(AVariableName: String): String;
    function ConfigVariableHasInheritedValue(AVariableName : String) : Boolean;

    procedure DeleteConfigVariable(AVariableName : String);

    function GetActiveConfig: String;
    procedure SetActiveConfig(AValue: String);

    // Returns the active config's parent config, if any
    function GetParentConfig: String;

    // Returns the names of all *.config files found in the project folder
    procedure GetConfigFileList(AList: TStringList);

    // Returns the config parent path for AConfig, i.e. parent (PARENT_CONFIG) and their parents etc.
    // The list is delimited with DirectorySeparators so you can use ExtractFileName for getting AConfig from the string
    function GetConfigRootPath(AConfig: String): String;


    // Minifies ASourceShader to ADestinationShader using ShaderMinifier, and
    // if ASourceShaderConfig is given, tries to re-map the time and resolution
    // uniform names based on the #defines written to the .h file by ShaderMinifier.
    function MinifyShader(ASourceShader, ADestinationShader, ASourceShaderConfig : String) : Boolean;

    // Remaps the uniform names to what ShaderMinifier has told them to be in
    // the current, minified, .h format shader. (if the current shader is not a .h file, raises an exception)
    // ASourceShaderConfig is the config from which the minification was done,
    // so it contains the original uniform names, for which the current .h
    // file ought to have #defined mappings in the beginning of the .h file.
    procedure RemapUniformsFromMinifiedShader(ASourceShaderConfig : String);

    // Create a new project into a new temporary folder.
    function NewProject(ATemplate : String) : Boolean;

    // Copy a project to a new folder named ANewName that's going to be created in ANewParentDir
    // and the main project file is going to be copied to ANewParentDir\ANewName\ANewName.
    // For example,
    //   SaveProjectAs('C:\temp', 'Prod.compofiller')
    // creates a folder "C:\temp\Prod.compofiller", copies all files from the current
    // directory to that folder, and renames the current project file to
    // "C:\temp\Prod.compofiller\Prod.compofiller"
    // Returns true, if successful. (though if not succesful, raises a bunch of exceptions! but this may change in the future)
    function SaveProjectAs(ANewParentDir, ANewName : String): Boolean;

    function DrawOneFrameToBitmap(ABitmap: Graphics.TBitmap): Boolean;
    function DrawTextsBitmapToPaintBox(ATarget: TPaintBox): Boolean;

    function GetGLInfo : String;

    function GetAverageFrameTimeMS : Single;

    // Pointer to the current/latest text drawn by the visuals DLL. Nil if not running or visuals DLL not loaded..
    function GetTextPtr : Pointer;
    function GetTextsBitmapInfo: PBITMAPINFO;

    property ProgramPath : String read FProgramPath write SetProgramPath;

    property AutoRebuild : Boolean read GetAutoRebuild write SetAutoRebuild;
    property KeepAudio : Boolean read FKeepAudio write SetKeepAudio;

    property OnAddProcessOutputLine : TAddProcessOutputLineEvent read FOnAddProcessOutputLine write SetOnAddProcessOutputLine;
    property AudioReady : Boolean read GetAudioReady;

    property ProjectFile : String read FProjectFile write SetProjectFile;
    property ProjectDirectory : String read FProjectDirectory write SetProjectDirectory;
    property ActiveConfig : String read GetActiveConfig write SetActiveConfig;

    property ShaderSourceFileName : String read FShaderSourceFileName;

    //: Length of project time-base unit in audio samples, i.e. if time-base is in bars, how long is one bar.
    property TimeDivider : Single read FTimeDivider write SetTimeDivider;

    property LoopStart : Single read GetLoopStartMusicalTime write SetLoopStartMusicalTime;
    property LoopEnd : Single read GetLoopEndMusicalTime write SetLoopEndMusicalTime;
    property LoopEnabled : Boolean read GetLoopEnabled write SetLoopEnabled;

    property VisualsWindowHandle : HWND read FVisualsWindowHandle write SetVisualsWindowHandle;

    property Running : Boolean read FRunning; // dang! this evolved to have two meanings, fix plz...
    property RunThreadIsRunning : Boolean read GetRunThreadIsRunning; // in "pause" mode we're "not running" but kind of still running
    property AudioRenderingIsFinished: Boolean read GetAudioRenderingIsFinished;

    property OnPlaybackStateChanged : TBuildEvent read FOnPlaybackStateChanged write FOnPlaybackStateChanged;
    property OnBuildStart : TBuildEvent read FOnBuildStart write FOnBuildStart;
    property OnBuildEnd : TBuildEvent read FOnBuildEnd write FOnBuildEnd;
    property OnShaderErrors : TShaderErrorsEvent read FOnShaderErrors write SetOnShaderErrors;

  end; // class TEngine

function ForceProjectDirectoryFormat(ADir : String) : String;


implementation

uses
  strutils, LazFileUtils, FileUtil,

  UBuilder, UConfig,
  UVariableNames,
  UPreprocessShader;

function ForceProjectDirectoryFormat(ADir: String): String;
begin
  Result := ADir;
  ForcePathDelims(Result);
  Result := AppendPathDelim(Result);
end;

// We need config root paths for sorting the config list
function TEngine.GetConfigRootPath(AConfig : String) : String;
var
  confname : String;
  config : TConfig;
  f : String;
  parent : String;
  parents : TStringList;
begin
  parents := TStringList.Create;
  confname := AConfig;
  try
    parents.Add(confname);
    Result := confname;
    repeat
      config := TConfig.Create;
      try
        config.FileName := FProjectDirectory + confname;
        parent := '';
        f := '';
        config.GetVariableValue(CV_PARENT_CONFIG, parent, f, false);
      finally
        config.Free;
      end;

      if (f <> '') and (ExtractFileName(f) <> ExtractFileName(confname)) then
        raise Exception.CreateFmt('When finding out the parent path for %a: Something is wrong with config %s! Its parent config is found from %s!?', [AConfig, confname, f]);

      if (parent <> '') then
      begin
        parent := ExtractFileName(parent);
        if parents.IndexOf(parent) >= 0 then
          raise Exception.CreateFmt('Cyclic/recursive parent path detected for %s, %s was already in the parent path!', [AConfig, confname]);
        parents.Add(parent);
        Result := parent + DirectorySeparator + Result;

        confname := parent;
      end;
    until (parent = ''); // root config has no parent
  finally
    parents.Free;
  end;
end; // TEngine.GetConfigRootPath

{ TEngine }

procedure TEngine.SetAutoRebuild(AValue: Boolean);
begin
  Self.SetProjectVariableValue(PREFS_AUTOREBUILD_DLLS, IntToStr(Ord(AValue)));
end;

procedure TEngine.SetKeepAudio(AValue: Boolean);
begin
  if FKeepAudio=AValue then Exit;
  FKeepAudio:=AValue;
end;

procedure TEngine.SetOnAddProcessOutputLine(AValue: TAddProcessOutputLineEvent);
begin
  FOnAddProcessOutputLine := AValue;
end;

procedure TEngine.SetOnShaderErrors(AValue: TShaderErrorsEvent);
begin
  if FOnShaderErrors=AValue then Exit;
  FOnShaderErrors:=AValue;
end;

procedure TEngine.SetProgramPath(AValue: String);
begin
  if FProgramPath=AValue then Exit;
  FProgramPath:=AValue;
end;

procedure TEngine.SetProjectDirectory(AValue: String);
begin
  if FProjectDirectory=AValue then Exit;
  FProjectDirectory:=AValue;
end;

procedure TEngine.SetProjectFile(AValue: String);
begin
  if FProjectFile=AValue then Exit;
  FProjectFile:=AValue;
end;

procedure TEngine.SetTimeDivider(AValue: Single);
begin
  if FTimeDivider=AValue then Exit;
  FTimeDivider:=AValue;
end;

function TEngine.GetAudioReady: Boolean;
begin
  Result := CheckAudioDLLLoaded;
end;

function TEngine.GetAutoRebuild: Boolean;
begin
  Result := (Self.GetProjectVariableValue(PREFS_AUTOREBUILD_DLLS) <> '0');
end;

function TEngine.CheckAudioDLLLoaded : Boolean;
var
  dllpath : String;
begin
  Result := false;
  dllpath := FProjectDirectory + 'debug_audio.dll';
  if not FileExists(dllpath) then
    if Self.AutoRebuild then
    begin
      RebuildDLLs;
      if not FileExists(dllpath) then
      begin
        AddLogMessage('Error: could not build ' + dllpath);
        Exit;
      end;
    end;

  if FAudioDLL = nil then
    FAudioDLL := TAudioDLL.Create(dllpath);
  if not FAudioDLL.Loaded then
  begin
    FAudioDLL.Load();
    if not FAudioDLL.Loaded then
      Exit;
  end;
  Result := true;
end;

function TEngine.CheckAudioReady : Boolean;
begin
  Result := CheckAudioDLLLoaded;
end;


constructor TEngine.Create;
begin
  inherited Create;

  FRunThreadCommandProxy := TRunThreadCommandProxy.Create;
end;

destructor TEngine.Destroy;
var
  h : THandle;
begin
  StopAndUnloadDLLs;

  if FRunThread <> nil then
  begin // this shouldn't even happen?!
    FRunThreadCommandProxy.ExecuteCommandFuncSync(@FRunThread.cmdTerminate, nil);
    Windows.TerminateThread(FRunThread.Handle, 0);
  end;

  if FAudioDLL <> nil then
  begin
    h := FAudioDLL.GetAudioRendererThreadHandle();
    Windows.TerminateThread(h, 0);
  end;

  if FRunThreadCommandProxy <> nil then
    FreeAndNil(FRunThreadCommandProxy);

  if FAudioBuffer <> nil then
    FreeMem(FAudioBuffer);

  inherited Destroy;
end;

procedure TEngine.FreeAudioBuffer;
begin
  FreeMem(FAudioBuffer);
  FAudioBuffer := nil;
  FAudioBufferAllocatedLengthBytes := 0;
  FAudioBufferLengthSamples := 0;
  FAudioDelayLength := 0;
end;

procedure TEngine.StopAndTerminateRunThread;
begin
  if FRunning then
    Stop;

  if FRunThread <> nil then
  begin
    CheckThreadCommand(FRunThreadCommandProxy.ExecuteCommandFuncSync(@FRunThread.cmdTerminate, nil));
    FRunThread := nil;
  end;
  if Assigned(FOnPlaybackStateChanged) then
    FOnPlaybackStateChanged(Self, 'Stopped');
end;

procedure TEngine.StopAndUnloadDLLs;
begin
  StopAndTerminateRunThread;

  if (FAudioDLL <> nil) then // and FAudioDLL.Loaded then
    FreeAndNil(FAudioDLL); // the destructor will kill the 4klang audio renderer thread

  if (FAudioBuffer <> nil) and not FKeepAudio then
    FreeAudioBuffer;

  if (FRunThreadCommandProxy <> nil) then
    FreeAndNil(FRunThreadCommandProxy);

  if Assigned(FOnPlaybackStateChanged) then
    FOnPlaybackStateChanged(Self, '');
end;

function RemoveTrailingBackslash(AString : String) : String;
begin
  if (Length(AString)>0) and (AString[Length(AString)]='\') then
    Result := Copy(AString, 1, Length(AString)-1)
  else
    Result := AString;
end;

procedure TEngine.RebuildDLLs;
var
  builder : TBuilder;
//  old_playing : Boolean;
//  old_time : Integer;
begin
{  if Self.FRunThreadCommandProxy <> nil then
  begin
    old_time := Self.FRunThreadCommandProxy.GetTime;
    old_playing := Self.FRunning;
  end
  else
  begin
    old_time := 0;
    old_playing := false;
  end;}

  StopAndUnloadDLLs;

  if Assigned(FOnBuildStart) then FOnBuildStart(Self, 'Building DLLs...');
  try

    builder := TBuilder.Create;
    try
      // We don't SetUpScriptObject() the builder here, because the reason it exists
      // is to explicate into a Makefile compatible script file all the stuff
      // that SetUpScriptObject() sets up into the script.
      builder.WorkDirectory := Self.FProjectDirectory;
      builder.OnAddProcessOutputLine := Self.FOnAddProcessOutputLine;

      // Name the temporary file ".mk", to highlight that you should be able to
      // build the stuff with e.g. GNU Make as well
      builder.SaveScriptToFileAndRun(
        '__temp_DLL_build_script.mk',
          '# Compofiller Studio temp make/build script ' + #13#10
        + '# You should be able to build this with GNU Make like this:' + #13#10
        + '# >  make -f __temp_DLL_build_script.mk debug_audio.dll' + #13#10
        + '# >  make -f __temp_DLL_build_script.mk debug_visuals.dll' + #13#10
        + Self.GetBuildVariableScriptRows + #13#10
        + 'include BuildDLLs.script' + #13#10
      );

    finally
      builder.Free;
    end;


  finally
    if Assigned(FOnBuildEnd) then FOnBuildEnd(Self, '');
  end;

//  if old_playing then
//    Self.Play(old_time);
end;


function TEngine.GetBuildVariableScriptRows : String;
begin
  Result :=
    BV_PROGRAM_DIR+'='+RemoveTrailingBackslash(FProgramPath) + #13#10 + #13#10
    + BV_PROJECT_FILE+'='+FProjectFile + #13#10 + #13#10
    + BV_PROJECT_DIR+'='+FProjectDirectory + #13#10 + #13#10
    + BV_CONFIG_FILE+'='+GetActiveConfig + #13#10 + #13#10
  ;
end;


procedure TEngine.RebuildEXE;
var
  builder : TBuilder;
begin
  StopAndUnloadDLLs;

  if Assigned(FOnBuildStart) then FOnBuildStart(Self, 'Building EXE...');
  try
    builder := TBuilder.Create;
    try
      builder.WorkDirectory := Self.FProjectDirectory;
      builder.OnAddProcessOutputLine := Self.FOnAddProcessOutputLine;

      // You should be able to also build this temp script with make like this:
      //       make -f __temp_EXE_build.script release.exe

      builder.SaveScriptToFileAndRun(
        '__temp_EXE_build.mk',
          '# Compofiller Studio temp make/build script ' + #13#10
        + '# You should be able to build this with GNU Make like this:' + #13#10
        + '# >  make -f __temp_EXE_build_script.mk release.exe' + #13#10
        + '# (or whatever is the name for your final release.exe)' + #13#10
        + Self.GetBuildVariableScriptRows + #13#10
        + 'include BuildEXE.script' + #13#10
      );
      CheckAudioReady;
    finally
      builder.Free;
    end;

  finally
    if Assigned(FOnBuildEnd) then FOnBuildEnd(Self, '');
  end;
end;


procedure TEngine.RunEXE;
var
  builder : TBuilder;
begin
  if Assigned(FOnBuildStart) then FOnBuildStart(Self, 'Running EXE...');
  try
    if not FileExists(ProjectDirectory + GetEffectiveVariableValueInActiveConfig(CV_OUTPUT_EXE_NAME)) then
    begin
      Self.FOnAddProcessOutputLine('Error: EXE not found, cannot run. Maybe you should build it first?', 0);
      Exit;
    end;

    StopAndTerminateRunThread; // we don't want the run thread to run while the exe is running too

    builder := TBuilder.Create;
    try
      Self.SetUpScriptObject(builder);
      builder.OnAddProcessOutputLine := Self.FOnAddProcessOutputLine;
      builder.IsDummyTarget := true; // avoid error message about not being able to build "run"
      builder.RunScriptFromFile('RunEXE.script');
    finally
      builder.Free;
    end;

  finally
    if Assigned(FOnBuildEnd) then FOnBuildEnd(Self, '');
  end;
end;

procedure TEngine.SetVariableValueInConfig(AConfigFile, AVariableName, AVariableValue : String);
var
  config : TConfig;
begin
  config := TConfig.Create;
  try
    Self.SetUpScriptObject(config);
    config.FileName := AConfigFile;
    config.SetVariableValue(AVariableName, AVariableValue);
  finally
    config.Free;
  end;
end;

procedure TEngine.SetUpScriptObject(AScript : TScriptRunner);
begin
  AScript.WorkDirectory := Self.ProjectDirectory;
  AScript.SetVariable(BV_PROJECT_DIR, Self.FProjectDirectory, 0);
  AScript.SetVariable(BV_PROJECT_FILE, FProjectFile, 0);
  AScript.SetVariable(BV_PROGRAM_DIR, RemoveTrailingBackslash(FProgramPath), 0);
  AScript.SetVariable(BV_CONFIG_FILE, GetActiveConfig, 0);
end;

procedure TEngine.SetVisualsWindowHandle(AValue: HWND);
begin
  if FVisualsWindowHandle=AValue then Exit;
  FVisualsWindowHandle:=AValue;
end;

function TEngine.GetEffectiveVariableValueInConfig(AConfigFile, AVariableName : String) : String;
var
  config : TConfig;
  dummy : String;
begin
  Result := '';
  dummy := '';
  config := TConfig.Create;
  try
    Self.SetUpScriptObject(config);
    config.FileName := AConfigFile;
    config.GetVariableValue(AVariableName, Result, dummy, true);
  finally
    config.Free;
  end;
end;

function TEngine.GetVariableValueInConfig_NO_INCLUDE(AConfigFile, AVariableName : String) : String;
var
  config : TConfig;
  c : String;
begin
  Result := '';
  c := '';
  config := TConfig.Create;
  try
    Self.SetUpScriptObject(config);
    config.FileName := AConfigFile;
    config.GetVariableValue(AVariableName, Result, c, false);
    if ExtractFileName(c) <> ExtractFileName(AConfigFile) then
      Result := '';
  finally
    config.Free;
  end;
end;


procedure TEngine.GetConfigFileList(AList : TStringList);
var
  info : TSearchRec;
begin
  try
    if FindFirst(FProjectDirectory + '*.config', faAnyFile, Info) = 0 then
    begin
      repeat
        AList.Add(info.Name);
      until FindNext(info) <> 0;
    end;
  finally
  end;
end;


procedure TEngine.RemapUniformsFromMinifiedShader(ASourceShaderConfig : String);
var
  new_minified_shader_h : String;
  sl, new_variable_names : TStringList;
  dummy,
  old_time_uniform_name, old_resolution_uniform_name, old_texts_uniform_name,
  new_time_uniform_name, new_resolution_uniform_name, new_texts_uniform_name
    : String;
begin
  dummy := '';
  sl := TStringList.Create;
  new_variable_names := nil;
  try
    new_variable_names := TStringList.Create;
    new_minified_shader_h := GetEffectiveVariableValueInActiveConfig(CV_SHADER_FILE);
    if not (AnsiLowerCase(ExtractFileExt(new_minified_shader_h))='.h') then
      raise Exception.Create('RemapUniformsFromMinifiedShader: not a .h file!?');
    sl.LoadFromFile(FProjectDirectory + new_minified_shader_h);
    UPreprocessShader.ShaderMinifierHToPlainString(sl, dummy, new_variable_names);
    old_time_uniform_name :=
      AnsiReplaceStr(
        GetEffectiveVariableValueInConfig(ASourceShaderConfig, CV_TIME_UNIFORM_NAME),
        '''', '' // remove hyphens
      );
    old_resolution_uniform_name :=
      AnsiReplaceStr(
        GetEffectiveVariableValueInConfig(ASourceShaderConfig, CV_RESOLUTION_UNIFORM_NAME),
        '''', '' // remove hyphens
      );
    old_texts_uniform_name :=
      AnsiReplaceStr(
        GetEffectiveVariableValueInConfig(ASourceShaderConfig, CV_TEXTS_UNIFORM_NAME),
        '''', '' // remove hyphens
      );

    // map the names
    new_time_uniform_name := new_variable_names.Values[AnsiUpperCase(old_time_uniform_name)];
    new_resolution_uniform_name := new_variable_names.Values[AnsiUpperCase(old_resolution_uniform_name)];
    new_texts_uniform_name := new_variable_names.Values[AnsiUpperCase(old_texts_uniform_name)];

    if new_time_uniform_name <> '' then
      SetVariableValueInActiveConfig(CV_TIME_UNIFORM_NAME, new_time_uniform_name);

    if new_resolution_uniform_name <> '' then
      SetVariableValueInActiveConfig(CV_RESOLUTION_UNIFORM_NAME, new_resolution_uniform_name);

    if new_texts_uniform_name <> '' then
      SetVariableValueInActiveConfig(CV_TEXTS_UNIFORM_NAME, new_texts_uniform_name);

  finally
    new_variable_names.Free;
    sl.Free;
  end;
end;

procedure GetNewTempProjNameAndDir(APrefix : String; APostFix : String; var ADir, AProjName : String);
var
  tempdir : String;
  i : Integer;
begin
  tempdir := GetTempDir(false); // false : user-local temp dir
  if not DirectoryIsWritable(tempdir) then
    raise Exception.Create('Temp directory is not writable?!');

  i := 1;
  repeat
    if i = 1000 then raise Exception.Create('Haloo ny');
    AProjName := APrefix + '-' + IntToStr(i) + APostFix;
    ADir := tempdir + AProjName + '\';
    Inc(i);
  until not DirectoryExists(ADir);
end;


function TEngine.NewProject(ATemplate: String): Boolean;
var
  dstdir, srcdir, projname : String;
begin
  Result := false;
  dstdir := '';
  projname := '';

  AddLogMessage('New project');

  GetNewTempProjNameAndDir('MyProject', '.compofiller', dstdir, projname);
  srcdir := Self.ProgramPath + 'Templates\' + ATemplate + '\';

  if not DirectoryExists(srcdir) then
    raise Exception.CreateFmt('Template directory %s not found. Application installation broken?', [srcdir]);

  AddLogMessage(Format('Copying files from %s to %s', [srcdir, dstdir]));

  // Copy stuff from template to new project directory
  if not CopyDirTree(srcdir, dstdir, [cffCreateDestDirectory, cffPreserveTime]) then
    raise Exception.CreateFmt('Failed to copy files from template directory %s to new project %s', [srcdir, dstdir]);


  // Rename the project file to the same name as the project directory.
  if not RenameFile(dstdir + 'MyProject.compofiller', dstdir + projname) then
    raise Exception.CreateFmt('Failed to rename project file to %s', [projname]);

  // Loading the project sets up everything
  Self.LoadProject(dstdir + projname);

  Result := true;
end;

function SanitizeFileName(AName : String) : String;
var
  i : Integer;
  c : Char;
begin
  Result := '';
  for i := 1 to Length(AName) do
  begin
    c := AName[i];
    if c in [Chr(0)..Chr(32),
             '\','/','(',')','#','!','=','+','?','*','''','"','&','%','{','[',']','}',',',';',':']
    then
      Result := Result + '_'
    else
      Result := Result + c;
  end;
end;

function TEngine.SaveProjectAs(ANewParentDir, ANewName : String): Boolean;
var
  dstdir, srcdir, projname : String;
begin
  ANewName := SanitizeFileName(ANewName);

  if (ANewName = '') then
    raise Exception.Create('Cannot move project to an empty name!');

  if (ExtractFileNameWithoutExt(ANewName) = '') then
    raise Exception.CreateFmt('Bad name for a project: %s.', [ANewName]);

  projname := ChangeFileExt(ANewName, '.compofiller');

  if not DirectoryExists(ANewParentDir) then
    raise Exception.CreateFmt('Cannot move project to %s, directory does not exist.', [ANewParentDir]);

  if not DirectoryIsWritable(ANewParentDir) then
    raise Exception.CreateFmt('Cannot move project to %s%s%s, directory is not writable.', [ANewParentDir, DirectorySeparator, ANewName]);

  dstdir :=
    ForceProjectDirectoryFormat(AppendPathDelim(ANewParentDir) + AppendPathDelim(projname));

  if FileExists(dstdir) then
    raise Exception.CreateFmt('Cannot move project to %s, already exists.', [dstdir]);

  srcdir := ForceProjectDirectoryFormat(Self.ProjectDirectory);


  // Copy stuff from template to new project directory
  CopyDirTree(srcdir, dstdir, [cffCreateDestDirectory, cffPreserveTime]);

  // Rename the project file to the same name as the project directory.
  RenameFile(dstdir + Self.ProjectFile, dstdir + projname);

  // Loading the project sets up everything
  Self.LoadProject(dstdir + projname);

  Result := true;
end;

//Save a string as a file
procedure SaveString(AString, AFileName : String);
var
  f : TextFile;
begin
  AssignFile(f, AFileName);
  try
    ReWrite(f);
    Write(f, AString);
  finally
    CloseFile(f);
  end;
end;

function TEngine.MinifyShader(ASourceShader, ADestinationShader, ASourceShaderConfig : String): Boolean;
var
  builder : TBuilder;
  sl : TStringList;
  plain_glsl_shader : String;
begin
  Result := false;
  plain_glsl_shader := '';
  builder := TBuilder.Create;
  try
    if AnsiLowerCase(ExtractFileExt(ASourceShader)) = '.h' then
    begin // Shader is already minified !? ok, to each her own, maybe they've
          // messed with it so much that they want to try a new round.
          // Or maybe it's not minified, just in .h format.
          // So let's convert it to plain GLSL first.
      sl := TStringList.Create;
      sl.LoadFromFile(FProjectDirectory + ASourceShader);
      UPreprocessShader.ShaderMinifierHToPlainString(sl, plain_glsl_shader, nil);
      sl.Free;
      ASourceShader := '__temp_shader_for_minifying.glsl';
      SaveString(plain_glsl_shader, FProjectDirectory + ASourceShader);
    end;
    Self.SetUpScriptObject(builder);
    builder.SetVariable(BV_SOURCE_FILE, ASourceShader, 0);
    builder.SetVariable(BV_DESTINATION_FILE, ADestinationShader, 0);
    builder.OnAddProcessOutputLine := Self.FOnAddProcessOutputLine;
    Result := builder.RunScriptFromFile('MinifyShader.script');
  finally
    builder.Free;
  end;
end;

function TEngine.GetProjectVariableValue(AVariableName : String): String;
var
  project_file : TConfig;
  s, f : String;
begin
  Result := '';
  s := '';
  f := '';
  project_file := TConfig.Create;
  try
    project_file.WorkDirectory := Self.FProjectDirectory;
    project_file.FileName := FProjectFile;
    project_file.GetVariableValue(AVariableName, s, f, true);
    Result := s;
  finally
    project_file.Free;
  end;
end;

procedure TEngine.SetProjectVariableValue(AVariableName, AVariableValue : String);
var
  project_file : TConfig;
begin
  project_file := TConfig.Create;
  try
    project_file.WorkDirectory := Self.FProjectDirectory;
    project_file.FileName := FProjectFile;
    project_file.SetVariableValue(AVariableName, AVariableValue);
  finally
    project_file.Free;
  end;
end;

procedure TEngine.GetEffectiveVariableValueInActiveConfigEx(const AVariableName : String; var AFoundValue, AFoundInScript : String);
var
  config : TConfig;
  s, f : String;
begin
  config := TConfig.Create;
  try
    Self.SetUpScriptObject(config);
    config.FileName := GetProjectVariableValue(PV_ACTIVE_CONFIG);
    s := '';
    f := '';
    config.GetVariableValue(AVariableName, s, f, true);
    AFoundValue := s;
    AFoundInScript := ExtractFileName(f);
  finally
    config.Free;
  end;
end;

function TEngine.GetEffectiveVariableValueInActiveConfig(const AVariableName : String) : String;
var
  config : TConfig;
  dummy : String;
begin
  Result := '';
  dummy := '';
  config := TConfig.Create;
  try
    Self.SetUpScriptObject(config);
    config.FileName := GetActiveConfig;
    config.GetVariableValue(AVariableName, Result, dummy, true);
  finally
    config.Free;
  end;
end;

function TEngine.GetConfigNameOfEffectiveValueForVariable(const AVariableName: String): String;
var
  dummy_effective_value : String;
begin
  Result := '';
  dummy_effective_value := '';
  GetEffectiveVariableValueInActiveConfigEx(AVariableName, dummy_effective_value, Result);
end;

function TEngine.ConfigVariableHasInheritedValue(AVariableName: String): Boolean;
begin
  Result := (ConfigVariableInheritedValue(AVariableName) <> '');
end;

function TEngine.ConfigVariableInheritedValue(AVariableName: String): String;
var
  dummy : String;
begin
  Result := '';
  dummy := '';
  // BUGI! Tämä ei itse asiassa palauta parent-arvoa vaan "kantaisän" eli
  // IHAN ENSIMMÄISEN mitä vastaan tulee. :/
  GetConfigVariableInheritedValueAndConfig(AVariableName, Result, dummy);
end;

procedure TEngine.GetConfigVariableInheritedValueAndConfig(AVariableName: String; var AInheritedValue, AInheritedValueConfig : String);
var
  config : TConfig;
  dummy, dummy2 : String;
begin
  dummy := '';
  dummy2 := '';
  config := TConfig.Create;
  try
    Self.SetUpScriptObject(config);
    config.FileName := GetActiveConfig;
    config.GetVariableValueAndItsInheritedValue(AVariableName, dummy, dummy2, AInheritedValue, AInheritedValueConfig, true);
  finally
    config.Free;
  end;
end;

procedure TEngine.DeleteConfigVariable(AVariableName: String);
begin
  raise Exception.Create('DeleteConfigVariable() not implemented');
end;


function TEngine.GetActiveConfig : String;
begin
  if FActiveConfig = '' then
    FActiveConfig := GetProjectVariableValue(PV_ACTIVE_CONFIG);
  Result := FActiveConfig;
end;

procedure TEngine.RefreshAudioThings;
begin
  try
    FAudioDelayLength := StrToInt(GetEffectiveVariableValueInActiveConfig(CV_AUDIO_DELAY));

  except
    on EConvertError do FAudioDelayLength := 0;
  end;
end;

procedure TEngine.SetActiveConfig(AValue: String);
begin
  if FActiveConfig <> AValue then
  begin
    FActiveConfig := AValue;
    SetProjectVariableValue(PV_ACTIVE_CONFIG, FActiveConfig);

    // PARENT_CONFIG cannot be read by including anything, because it is
    // set BEFORE the include lines, so its value gets overridden.
    FParentConfig := GetVariableValueInConfig_NO_INCLUDE(FActiveConfig, CV_PARENT_CONFIG);
    RefreshShaderFileName;
    RefreshAudioThings;
  end;
end;

function TEngine.GetParentConfig: String;
begin
  Result := FParentConfig;
end;

procedure TEngine.SetVariableValueInActiveConfig(AVariableName, AVariableValue : String);
var
  config : TConfig;
begin
  config := TConfig.Create;
  try
    Self.SetUpScriptObject(config);
    config.FileName := Self.GetActiveConfig;
    config.SetVariableValue(AVariableName, AVariableValue);
  finally
    config.Free;
  end;
end;

function TEngine.LoadProject(AProjectFile : String) : Boolean;
begin
  SetProjectFile(ExtractFileName(AProjectFile));
  FProjectDirectory := ExtractFilePath(AProjectFile);
  Result := FileExists(AProjectFile);
  if Result then
    SetActiveConfig(GetProjectVariableValue(PV_ACTIVE_CONFIG));
end;

function TEngine.GetAudioPlaybackBufferPtr: Pointer;
begin
  CheckAudioReady;

  Result := FAudioDLL.GetAudioPlaybackBufferPtr();
end;

procedure TEngine.SetAudioPlaybackBufferPtr(AValue: Pointer);
begin
  CheckAudioReady;

  FAudioDLL.SetAudioPlaybackBufferPtr(AValue);
end;

function TEngine.CheckThreadCommand(AThreadCommandQueueResult : TThreadCommadQueueResult) : Boolean;
var
  error_info : String;
begin
  Result := false;
  error_info := '';
  case AThreadCommandQueueResult of
    tcqOk : Result := true;
    tcqThreadCrashed : begin
      error_info := FRunThreadCommandProxy.ThreadCrashInfo;
      // AARGH! the run thread is crashed ... so next time we'll have to create a new one.
      // Let's just hope that it managed to at least unload the DLLs it had loaded.
      FRunThread := nil;
      // Let's just create a new command proxy as well.
      FreeAndNil(FRunThreadCommandProxy);
      FRunThreadCommandProxy := TRunThreadCommandProxy.Create;
    end;
    tcqTimeout : error_info := 'Command timeout! Thread is jammed?';
    tcqQueueEmpty : error_info := 'Queue empty?!?! What';
  else
    error_info := 'Some unknown situation.';
  end;
  if (not Result) and (error_info <> '') and Assigned(FOnAddProcessOutputLine) then
    FOnAddProcessOutputLine('ERROR! Thread command failed. ' + error_info, 0);
end;

procedure TEngine.RestartAudioFromPosition(APosition : Integer);
begin
  if not CheckAudioReady then
    Exit;

  if not CheckThreadCommand(FRunThreadCommandProxy.ExecuteCommandFuncSync(@FRunThread.cmdStopPlaying, nil)) then Exit;
  if not CheckThreadCommand(FRunThreadCommandProxy.ExecuteCommandFuncSync(@FRunThread.cmdSetTime, Pointer(PtrInt(APosition)))) then Exit;
  if not CheckThreadCommand(FRunThreadCommandProxy.ExecuteCommandFuncSync(@FRunThread.cmdStartPlaying, nil)) then Exit;
end;

procedure TEngine.SetAudioPosition(APosition : Integer);
begin
  if not CheckAudioReady then
    Exit;

  if FRunThread <> nil then
    if not CheckThreadCommand(FRunThreadCommandProxy.ExecuteCommandFuncSync(@FRunThread.cmdSetTime, Pointer(PtrInt(APosition)))) then Exit;
end;

function TEngine.ConvertMusicalTimeToAudioPosition(AMusicalTime: Single): Integer;
begin
  Result := Trunc(AMusicalTime * TimeDivider);
end;

function TEngine.ConvertAudioPositionToMusicalTime(AAudioPosition: Integer): Single;
begin
  Result := Single(AAudioPosition) / TimeDivider;
end;

function TEngine.GetLoopStartAudioPosition: Integer;
begin
  Result := FLoopStartAudioPosition;
end;

function TEngine.GetLoopStartMusicalTime: Single;
begin
  Result := FLoopStartMusicalTime;
end;

procedure TEngine.SetLoopStartMusicalTime(AValue: Single);
begin
  if FLoopStartMusicalTime=AValue then Exit;
  if AValue < 0.0 then AValue := 0.0;
  FLoopStartMusicalTime:=AValue;
  FLoopStartAudioPosition := ConvertMusicalTimeToAudioPosition(FLoopStartMusicalTime);
  if FRunThread <> nil then
    CheckThreadCommand(FRunThreadCommandProxy.ExecuteCommandFuncSync(@FRunThread.cmdSetLoopStartAudioPosition, Pointer(PtrInt(FLoopStartAudioPosition))));
end;

function TEngine.GetLoopEndAudioPosition: Integer;
begin
  //RefreshLoopValuesFromAudioDLL;
  Result := FLoopEndAudioPosition;
end;

function TEngine.GetLoopEndMusicalTime: Single;
begin
  Result := FLoopEndMusicalTime;
end;

procedure TEngine.SetLoopEndMusicalTime(AValue: Single);
begin
  if FLoopEndMusicalTime=AValue then Exit;
  FLoopEndMusicalTime:=AValue;
  FLoopEndAudioPosition := ConvertMusicalTimeToAudioPosition(FLoopEndMusicalTime);
  if FRunThread <> nil then
    CheckThreadCommand(FRunThreadCommandProxy.ExecuteCommandFuncSync(@FRunThread.cmdSetLoopEndAudioPosition, Pointer(PtrInt(FLoopEndAudioPosition))));
end;


function TEngine.GetLoopEnabled: Boolean;
begin
  Result := FLoopEnabled;
end;

function TEngine.GetAudioRenderingIsFinished: Boolean;
var
  thread_handle : THandle;
begin
  Result := (FRunThread <> nil) and (FAudioDLL <> nil) and (FAudioDLL.Loaded);
  if Result then
  begin
    thread_handle := FAudioDLL.GetAudioRendererThreadHandle();
    if WaitForSingleObject(thread_handle, 0) <> WAIT_OBJECT_0 then
      Result := false; // this doesn't mean it is necessarily running, but at least it isn't finished
  end;
end;

function TEngine.GetRunThreadIsRunning: Boolean;
begin
  Result := (FRunThread <> nil);
end;

procedure TEngine.SetLoopEnabled(AValue: Boolean);
begin
  FLoopEnabled := AValue;

  if FRunThread <> nil then
    CheckThreadCommand(FRunThreadCommandProxy.ExecuteCommandFuncSync(@FRunThread.cmdSetLoopEnabled, Pointer(PtrInt(Ord(FLoopEnabled)))));
  // If we're not running, there's no run thread to notify.
end;


function TEngine.GetAllocatedAudioLengthInMonoSamples: Cardinal;
var
  AudioLength: QWord;
begin
  if (FAudioDLL = nil) or not (FAudioDLL.Loaded) then
    Result := 0
  else
  begin
    AudioLength := QWord(FAudioDLL.GetMusicLengthSamples()) * 2 +
      QWord(FAudioDelayLength) * 2;
    if AudioLength > High(Cardinal) then
      raise ERangeError.Create('Audio length exceeds the supported range.');
    Result := Cardinal(AudioLength);
  end;
end;

function TEngine.GetCurrentAudioPosition: Integer;
begin
  if FRunThreadCommandProxy <> nil then
    Result := FRunThreadCommandProxy.GetTime()
  else
    Result := -1;
end;

function TEngine.GetMusicSampleRate : Cardinal;
begin
  if CheckAudioDLLLoaded then
    Result := FAudioDLL.GetMusicSampleRate()
  else
    Result := 0;
end;

function TEngine.GetMusicLengthSamples : Cardinal;
begin
  if CheckAudioDLLLoaded then
    Result := FAudioDLL.GetMusicLengthSamples()
  else
    Result := 0;
end;

function TEngine.GetMusicBPM : Single;
begin
  if CheckAudioDLLLoaded then
    Result := FAudioDLL.GetMusicBPM()
  else
  begin
    AddLogMessage('Cannot get 4klang music attributes.');
    Result := 0.0;
  end;
end;

procedure TEngine.AddLogMessage(AMessage : String);
begin
  if Assigned(FOnAddProcessOutputLine) then
    FOnAddProcessOutputLine(AMessage, 0);
end;


procedure TEngine.Play(AStartTime : Integer);
var
  command_result : TCommandResultRec;
  audio_buffer_samples : QWord;
begin
  try
    RefreshShaderFileName;
    RefreshAudioThings;

    if not CheckAudioReady then
    begin
      AddLogMessage('Error: Cannot play, cannot get audio ready?');
      Exit;
    end;

    audio_buffer_samples := (QWord(Self.GetAllocatedAudioLengthInMonoSamples()) + 1) div 2;
    if (FAudioBuffer <> nil)
    and (audio_buffer_samples * 4 > QWord(FAudioBufferAllocatedLengthBytes))
    then // if the audio compiled in the DLL is too long to fit the currently allocated buffer, free the old buffer
      FreeAudioBuffer;

    if FAudioBuffer = nil then
    begin
      if audio_buffer_samples > QWord(High(Integer) div 4) then
        raise ERangeError.Create('Audio buffer exceeds the supported size.');
      FAudioBufferLengthSamples := Integer(audio_buffer_samples);
      FAudioBufferAllocatedLengthBytes := FAudioBufferLengthSamples * 4;
      GetMem(FAudioBuffer, FAudioBufferAllocatedLengthBytes);
      FillChar(FAudioBuffer^, FAudioBufferAllocatedLengthBytes, 0);
    end;

    FAudioDLL.SetRenderedAudioBufferPtr(FAudioBuffer + FAudioDelayLength * 4);

    // It might make sense to place audio rendering and audio playback in
    // separate DLLs, because they're really separate and run in separate threads.

    if FAudioDLL.GetAudioRendererThreadHandle() = 0 then
      FAudioDLL.StartAudioRendererThread;

    FRunning := true;

    if FRunThreadCommandProxy = nil then
      FRunThreadCommandProxy := TRunThreadCommandProxy.Create;

    if FRunThread = nil then
    begin
      FRunThread :=
        TRunThread.Create(
          FRunThreadCommandProxy, FProjectDirectory, FShaderSourceFileName,
          Self.VisualsWindowHandle, FAudioDLL, Self.FAudioBuffer, FAudioBufferLengthSamples,
          FLoopEnabled, FLoopStartAudioPosition, FLoopEndAudioPosition
          );
      // The RunThread is created in "suspended" state.
      FRunThread.Start; // <-- this STARTS the thread. After this is not suspended anymore!!
      // *** THE RUN THREAD MUST NOT BE TALKED TO DIRECTLY !!!!!! ONLY VIA THE COMMAND PROXY ***
    end;

    // This will get executed as soon as the visuals thread is running:
    if not CheckThreadCommand(FRunThreadCommandProxy.ExecuteCommandFuncSync(@FRunThread.cmdStartPlaying, @command_result)) then
    begin
      AddLogMessage('Playing failed badly.');
      Exit;
    end;

    if not command_result.Result then
    begin
      AddLogMessage('Playing failed! Error: ' + command_result.Info);
      HighlightShaderErrors(FShaderSourceFileName, command_result.Info);
      Exit;
    end
    else
      HighlightShaderErrors(FShaderSourceFileName, ''); // remove error highlights

    if not CheckThreadCommand(FRunThreadCommandProxy.ExecuteCommandFuncSync(@FRunThread.cmdSetTime, Pointer(PtrInt(AStartTime)))) then
    begin
      AddLogMessage('SetTime failed badly.');
      Exit;
    end;

    command_result.Result := false;
    // Since we are starting to play, let's "manually" draw one complete frame,
    // and see if it worked without errors.
    if not CheckThreadCommand(FRunThreadCommandProxy.ExecuteCommandFuncSync(@FRunThread.cmdDrawFrame, @command_result)) then
    begin
      AddLogMessage('DrawFrame failed badly.');
      Exit;
    end;

    if not command_result.Result then
    begin
      AddLogMessage('DrawFrame failed! Error: ' + command_result.Info);
      HighlightShaderErrors(FShaderSourceFileName, command_result.Info);
    end
    else if command_result.Info <> '' then
    begin
      AddLogMessage(command_result.Info);
      HighlightShaderErrors(FShaderSourceFileName, command_result.Info);
    end
    else
    begin
      AddLogMessage('Success! Playback started without any warnings.');
      HighlightShaderErrors(FShaderSourceFileName, ''); // remove error highlights
    end;

  finally
    if Assigned(FOnPlaybackStateChanged) then
      FOnPlaybackStateChanged(Self, 'Playing');
  end;
end; // TEngine.Play

function TEngine.DrawOneFrameToBitmap(ABitmap : Graphics.TBitmap) : Boolean;
begin
  Result := false;
  if RunThreadIsRunning then
    Result := CheckThreadCommand(FRunThreadCommandProxy.ExecuteCommandFuncSync(@FRunThread.cmdCopyFrameToBitmap, ABitmap));
end;

function TEngine.DrawTextsBitmapToPaintBox(ATarget: TPaintBox): Boolean;
begin
  Result := false;
  if RunThreadIsRunning then
    Result := CheckThreadCommand(FRunThreadCommandProxy.ExecuteCommandFuncSync(@FRunThread.cmdCopyTextsBitmapToPaintBox, ATarget));
end;


function TEngine.GetGLInfo: String;
begin
  Result := '';
  if RunThreadIsRunning then
    CheckThreadCommand(FRunThreadCommandProxy.ExecuteCommandFuncSync(@FRunThread.cmdGetGLInfo, @Result));
end;

function TEngine.GetAverageFrameTimeMS: Single;
begin
  if RunThreadIsRunning then
    Result := FRunThreadCommandProxy.AverageFrameTimeMS
  else
    Result := -1.0;
end;

function TEngine.GetTextPtr: Pointer;
begin
  if FRunThread <> nil then
  begin
    FRunThreadCommandProxy.ExecuteCommandFuncSync(@FRunThread.cmdGetLastTextPtr, @Result);
  end
  else
    Result := nil;
end;

function TEngine.GetTextsBitmapInfo: PBITMAPINFO;
begin
  if FRunThread <> nil then
  begin
    FRunThreadCommandProxy.ExecuteCommandFuncSync(@FRunThread.cmdGetTextsBitmapInfo, @Result);
  end
  else
    Result := nil;
end;

procedure TEngine.Stop;
begin
  if FRunning then
    CheckThreadCommand(FRunThreadCommandProxy.ExecuteCommandFuncSync(@FRunThread.cmdStopPlaying, nil));
  FRunning := false;

  if Assigned(FOnPlaybackStateChanged) then
    FOnPlaybackStateChanged(Self, 'Paused');
end;

procedure TEngine.RefreshShaderFileName;
begin
  FShaderSourceFileName := GetEffectiveVariableValueInActiveConfig(CV_SHADER_FILE);
end;

procedure TEngine.HighlightShaderErrors(AFileName : String; AErrors : String);
var
  i : Integer;
  sl, errors : TStringList;
  s, linenumstr, errorstr : String;
  l, r, linenum : Integer;
begin
  sl := TStringList.Create;
  errors := TStringList.Create;
  try
    sl.Text := AErrors;
    for i := 0 to sl.Count - 1 do
    begin
      s := sl[i];
      l := Pos('(', s);
      r := Pos(')', s);
      if (l > 1) and (l < r) and (r < l + 6) then
      begin
        linenumstr := Copy(s, l+1, r-l-1);
        linenum := StrToIntDef(linenumstr, -1);
        if (r < (Length(s) - 1)) then
          errorstr := s
        else
          errorstr := '?';
        if linenum > 0 then
          errors.Values[IntToStr(linenum)] := errorstr;
      end;
    end;

    errors.Sorted := true;
    if Assigned(FOnShaderErrors) then
      FOnShaderErrors(Self, AFileName, errors);
  finally
    errors.Free;
    sl.Free;
  end;
end;

function TEngine.CheckShaderChanged : Boolean;
var
  fage : LongInt;
  fname : String;
  reload_result : TCommandResultRec;
  runparams : TRunParamsRec;
  draw_result : TCommandResultRec;

begin
  Result := false;
  fname := FProjectDirectory + FShaderSourceFileName;
  fage := FileAge(fname);
  if (fage <> FShaderSourceFileAge) or (FShaderSourceFileName <> FLastLoadedShaderSourceFileName) then
  begin
    Result := true;
    FShaderSourceFileAge := fage;
    if (FRunThread <> nil) and (FRunThreadCommandProxy <> nil) then
    begin
      reload_result := Default(TCommandResultRec);
      runparams.ShaderFileName := Self.FShaderSourceFileName;
      CheckThreadCommand(FRunThreadCommandProxy.ExecuteCommandFuncSync(@FRunThread.cmdSetRunParams, @runparams));
      CheckThreadCommand(FRunThreadCommandProxy.ExecuteCommandFuncSync(@FRunThread.cmdReloadShader, @reload_result));
      FLastLoadedShaderSourceFileName := FShaderSourceFileName;
      if not reload_result.Result or (reload_result.Info <> '') then
      begin
        AddLogMessage('Error. Something happened when reloading shader: ' + reload_result.Info);
        HighlightShaderErrors(FShaderSourceFileName, reload_result.Info);
      end
      else if (reload_result.Info = '') then
      begin
        AddLogMessage('Success! Shader reloaded without any warnings.');
        HighlightShaderErrors(FShaderSourceFileName, ''); // remove error highlights
      end;

      // If we're playing, then the next frame will be done with the new shader.
      // But if we're not playing, we redraw the current frame.
      if not FRunning then
      begin
        CheckThreadCommand(FRunThreadCommandProxy.ExecuteCommandFuncSync(@FRunThread.cmdDrawFrame, @draw_result));
        if not draw_result.Result then
        begin
          AddLogMessage('DrawFrame failed! Error: ' + draw_result.Info);
          HighlightShaderErrors(FShaderSourceFileName, draw_result.Info);
        end;
      end;
    end;
  end;
end; // TEngine.CheckShaderChanged

end.

