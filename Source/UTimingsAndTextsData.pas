unit UTimingsAndTextsData;
// Compofiller Studio by Yzi

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type

  TTimingsAndTextsRowRec = record
    GenerateData : Boolean; // if the line is commented out, it won't generate data, but it will show in the editor
    Time : Single;
    TimeAliasMacro : String; // even if the line doesn't generate data, it can be used as an alias macro
    Comment : String;
    CustomUniformValue : Integer;
    KeepPrevText : Boolean; // with "keep previous text" the editor will ignore the specified text string and generate a pointer to the same string as the previous line
    Text : String;
  end;
  PTimingsAndTextsRowRec = ^TTimingsAndTextsRowRec;


  { TTimingsAndTextsFileContents }

  TTimingsAndTextsFileContents = class(TObject)
  private
    // HOW THIS WORKS
    //
    // *** WHEN LOADING TO THE EDITOR GRID ***
    //  L0. Create new TimingsAndStringsFileContents object
    //  L1. Current .inc file on disk ---> (LoadLinesFromFile) ---> (ALines : TStrings somewhere in the caller)
    //  L2. FLines ---> (ParseLinesToStrings) ---> FStrings
    //  L3. FLines ---> (ParseLinesToTimings) ---> FTimings
    //  L4. (now the full timings can be read and fed into the editor grid)
    //  L5. Destroy the TimingsAndStringsFileContents object
    //
    // (...then the user edits the stuff in the editor grid, and perhaps wants to save the edited stuff...)
    //
    // *** WHEN SAVING TO THE .INC FILE ***
    //  S0. Create new TimingsAndStringsFileContents object
    //  S1. Old, to-be-updated .inc file on disk ---> (LoadLinesFromFile) ---> (ALines : TStrings somewhere in the caller)
    //  S2. For each timing/string row in the grid: InsertTimingLine()
    //  S3. UpdateLinesWithNewTimings
    //  S4. SaveLinesToFile
    //  S5. Destroy the TimingsAndStringsFileContents object

    FStrings : TStringList;
    FTimingsAndTextsRecords : array of TTimingsAndTextsRowRec;
    function GetTimingsAndTextsRecords(idx : Integer): TTimingsAndTextsRowRec;
    function GetTimingsAndTextsRecordsCount: Integer;
    procedure WriteStringsToAsmLines(AStringsLines: TStrings; AUseWideChars : Boolean; var AWideCharWarning : Boolean);
    procedure WriteTimingsToAsmLines(ATimingsLines: TStrings; AStrings: TStrings; ATimeDivider: Single);
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure FindLineIndicesFromAsmLines(ALines : TStrings; out AStringsStartLineIdx, AStringsEndLineIdx, ATimingsStartLineIdx, ATimingsEndLineIdx : Integer);
    procedure ParseStringsFromAsmLines(ALines : TStrings);
    procedure ParseTimingsFromAsmLines(ALines : TStrings);
    procedure AddTimingRec(ATimingRec: TTimingsAndTextsRowRec);
    procedure ReplaceTimingsAndTextsInAsmLines(ALines: TStrings; ATimeDivider: Single; AUseWideChars : Boolean; var AWideCharWarning : Boolean);

    property TimingsAndTextsRecords[idx : Integer] : TTimingsAndTextsRowRec read GetTimingsAndTextsRecords;
    property TimingsAndTextsRecordsCount : Integer read GetTimingsAndTextsRecordsCount;
  end;


implementation

function IndexOfFirstLineContainingString(AStrings : TStrings; ASearchForString : String) : Integer;
var
  i : Integer;
begin
  Result := -1;
  for i := 0 to AStrings.Count - 1 do
    if Pos(ASearchForString, AStrings[i]) > 0 then
    begin
      Result := i;
      Exit;
    end;
end;


function GetTagValue(ALine, ATag : String) : String;
var
  tagpos : Integer;
  i : Integer;
