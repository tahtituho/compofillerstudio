unit UEditorForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, SynHighlighterCpp, SynEdit, Forms, Controls,
  Graphics, Dialogs, StdCtrls, ExtCtrls, ActnList, UPreprocessShader,
  SynEditKeyCmds, RichMemo, LCLType;

type

  { TEditorForm }

  TEditorForm = class(TForm)
    SearchKeysHelpLabel: TLabel;
    SearchAgainBackwards: TAction;
    EndSearchAction: TAction;
    NumMatchesLabel: TLabel;
    SearchAgainAction: TAction;
    SearchTextAction: TAction;
    ErrorOnLineLabel: TLabel;
    BookmarkImages: TImageList;
    KeyShortcutsHelpLabel: TLabel;
    SearchTextEdit: TLabeledEdit;
    MinifyEditorShaderFromParentAction1: TAction;
    AutoReloadCheckBox: TCheckBox;
    MinifyFromParentButton: TButton;
    EditorsPanel: TPanel;
    SearchReplacePanel: TPanel;
    ProcessedTextMemoLabel: TLabel;
    ProcessedTextMemo: TRichMemo;
    SaveButton: TButton;
    FileNameLabel: TLabel;
    SaveAction: TAction;
    ActionList1: TActionList;
    CheckFileChangedTimer: TTimer;
    GetShaderTextButton: TButton;
    Splitter1: TSplitter;
    SynCppSyn1: TSynCppSyn;
    ShowLineErrorTimer: TTimer;
    UnprocessedTextMemo: TSynEdit;
    VariableNamesMemo: TMemo;
    procedure CheckFileChangedTimerTimer(Sender: TObject);
    procedure EndSearchActionExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MinifyEditorShaderFromParentAction1Update(Sender: TObject);
    procedure RemoveCCommentsButtonClick(Sender: TObject);
    procedure SaveActionExecute(Sender: TObject);
    procedure SearchAgainActionExecute(Sender: TObject);
    procedure SearchAgainBackwardsExecute(Sender: TObject);
    procedure SearchTextActionExecute(Sender: TObject);
    procedure SearchTextEditChange(Sender: TObject);
    procedure SearchTextEditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ShowLineErrorTimerTimer(Sender: TObject);
    procedure Splitter1Moved(Sender: TObject);
    procedure UnprocessedTextMemoChange(Sender: TObject);
    procedure UnprocessedTextMemoProcessCommand(Sender: TObject;
      var Command: TSynEditorCommand; var AChar: TUTF8Char; Data: pointer);
    procedure UnprocessedTextMemoSpecialLineColors(Sender: TObject;
      Line: integer; var Special: boolean; var FG, BG: TColor);
  private
    FErrorLineBackgroundColor: TColor;
    FErrorLineForegroundColor: TColor;
    FWarningLineBackgroundColor: TColor;
    FWarningLineForegroundColor: TColor;
    FFilePath : String;
    FFileAge : LongInt;
    FLastErrorsShownCaretY : Integer;

    FErrorLinesAreAboutProcessedShader : Boolean;
    FErrorLines : TStringList;

    function CheckFileChanged : Boolean;
    function GetErrorTextForLine(ALineNum: Integer): String;
    procedure ReloadFile(Sender: TObject);
    procedure SetErrorLineBackgroundColor(AValue: TColor);
    procedure SetErrorLineForegroundColor(AValue: TColor);
    procedure SetErrorTextForLine(ALineNum: Integer; AErrorText: String);
    procedure SetFilePath(AValue: String);
    procedure SetWarningLineBackgroundColor(AValue: TColor);
    procedure SetWarningLineForegroundColor(AValue: TColor);
    procedure UpdateNumMatchesLabel(ANumMatches: Integer);
    procedure UpdateProcessedMemoShaderText;
  public

    procedure ShaderRecompiled; // Just for the main form to let the editor know that a compilation was done. Main form calls ShowErrorsOnLines separately.
    procedure ShowErrorsOnLines(AFileName : String;AErrors : TStrings); // errors as "number=string" pairs

    procedure DirectoryMoved(AOldDir, ANewDir : String); // "someone" should call this if the project directory moves because of "Save As"


    property ErrorLineBackgroundColor : TColor read FErrorLineBackgroundColor write SetErrorLineBackgroundColor;
    property ErrorLineForegroundColor : TColor read FErrorLineForegroundColor write SetErrorLineForegroundColor;
    property WarningLineBackgroundColor : TColor read FWarningLineBackgroundColor write SetWarningLineBackgroundColor;
    property WarningLineForegroundColor : TColor read FWarningLineForegroundColor write SetWarningLineForegroundColor;
    property FilePath : String read FFilePath write SetFilePath;
  end;

