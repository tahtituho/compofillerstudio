unit UTimingsAndTextsEditorForm;
// Compofiller Studio by Yzi

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ValEdit,
  Grids, StdCtrls, ActnList, EditBtn, Spin, ButtonPanel, ComCtrls, ExtCtrls,
  UEngine,
  UConfigUIMappingHelpers;

type

  { TTimingsAndTextsEditorForm }

  TTimingsAndTextsEditorForm = class(TFormWithControlsRepresentingVariables)
    ActionList1: TActionList;
    AutoLocateCheckBox: TCheckBox;
    ExplanationAboutStuffLabel: TLabel;
    ExplanationAboutStuffLabel2: TLabel;
    PreviewPaintBox: TPaintBox;
    PreviewPanel: TPanel;
    UpdatePreviewTimer: TTimer;
    WidecharTextsCheckBox: TCheckBox;
    FontWidthSpinEdit: TSpinEdit;
    FontWidthSpinEditLabel: TLabel;
    FontItalicSpinEdit: TSpinEdit;
    FontEscapementSpinEdit: TSpinEdit;
    FontEscapementSpinEditLabel: TLabel;
    FontWeightSpinEdit: TSpinEdit;
    FontItalicSpinEditLabel: TLabel;
    FontOrientationSpinEdit: TSpinEdit;
    FontWeightSpinEditLabel: TLabel;
    FontUnderlineSpinEdit: TSpinEdit;
    FontStrikeoutSpinEditLabel: TLabel;
    FontStrikeoutSpinEdit: TSpinEdit;
    CloseAction: TAction;
    DeleteRowAction: TAction;
    DeleteRowButton: TButton;
    ConfigGroupBox: TGroupBox;
    CloseButton: TButton;
    FontDialog1: TFontDialog;
    FontEditLabel: TLabel;
    FontGroupBox: TGroupBox;
    FontNameButton: TButton;
    FontNameEdit: TEdit;
    FontSizeLabel: TLabel;
    CharacterExtraSpacingLabel: TLabel;
    FontSizeSpinEdit: TSpinEdit;
    CharacterExtraSpacingSpinEdit: TSpinEdit;
    FontUnderlineSpinEditLabel: TLabel;
    FontOrientationSpinEditLabel: TLabel;
    InsertNewRowAction: TAction;
    CreateFontHelpLabel: TLabel;
    LoadAction: TAction;
    OptionsGroupBox: TGroupBox;
    ResLabel: TLabel;
    ResolutionGroupBox: TGroupBox;
    ResolutionXEdit: TEdit;
    ResolutionYEdit: TEdit;
    SaveAction: TAction;
    SaveAndCloseAction: TAction;
    SaveAndCloseButton: TButton;
    LoadButton: TButton;
    TimingsAndTextsGroupBox: TGroupBox;
    InsertNewRowButton: TButton;
    SaveButton: TButton;
    TimingsAndTextsStringGrid: TStringGrid;
    procedure AutoLocateCheckBoxChange(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure CloseActionExecute(Sender: TObject);
    procedure DeleteRowActionExecute(Sender: TObject);
    procedure DeleteRowActionUpdate(Sender: TObject);
    procedure FontNameButtonClick(Sender: TObject);
    procedure FontNameEditChange(Sender: TObject);
    procedure Font_some_SpinEditChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure InsertNewRowActionExecute(Sender: TObject);
    procedure LoadActionExecute(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure PreviewPaintBoxPaint(Sender: TObject);
    procedure PreviewPanelResize(Sender: TObject);
    procedure ResolutionXEditChange(Sender: TObject);
    procedure ResolutionYEditChange(Sender: TObject);
    procedure SaveActionExecute(Sender: TObject);
    procedure SaveAndCloseActionExecute(Sender: TObject);
    procedure TimingsAndTextsStringGridCompareCells(Sender: TObject; ACol,
      ARow, BCol, BRow: Integer; var Result: integer);
    procedure TimingsAndTextsStringGridEditingDone(Sender: TObject);
    procedure TimingsAndTextsStringGridPrepareCanvas(sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
    procedure TimingsAndTextsStringGridSelectCell(Sender: TObject; aCol,
      aRow: Integer; var CanSelect: Boolean);
    procedure UpdatePreviewTimerTimer(Sender: TObject);
    procedure WidecharTextsCheckBoxChange(Sender: TObject);
  private

    FFilePath: String;
    FLastAutoLocatedRow : Integer;
    FLastStringPtrUpdatedToPreview : Pointer;
    FPreviewPaintBoxResizePending : Boolean;

  public

    function GetConfigVariableNameForControl(AControl: TControl): String; override;
    function GetProjectVariableNameForControl(AControl: TControl): String; override;
    procedure RefreshAllAttributes(Sender : TObject); override;

    procedure SetFilePath(AValue: String);

    procedure LoadTexts;
    procedure SaveTexts;

    procedure SetAutoRebuildNeeded(AValue : Boolean);  override;
    procedure SortRows;

    procedure DirectoryMoved(AOldDir, ANewDir : String); // "someone" should call this if the project directory moves because of "Save As"

    procedure UpdatePreview;

    property FilePath : String read FFilePath write SetFilePath;
  end;

var
  TimingsAndTextsEditorForm: TTimingsAndTextsEditorForm;

implementation

uses
  Windows,
  strutils,
  UVariableNames,
  UTimingsAndTextsData,
  UMainForm;
  

{$R *.lfm}

function SanitizeFontName(AString : String) : String;
begin
  Result := '''' + AnsiReplaceStr(AnsiReplaceStr(AString, '"', ''), '''', '') + '''';
end;


{ TTimingsAndTextsEditorForm }

function TTimingsAndTextsEditorForm.GetConfigVariableNameForControl(AControl : TControl) : String;
begin
  Result := '';
  if      AControl = ResolutionXEdit then Result := CV_TEXT_BITMAP_RESOLUTION_X
  else if AControl = ResolutionYEdit then Result := CV_TEXT_BITMAP_RESOLUTION_Y
  else if AControl = FontNameEdit    then Result := CV_TEXT_FONT_NAME
  else if AControl = FontSizeSpinEdit then Result := CV_TEXT_FONT_SIZE
  else if AControl = FontStrikeoutSpinEdit then Result := CV_TEXT_FONT_STRIKEOUT
  else if AControl = FontUnderlineSpinEdit then Result := CV_TEXT_FONT_UNDERLINE
  else if AControl = FontItalicSpinEdit then Result := CV_TEXT_FONT_ITALIC
  else if AControl = FontWeightSpinEdit then Result := CV_TEXT_FONT_WEIGHT
  else if AControl = FontOrientationSpinEdit then Result := CV_TEXT_FONT_ORIENTATION
  else if AControl = FontEscapementSpinEdit then Result := CV_TEXT_FONT_ESCAPEMENT
  else if AControl = FontWidthSpinEdit then Result := CV_TEXT_FONT_WIDTH
  else if AControl = CharacterExtraSpacingSpinEdit then Result := CV_TEXT_CHARACTER_EXTRA_SPACING
  else if AControl = WidecharTextsCheckBox then Result := CV_USE_WIDECHAR_TEXTS
    ;
end;

function TTimingsAndTextsEditorForm.GetProjectVariableNameForControl(
  AControl: TControl): String;
begin
  Result := '';
  if AControl = AutoLocateCheckBox then Result := PREFS_AUTO_LOCATE_TO_ACTIVE_TEXT
    ;

end;

procedure TTimingsAndTextsEditorForm.RefreshAllAttributes(Sender: TObject);
var
  save_FMassUpdating : Boolean;
begin
  if FMassUpdating then Exit;
  save_FMassUpdating := FMassUpdating;
  try
    FMassUpdating := true;

    RefreshAllStoredAttributesOfChildControls(Self);

  finally
    FMassUpdating := save_FMassUpdating;
  end;
end;

procedure TTimingsAndTextsEditorForm.FontNameButtonClick(Sender: TObject);
begin
  if FontDialog1.Execute then
    FontNameEdit.Text := SanitizeFontName(FontDialog1.Font.Name);
end;

procedure TTimingsAndTextsEditorForm.CancelButtonClick(Sender: TObject);
begin
  Close;
end;

procedure TTimingsAndTextsEditorForm.AutoLocateCheckBoxChange(Sender: TObject);
begin
  SaveControlToProject(AutoLocateCheckBox, IntToStr(Ord(AutoLocateCheckBox.Checked)));
  RefreshAllAttributes(Sender);
end;

procedure TTimingsAndTextsEditorForm.CloseActionExecute(Sender: TObject);
begin
  Close;
end;

procedure TTimingsAndTextsEditorForm.DeleteRowActionExecute(Sender: TObject);
var
  rowidx : Integer;
begin
  if TimingsAndTextsStringGrid.RowCount > 2 then
  begin
    rowidx := TimingsAndTextsStringGrid.Row;
    TimingsAndTextsStringGrid.DeleteRow(rowidx);
  end;
end;

procedure TTimingsAndTextsEditorForm.DeleteRowActionUpdate(Sender: TObject);
begin
  DeleteRowAction.Enabled := TimingsAndTextsStringGrid.RowCount > 2;
end;

procedure TTimingsAndTextsEditorForm.FontNameEditChange(Sender: TObject);
begin
  ChangeEditValueAndSaveToConfigAndRefresh(FontNameEdit, SanitizeFontName(FontNameEdit.Text));
  SetAutoRebuildNeeded(true);
end;

procedure TTimingsAndTextsEditorForm.Font_some_SpinEditChange(Sender: TObject);
begin
  if Sender is TSpinEdit then
  begin
    ChangeEditValueAndSaveToConfigAndRefresh(TSpinEdit(Sender), (Sender as TSpinEdit).Text);
    SetAutoRebuildNeeded(true);
  end;
end;

procedure TTimingsAndTextsEditorForm.FormCreate(Sender: TObject);
begin
  FLastAutoLocatedRow := -1;
  FPreviewPaintBoxResizePending := true;
end;

procedure TTimingsAndTextsEditorForm.FormShow(Sender: TObject);
begin
  LoadActionExecute(Sender);
  PreviewPanel.DoubleBuffered := true;
end;

procedure TTimingsAndTextsEditorForm.SortRows;
begin
  TimingsAndTextsStringGrid.SortColRow(true, 1);
end;

procedure TTimingsAndTextsEditorForm.InsertNewRowActionExecute(
  Sender: TObject);
var
  rowidx, i : Integer;
begin
  rowidx := TimingsAndTextsStringGrid.Row;
  TimingsAndTextsStringGrid.InsertColRow(false, rowidx);
  for i := 0 to TimingsAndTextsStringGrid.ColCount-1 do
    TimingsAndTextsStringGrid.Cells[i, rowidx] := TimingsAndTextsStringGrid.Cells[i, rowidx+1];
end;

procedure TTimingsAndTextsEditorForm.LoadActionExecute(Sender: TObject);
begin
  LoadTexts;
  RefreshAllAttributes(Sender);
end;

procedure TTimingsAndTextsEditorForm.PaintBox1Paint(Sender: TObject);
begin
  UpdatePreview;
end;

procedure TTimingsAndTextsEditorForm.PreviewPaintBoxPaint(Sender: TObject);
begin
  UpdatePreview;
end;

procedure TTimingsAndTextsEditorForm.PreviewPanelResize(Sender: TObject);
var
  texts_res_x, texts_res_y : Integer;
  texts_bitmapinfo : PBITMAPINFO;
//  w, h, x, y, t, l : Integer;
begin
  texts_bitmapinfo := FEngine.GetTextsBitmapInfo;
  if texts_bitmapinfo = nil then begin FPreviewPaintBoxResizePending := true; Exit; end;

  texts_res_x := texts_bitmapinfo^.bmiHeader.biWidth;
  texts_res_y := texts_bitmapinfo^.bmiHeader.biHeight;
  if (texts_res_x <= 0) or (texts_res_y <= 0) or (PreviewPanel.Height <= 0) then begin FPreviewPaintBoxResizePending := true; Exit; end;


  if (PreviewPanel.Width / PreviewPanel.Height) < (texts_res_x / texts_res_y) then
  begin
    PreviewPaintBox.Width := PreviewPanel.Width;
    PreviewPaintBox.Height := (PreviewPaintBox.Width * texts_res_y) div texts_res_x;
    PreviewPaintBox.Left := 0;
    PreviewPaintBox.Top := (PreviewPanel.Height - (texts_res_y * PreviewPanel.Width) div texts_res_x) div 2;
  end
  else
  begin
    PreviewPaintBox.Height := PreviewPanel.Height;
    PreviewPaintBox.Width := (PreviewPaintBox.Height * texts_res_x) div texts_res_y;
    PreviewPaintBox.Top := 0;
    PreviewPaintBox.Left := (PreviewPanel.Width - (texts_res_x * PreviewPanel.Height) div texts_res_y) div 2;
//    w := PreviewPanel.Width; h := PreviewPanel.Height; x := PreviewPaintBox.Width; y := PreviewPaintBox.Height; t := PreviewPaintBox.Top; l := PreviewPaintBox.Left;
//    ShowMessage(Format('w:%d, h:%d, x:%d, y:%d, t:%d, l:%d', [w, h, x, y, t, l]));
  end;
  FPreviewPaintBoxResizePending := false;
end;

procedure TTimingsAndTextsEditorForm.ResolutionXEditChange(Sender: TObject);
begin
  ChangeEditValueAndSaveToConfigAndRefresh(ResolutionXEdit, ResolutionXEdit.Text);
  SetAutoRebuildNeeded(true);
end;

procedure TTimingsAndTextsEditorForm.ResolutionYEditChange(Sender: TObject);
begin
  ChangeEditValueAndSaveToConfigAndRefresh(ResolutionYEdit, ResolutionYEdit.Text);
  SetAutoRebuildNeeded(true);
end;

procedure TTimingsAndTextsEditorForm.SaveActionExecute(Sender: TObject);
var
  old_row : Integer;
begin
  old_row := TimingsAndTextsStringGrid.Row;
  SaveTexts;
  LoadTexts; // reload immediately after saving, so we see what what we get
  TimingsAndTextsStringGrid.Row := old_row;
end;

procedure TTimingsAndTextsEditorForm.SaveAndCloseActionExecute(Sender: TObject);
begin
  SaveTexts;
  Close;
end;

procedure TTimingsAndTextsEditorForm.TimingsAndTextsStringGridCompareCells(
  Sender: TObject; ACol, ARow, BCol, BRow: Integer; var Result: integer);
var
  str1, str2 : String;
  f1, f2 : Single;
begin
  if ACol <> BCol then
    raise Exception.Create('onko järkee vai ei');
  str1 := TimingsAndTextsStringGrid.Cells[ACol, ARow];
  str2 := TimingsAndTextsStringGrid.Cells[BCol, BRow];
  if ACol = 1 then
  begin
    f1 := StrToFloatDef(str1, -1);
    f2 := StrToFloatDef(str2, -1);
    if f1 < f2 then Result := -1
    else if f1 > f2 then Result := 1
    else
      Result := ARow - BRow; // if time values are identical, keep original order
  end
  else
    Result := AnsiCompareText(str1, str2);
end;

procedure TTimingsAndTextsEditorForm.TimingsAndTextsStringGridEditingDone(
  Sender: TObject);
begin
  SortRows;
end;

procedure TTimingsAndTextsEditorForm.TimingsAndTextsStringGridPrepareCanvas(sender: TObject;
  aCol, aRow: Integer; aState: TGridDrawState);
var
  ts : TTextStyle;
begin
  ts  := TimingsAndTextsStringGrid.Canvas.TextStyle;
  ts.Wordbreak := true;
  ts.SingleLine := false;
  TimingsAndTextsStringGrid.Canvas.TextStyle := ts;
end;

procedure TTimingsAndTextsEditorForm.TimingsAndTextsStringGridSelectCell(
  Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
var
  t : Single;
  p : Integer;
begin
  if (aRow <> FLastAutoLocatedRow) and AutoLocateCheckBox.Checked then
  begin
    t := StrToFloatDef(TimingsAndTextsStringGrid.Cells[1, aRow], -1);
    if t >= 0.0 then
    begin
      p := FEngine.ConvertMusicalTimeToAudioPosition(t);
      FEngine.SetAudioPosition(p);
    end;
    FLastAutoLocatedRow := aRow;
  end;
end;

procedure TTimingsAndTextsEditorForm.UpdatePreviewTimerTimer(Sender: TObject);
begin
  PreviewPanel.Invalidate;
end;

procedure TTimingsAndTextsEditorForm.WidecharTextsCheckBoxChange(Sender: TObject
  );
begin
  SaveControlToConfig(WidecharTextsCheckBox, IntToStr(Ord(WidecharTextsCheckBox.Checked)));
  RefreshAllAttributes(Sender);
  SetAutoRebuildNeeded(true);
end;


procedure TTimingsAndTextsEditorForm.SetFilePath(AValue: String);
begin
  if FFilePath=AValue then Exit;
  FFilePath:=AValue;
end;

// Convert CR/LF to \n
function EscapeText(AString : String) : String;
begin
  Result := AnsiReplaceStr(AString, #13#10, '\n');
  Result := AnsiReplaceStr(AString, #13, '\n');
end;

// Convert \n to CR/LF
function UnEscapeText(AString : String) : String;
begin
  Result := AnsiReplaceStr(AString, '\n', #13);
end;


procedure TTimingsAndTextsEditorForm.LoadTexts;
var
  contents : TTimingsAndTextsFileContents;
  file_lines : TStringList;
  timingrec : TTimingsAndTextsRowRec;
  i, row  : Integer;
begin
  file_lines := TStringList.Create;
  file_lines.LoadFromFile(FFilePath);
  contents := TTimingsAndTextsFileContents.Create;
  contents.ParseStringsFromAsmLines(file_lines);
  contents.ParseTimingsFromAsmLines(file_lines);
  try
    TimingsAndTextsStringGrid.Clear;

    TimingsAndTextsStringGrid.RowCount := contents.TimingsAndTextsRecordsCount + TimingsAndTextsStringGrid.FixedRows + 1;

    for i := 0 to contents.TimingsAndTextsRecordsCount - 1 do
    begin
      timingrec := contents.TimingsAndTextsRecords[i];

      row := TimingsAndTextsStringGrid.FixedRows + i;
      TimingsAndTextsStringGrid.Cells[0, row] := IntToStr(Ord(timingrec.GenerateData));
      TimingsAndTextsStringGrid.Cells[1, row] := FloatToStr(timingrec.Time);
      TimingsAndTextsStringGrid.Cells[2, row] := timingrec.TimeAliasMacro;
      TimingsAndTextsStringGrid.Cells[3, row] := timingrec.Comment;
      TimingsAndTextsStringGrid.Cells[4, row] := IntToStr(timingrec.CustomUniformValue);
      TimingsAndTextsStringGrid.Cells[5, row] := IntToStr(Ord(timingrec.KeepPrevText));
      TimingsAndTextsStringGrid.Cells[6, row] := EscapeText(timingrec.Text);
    end;

  finally
    contents.Free;
    file_lines.Free;
  end;
end;

procedure TTimingsAndTextsEditorForm.SaveTexts;
var
  file_lines : TStringList;
  contents : TTimingsAndTextsFileContents;
  timingrec : TTimingsAndTextsRowRec;
  i, row, numrows : Integer;
  widechar_warning : Boolean;
begin
  // the engine object is needed to get the time divider
  if not Assigned(FEngine) then
    raise Exception.Create('Cannot SaveTexts without engine');

  file_lines := TStringList.Create;
  contents := TTimingsAndTextsFileContents.Create;
  file_lines.LoadFromFile(FFilePath);
  try
    // Update strings from grid
    numrows := TimingsAndTextsStringGrid.RowCount - TimingsAndTextsStringGrid.FixedRows;
    for i := 0 to numrows-1 do
    begin
      row := TimingsAndTextsStringGrid.FixedRows + i;

      Initialize(timingrec);
      timingrec.GenerateData := (TimingsAndTextsStringGrid.Cells[0, row] <> '0');
      timingrec.Time := StrToFloatDef(TimingsAndTextsStringGrid.Cells[1, row], -1);
      timingrec.TimeAliasMacro := TimingsAndTextsStringGrid.Cells[2, row];
      timingrec.Comment := TimingsAndTextsStringGrid.Cells[3, row];
      timingrec.CustomUniformValue := StrToIntDef(TimingsAndTextsStringGrid.Cells[4, row], 0);
      timingrec.KeepPrevText := (TimingsAndTextsStringGrid.Cells[5, row] <> '0');
      timingrec.Text := UnEscapeText(TimingsAndTextsStringGrid.Cells[6, row]);

      contents.AddTimingRec(timingrec);
    end;


    // Update the lines with new stuff
    widechar_warning := false;
    contents.ReplaceTimingsAndTextsInAsmLines(file_lines, (FEngine as TEngine).TimeDivider, WidecharTextsCheckBox.Checked, widechar_warning);

    if widechar_warning then
    begin
      if MessageDlg('Non-ASCII characters detected. Would you like to turn on the widechar option?', mtWarning, mbYesNo, 0) = mrYes then
      begin
        WidecharTextsCheckBox.Checked := true;
        contents.ReplaceTimingsAndTextsInAsmLines(file_lines, (FEngine as TEngine).TimeDivider, WidecharTextsCheckBox.Checked, widechar_warning);
      end;
    end;

    // Overwrite the old file with the updated lines
    file_lines.SaveToFile(FFilePath);

    SetAutoRebuildNeeded(true);

  finally
    contents.Free;
    file_lines.Free;
  end;
end; // TTimingsAndTextsEditorForm.SaveTexts

procedure TTimingsAndTextsEditorForm.SetAutoRebuildNeeded(AValue: Boolean);
begin
  if AValue then
    MainForm.SetAutoRebuildNeeded(AValue);
end;

procedure TTimingsAndTextsEditorForm.DirectoryMoved(AOldDir, ANewDir: String);
var
  p : String;
begin
  p := ForceProjectDirectoryFormat(ExtractFileDir(FFilePath));
  if (p = AOldDir) then
    FFilePath := ForceProjectDirectoryFormat(ANewDir) + ExtractFileName(FFilePath);
end;

procedure TTimingsAndTextsEditorForm.UpdatePreview;
var
  current_text_ptr : Pointer;
begin
  if FEngine = nil then Exit;
  if FPreviewPaintBoxResizePending then PreviewPanelResize(Self);
  current_text_ptr := FEngine.GetTextPtr;
  if current_text_ptr <> FLastStringPtrUpdatedToPreview then
    FLastStringPtrUpdatedToPreview := current_text_ptr;
//  if (FLastStringPtrUpdatedToPreview <> nil) then
  FEngine.DrawTextsBitmapToPaintBox(PreviewPaintBox);
end;

end.