begin
  Result := '';
  tagpos := Pos(ATag, ALine);
  if tagpos <= 0 then Exit;
  if Length(ALine) <= (tagpos + Length(ATag)) then Exit;
  i := tagpos + Length(ATag);
  if ALine[i] <> '(' then Exit;
  Inc(i);
  while (i <= Length(ALine)) and (ALine[i]<>')') do
  begin
    Result := Result + ALine[i];
    Inc(i);
  end;
end;

procedure GetTwoCommaSeparatedValues(const AString : String; out AStringPart1, AStringPart2 : String);
var
  commapos : Integer;
begin
  commapos := Pos(',', AString);
  if commapos <= 0 then
  begin
    AStringPart1 := AString;
    AStringPart2 := '';
  end
  else
  begin
    AStringPart1 := Copy(AString, 1, commapos-1);
    AStringPart2 := Copy(AString, commapos+1, Length(AString)-commapos);
  end;
end;

procedure GetThreeCommaSeparatedValues(const AString : String; out AStringPart1, AStringPart2, AStringPart3 : String);
var
  s : String;
begin
  GetTwoCommaSeparatedValues(AString, AStringPart1, s);
  GetTwoCommaSeparatedValues(s, AStringPart2, AStringPart3);
end;

// Convert NASM/YASM string literal to String. Either 'foobar' or a bunch of comma-separated numbers.
// Hex numbers not yet supported.
function ConvertAsmToString(AInput : String) : String;
var
  i : Integer;
  trimmed, s : String;
  sl : TStringList;