var
  EditorForm: TEditorForm;

implementation

uses
  Windows,
  Math,
  SynEditTypes,
  UEngine;

{$R *.lfm}

function GLErrorLooksLikeWarningOnly(AError : String) : Boolean;
var
  p : Integer;
begin
  p := Pos('WARNING', AnsiUpperCase(AError));
  Result := (p >= 1) and (p < 20);
end;

{ TEditorForm }

procedure TEditorForm.RemoveCCommentsButtonClick(Sender: TObject);
begin
  ProcessedTextMemo.Clear;
  ProcessedTextMemo.Lines.AddStrings(UnprocessedTextMemo.Lines);
  ProcessedTextMemo.WordWrap := false;
//  UPreprocessShader.ReplaceCComments(ProcessedTextMemo.Lines);
end;

procedure TEditorForm.SaveActionExecute(Sender: TObject);
begin
  CheckFileChangedTimer.Enabled := false;
  UnprocessedTextMemo.Lines.SaveToFile(FFilePath);
  CheckFileChanged; // reset FFileAge
  ErrorOnLineLabel.Caption := 'File saved. Note: auto-compilation and error-checking only work in Play or Pause mode. (Press F9 to play/pause)';
  ErrorOnLineLabel.Font.Color := TColor($505050);
  CheckFileChangedTimer.Enabled := true;
end;

procedure TEditorForm.UpdateNumMatchesLabel(ANumMatches : Integer);
begin
  // I guess SynEdit's SearchReplace() only returns a number > 1, if it's used for "replace all", or something
  if ANumMatches = 0 then
    NumMatchesLabel.Caption := 'Not found'
  else if ANumMatches = 1 then
    NumMatchesLabel.Caption := 'Found'
  else
    NumMatchesLabel.Caption := 'Found ' + IntToStr(ANumMatches);
end;

procedure TEditorForm.SearchAgainActionExecute(Sender: TObject);
var
  matches : Integer;
begin
  matches := UnprocessedTextMemo.SearchReplace(SearchTextEdit.Text, '', [ssoFindContinue]);
  if matches = 0 then
    matches := UnprocessedTextMemo.SearchReplace(SearchTextEdit.Text, '', [ssoEntireScope]);
  UpdateNumMatchesLabel(matches)
end;

procedure TEditorForm.SearchAgainBackwardsExecute(Sender: TObject);
var
  matches : Integer;
begin
  matches := UnprocessedTextMemo.SearchReplace(SearchTextEdit.Text, '', [ssoFindContinue, ssoBackwards]);
  if matches = 0 then
    matches := UnprocessedTextMemo.SearchReplace(SearchTextEdit.Text, '', [ssoEntireScope, ssoBackwards]);
  UpdateNumMatchesLabel(matches)
end;

procedure TEditorForm.SearchTextActionExecute(Sender: TObject);
begin
  if SearchReplacePanel.Visible then
    SearchAgainActionExecute(Sender)
  else
  begin
    SearchReplacePanel.Visible := true;
    NumMatchesLabel.Caption := '';
    SearchTextEdit.SetFocus;
    SearchTextEditChange(Sender);
  end;
end;

