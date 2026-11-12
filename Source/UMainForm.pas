unit UMainForm;
// Compofiller Studio
// by Yzi 2018

{$mode objfpc}{$H+}

interface

uses
{$ifdef WINDOWS}
  Windows,
{$endif}

  Classes, SysUtils, FileUtil, SynEdit, SynHighlighterAny, RichMemo,
  Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, ComCtrls, ActnList,
  EditBtn, Buttons,
  UEngine,

  UWaveformZoomDisplay, Types,
  UConfigUIMappingHelpers
  ;

const
  MAIN_WINDOW_CAPTION = 'Compofiller Studio v1.0 Beta 8 by Yzi/Fit';

type

  { TMainForm }
  TMainForm = class(TFormWithControlsRepresentingVariables)
    ErrorsOnlyCheckBox: TCheckBox;
    ClearProcessOutputMemoAction: TAction;
    Bevel2: TBevel;
    Bevel3: TBevel;
    ClearProcessOutputMemoButton: TButton;
    FrameTextureUnitComboBox: TComboBox;
    MusicHelpLabel: TLabel;
    TextsTextureUnitComboBoxLabel: TLabel;
    TextsTextureUnitComboBox: TComboBox;
    TextsSamplerUniformNameEdit: TEdit;
    EditTimingsAndTextsButton: TButton;
    EditTextsAction: TAction;
    Button1: TButton;
    Button2: TButton;
    CustomUniformNameEdit: TEdit;
    FrameTextureUnitComboBoxLabel: TLabel;
    UseCustomUniformCheckBox: TCheckBox;
    UseTextsUniformCheckBox: TCheckBox;
    UseTextsCheckBox: TCheckBox;
    NegateTimeOnSecondPassCheckBox: TCheckBox;
    MipMapCheckBox: TCheckBox;
    LinkerComboBox: TComboBox;
    EditNFOButton: TButton;
    PackageReleaseGroupBox: TGroupBox;
    MusicWaveDisplayPanel: TPanel;
    ScreenshotButton: TButton;
    TopRulerPaintBox: TPaintBox;
    BottomRulerPaintBox: TPaintBox;
    SeekBiggerJumpForwardAction: TAction;
    SeekBiggerJumpBackwardAction: TAction;
    ZipAction: TAction;
    EditNFOAction: TAction;
    TwoPassRenderCheckBox: TCheckBox;
    FrameToTextureCheckBox: TCheckBox;
    SaveScreenshotDialog: TSaveDialog;
    ScreenshotAction: TAction;
    MusicValuesLabel1: TLabel;
    TimeDisplayLabel: TLabel;
    LoopCheckBox: TCheckBox;
    LoopStartEdit: TEdit;
    LoopEndEdit: TEdit;
    SaveAudioToFileAction: TAction;
    ForwardBitBtn4: TBitBtn;
    GoToEndBitBtn: TBitBtn;
    GoToLoopEndAction: TAction;
    GoToLoopEndBitBtn: TBitBtn;
    GoToLoopStartAction: TAction;
    GoToLoopStartBitBtn: TBitBtn;
    GoToStartBitBtn: TBitBtn;
    SaveAudioToFileButton: TButton;
    SaveAudioDialog: TSaveDialog;
    TimeDisplayPanel: TPanel;
    PlayPauseBitBtn: TBitBtn;
    RewindBitBtn: TBitBtn;
    SeekForwardAction: TAction;
    SeekBackwardAction: TAction;
    PauseAction: TAction;
    GoToEndAction: TAction;
    GoToStartAction: TAction;
    StopAction: TAction;
    PlayAction: TAction;
    ProjectFileNameEdit: TEdit;
    OpenDialog1: TOpenDialog;
    OpenProjectAction: TAction;
    AudioOffsetEdit: TLabeledEdit;
    OpenProjectButton: TButton;
    KeepAudioCheckBox: TCheckBox;
    ParentConfigLabel: TLabel;
    MinifyShaderFromParentButton: TButton;
    MinifyShaderFromParentAction: TAction;
    EditShaderAction: TAction;
    EditMusicSourceAction: TAction;
    AutoRebuildDLLCheckBox: TCheckBox;
    Bevel1: TBevel;
    EditShaderButton: TButton;
    EditMusicSourceButton: TButton;
    LinkerLabel: TLabel;
    SaveDialog1: TSaveDialog;
    StopBitBtn: TBitBtn;
    TimeBaseComboboxLabel: TLabel;
    TimeBaseComboBox: TComboBox;
    AutoRebuildTimer: TTimer;
    UseTimeDividerInX86CodeCheckBox: TCheckBox;
    MusicBeatsPerBarEdit: TLabeledEdit;
    ResolutionLabel: TLabel;
    ProjectFolderEdit: TEdit;
    MusicLengthMinutesSecndsEdit: TEdit;
    EXENameEdit: TLabeledEdit;
    MusicValuesLabel: TLabel;
    ResolutionYEdit: TEdit;
    ResolutionXEdit: TEdit;
    RunEXEAction: TAction;
    RebuildTestingDLLsAction: TAction;
    BuildEXEAction: TAction;
    CrinklerOrderTriesEdit: TLabeledEdit;
    ResLabel: TLabel;
    OptionsAction: TAction;
    OptionsButton: TButton;
    SaveProjectAsAction: TAction;
    NewProjectAction: TAction;
    NewProjectButton: TButton;
    SaveProjectAsButton: TButton;
    OpenMusicSourceAction: TAction;
    OpenMusicSourceButton: TButton;
    MusicSampleRateEdit: TLabeledEdit;
    MusicBPMEdit: TLabeledEdit;
    MusicLengthSamplesEdit: TLabeledEdit;
    TimeDividerEdit: TLabeledEdit;
    OpenShaderAction: TAction;
    CopyToNewConfigAction: TAction;
    OpenProjectFolderInExplorerAction: TAction;
    OpenProjectFolderInExplorerButton: TButton;
    OpenShaderButton: TButton;
    CreateNewConfigButton: TButton;
    ConfigComboBox: TComboBox;
    ConfigComboBoxLabel: TLabel;
    ProjectFileLabel: TLabel;
    ResolutionUniformNameEdit: TEdit;
    RunEXEButton: TButton;
    DummyAction1: TAction;
    ActionList1: TActionList;
    BuildExeButton: TButton;
    CheckShaderChangedTimer: TTimer;
    TimeUniformNameEdit: TEdit;
    RebuildTestingDLLsButton: TButton;
    UseResolutionUniformCheckBox: TCheckBox;
    UseTimeUniformCheckBox: TCheckBox;
    ProcessOutputMemo: TRichMemo;
    ShaderFileNameEdit: TFileNameEdit;
    MusicSourceFileNameEdit: TFileNameEdit;
    MusicSourceFileNameLabel: TLabel;
    ProjectFolderLabel: TLabel;
    MusicWaveDisplayPaintBox: TPaintBox;
    ShaderGroupBox: TGroupBox;
    MusicGroupBox: TGroupBox;
    ProjectGroupBox: TGroupBox;
    TestingGroupBox: TGroupBox;
    FinalProductGroupBox: TGroupBox;
    WaveformUpdateTimer: TTimer;
    procedure ActionList1Update(AAction: TBasicAction; var Handled: Boolean);
    procedure AudioOffsetEditChange(Sender: TObject);
    procedure AutoRebuildDLLCheckBoxChange(Sender: TObject);
    procedure AutoRebuildTimerTimer(Sender: TObject);
    procedure BottomRulerPaintBoxPaint(Sender: TObject);
    procedure BuildEXEActionExecute(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure CheckShaderChangedTimerTimer(Sender: TObject);
    procedure ClearProcessOutputMemoActionExecute(Sender: TObject);
    procedure ConfigComboBoxChange(Sender: TObject);
    procedure ConfigComboBoxDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure ConfigComboBoxDropDown(Sender: TObject);
    procedure CrinklerOrderTriesEditChange(Sender: TObject);
    procedure EditNFOActionExecute(Sender: TObject);
    procedure EditShaderActionExecute(Sender: TObject);
    procedure EditTextsActionExecute(Sender: TObject);
    procedure EXENameEditChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FrameToTextureCheckBoxChange(Sender: TObject);
    procedure GoToEndActionExecute(Sender: TObject);
    procedure GoToLoopEndActionExecute(Sender: TObject);
    procedure GoToLoopStartActionExecute(Sender: TObject);
    procedure GoToStartActionExecute(Sender: TObject);
    procedure KeepAudioCheckBoxChange(Sender: TObject);
    procedure LinkerComboBoxChange(Sender: TObject);
    procedure LinkerComboBoxDropDown(Sender: TObject);
    procedure LoopCheckBoxChange(Sender: TObject);
    procedure LoopEndEditChange(Sender: TObject);
    procedure LoopStartEditChange(Sender: TObject);
    procedure MinifyShaderFromParentActionExecute(Sender: TObject);
    procedure MinifyShaderFromParentActionUpdate(Sender: TObject);
    procedure MipMapCheckBoxChange(Sender: TObject);
    procedure MusicBeatsPerBarEditChange(Sender: TObject);
    procedure MusicSourceFileNameEditChange(Sender: TObject);
    procedure MusicWaveDisplayPaintBoxMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MusicWaveDisplayPaintBoxMouseMove(Sender: TObject;
      Shift: TShiftState; X, Y: Integer);
    procedure MusicWaveDisplayPaintBoxMouseUp(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MusicWaveDisplayPaintBoxPaint(Sender: TObject);
    procedure MusicWaveDisplayPaintBoxResize(Sender: TObject);
    procedure NegateTimeOnSecondPassCheckBoxChange(Sender: TObject);
    procedure NewProjectActionExecute(Sender: TObject);
    procedure OpenMusicSourceActionExecute(Sender: TObject);
    procedure OpenProjectActionExecute(Sender: TObject);
    procedure OpenProjectFolderInExplorerActionExecute(Sender: TObject);
    procedure OpenShaderActionExecute(Sender: TObject);
    procedure PauseActionExecute(Sender: TObject);
    procedure PlayActionExecute(Sender: TObject);
    procedure ProcessOutputMemoDblClick(Sender: TObject);
    procedure RebuildTestingDLLsActionExecute(Sender: TObject);
    procedure ResolutionUniformNameEditChange(Sender: TObject);
    procedure ResolutionXEditChange(Sender: TObject);
    procedure ResolutionYEditChange(Sender: TObject);
    procedure RunEXEActionExecute(Sender: TObject);
    procedure SaveAudioToFileActionExecute(Sender: TObject);
    procedure SaveAudioToFileActionUpdate(Sender: TObject);
    procedure SaveProjectAsActionExecute(Sender: TObject);
    procedure ScreenshotActionExecute(Sender: TObject);
    procedure SeekBackwardActionExecute(Sender: TObject);
    procedure SeekBiggerJumpBackwardActionExecute(Sender: TObject);
    procedure SeekBiggerJumpForwardActionExecute(Sender: TObject);
    procedure SeekForwardActionExecute(Sender: TObject);
    procedure ShaderFileNameEditChange(Sender: TObject);
    procedure StopActionExecute(Sender: TObject);
    procedure TestingGroupBoxClick(Sender: TObject);
    procedure TextsSamplerUniformNameEditChange(Sender: TObject);
    procedure TimeBaseComboBoxChange(Sender: TObject);
    procedure TimeBaseComboBoxDropDown(Sender: TObject);
    procedure TimeDisplayPanelClick(Sender: TObject);
    procedure TimeDividerEditChange(Sender: TObject);
    procedure TimeUniformNameEditChange(Sender: TObject);
    procedure TopRulerPaintBoxPaint(Sender: TObject);
    procedure TwoPassRenderCheckBoxChange(Sender: TObject);
    procedure UseResolutionUniformCheckBoxChange(Sender: TObject);
    procedure UseTextsCheckBoxChange(Sender: TObject);
    procedure UseTextsUniformCheckBoxChange(Sender: TObject);
    procedure UseTimeDividerInX86CodeCheckBoxChange(Sender: TObject);
    procedure UseTimeUniformCheckBoxChange(Sender: TObject);
    procedure WaveformUpdateTimerTimer(Sender: TObject);
  private
    FProgramPath : String;
    FWaveformZoomDisplay : TWaveformZoomDisplay;
    FAutoRebuildNeeded : Boolean; // AutoRebuildTimer checks this and performs a rebuild if needed
    procedure AddProcessOutputLine(AString: String; AIndentDepth : Integer);
    procedure CheckTools;
    procedure EngineBuildEnd(ASender: TEngine; ADescription: String);
    procedure EngineBuildStart(ASender: TEngine; ADescription: String);
    procedure EngineShaderErrors(ASender: TEngine; AFileName : String; AErrors: TStrings);
    procedure OpenFileInExternalTextEditor(ADirectory: String; AFileName: String;
      ALineNumber: Integer);
    procedure EnginePlaybackStateChanged(ASender: TEngine; ADescription: String);
    procedure RefreshPlayPauseButton;
    procedure RefreshTimeDisplay(ACurrentPosition : Integer);
    procedure RefreshWaveformDisplayParameters;
    procedure RefreshConfigCombobox;
    procedure RefreshMusicValues(Sender : TObject);
    // returns true, iff value is changed
    procedure ShellExecFile(ADirectory: String; AFileName: String);
    procedure UpdatePositionDisplays(AImmediate : Boolean);
  public
    function GetConfigVariableNameForControl(AControl: TControl): String; override;
    function GetProjectVariableNameForControl(AControl: TControl): String; override;
    procedure RefreshAllAttributes(Sender : TObject); override;

    procedure SetAutoRebuildNeeded(AValue : Boolean);  override;

  end;

var
  MainForm: TMainForm;

implementation

uses
  strutils,
  LCLType,
  UVariableNames,
  UVisualsForm,
  UEditorForm,
  UEditTextForm,
  UWAVFile,
  UTimingsAndTextsEditorForm;

{$R *.lfm}


function SanitizeUniformName(AString : String) : String;
begin
  Result := '''' + AnsiReplaceStr(AnsiReplaceStr(AString, '"', ''), '''', '') + '''';
end;


function SanitizeFloat(AString : String) : String;
var
  i : Integer;
  s : String;
  numberfoundbeforepoint : Boolean;
  numberfoundafterpoint : Boolean;
  pointfound : Boolean;
begin
  Result := '';
  pointfound := false;
  numberfoundbeforepoint := false;
  numberfoundafterpoint := false;
  s := Trim(AString);
  i := 1;
  while i <= Length(s) do
  begin
    if (i = 1) and (s[i]='-') then begin Result := '-'; end
    else if not pointfound and (s[i] in ['0'..'9']) then begin Result := Result + s[i]; numberfoundbeforepoint := true; end
    else if (s[i] = '.') and not pointfound then
      begin
        if not numberfoundbeforepoint then Result := Result + '0';
        Result := Result + s[i];
        pointfound := true;
      end
    else if pointfound and (s[i] in ['0'..'9']) then begin Result := Result + s[i]; numberfoundafterpoint := true; end
      ;
    Inc(i);
  end;
  if not pointfound then Result := Result + '.0'
  else if not numberfoundafterpoint then Result := Result + '0';
end; // SanitizeFloat

function SanitizeFloatIfNotEmpty(AString : String) : String;
begin
  if AString = '' then Result := '' else Result := SanitizeFloat(AString);
end;

function SanitizeInt(AString : String) : String;
var
  i : Integer;
  s : String;
begin
  Result := '';
  s := Trim(AString);
  i := 1;
  while i <= Length(s) do
  begin
    if (i = 1) and (s[i]='-') then begin Result := '-'; end
    else if (s[i] in ['0'..'9']) then begin Result := Result + s[i]; end;
    Inc(i);
  end;
end; // SanitizeInt

function SanitizePositiveInt(AString : String) : String;
var
  i : Integer;
  s : String;
begin
  Result := '';
  s := Trim(AString);
  i := 1;
  while i <= Length(s) do
  begin
    if (s[i] in ['0'..'9']) then begin Result := Result + s[i]; end;
    Inc(i);
  end;
end; // SanitizePositiveInt


function LooksLikeReferenceToTextFile(AString : String; var AOutFileName : String; var AOutRow : Integer) : Boolean;
begin
  // for example: "debug_visuals.asm:281: error: expecting floating-point number"
  Result := (WordCount(AString, [':']) >= 3);
  if Result then
  begin
    AOutFileName := ExtractWord(1, AString, [':']);
    AOutRow := StrToIntDef(ExtractWord(2, AString, [':']), 0);
  end;
end;

function ExtractFileNameWithoutExt(filePath: string) : string;
var
  temp: string;
begin
  temp := ExtractFileName(filePath);
  Result := temp.Split('.')[0];
end;

{ TMainForm }


function TMainForm.GetConfigVariableNameForControl(AControl : TControl) : String;
begin
  // This routine maps GUI controls i.e. edit boxes, check boxes etc. to configuration variable names

  Result := '';
  if      AControl = ShaderFileNameEdit              then Result := CV_SHADER_FILE
  else if AControl = MusicSourceFileNameEdit         then Result := CV_MUSIC_4KLANG_INC_FILE
  else if AControl = MusicBeatsPerBarEdit            then Result := CV_MUSIC_BEATS_PER_BAR

  else if AControl = TimeBaseComboBox                then Result := CV_TIME_BASE
  else if AControl = UseTimeUniformCheckBox          then Result := CV_USE_TIME_UNIFORM
  else if AControl = TimeUniformNameEdit             then Result := CV_TIME_UNIFORM_NAME
  else if AControl = TimeDividerEdit                 then Result := CV_TIME_DIVIDER

  else if AControl = AudioOffsetEdit                 then Result := CV_AUDIO_DELAY

  // Loop start/end points
  else if AControl = LoopStartEdit                   then Result := CV_LOOP_START
  else if AControl = LoopEndEdit                     then Result := CV_LOOP_END
  else if AControl = LoopCheckBox                    then Result := CV_LOOP_ENABLED

  else if AControl = UseTextsCheckBox                then Result := CV_USE_TEXTS
  else if AControl = UseTextsUniformCheckBox         then Result := CV_USE_TEXTS_UNIFORM
  else if AControl = TextsSamplerUniformNameEdit     then Result := CV_TEXTS_UNIFORM_NAME

  else if AControl = UseTimeDividerInX86CodeCheckBox then Result := CV_USE_TIME_DIVIDER_IN_X86_CODE
  else if AControl = UseResolutionUniformCheckBox    then Result := CV_USE_RESOLUTION_UNIFORM
  else if AControl = ResolutionUniformNameEdit       then Result := CV_RESOLUTION_UNIFORM_NAME
  else if AControl = ResolutionXEdit                 then Result := CV_RESOLUTION_X
  else if AControl = ResolutionYEdit                 then Result := CV_RESOLUTION_Y

  else if AControl = TwoPassRenderCheckBox           then Result := CV_TWO_PASS_RENDERING
  else if AControl = FrameToTextureCheckBox          then Result := CV_FRAME_TO_TEXTURE
  else if AControl = MipMapCheckBox                  then Result := CV_USE_MIPMAP
  else if AControl = NegateTimeOnSecondPassCheckBox  then Result := CV_SECOND_PASS_NEGATIVE_TIME

  else if AControl = CrinklerOrderTriesEdit          then Result := CV_CRINKLER_ORDERTRIES

  else if AControl = EXENameEdit                     then Result := CV_OUTPUT_EXE_NAME

  else if AControl = LinkerComboBox                  then Result := CV_EXE_LINKER_PROGRAM
    ;
end;

function TMainForm.GetProjectVariableNameForControl(AControl : TControl) : String;
begin
  Result := '';
  if AControl = AutoRebuildDLLCheckBox then Result := PREFS_AUTOREBUILD_DLLS
  else if AControl = KeepAudioCheckBox      then Result := PREFS_KEEP_AUDIO
    ;
end;

procedure TMainForm.ShellExecFile(ADirectory : String; AFileName : String);
begin
  ShellExecute(Handle, 'open', 'explorer.exe', PChar(AFileName), PChar(ADirectory), SW_NORMAL);
end;

procedure TMainForm.SetAutoRebuildNeeded(AValue: Boolean);
begin
  FAutoRebuildNeeded := AValue;
  if AutoRebuildTimer.Enabled then
  begin // reset timer
    AutoRebuildTimer.Enabled := false;
    AutoRebuildTimer.Enabled := true;
  end;
end;

procedure TMainForm.OpenFileInExternalTextEditor(ADirectory : String; AFileName : String; ALineNumber : Integer);
var
  params : String;
begin
  params := Format('%s -goto:%d', [AFileName, ALineNumber]);
  ShellExecute(Handle, 'open', 'scite.exe', PChar(params), PChar(ADirectory), SW_NORMAL);
end;


procedure TMainForm.RefreshMusicValues(Sender : TObject);
const
  DLL_NEEDED_PLZ = 'DLL please!';
var
  muslen, smprate : Integer;
  musbpm, time_divider, beats_per_bar : Single;
  minutes, seconds : String;
  time_base : String;
  s : String;
  time_base_effective_value_config,
    music_effective_value_config,
    new_time_divider : String;
  total_audio_buffer_length, audio_delay : Integer;
    format_settings : TFormatSettings;
begin
    format_settings := DefaultFormatSettings;
    format_settings.DecimalSeparator := '.';
  if FEngine <> nil then
  begin
    muslen := FEngine.GetMusicLengthSamples();
    smprate := FEngine.GetMusicSampleRate();
    musbpm := FEngine.GetMusicBPM();

    if (muslen = 0) or (smprate = 0) then
    begin
      MusicBPMEdit.Text := DLL_NEEDED_PLZ;
      MusicLengthSamplesEdit.Text := DLL_NEEDED_PLZ;
      MusicSampleRateEdit.Text := DLL_NEEDED_PLZ;
      MusicLengthMinutesSecndsEdit.Text := DLL_NEEDED_PLZ;
      Exit;
    end;

    MusicBPMEdit.Text := FormatFloat('0.000', musbpm, format_settings);
    MusicLengthSamplesEdit.Text := IntToStr(muslen);
    MusicSampleRateEdit.Text := IntToStr(smprate);

    seconds := IntToStr(((muslen + smprate - 1) div smprate) mod 60);
    minutes := IntToStr((muslen div smprate) div 60);
    MusicLengthMinutesSecndsEdit.Text := minutes + ' m ' + seconds + ' s';

    s := FEngine.GetEffectiveVariableValueInActiveConfig(CV_MUSIC_BEATS_PER_BAR);
    beats_per_bar := StrToFloat(s, format_settings);

    time_base := FEngine.GetEffectiveVariableValueInActiveConfig(CV_TIME_BASE);
    if time_base = 'custom' then
    begin
      TimeDividerEdit.ReadOnly := false;
      TimeDividerEdit.Color := clDefault;
      TimeDividerEdit.Text := SanitizeFloat(TimeDividerEdit.Text);
    end
    else
    begin // non-custom time base: the time divider is set based on things
      TimeDividerEdit.ReadOnly := true;
      TimeDividerEdit.Color := clBtnFace;
      if time_base = 'beats' then
        // time equation:     time = audiotime / (smprate * 60 / musbpm)
        time_divider := (smprate * 60 / musbpm)

      else if time_base = 'bars' then
        // time equation:     time = audiotime / (smprate * 60 / (musbpm / beats_per_bar))
        time_divider := (smprate * 60 * beats_per_bar) / musbpm

      else if time_base = 'seconds' then
        // time equation:     time = audiotime / smprate
        time_divider := smprate;

      TimeDividerEdit.Text := FormatFloat('0.000', time_divider, format_settings);
    end;

    // Find out in which config TIME_BASE is defined
    time_base_effective_value_config := FEngine.GetConfigNameOfEffectiveValueForVariable(CV_TIME_BASE);

    new_time_divider := TimeDividerEdit.Text;
    // Set TimeDivider to the value that was calculated based on tempo and config settings (from debug_audio.dll where it got from 4klang.inc)
    FEngine.SetVariableValueInConfig(time_base_effective_value_config, CV_TIME_DIVIDER, new_time_divider);
    FEngine.SetVariableValueInConfig(time_base_effective_value_config, CV_TIME_DIVIDER_INT, IntToStr(Trunc(StrToFloat(new_time_divider, format_settings))));

    // Did we change TIME_BASE? (it might be a better idea to actually get the effective value from the DLL itself)
//    if new_time_divider <> old_time_divider then
//      SetAutoRebuildNeeded(true);

    music_effective_value_config := FEngine.GetConfigNameOfEffectiveValueForVariable(CV_MUSIC_4KLANG_INC_FILE);
    audio_delay := StrToIntDef(FEngine.GetEffectiveVariableValueInActiveConfig(CV_AUDIO_DELAY), 0);
    total_audio_buffer_length := muslen + audio_delay;

    // in some future version we could let the user set a different prod end time, but for now let's just end when the music ends
    FEngine.SetVariableValueInConfig(music_effective_value_config, CV_PROD_END_TIME, IntToStr(total_audio_buffer_length));
    FEngine.SetVariableValueInConfig(music_effective_value_config, CV_AUDIO_DELAY, IntToStr(audio_delay));
    FEngine.SetVariableValueInConfig(music_effective_value_config, CV_AUDIO_BUFFER_ALLOCATED_LENGTH, IntToStr(total_audio_buffer_length));
    FEngine.SetVariableValueInConfig(music_effective_value_config, CV_AUDIO_SAMPLING_RATE, IntToStr(smprate));

    FEngine.TimeDivider := time_divider;
    FEngine.LoopStart := StrToFloat(FEngine.GetEffectiveVariableValueInActiveConfig(CV_LOOP_START), format_settings);
    FEngine.LoopEnd := StrToFloat(FEngine.GetEffectiveVariableValueInActiveConfig(CV_LOOP_END), format_settings);
    FEngine.LoopEnabled := (FEngine.GetEffectiveVariableValueInActiveConfig(CV_LOOP_ENABLED) = '1');

    RefreshWaveformDisplayParameters;
    MusicWaveDisplayPanel.Invalidate;
  end;
end; // TMainForm.RefreshMusicValues

procedure TMainForm.RebuildTestingDLLsActionExecute(Sender: TObject);
var
  run_thread_was_alive, was_playing : Boolean;
  old_playback_position : Integer;
begin
  run_thread_was_alive := FEngine.RunThreadIsRunning;
  was_playing := FEngine.Running;
  old_playback_position := FEngine.GetCurrentAudioPosition;

  FWaveformZoomDisplay.AudioBuffer := nil;
  FEngine.RebuildDLLs;

  RefreshMusicValues(Sender);
  FWaveformZoomDisplay.Reset;

  if run_thread_was_alive then
  begin
    FEngine.Play(old_playback_position);
    if not was_playing then
    begin // was paused
      FEngine.Stop;
      FEngine.SetAudioPosition(old_playback_position);
    end;
  end;
end;

procedure TMainForm.ResolutionUniformNameEditChange(Sender: TObject);
begin
  SaveControlToConfig(ResolutionUniformNameEdit, SanitizeUniformName(ResolutionUniformNameEdit.Text));
  RefreshAllAttributes(Sender);
end;

procedure TMainForm.AddProcessOutputLine(AString : String; AIndentDepth : Integer);

  procedure AddColoredLine(AString: String; const AColor : TColor);
  begin
    ProcessOutputMemo.SelStart := Length(ProcessOutputMemo.Text);
    ProcessOutputMemo.SelText := AString;
    ProcessOutputMemo.SelLength := Length(AString);
    ProcessOutputMemo.SetRangeColor(ProcessOutputMemo.SelStart, ProcessOutputMemo.SelLength, AColor);

    ProcessOutputMemo.SelStart := Length(ProcessOutputMemo.Text);
    ProcessOutputMemo.SelText := '';
  end;

const
  COMMAND_COLOR = TColor($FF8080);
  ERROR_COLOR = clRed;
  SUCCESS_COLOR = TColor($00A000);
  WARNING_COLOR = TColor($0080AF); // some sort of an orange
  DEFAULT_INFO_COLOR = clSilver;
var
  indent : String;
  c : TColor;
begin
  // Colorize the log text lines
  if Pos('> ', AString) = 1 then
    c := COMMAND_COLOR
  else if strutils.AnsiContainsText(AString, 'rror:')
          or strutils.AnsiContainsText(AString, ' error ')
          or strutils.AnsiContainsText(AString, 'annot find')
          or strutils.AnsiContainsText(AString, 'error!')
          or strutils.AnsiContainsText(AString, 'error.')
          or strutils.AnsiContainsText(AString, ' cannot open ')
  then
    c := ERROR_COLOR
  else if strutils.AnsiContainsText(AString, 'Success') then
    c := SUCCESS_COLOR
  else if strutils.AnsiContainsText(AString, 'arning') then
    c := WARNING_COLOR
  else
    c := DEFAULT_INFO_COLOR;

  indent := '';
  while AIndentDepth > 0 do
  begin
    indent := indent + '    ';
    Dec(AIndentDepth);
  end;
  AddColoredLine(indent + AString + #13, c);
end; // procedure TMainForm.AddProcessOutputLine


procedure TMainForm.ResolutionXEditChange(Sender: TObject);
begin
  ChangeEditValueAndSaveToConfigAndRefresh(ResolutionXEdit, ResolutionXEdit.Text);
  SetAutoRebuildNeeded(true);
end;

procedure TMainForm.ResolutionYEditChange(Sender: TObject);
begin
  ChangeEditValueAndSaveToConfigAndRefresh(ResolutionYEdit, ResolutionYEdit.Text);
  SetAutoRebuildNeeded(true);
end;

procedure TMainForm.RunEXEActionExecute(Sender: TObject);
begin
  FEngine.RunEXE;
end;

procedure TMainForm.SaveAudioToFileActionExecute(Sender: TObject);
begin
  if SaveAudioDialog.Execute then
  begin
    UWAVFile.write_wav_stereo_16bit(
      SaveAudioDialog.FileName,
      FEngine.FullAudioBuffer,
      FEngine.GetMusicLengthSamples * 2 * 2,
      FEngine.GetMusicSampleRate()
    );
  end;
end;

procedure TMainForm.SaveAudioToFileActionUpdate(Sender: TObject);
begin
  SaveAudioToFileAction.Enabled :=
    (FEngine <> nil) and (FEngine.FullAudioBuffer <> nil);
end;



procedure TMainForm.SaveProjectAsActionExecute(Sender: TObject);
var
  old_project_dir, d, n : String;
begin
  if SaveDialog1.Execute then
  begin
    old_project_dir := FEngine.ProjectDirectory;
    FEngine.StopAndUnloadDLLs;
    d := ExtractFileDir(ExpandFileName(SaveDialog1.FileName));
    n := ExtractFileName(SaveDialog1.FileName);
    if FEngine.SaveProjectAs(d, n) then
      ;
    RefreshAllAttributes(Sender);

    // project directory changed ... have to change the text editors' paths
    EditorForm.DirectoryMoved(ForceProjectDirectoryFormat(old_project_dir), FEngine.ProjectDirectory);
    EditTextForm.DirectoryMoved(ForceProjectDirectoryFormat(old_project_dir), FEngine.ProjectDirectory);
  end;
end;

procedure TMainForm.ScreenshotActionExecute(Sender: TObject);
var
  temp_bitmap : TBitmap;
  jpeg : TJPEGImage;
begin
  SaveScreenshotDialog.InitialDir := FEngine.ProjectDirectory;
  if SaveScreenshotDialog.Execute then
  begin
    temp_bitmap  := TBitmap.Create;
    jpeg := TJPEGImage.Create;
    try
      FEngine.Stop;
      temp_bitmap.Handle := Windows.CreateCompatibleBitmap(VisualsForm.Handle, VisualsForm.ClientWidth, VisualsForm.ClientHeight);
      temp_bitmap.SetSize(VisualsForm.ClientWidth, VisualsForm.ClientHeight);
      FEngine.DrawOneFrameToBitmap(temp_bitmap);
      jpeg.Assign(temp_bitmap);
      jpeg.CompressionQuality:=90;
      jpeg.SaveToFile(SaveScreenshotDialog.FileName);
      FEngine.SetProjectVariableValue(PV_PROJECT_SCREENSHOT,ExtractRelativepath(FEngine.ProjectDirectory,SaveScreenshotDialog.FileName));
    finally
      FreeAndNil(jpeg);
      FreeAndNil(temp_bitmap);
    end;
  end;
end;

procedure TMainForm.SeekBackwardActionExecute(Sender: TObject);
begin
  if FEngine.Running then // in play mode, seek speed is 250 ms per click/press
    FEngine.SetAudioPosition(FEngine.GetCurrentAudioPosition - (Integer(FEngine.GetMusicSampleRate) * 250) div 1000)
  else
    FEngine.SetAudioPosition(FEngine.GetCurrentAudioPosition - (Integer(FEngine.GetMusicSampleRate) * 10) div 1000);
  MusicWaveDisplayPaintBox.Invalidate;
end;

procedure TMainForm.SeekForwardActionExecute(Sender: TObject);
begin
  if FEngine.Running then
    FEngine.SetAudioPosition(FEngine.GetCurrentAudioPosition + (Integer(FEngine.GetMusicSampleRate) * 250) div 1000)
  else
    FEngine.SetAudioPosition(FEngine.GetCurrentAudioPosition + (Integer(FEngine.GetMusicSampleRate) * 10) div 1000);
  MusicWaveDisplayPaintBox.Invalidate;
end;

procedure TMainForm.SeekBiggerJumpBackwardActionExecute(Sender: TObject);
var
  aupos, timeunit : Integer;
begin
  if FEngine.RunThreadIsRunning then
  begin
    if FEngine.Running then
      FEngine.SetAudioPosition(FEngine.GetCurrentAudioPosition - Trunc(FEngine.TimeDivider))
    else
    begin
      aupos := FEngine.GetCurrentAudioPosition - 1;
      timeunit := Trunc(FEngine.TimeDivider);
      // in pause mode go to start of current time unit (bar)
      FEngine.SetAudioPosition(aupos - aupos mod timeunit);
    end;
    MusicWaveDisplayPaintBox.Invalidate;
  end;
end;

procedure TMainForm.SeekBiggerJumpForwardActionExecute(Sender: TObject);
var
  aupos, timeunit : Integer;
begin
  if FEngine.RunThreadIsRunning then
  begin
    if FEngine.Running then
      FEngine.SetAudioPosition(FEngine.GetCurrentAudioPosition + Trunc(FEngine.TimeDivider))
    else
    begin
      aupos := FEngine.GetCurrentAudioPosition;
      timeunit := Trunc(FEngine.TimeDivider);
      // in pause mode go to start of next time unit (bar)
      FEngine.SetAudioPosition(aupos - aupos mod timeunit + timeunit);
    end;
    MusicWaveDisplayPaintBox.Invalidate;
  end;
end;

procedure TMainForm.ShaderFileNameEditChange(Sender: TObject);
begin
  SaveControlToConfig(ShaderFileNameEdit, ShaderFileNameEdit.Text);
  FEngine.RefreshShaderFileName;
end;

procedure TMainForm.StopActionExecute(Sender: TObject);
begin
  FEngine.StopAndUnloadDLLs;
  PlayPauseBitBtn.Action := PlayAction;
  RefreshWaveformDisplayParameters;
  MusicWaveDisplayPanel.Invalidate;
end;

procedure TMainForm.TestingGroupBoxClick(Sender: TObject);
begin

end;

procedure TMainForm.TextsSamplerUniformNameEditChange(Sender: TObject);
begin
  SaveControlToConfig(TextsSamplerUniformNameEdit, SanitizeUniformName(TextsSamplerUniformNameEdit.Text));
  RefreshAllAttributes(Sender);
  SetAutoRebuildNeeded(true);
end;


procedure TMainForm.FormCreate(Sender: TObject);
begin
  FProgramPath := ExtractFilePath(Application.ExeName);
  FEngine := TEngine.Create;
  FEngine.ProgramPath := FProgramPath;

  FWaveformZoomDisplay := TWaveformZoomDisplay.Create;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  if FWaveformZoomDisplay <> nil then
    FreeAndNil(FWaveformZoomDisplay);
  if FEngine <> nil then
    FreeAndNil(FEngine);
end;

// Fill the configuration combo box list with .config file names in the project folder
procedure TMainForm.RefreshConfigCombobox;
  function GetConfigIndent(AConfigParentPath : String) : Integer;
  var
    i : Integer;
  begin
    Result := 0;
    for i := 1 to Length(AConfigParentPath) do
      if AConfigParentPath[i] = DirectorySeparator then
        Result := Result + 1;
  end;
var
  sl : TStringList;
  i : Integer;
begin
  ConfigComboBox.Items.Clear;
  sl := TStringList.Create;
  try
    FEngine.GetConfigFileList(sl);
    for i := 0 to sl.Count - 1 do
      sl[i] := FEngine.GetConfigRootPath(sl[i]);

    sl.Sort;

    for i := 0 to sl.Count - 1 do
    begin
      ConfigComboBox.Items.Add(ExtractFileName(sl[i]));
      ConfigComboBox.Items.Objects[i] := TObject(PtrInt(GetConfigIndent(sl[i]))); // kludge! we store an integer in the object reference
    end;

  finally
    sl.Free;
  end;
end;


procedure TMainForm.RefreshAllAttributes(Sender : TObject);
var
  save_FMassUpdating : Boolean;
  parconf : String;
begin
  if FMassUpdating then Exit;

//  ProcessOutputMemo.Lines.Add('BEGIN RefreshAllAttributes(' + Sender.ClassName + ')');
  save_FMassUpdating := FMassUpdating;
  FMassUpdating := true;

  // Project-related things
  ProjectFileNameEdit.Text := FEngine.ProjectFile;
  ProjectFolderEdit.Text := ExpandFileName(FEngine.ProjectDirectory);

  // Config-related things
  RefreshConfigCombobox; // the active config is a part of project settings
  ConfigComboBox.Text := FEngine.GetProjectVariableValue(PV_ACTIVE_CONFIG);

//  FEngine.GetProjectVariableValue(PV_ACTIVE_CONFIG);
  parconf := FEngine.GetParentConfig;
  if parconf = '' then parconf := '(none)';
  ParentConfigLabel.Caption := 'Parent config: ' + parconf;

  // Config, all the rest
  RefreshAllStoredAttributesOfChildControls(Self);

  // ============= TODO =============
  //VisualsForm.ClientWidth := StrToIntDef(FEngine.GetEffectiveVariableValueInActiveConfig(CV_RESOLUTION_X), 640)
//  FEngine.GetProjectVariableValue(PV_ACTIVE_CONFIG);

  CrinklerOrderTriesEdit.Enabled := (Pos('Crinkler', LinkerComboBox.Text) > 0);

  // Read 4klang music values from the audio DLL where they're compiled/baked in
  RefreshMusicValues(Sender);

  VisualsForm.ClientWidth := StrToIntDef(FEngine.GetEffectiveVariableValueInActiveConfig(CV_RESOLUTION_X), 640);
  VisualsForm.ClientHeight := StrToIntDef(FEngine.GetEffectiveVariableValueInActiveConfig(CV_RESOLUTION_Y), 480);

//  ProcessOutputMemo.Lines.Add('END RefreshAllAttributes(' + Sender.ClassName + ')');
  FMassUpdating := save_FMassUpdating;
end;

procedure TMainForm.CheckTools;
var
  shader_minifier_path : String;
begin
  // if ShaderMinifier executable not found, show a message
  shader_minifier_path := FEngine.ProgramPath + 'Tools\ShaderMinifier\shader_minifier.exe';
  if not FileExists(shader_minifier_path) then
  begin
    MessageDlg(
           'ShaderMinifier executable not found',
           Format('%s not found. Automatic shader minification will not work.'+
                  '\n Download it from http://www.pouet.net/prod.php?which=55176 or https://github.com/laurentlb/Shader_Minifier/', [shader_minifier_path]),
           mtWarning,
           [mbOK], 0)
  end;
end;


procedure TMainForm.EngineBuildStart(ASender : TEngine; ADescription : String);
begin
  RefreshPlayPauseButton;
  Self.Caption := ADescription;
  Self.Color := TColor($105010);
  Self.Repaint;
end;

procedure TMainForm.EngineBuildEnd(ASender : TEngine; ADescription : String);
begin
  RefreshPlayPauseButton;
  Self.Caption := MAIN_WINDOW_CAPTION;
  Self.Color := clDefault;
  Self.Repaint;
end;

procedure TMainForm.EnginePlaybackStateChanged(ASender : TEngine; ADescription : String);
begin
  RefreshPlayPauseButton;
end;

procedure TMainForm.EngineShaderErrors(ASender : TEngine; AFileName : String; AErrors: TStrings);
begin
  EditorForm.ShaderRecompiled;
  EditorForm.ShowErrorsOnLines(AFileName, AErrors);
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  FEngine.OnAddProcessOutputLine := @Self.AddProcessOutputLine;
  FEngine.OnBuildStart := @Self.EngineBuildStart;
  FEngine.OnBuildEnd := @Self.EngineBuildEnd;
  FEngine.OnShaderErrors := @Self.EngineShaderErrors;
  FEngine.OnPlaybackStateChanged := @Self.EnginePlaybackStateChanged;

  CheckTools;

  // Load project given on command line
  if (ParamCount > 0) and FileExists(ParamStr(1)) then
  begin
    if FEngine.LoadProject(ParamStr(1)) then
      RefreshAllAttributes(Sender); // This is a bit problematic, because the engine is supposed to be able to load a project
  end
  else
  begin
    if FEngine.NewProject('4k_intro') then
      RefreshAllAttributes(Sender); // This is a bit problematic, because the engine is supposed to be able to load a project

    // ShowMessageFmt('Project file %s doesn''t exist. Cannot load.', [ParamStr(1)]);
  end;

  FocusControl(PlayPauseBitBtn);
end;

procedure TMainForm.FrameToTextureCheckBoxChange(Sender: TObject);
begin
  SaveControlToConfig(FrameToTextureCheckBox, IntToStr(Ord(FrameToTextureCheckBox.Checked)));
  RefreshAllAttributes(Sender);
  SetAutoRebuildNeeded(true);
end;

procedure TMainForm.GoToEndActionExecute(Sender: TObject);
begin
  FEngine.SetAudioPosition(FEngine.GetMusicLengthSamples);
  MusicWaveDisplayPaintBox.Invalidate;
end;

procedure TMainForm.GoToLoopEndActionExecute(Sender: TObject);
begin
  FEngine.SetAudioPosition(FEngine.GetLoopEndAudioPosition);
  MusicWaveDisplayPaintBox.Invalidate;
end;

procedure TMainForm.GoToLoopStartActionExecute(Sender: TObject);
begin
  FEngine.SetAudioPosition(FEngine.GetLoopStartAudioPosition);
  MusicWaveDisplayPaintBox.Invalidate;
end;

procedure TMainForm.GoToStartActionExecute(Sender: TObject);
begin
  FEngine.SetAudioPosition(0);
  MusicWaveDisplayPaintBox.Invalidate;
end;

procedure TMainForm.KeepAudioCheckBoxChange(Sender: TObject);
begin
  if FEngine <> nil then
    FEngine.KeepAudio := KeepAudioCheckBox.Checked;
end;

procedure TMainForm.LinkerComboBoxChange(Sender: TObject);
begin
  if Pos('(', LinkerComboBox.Text) > 0 then // if the value comes from a parent config, the text is like "foobar (some.config)"
    SaveControlToConfig(LinkerComboBox, '')
  else
    SaveControlToConfig(LinkerComboBox, LinkerComboBox.Text);
  RefreshAllAttributes(Sender);
end;

procedure TMainForm.LinkerComboBoxDropDown(Sender: TObject);
const
  USE_PARENT_VALUE_TEXT = '(use parent value)';
var
  t : String;
begin
  if (Pos('(', LinkerComboBox.Text) > 0) then
    t := USE_PARENT_VALUE_TEXT
  else
    t := LinkerComboBox.Text;
  LinkerComboBox.Font.Style := [];
  LinkerComboBox.Items.Clear;
  LinkerComboBox.Items.Add('GNU ld');
  LinkerComboBox.Items.Add('Crinkler');
  if FEngine.ConfigVariableHasInheritedValue(GetConfigVariableNameForControl(LinkerComboBox)) then
    LinkerComboBox.Items.Add(USE_PARENT_VALUE_TEXT);
  LinkerComboBox.Text := t;
end;

procedure TMainForm.LoopCheckBoxChange(Sender: TObject);
var
  value : String;
begin
  if LoopCheckBox.Checked then value := '1' else value := '0';
  SaveControlToConfig(LoopCheckBox, value);
  RefreshAllAttributes(Sender);
end;

procedure TMainForm.LoopEndEditChange(Sender: TObject);
begin
  ChangeEditValueAndSaveToConfigAndRefresh(LoopEndEdit, SanitizeFloat(LoopEndEdit.Text));
  RefreshWaveformDisplayParameters;
  MusicWaveDisplayPanel.Invalidate;
end;

procedure TMainForm.LoopStartEditChange(Sender: TObject);
begin
  ChangeEditValueAndSaveToConfigAndRefresh(LoopStartEdit, SanitizeFloat(LoopStartEdit.Text));
  RefreshWaveformDisplayParameters;
  MusicWaveDisplayPanel.Invalidate;
end;

procedure TMainForm.MinifyShaderFromParentActionExecute(Sender: TObject);
var
  parent_shader, parent_shader_config, minified_shader : String;
begin
  parent_shader := '';
  parent_shader_config := '';
  minified_shader := '';
  Self.EngineBuildStart(FEngine, 'Minifying shader...');
  try
    FEngine.GetConfigVariableInheritedValueAndConfig(CV_SHADER_FILE, parent_shader, parent_shader_config);
    minified_shader := ExtractFileNameWithoutExt(parent_shader) + '_minified.h';
    if (parent_shader <> '')
  //  and (AnsiLowerCase(ExtractFilePath(parent_shader)) <> '.h')
  //  and (parent_shader <> minified_shader) // <-- what the
    then
    begin
      if FileExists(FEngine.ProjectDirectory + minified_shader) then
        if MessageDlg(
             'Confirm overwriting shader?',
             Format('Shader file %s exists. Overwrite it with a minified version of %s?', [minified_shader, parent_shader]),
             mtConfirmation,
             [mbOK, mbCancel], 0) <> mrOK
        then
          Exit;
      if FEngine.MinifyShader(parent_shader, minified_shader, parent_shader_config) then
      begin
        FEngine.SetVariableValueInActiveConfig(CV_SHADER_FILE, minified_shader);
        FEngine.RemapUniformsFromMinifiedShader(parent_shader_config);
        FEngine.RefreshShaderFileName;
        SetAutoRebuildNeeded(true);
      end;
      RefreshAllAttributes(Sender);
    end;

  finally
    Self.EngineBuildEnd(FEngine, '');
  end;
end; // MinifyShaderFromParentActionExecute

procedure TMainForm.MinifyShaderFromParentActionUpdate(Sender: TObject);
begin
  MinifyShaderFromParentAction.Enabled :=
    (FEngine <> nil) and (FEngine.GetParentConfig <> '');
end;

procedure TMainForm.MipMapCheckBoxChange(Sender: TObject);
begin
  SaveControlToConfig(MipMapCheckBox, IntToStr(Ord(MipMapCheckBox.Checked)));
  RefreshAllAttributes(Sender);
  SetAutoRebuildNeeded(true);
end;

procedure TMainForm.MusicBeatsPerBarEditChange(Sender: TObject);
begin
  ChangeEditValueAndSaveToConfigAndRefresh(MusicBeatsPerBarEdit, SanitizeFloatIfNotEmpty(MusicBeatsPerBarEdit.Text));
end;

procedure TMainForm.MusicSourceFileNameEditChange(Sender: TObject);
begin
  SaveControlToConfig(MusicSourceFileNameEdit, MusicSourceFileNameEdit.Text);
  RefreshAllAttributes(Sender);
end;

procedure TMainForm.MusicWaveDisplayPaintBoxMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FWaveformZoomDisplay.MouseDown(Button, Shift, X, Y);

  if (FEngine.RunThreadIsRunning) then
  begin
    FEngine.SetAudioPosition(FWaveformZoomDisplay.GetAudioPositionForDisplayPoint(X, Y));
    UpdatePositionDisplays(true);
  end;
end;

procedure TMainForm.MusicWaveDisplayPaintBoxMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  FWaveformZoomDisplay.MouseMove(Shift, X, Y);

  if FEngine.RunThreadIsRunning and FWaveformZoomDisplay.MouseIsDown then
  begin
    FEngine.SetAudioPosition(FWaveformZoomDisplay.GetAudioPositionForDisplayPoint(X, Y));
    UpdatePositionDisplays(true);
  end;
end;

procedure TMainForm.MusicWaveDisplayPaintBoxMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FWaveformZoomDisplay.MouseUp(Button, Shift, X, Y);
end;


procedure TMainForm.ConfigComboBoxChange(Sender: TObject);
begin
  FEngine.SetActiveConfig(Trim(ConfigComboBox.Text));
  SetAutoRebuildNeeded(true);
  RefreshAllAttributes(Sender);
end;

procedure TMainForm.ConfigComboBoxDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
begin
  ConfigComboBox.Canvas.FillRect(ARect);
  ConfigComboBox.Canvas.TextRect(
    ARect,
    ARect.Left + 2 + PtrInt(ConfigComboBox.Items.Objects[Index]) * 14,
    ARect.Top,
    ConfigComboBox.Items[Index]
  );
end;

procedure TMainForm.ConfigComboBoxDropDown(Sender: TObject);
begin
  RefreshConfigCombobox;
  ConfigComboBox.Text := FEngine.ActiveConfig;
end;

procedure TMainForm.CrinklerOrderTriesEditChange(Sender: TObject);
begin
  ChangeEditValueAndSaveToConfigAndRefresh(CrinklerOrderTriesEdit, CrinklerOrderTriesEdit.Text);
end;

procedure TMainForm.EditNFOActionExecute(Sender: TObject);
begin
  EditTextForm.FilePath := FEngine.ProjectDirectory + FEngine.GetProjectVariableValue(PV_PROJECT_INFO_FILE);
  EditTextForm.Show;
end;

procedure TMainForm.EditShaderActionExecute(Sender: TObject);
begin
  EditorForm.FilePath := FEngine.ProjectDirectory + FEngine.GetEffectiveVariableValueInActiveConfig(CV_SHADER_FILE);
  EditorForm.Show;
end;

procedure TMainForm.EditTextsActionExecute(Sender: TObject);
begin
  TimingsAndTextsEditorForm.FilePath := FEngine.ProjectDirectory + 'timings_and_texts.inc'; // FEngine.GetEffectiveVariableValueInActiveConfig(CV_...);
  TimingsAndTextsEditorForm.Engine := FEngine;
  TimingsAndTextsEditorForm.Show;
end;

procedure TMainForm.EXENameEditChange(Sender: TObject);
begin
  SaveControlToConfig(EXENameEdit, EXENameEdit.Text);
  RefreshAllAttributes(Sender);
end;


procedure TMainForm.ActionList1Update(AAction: TBasicAction; var Handled: Boolean);
var
  b : Boolean;
begin
  TimeUniformNameEdit.Enabled := UseTimeUniformCheckBox.Checked;
  ResolutionUniformNameEdit.Enabled := UseResolutionUniformCheckBox.Checked;
  b := ScreenshotAction.Enabled;
  ScreenshotAction.Enabled := FEngine.RunThreadIsRunning;
  if not b and FEngine.RunThreadIsRunning then
    ScreenshotButton.Update; // why oh why
end;

procedure TMainForm.AudioOffsetEditChange(Sender: TObject);
begin
  ChangeEditValueAndSaveToConfigAndRefresh(AudioOffsetEdit, SanitizePositiveInt(AudioOffsetEdit.Text));
end;

procedure TMainForm.AutoRebuildDLLCheckBoxChange(Sender: TObject);
begin
  AutoRebuildTimer.Enabled := AutoRebuildDLLCheckBox.Checked;
end;

procedure TMainForm.AutoRebuildTimerTimer(Sender: TObject);
begin
  if FAutoRebuildNeeded then
  begin
    RebuildTestingDLLsAction.Execute;
    FAutoRebuildNeeded := false;
  end;
end;

procedure TMainForm.BottomRulerPaintBoxPaint(Sender: TObject);
begin
  FWaveformZoomDisplay.DrawBottomRuler(BottomRulerPaintBox.Canvas, BottomRulerPaintBox.ClientRect);
end;


procedure TMainForm.BuildEXEActionExecute(Sender: TObject);
begin
  FEngine.OnAddProcessOutputLine := @Self.AddProcessOutputLine;
  FEngine.RebuildEXE;
end;

procedure TMainForm.Button2Click(Sender: TObject);
var
  s : String;
begin
  if (FEngine <> nil) then
  begin
    s := FEngine.GetGLInfo;
    ShowMessage(s);
  end;
end;

procedure TMainForm.CheckShaderChangedTimerTimer(Sender: TObject);
begin
  if FEngine <> nil then
  begin
    if FEngine.CheckShaderChanged then
    begin
      if EditorForm <> nil then
        if EditorForm.FilePath <> (FEngine.ProjectDirectory + FEngine.ShaderSourceFileName) then
          EditorForm.FilePath := (FEngine.ProjectDirectory + FEngine.ShaderSourceFileName);
    end;
  end;
end;

procedure TMainForm.ClearProcessOutputMemoActionExecute(Sender: TObject);
begin
  ProcessOutputMemo.Clear;
end;

procedure TMainForm.RefreshTimeDisplay(ACurrentPosition : Integer); // fast update of time position, this is done often
begin
  TimeDisplayLabel.Caption :=
       'Audio sample: ' + IntToStr(ACurrentPosition) + #13#10
     + 'Time: '+ FloatToStrF(FEngine.ConvertAudioPositionToMusicalTime(ACurrentPosition), ffFixed, 6, 4);
end;

procedure TMainForm.RefreshWaveformDisplayParameters;
begin
  if FEngine = nil then Exit;
  if not FEngine.AudioReady then Exit;
  FWaveformZoomDisplay.AudioBuffer := FEngine.FullAudioBuffer;
  FWaveformZoomDisplay.AudioBufferLengthInMonoSamples := FEngine.GetAllocatedAudioLengthInMonoSamples();

  FWaveformZoomDisplay.RulerMajorUnitDuration := FEngine.TimeDivider; // "major unit" e.g. bars
  if TimeBaseComboBox.Text = 'bars' then
    FWaveformZoomDisplay.RulerMinorUnitDuration := Trunc(FEngine.TimeDivider / StrToFloatDef(MusicBeatsPerBarEdit.Text, 1.0))
  else
    FWaveformZoomDisplay.RulerMinorUnitDuration := 0;
  FWaveformZoomDisplay.SamplesPerSecond := FEngine.GetMusicSampleRate();

  FWaveformZoomDisplay.LeftLoopLocatorPos := FEngine.ConvertMusicalTimeToAudioPosition(FEngine.LoopStart);
  FWaveformZoomDisplay.RightLoopLocatorPos := FEngine.ConvertMusicalTimeToAudioPosition(FEngine.LoopEnd);
end;

procedure TMainForm.MusicWaveDisplayPaintBoxPaint(Sender: TObject);
begin
  FWaveformZoomDisplay.DrawWaveformBitmap(MusicWaveDisplayPaintBox.Canvas, MusicWaveDisplayPaintBox.ClientRect);
end;

procedure TMainForm.MusicWaveDisplayPaintBoxResize(Sender: TObject);
begin
  FWaveformZoomDisplay.Width := MusicWaveDisplayPaintBox.Width;
  FWaveformZoomDisplay.Height := MusicWaveDisplayPaintBox.Height;
  UpdatePositionDisplays(false);
end;

procedure TMainForm.NegateTimeOnSecondPassCheckBoxChange(Sender: TObject);
begin
  SaveControlToConfig(NegateTimeOnSecondPassCheckBox, IntToStr(Ord(NegateTimeOnSecondPassCheckBox.Checked)));
  RefreshAllAttributes(Sender);
  SetAutoRebuildNeeded(true);
end;

procedure TMainForm.NewProjectActionExecute(Sender: TObject);
begin
  // TODO: ask which template to use
  FEngine.StopAndUnloadDLLs;
  FEngine.NewProject('4k_intro');
  RefreshAllAttributes(Sender);
end;

procedure TMainForm.OpenMusicSourceActionExecute(Sender: TObject);
begin
  ShellExecFile(FEngine.ProjectDirectory, FEngine.GetEffectiveVariableValueInActiveConfig(CV_MUSIC_4KLANG_INC_FILE));
end;

procedure TMainForm.OpenProjectActionExecute(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    FEngine.StopAndUnloadDLLs;
    FEngine.LoadProject(ExpandFileName(OpenDialog1.FileName));
    RefreshAllAttributes(Sender);
  end;
end;

procedure TMainForm.OpenProjectFolderInExplorerActionExecute(Sender: TObject);
begin
  ShellExecFile('', FEngine.ProjectDirectory);
end;

procedure TMainForm.OpenShaderActionExecute(Sender: TObject);
begin
  ShellExecFile(FEngine.ProjectDirectory, FEngine.GetEffectiveVariableValueInActiveConfig(CV_SHADER_FILE));
end;

procedure TMainForm.PauseActionExecute(Sender: TObject);
begin
  FEngine.Stop; // stop but don't kill run thread
  PlayPauseBitBtn.Action := PlayAction;
end;

procedure TMainForm.RefreshPlayPauseButton;
begin
  if (FEngine = nil) then Exit;
  if FEngine.Running then
  begin
    PlayPauseBitBtn.Action := PauseAction;
    PlayAction.Enabled := false;
    PlayAction.ShortCut := KeyToShortCut(VK_UNDEFINED, []);
    PauseAction.Enabled := true;
    PauseAction.ShortCut := KeyToShortCut(VK_F9, []);
  end
  else
  begin
    PlayPauseBitBtn.Action := PlayAction;
    PauseAction.Enabled := false;
    PauseAction.ShortCut := KeyToShortCut(VK_UNDEFINED, []);
    PlayAction.Enabled := true;
    PlayAction.ShortCut := KeyToShortCut(VK_F9, []);
  end;
end;

procedure TMainForm.PlayActionExecute(Sender: TObject);
var
  oldpos : Integer;
begin
  if VisualsForm.Visible = false then VisualsForm.Show;
  FEngine.VisualsWindowHandle := VisualsForm.Handle;
  // Show the visuals on the editor window ... it doesn't really work like this, a proper
  // overlay of the editor and OpenGL visuals needs the editor to be drawn in a bitmap buffer.
  //FEngine.VisualsWindowHandle := EditorForm.UnprocessedTextMemo.Handle;
  oldpos := FEngine.GetCurrentAudioPosition;
  if oldpos < 0 then oldpos := 0;
  FEngine.Play(oldpos);
  RefreshPlayPauseButton;
  WaveformUpdateTimer.Enabled := true;
end;

procedure TMainForm.ProcessOutputMemoDblClick(Sender: TObject);
var
  range : TParaRange;
  textline, filename : String;
  rownum : Integer;
begin
  textline := '';
  filename := '';
  rownum := 0;
  range := Default(TParaRange);
  if ProcessOutputMemo.GetParaRange(ProcessOutputMemo.SelStart, range) then
  begin
    // get text of clicked paragraph, without line breaks
    textline := ProcessOutputMemo.GetText(range.start, range.lengthNoBr);
    if LooksLikeReferenceToTextFile(textline, filename, rownum) then
    begin
      if not FileExists(FEngine.ProjectDirectory + '\' + filename) then
        MessageDlg('Error', Format('File %s not found.', [FEngine.ProjectDirectory + '\' + filename]), mtError, [mbOk], 0)
      else
        OpenFileInExternalTextEditor(FEngine.ProjectDirectory, filename, rownum);
    end;
  end;
end;


procedure TMainForm.TimeBaseComboBoxChange(Sender: TObject);
begin
  if Pos('(', TimeBaseComboBox.Text) > 0 then // if it's from a parent config, the text is something like "Bars (base.config)"
    SaveControlToConfig(TimeBaseComboBox, '')
  else
    SaveControlToConfig(TimeBaseComboBox, TimeBaseComboBox.Text);
  RefreshAllAttributes(Sender);
end;


procedure TMainForm.TimeBaseComboBoxDropDown(Sender: TObject);
const
  USE_PARENT_VALUE_TEXT = '(use parent value)';
var
  t : String;
begin
  if (Pos('(', TimeBaseComboBox.Text) > 0) then
    t := USE_PARENT_VALUE_TEXT
  else
    t := TimeBaseComboBox.Text;
  TimeBaseComboBox.Font.Style := [];
  TimeBaseComboBox.Items.Clear;
  TimeBaseComboBox.Items.Add('beats');
  TimeBaseComboBox.Items.Add('bars');
  TimeBaseComboBox.Items.Add('seconds');
  TimeBaseComboBox.Items.Add('custom');
  if FEngine.ConfigVariableHasInheritedValue(GetConfigVariableNameForControl(TimeBaseComboBox)) then
    TimeBaseComboBox.Items.Add(USE_PARENT_VALUE_TEXT);
  TimeBaseComboBox.Text := t;
end;

procedure TMainForm.TimeDisplayPanelClick(Sender: TObject);
begin

end;

procedure TMainForm.TimeDividerEditChange(Sender: TObject);
begin
  SaveControlToConfig(TimeDividerEdit, SanitizeFloat(TimeDividerEdit.Text));
  RefreshAllAttributes(Sender);
  SetAutoRebuildNeeded(true);
end;

procedure TMainForm.TimeUniformNameEditChange(Sender: TObject);
begin
  SaveControlToConfig(TimeUniformNameEdit, SanitizeUniformName(TimeUniformNameEdit.Text));
  RefreshAllAttributes(Sender);
  SetAutoRebuildNeeded(true);
end;

procedure TMainForm.TopRulerPaintBoxPaint(Sender: TObject);
begin
  FWaveformZoomDisplay.DrawTopRuler(TopRulerPaintBox.Canvas, TopRulerPaintBox.ClientRect);
end;

procedure TMainForm.TwoPassRenderCheckBoxChange(Sender: TObject);
begin
  SaveControlToConfig(TwoPassRenderCheckBox, IntToStr(Ord(TwoPassRenderCheckBox.Checked)));
  RefreshAllAttributes(Sender);
  SetAutoRebuildNeeded(true);
end;

procedure TMainForm.UseResolutionUniformCheckBoxChange(Sender: TObject);
begin
  SaveControlToConfig(UseResolutionUniformCheckBox, IntToStr(Ord(UseResolutionUniformCheckBox.Checked)));
  RefreshAllAttributes(Sender);
  SetAutoRebuildNeeded(true);
end;

procedure TMainForm.UseTextsCheckBoxChange(Sender: TObject);
begin
  SaveControlToConfig(UseTextsCheckBox, IntToStr(Ord(UseTextsCheckBox.Checked)));
  RefreshAllAttributes(Sender);
  SetAutoRebuildNeeded(true);
end;

procedure TMainForm.UseTextsUniformCheckBoxChange(Sender: TObject);
begin
  SaveControlToConfig(UseTextsUniformCheckBox, IntToStr(Ord(UseTextsUniformCheckBox.Checked)));
  RefreshAllAttributes(Sender);
  SetAutoRebuildNeeded(true);
end;

procedure TMainForm.UseTimeDividerInX86CodeCheckBoxChange(Sender: TObject);
begin
  SaveControlToConfig(UseTimeDividerInX86CodeCheckBox, IntToStr(Ord(UseTimeDividerInX86CodeCheckBox.Checked)));
  RefreshAllAttributes(Sender);
  SetAutoRebuildNeeded(true);
end;

procedure TMainForm.UseTimeUniformCheckBoxChange(Sender: TObject);
begin
  SaveControlToConfig(UseTimeUniformCheckBox, IntToStr(Ord(UseTimeUniformCheckBox.Checked)));
  RefreshAllAttributes(Sender);
  SetAutoRebuildNeeded(true);
end;

procedure TMainForm.UpdatePositionDisplays(AImmediate : Boolean);
var
  r : TRect;
  aupos : Integer;
  wasalreadyfullycached : Boolean;
begin
  if (FEngine <> nil) and (FEngine.RunThreadIsRunning)
  then
  begin
    wasalreadyfullycached := FWaveformZoomDisplay.FullyCached;
    if FEngine.AudioRenderingIsFinished then
      FWaveformZoomDisplay.AudioRenderingIsFinished := true;
    aupos := FEngine.GetCurrentAudioPosition();
    FWaveformZoomDisplay.CurrentPlaybackPosition := aupos;
    FWaveformZoomDisplay.AudioRenderingIsFinished := FEngine.AudioRenderingIsFinished;
    if FWaveformZoomDisplay.FullyInvalidatedInFullyCachedState then
    begin
      r := FWaveformZoomDisplay.GetRectForDrawing(aupos);
      r.Offset(MusicWaveDisplayPaintBox.Left, MusicWaveDisplayPaintBox.Top);
      InvalidateRect(MusicWaveDisplayPaintBox.Parent.Handle, r, false);
    end
    else
    begin // if the waveform display isn't fully cached yet, keep re-setting everything about it
      RefreshWaveformDisplayParameters;
      MusicWaveDisplayPaintBox.Invalidate; // causes a complete redraw
      FWaveformZoomDisplay.FullyInvalidatedInFullyCachedState := wasalreadyfullycached;
    end;
    if AImmediate then
      MusicWaveDisplayPaintBox.Parent.Update;
    RefreshTimeDisplay(aupos);
    if AImmediate then
      TimeDisplayPanel.Update;
    VisualsForm.DisplayAverageFrameTime(FEngine.GetAverageFrameTimeMS);
  end;
end; // TMainForm.UpdatePositionDisplays


procedure TMainForm.WaveformUpdateTimerTimer(Sender: TObject);
begin
  // don't update immediately in the timer handler, it's enough to let the window message loop handle this
  UpdatePositionDisplays(false);
end;


end.