begin
  Result := '';
  trimmed := Trim(AInput); // remove whitespace from start and end
  if Length(trimmed) < 2 then
    raise Exception.Create('Invalid asm string ' + AInput);
  if trimmed[1]='''' then
  begin // string in hyphens
    if trimmed[Length(trimmed)] <> '''' then // last char has to be a hyphen too
      raise Exception.Create('Invalid asm string ' + AInput);
    Result := Copy(trimmed, 2, Length(trimmed)-2);
    Result := StringReplace(Result, '\n', #13#10, [rfReplaceAll]);
  end
  else
  begin // list of numbers
    sl := TStringList.Create;
    try // construct a string from comma-separated numbers
      sl.Delimiter := ',';
      sl.DelimitedText := trimmed;
      for i := 0 to sl.Count-1 do
      begin
        s := sl[i];
        if s <> '' then
          Result := Result + UTF8Encode(WideChar(StrToInt(s)))
        else
          raise Exception.Create('Invalid stuff in asm string' + AInput);
      end;
    finally
      sl.Free;
    end;
  end;
end; // function ConvertAsmToString

function AllCharsGoNicelyToAsmString(AUnicodeString : UnicodeString) : Boolean;
var
  i : Integer;
begin
  Result := true;
  for i := 1 to Length(AUnicodeString) do
  begin
    if (Ord(AUnicodeString[i]) < 32) or (Ord(AUnicodeString[i]) > 127) or (AUnicodeString[i] in ['''', '"', '\', '?', '`'])
    then
    begin
      Result := false;
      Exit;
    end;
  end;
end;

function ConvertStringToAsm(AString : String; AUseWideChars : Boolean; var AWideCharWarning : Boolean) : String;
var
  i : Integer;
  ucs : UnicodeString;
  nice : Boolean;
begin
  ucs := UTF8Decode(AString);

  nice := AllCharsGoNicelyToAsmString(ucs);
  if not AUseWideChars and nice then
  begin
    Result := '''' + AString + '''';
  end
  else
  begin
    if not AUseWideChars and not nice then
      AWideCharWarning := true;

    Result := '';
    for i := 1 to Length(ucs) do
    begin
      if i > 1 then
        Result := Result + ', ';
      // Result := Result + IntToStr(Ord(AString[i]));
      Result := Result + IntToStr(Ord(ucs[i]));
    end;
  end;
end;


const
    DEFINE_TIMING_TAG = 'DEFINE_TIMING';
    TIMING_TIME_TAG = 'TIMING_TIME';
    TIMING_ALIAS_TAG = 'TIMING_ALIAS';
    TIMING_CUSTOM_TAG = 'TIMING_CUSTOM';
    TIMING_STRING_TAG = 'TIMING_STRING';


function ConvertTimingLineToRec(ALine : String; AStrings : TStrings) : TTimingsAndTextsRowRec;
var
  trimmed : String;
  timing_time, timing_alias, timing_custom, timing_string, timing_comment : String;
  semicolon_pos : Integer;
  timing_time_part_1, timing_time_part_2, timing_time_part_3,
  timing_string_part_1, timing_string_part_2 : String;
begin
  FillChar(Result, SizeOf(Result), 0);
  trimmed := Trim(ALine);
  if Length(trimmed) < 10 then
    raise Exception.Create('Invalid timing line ' + ALine);
  if trimmed[1] = ';' then
  begin // line is entirely commented out, so it's a "don't generate data" line
    trimmed := Trim(Copy(trimmed, 2, Length(trimmed)-1));
    Result.GenerateData := false
  end
  else
    Result.GenerateData := true;

  if Pos(DEFINE_TIMING_TAG, trimmed) <> 1 then
    raise Exception.Create(DEFINE_TIMING_TAG + ' is missing, invalid timing line ' + ALine);

  timing_time := GetTagValue(trimmed, TIMING_TIME_TAG);
  timing_alias := GetTagValue(trimmed, TIMING_ALIAS_TAG);
  timing_custom := GetTagValue(trimmed, TIMING_CUSTOM_TAG);
  timing_string := GetTagValue(trimmed, TIMING_STRING_TAG);
  semicolon_pos := Pos(';', trimmed);
  if semicolon_pos >= 1 then
    timing_comment := Trim(Copy(trimmed, semicolon_pos+1, Length(trimmed)-semicolon_pos))
  else
    timing_comment := '';
  GetThreeCommaSeparatedValues(timing_time, timing_time_part_1, timing_time_part_2, timing_time_part_3);
  GetTwoCommaSeparatedValues(timing_string, timing_string_part_1, timing_string_part_2);
  Result.Comment := timing_comment;
  Result.CustomUniformValue := StrToInt(timing_custom);
  Result.KeepPrevText := (timing_string_part_1 <> '0');
  Result.Text := AStrings.Values[timing_string_part_2];
  Result.Time := StrToIntDef(timing_time_part_1, 0) + StrToFloatDef(timing_time_part_2, 0.0);
  Result.TimeAliasMacro := ConvertAsmToString(timing_alias);
end;

function FindStringsNameForValue(AStrings : TStrings; AValue : String) : String;
var
  i : Integer;
begin
  Result := '';
  for i := 0 to AStrings.Count - 1 do
  begin
    if AStrings.ValueFromIndex[i] = AValue then
    begin
      Result := AStrings.Names[i];
      Exit;
    end;
  end;
end;

function CleanCommentForAsm(AString : String) : String;
var
  i : Integer;
begin
  Result := '';
  for i := 1 to Length(AString) do
  begin
    if AString[i] >= Chr(32) then
      Result := Result + AString[i];
  end;
end;

// DEFINE_TIMING TIMING_TIME(5,0.00000,441000) TIMING_ALIAS('') TIMING_CUSTOM(0) TIMING_STRING(0,_string2)  ;    this is a komment
//; DEFINE_TIMING TIMING_TIME(6,0.00000,529200) TIMING_ALIAS('') TIMING_CUSTOM(0) TIMING_STRING(0,_string3)  ;    this timing line is not active at all
//DEFINE_TIMING TIMING_TIME(7,0.00000,617400) TIMING_ALIAS('') TIMING_CUSTOM(0) TIMING_STRING(0,_string4)  ;    eiruhigegiuerh
function ConvertTimingRecToAsmLine(ARec : TTimingsAndTextsRowRec; AStrings : TStrings; ATimeDivider : Single) : String;
var
  timesum : Single;
  string_name : String;
begin
  DecimalSeparator := '.';
  if ARec.GenerateData then
    Result := ''
  else
    Result := '; ';
  timesum := ARec.Time;
  string_name := FindStringsNameForValue(AStrings, ARec.Text);
  Result := Result +
    DEFINE_TIMING_TAG + ' '
     + TIMING_TIME_TAG + '(' + IntToStr(Trunc(Int(timesum))) + ',' + FloatToStrF(Frac(timesum), ffFixed, 9, 5) + ',' + IntToStr(Trunc(timesum * ATimeDivider)) + ') '
     + TIMING_ALIAS_TAG + '(''' + ARec.TimeAliasMacro + ''') '
     + TIMING_CUSTOM_TAG + '(' + IntToStr(ARec.CustomUniformValue) + ') '
     + TIMING_STRING_TAG + '(' + IntToStr(Integer(ARec.KeepPrevText)) + ',' + string_name + ') '
     + ' ; ' + CleanCommentForAsm(ARec.Comment);
end;


constructor TTimingsAndTextsFileContents.Create;
begin
  //FLines := TStringList.Create;
  FStrings := TStringList.Create;

//  FStringsStartLineIdx := -1;
//  FStringsEndLineIdx := -1;
//  FTimingsStartLineIdx := -1;
//  FTimingsEndLineIdx := -1;
end;

destructor TTimingsAndTextsFileContents.Destroy;
begin
  FreeAndNil(FStrings);
  //FreeAndNil(FLines);

  inherited;
end;

{function TTimingsAndTextsFileContents.GetLines(Idx : Integer): String;
begin
  if (Idx < 0) or (Idx >= FLines.Count) then
    raise ERangeError.CreateFmt('Invalid timings and strings line index %d', [Idx]);
  Result := FLines[Idx];
end;}

function TTimingsAndTextsFileContents.GetTimingsAndTextsRecords(idx : Integer
  ): TTimingsAndTextsRowRec;
begin
  Result := FTimingsAndTextsRecords[Low(FTimingsAndTextsRecords) + idx];
end;

function TTimingsAndTextsFileContents.GetTimingsAndTextsRecordsCount: Integer;
begin
  Result := Length(FTimingsAndTextsRecords);
end;

const
  DEFINE_STRING = 'DEFINE_STRING';
  END_STRING = 'END_STRING';
  STRING_BASE_NAME = '_string';

procedure TTimingsAndTextsFileContents.WriteStringsToAsmLines(AStringsLines : TStrings; AUseWideChars : Boolean; var AWideCharWarning : Boolean);
var
  i : Integer;
  line, string_name, string_body, string_body_asm : String;
begin
  AStringsLines.Clear;
  for i := 0 to FStrings.Count - 1 do
  begin
    string_name := FStrings.Names[i];
    string_body := FStrings.ValueFromIndex[i];
    string_body_asm := ConvertStringToAsm(string_body, AUseWideChars, AWideCharWarning);
    line := string_name + ': ' + DEFINE_STRING + ' ' + string_body_asm + ' ' + END_STRING;
    AStringsLines.Add(line);
  end;
end; // TTimingsAndTextsFileContents.WriteStringsToAsmLines

procedure TTimingsAndTextsFileContents.WriteTimingsToAsmLines(ATimingsLines : TStrings; AStrings : TStrings; ATimeDivider : Single);
var
  i : Integer;
  r, prevrec : TTimingsAndTextsRowRec;
  line : String;
begin
  Initialize(prevrec);
  ATimingsLines.Clear;
  for i := Low(FTimingsAndTextsRecords) to High(FTimingsAndTextsRecords) do
  begin
    r := FTimingsAndTextsRecords[i];
    if r.KeepPrevText then r.Text := prevrec.Text;
    line := ConvertTimingRecToAsmLine(r, AStrings, ATimeDivider);
    ATimingsLines.Add(line);
    prevrec := r;
  end;
end; // TTimingsAndTextsFileContents.WriteTimingsToAsmLines

procedure TTimingsAndTextsFileContents.ParseStringsFromAsmLines(ALines : TStrings);
var
  i, colonpos, defpos, endpos : Integer;
  line, string_body, string_name : String;
  strings_start_line_idx, strings_end_line_idx, timings_start_line_idx, timings_end_line_idx : Integer;
begin
    // käy läpi strings-rivit, parsi elementeiksi, syötä strings-listaan
  Self.FindLineIndicesFromAsmLines(ALines, strings_start_line_idx, strings_end_line_idx, timings_start_line_idx, timings_end_line_idx);

  FStrings.Clear;
  for i := strings_start_line_idx + 1 to strings_end_line_idx - 1 do
  begin
    line := Trim(ALines[i]);
    // _string0: DEFINE_STRING 'TEH CREW' END_STRING
    colonpos := Pos(':', line);
    defpos := Pos(DEFINE_STRING, line);
    endpos := Pos(END_STRING, line);
    if not ((colonpos >= 2) and (defpos > colonpos) and (endpos > defpos)) then
      raise Exception.CreateFmt('Invalid line %d in timings and texts file.', [i+1]);
    string_name := Copy(line, 1, colonpos-1);
    string_body := ConvertAsmToString(Copy(line, defpos+Length(DEFINE_STRING), endpos-defpos-Length(DEFINE_STRING)));

    if FStrings.IndexOfName(string_name) >= 0 then
      raise Exception.CreateFmt('Invalid timings and texts file, duplicate string name %s', [string_name]);
    FStrings.Values[string_name] := string_body;
  end;
end; // TTimingsAndTextsFileContents.ParseStringsFromAsmLines

procedure TTimingsAndTextsFileContents.ParseTimingsFromAsmLines(ALines : TStrings);
var
  i, recidx, newcount : Integer;
  line : String;
  timingrec : TTimingsAndTextsRowRec;
  strings_start_line_idx, strings_end_line_idx, timings_start_line_idx, timings_end_line_idx : Integer;
begin
  Self.FindLineIndicesFromAsmLines(ALines, strings_start_line_idx, strings_end_line_idx, timings_start_line_idx, timings_end_line_idx);
  newcount := timings_end_line_idx - timings_start_line_idx - 1;
  if newcount < 0 then
    raise Exception.Create('Error buggendaali est');
  SetLength(FTimingsAndTextsRecords, newcount);
  recidx := 0;
  for i := timings_start_line_idx + 1 to timings_end_line_idx - 1 do
  begin
    line := ALines[i];
    // _string0: DEFINE_STRING 'TEH CREW' END_STRING
    timingrec := ConvertTimingLineToRec(line, FStrings);
    FTimingsAndTextsRecords[recidx] := timingrec;
    Inc(recidx);
  end;
end;


procedure TTimingsAndTextsFileContents.FindLineIndicesFromAsmLines(ALines : TStrings;
  out AStringsStartLineIdx, AStringsEndLineIdx, ATimingsStartLineIdx, ATimingsEndLineIdx : Integer
);
begin
  AStringsStartLineIdx := IndexOfFirstLineContainingString(ALines, '__STRINGS_START__');
  AStringsEndLineIdx := IndexOfFirstLineContainingString(ALines, '__STRINGS_END__');
  ATimingsStartLineIdx := IndexOfFirstLineContainingString(ALines, '__TIMINGS_START__');
  ATimingsEndLineIdx := IndexOfFirstLineContainingString(ALines, '__TIMINGS_END__');
  if (AStringsEndLineIdx <= AStringsStartLineIdx) or (AStringsStartLineIdx < 1) then
    raise Exception.Create('Invalid strings start/end');
  if (ATimingsEndLineIdx <= ATimingsStartLineIdx) or (ATimingsStartLineIdx < 1) then
    raise Exception.Create('Invalid timings start/end');
  if (ATimingsStartLineIdx <= AStringsEndLineIdx) then
    raise Exception.Create('Invalid stuff in asm lines! Strings must come BEFORE timings.');
end;


procedure TTimingsAndTextsFileContents.AddTimingRec(ATimingRec : TTimingsAndTextsRowRec);
var
  string_name : String;
begin
  // Is the text string already in FStrings?
  string_name := FindStringsNameForValue(FStrings, ATimingRec.Text);
  if string_name = '' then
  begin // not found - add the string
    string_name := STRING_BASE_NAME + IntToStr(FStrings.Count);
    FStrings.Values[string_name] := ATimingRec.Text;
  end;

  SetLength(FTimingsAndTextsRecords, Length(FTimingsAndTextsRecords)+1);
  FTimingsAndTextsRecords[Length(FTimingsAndTextsRecords)-1] := ATimingRec;
end;

procedure TTimingsAndTextsFileContents.ReplaceTimingsAndTextsInAsmLines(ALines : TStrings; ATimeDivider : Single; AUseWideChars : Boolean; var AWideCharWarning : Boolean);
var
  new_asm_strings, new_asm_timings : TStringList; // updated strings
  strings_start_line_idx, strings_end_line_idx, timings_start_line_idx, timings_end_line_idx : Integer;
  i : Integer;
begin
  // Before calling this routine, the strings and timings have been updated into Self (with Clear + Add routines)

  Self.FindLineIndicesFromAsmLines(ALines, strings_start_line_idx, strings_end_line_idx, timings_start_line_idx, timings_end_line_idx);

  // now strings_start_line_idx etc have been updated, so we know which part of the lines to replace with new stuff

  new_asm_strings := TStringList.Create;
  new_asm_timings := TStringList.Create;
  try
    // Strings
    Self.WriteStringsToAsmLines(new_asm_strings, AUseWideChars, AWideCharWarning);

    // Timings, which point to the Strings
    Self.WriteTimingsToAsmLines(new_asm_timings, FStrings, ATimeDivider);

    // Remove old strings lines from ALines, i.e. all lines between strings_start_line_idx and strings_end_line_idx, not including the start/end lines themselves
    Self.FindLineIndicesFromAsmLines(ALines, strings_start_line_idx, strings_end_line_idx, timings_start_line_idx, timings_end_line_idx);
    for i := 1 to (strings_end_line_idx - strings_start_line_idx - 1) do
      ALines.Delete(strings_start_line_idx + 1);

    // Remove old timings lines from ALines, i.e. all lines between timings_start_line_idx, timings_end_line_idx, not including the start/end lines themselves
    Self.FindLineIndicesFromAsmLines(ALines, strings_start_line_idx, strings_end_line_idx, timings_start_line_idx, timings_end_line_idx);
    for i := 1 to (timings_end_line_idx - timings_start_line_idx - 1) do
      ALines.Delete(timings_start_line_idx + 1);

    // Insert new strings asm lines
    Self.FindLineIndicesFromAsmLines(ALines, strings_start_line_idx, strings_end_line_idx, timings_start_line_idx, timings_end_line_idx);
    for i := 1 to new_asm_strings.Count do
      ALines.Insert(strings_start_line_idx+i, new_asm_strings[i-1]);

    // Insert new timings asm lines
    Self.FindLineIndicesFromAsmLines(ALines, strings_start_line_idx, strings_end_line_idx, timings_start_line_idx, timings_end_line_idx);
    for i := 1 to new_asm_timings.Count do
      ALines.Insert(timings_start_line_idx+i, new_asm_timings[i-1]);

  finally
    new_asm_timings.Free;
    new_asm_strings.Free;
  end;
end; // TTimingsAndTextsFileContents.ReplaceTimingsAndTextsInAsmLines

end.