procedure TEditorForm.SearchTextEditChange(Sender: TObject);
var
  matches : Integer;
begin
  matches := UnprocessedTextMemo.SearchReplace(SearchTextEdit.Text, '', [ssoEntireScope]);
  UpdateNumMatchesLabel(matches);
end;

procedure TEditorForm.SearchTextEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE :
    begin
      SearchReplacePanel.Hide;
      UnprocessedTextMemo.SetFocus;
    end;
    VK_RETURN : SearchAgainActionExecute(Sender);
  end;
end;

procedure TEditorForm.ShowLineErrorTimerTimer(Sender: TObject);
var
  errortext, warningtext : String;
  i : Integer;
begin
  if not FErrorLinesAreAboutProcessedShader then
  begin
    if (UnprocessedTextMemo.CaretY <> FLastErrorsShownCaretY)then
    begin
      errortext := GetErrorTextForLine(UnprocessedTextMemo.CaretY);
      ErrorOnLineLabel.Caption := errortext;
      if errortext <> '' then
      begin
        if GLErrorLooksLikeWarningOnly(errortext) then
          ErrorOnLineLabel.Font.Color := FWarningLineForegroundColor
        else
          ErrorOnLineLabel.Font.Color := FErrorLineForegroundColor;
      end;
      FLastErrorsShownCaretY := UnprocessedTextMemo.CaretY;
    end;
  end
  else
  begin
    // The errors are about the processed text, i.e. the left memo is in ".h"
    // format and the real compiled shader is in the right-hand side memo.
    if FErrorLines.Count > 0 then
    begin
      ErrorOnLineLabel.Caption := '';
      warningtext := '';
      // Is there an actual error, or just warnings? try to find the first error
      for i := 0 to FErrorLines.Count - 1 do
      begin
        errortext := FErrorLines.ValueFromIndex[i];
        if not GLErrorLooksLikeWarningOnly(errortext) then
        begin
          ErrorOnLineLabel.Caption := errortext;
          ErrorOnLineLabel.Font.Color := FErrorLineForegroundColor;
          break;
        end
        else
          warningtext := errortext;
      end;
      // If we didn't find an error, show the warning then
      if (ErrorOnLineLabel.Caption = '') and (warningtext <> '') then
      begin
        ErrorOnLineLabel.Caption := warningtext;
        ErrorOnLineLabel.Font.Color := FWarningLineForegroundColor;
      end;
    end
    else
      ErrorOnLineLabel.Caption := '';
  end;
end;

procedure TEditorForm.Splitter1Moved(Sender: TObject);
begin
  // Splitter moved. Move processed memo caption.
  ProcessedTextMemoLabel.Left := EditorsPanel.Left + ProcessedTextMemo.Left;
end;

procedure TEditorForm.UnprocessedTextMemoChange(Sender: TObject);
begin
  // Clear error lines when the text is edited in any way.
  if FErrorLines.Count > 0 then
    FErrorLines.Clear;

  if AnsiLowerCase(ExtractFileExt(FFilePath)) = '.h' then
    UpdateProcessedMemoShaderText
  else
    ProcessedTextMemo.Clear;
end;

procedure TEditorForm.UnprocessedTextMemoProcessCommand(Sender: TObject;
  var Command: TSynEditorCommand; var AChar: TUTF8Char; Data: pointer);
begin
end;

procedure TEditorForm.UnprocessedTextMemoSpecialLineColors(Sender: TObject;
  Line: integer; var Special: boolean; var FG, BG: TColor);
var
  errortext : String;
begin
  if FErrorLinesAreAboutProcessedShader then
    Exit;
  errortext := GetErrorTextForLine(Line);
  if errortext <> '' then
  begin
    Special := true;
    if GLErrorLooksLikeWarningOnly(errortext) then
    begin
      FG := WarningLineForegroundColor;
      BG := WarningLineBackgroundColor;
    end
    else
    begin
      FG := ErrorLineForegroundColor;
      BG := ErrorLineBackgroundColor;
    end;
  end;
end;

procedure TEditorForm.SetFilePath(AValue: String);
begin
  if FFilePath=AValue then Exit;
  FFilePath:=AValue;
  FileNameLabel.Caption := ExtractFileName(FFilePath);

  ReloadFile(Self);
  FFileAge := -1;
  CheckFileChanged;
end;

procedure TEditorForm.SetWarningLineBackgroundColor(AValue: TColor);
begin
  if FWarningLineBackgroundColor=AValue then Exit;
  FWarningLineBackgroundColor:=AValue;
end;

procedure TEditorForm.SetWarningLineForegroundColor(AValue: TColor);
begin
  if FWarningLineForegroundColor=AValue then Exit;
  FWarningLineForegroundColor:=AValue;
end;

procedure TEditorForm.UpdateProcessedMemoShaderText;
  procedure AddColoredLine(ARichMemo : TRichMemo; AString: String; const AColor : TColor);
  begin
    ARichMemo.SelStart := Length(ARichMemo.Text);
    ARichMemo.SelText := AString;
    ARichMemo.SelLength := Length(AString);
    ARichMemo.SetRangeColor(ARichMemo.SelStart, ARichMemo.SelLength, AColor);

    ARichMemo.SelStart := Length(ARichMemo.Text);
  end;
var
  i : Integer;
  s : String;
  sl, stringstoadd : TStringList;
  c : TColor;
begin
  s := '';
  sl := TStringList.Create;
  stringstoadd := TStringList.Create;
  try
    sl.AddStrings(UnprocessedTextMemo.Lines);
    VariableNamesMemo.Clear;
    ProcessedTextMemo.Clear;
    UPreprocessShader.ShaderMinifierHToPlainString(sl, s, VariableNamesMemo.Lines);
    stringstoadd.Text := s;

    // if a line contains an error, show it in red
    for i := 0 to stringstoadd.Count - 1 do
    begin
      if GetErrorTextForLine(i+1) <> '' then
      begin
        if GLErrorLooksLikeWarningOnly(GetErrorTextForLine(i+1)) then
          c := clYellow
        else
          c := clRed
      end
      else
        c := clSkyBlue;
      AddColoredLine(ProcessedTextMemo, stringstoadd[i] + #13#10, c);
    end;

    ProcessedTextMemo.WordWrap := true;
  finally
    stringstoadd.Free;
    sl.Free;
  end;
end;

function TEditorForm.GetErrorTextForLine(ALineNum : Integer) : String;
begin
  Result := FErrorLines.Values[IntToStr(ALineNum)];
end;

procedure TEditorForm.SetErrorTextForLine(ALineNum : Integer; AErrorText : String);
begin
  FErrorLines.Values[IntToStr(ALineNum)] := AErrorText;
end;

procedure TEditorForm.ShaderRecompiled;
begin
  ErrorOnLineLabel.Caption := '';
end;

procedure TEditorForm.ShowErrorsOnLines(AFileName : String; AErrors: TStrings);
var
  i, p : Integer;
  firsterrorline, errorline : Integer;
  errortext, warningtext : String;
  s : String;
begin
  // Clear errors
  FErrorLines.Clear;
  FLastErrorsShownCaretY := -1;

  // Update FErrorsLines based on the given errors
  FErrorLines.Sorted := false;
  firsterrorline := MaxInt;
  warningtext := '';
  for i := 0 to AErrors.Count - 1 do
  begin
    s := AErrors[i];
    p := Pos('=', s);
    if p >= 2 then
    begin
      errorline := StrToIntDef(Copy(s, 1, p-1), -1);
      errortext := Copy(s, p+1, Length(s)-p);
      if errorline >= 0 then
      begin
        if (not GLErrorLooksLikeWarningOnly(errortext)) then // don't scroll the window on warnings only
        begin
          if (errorline < firsterrorline) then
            firsterrorline := errorline;
        end
        else
          if (warningtext = '') then warningtext := errortext;

        SetErrorTextForLine(errorline, errortext);
      end;
    end;
  end;
  FErrorLines.Sorted := true;

  if AnsiLowerCase(ExtractFileExt(AFileName)) = '.h' then
  begin
    FErrorLinesAreAboutProcessedShader := true;
    UpdateProcessedMemoShaderText;
    // TODO
    // If the compiled shader that has errors is minified, then we have to show the errors on the rightmost text memo.
  end
  else
  begin // the shader is in "regular" format, not in C header .h format
    FErrorLinesAreAboutProcessedShader := false;
    if firsterrorline < MaxInt then
    begin
      // if the first error line is not already visible, scroll it to the center of the editor
      if (firsterrorline < UnprocessedTextMemo.TopLine)
         or (firsterrorline >= (UnprocessedTextMemo.TopLine + UnprocessedTextMemo.LinesInWindow))
      then
        UnprocessedTextMemo.TopLine := Max(firsterrorline - UnprocessedTextMemo.LinesInWindow div 2, 1);
      // move the cursor to the first error line
      UnprocessedTextMemo.CaretY := firsterrorline;
    end
    else
    begin // no error, but maybe a warning?
      if warningtext <> '' then
      begin
        ErrorOnLineLabel.Caption := warningtext;
        ErrorOnLineLabel.Font.Color := FWarningLineForegroundColor
      end;
    end;
  end;
  UnprocessedTextMemo.Refresh;
end; // ShowErrorsOnLines

procedure TEditorForm.MinifyEditorShaderFromParentAction1Update(Sender: TObject);
begin
  //
end;

function TEditorForm.CheckFileChanged : Boolean;
var
  fage : LongInt;
begin
  Result := false;
  if not FileExists(FFilePath) then
  begin
    FFileAge := 0;
    Exit;
  end;
  fage := FileAge(FFilePath);
  if (fage <> FFileAge) then
  begin
    FFileAge := fage;
    Result := true;
  end;
end;

procedure TEditorForm.SetErrorLineBackgroundColor(AValue: TColor);
begin
  if FErrorLineBackgroundColor=AValue then Exit;
  FErrorLineBackgroundColor:=AValue;
end;

procedure TEditorForm.SetErrorLineForegroundColor(AValue: TColor);
begin
  if FErrorLineForegroundColor=AValue then Exit;
  FErrorLineForegroundColor:=AValue;
end;

procedure TEditorForm.ReloadFile(Sender: TObject);
var
  savepos : TPoint;
begin
  savepos := UnprocessedTextMemo.LogicalCaretXY;
  UnprocessedTextMemo.Lines.LoadFromFile(FFilePath);
  UnprocessedTextMemoChange(Sender);
  UnprocessedTextMemo.LogicalCaretXY := savepos;
end;

procedure TEditorForm.CheckFileChangedTimerTimer(Sender: TObject);
begin
  if CheckFileChanged then
    if AutoReloadCheckBox.Checked then
      ReloadFile(Sender);
end;

procedure TEditorForm.EndSearchActionExecute(Sender: TObject);
begin
  SearchReplacePanel.Visible := false;
  EndSearchAction.Enabled := false;
end;

procedure TEditorForm.FormCreate(Sender: TObject);
begin
  FErrorLineBackgroundColor := TColor($000040);
  FErrorLineForegroundColor := TColor($3080FF);
  FWarningLineBackgroundColor := clBlack;
  FWarningLineForegroundColor := TColor($3080D0);
  FErrorLines := TStringList.Create;
  FErrorLines.Clear;
end;

procedure TEditorForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FErrorLines);
end;


procedure TEditorForm.DirectoryMoved(AOldDir, ANewDir: String);
var
  p : String;
begin
  p := ForceProjectDirectoryFormat(ExtractFileDir(FFilePath));
  if (p = AOldDir) then
    FFilePath := ForceProjectDirectoryFormat(ANewDir) + ExtractFileName(FFilePath);
end;

end.



