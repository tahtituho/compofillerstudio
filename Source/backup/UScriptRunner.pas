unit UScriptRunner;
// Compofiller Studio by Yzi 2017

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows;



type
  TAddProcessOutputLineEvent = procedure(AString : String; AIndentLevel : Integer) of object;

  TThingsThatCanBeDoneToAVariableInAVariableHandlerMethod = (doNothing, doChange, doDelete);

  TScriptRunner = class;

  { TConditionalStack }

  TConditionalStackItemRec = record
    ParentStackIsTrue : Boolean; // the next higher level and all its higher level conditionals are true
    IsTrue : Boolean; // conditional evaluated as true on the definition line
    IsElse : Boolean; // if we're inside an "else" directive
  end;

  TConditionalStack = class(TObject)
  private
    FItems : array of TConditionalStackItemRec;
    FStackTop : Integer;
    function EvaluateDefinedCondition(AConditionalString: String;
      AVariables: TStrings): Boolean;
    function EvaluateEquivalenceCondition(AConditionalString: String;
      AVariables: TStrings): Boolean;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Clear;
    function UpdateAndReturnTrueIffLineIsAConditional(ALine : String; AVariables : TStrings) : Boolean;
    function ConditionIsTrueNow : Boolean;
    function ParentStackIsTrueNow : Boolean;
    function InElseNow : Boolean;
    function NumUnterminatedConditionals : Integer;
    procedure Pop;
    procedure Push(AParentIsTrue, AIsTrue, AIsElse : Boolean);
  end;

  { TScriptRunner }

  TScriptRunner = class(TObject)
  protected
    FConfigFile: String;
    FError: String;
    FVariables : TStringList;

    FOnAddProcessOutputLine: TAddProcessOutputLineEvent;
    FWorkDirectory: String;

    FProcessInfo : TProcessInformation;

    FIsDummyTarget : Boolean; // a target which isn't supposed to produce a file

    procedure AddProcessOutput(AString: String; AIndentLevel : Integer);
    function RunScriptFromFile_internal(AFileName : String; AIncludeDepth : Integer) : Boolean;
    procedure SetConfigFile(AValue: String);
    procedure SetOnAddProcessOutputLine(AValue: TAddProcessOutputLineEvent);
    procedure SetOnProcessOutputLine(AValue: TAddProcessOutputLineEvent);
    procedure SetWorkDirectory(AValue: String);

    function DosExitCode: DWORD;
    function Exec(const AFilePath, AParams : String): Integer;

    procedure SetError(AError: String);

  public
    constructor Create; virtual;
    destructor Destroy; override;

//    procedure ExpandStrings(ASource, ADestination: TStrings);

    function RunScript(AScriptFileName : String; AScript : TStrings; AIncludeDepth : Integer) : Boolean;
    function RunScriptFromFile(AFileName : String) : Boolean;

    // "Callbacks", i.e. virtual methods that the subclasses must override.
    // These methods are used so that the same script parsing code can be used
    // for many different things.
    // Script handling/running stops, if a callback returns false.
    //
    // AScriptFile : the name of the file where the variable or target was found
    function HandleBuildTarget(AScriptFile, ATargetName, ATargetCommand : String) : Boolean; virtual; abstract;

    // ASaveChanges : the handler sets to true, iff changes should be written to the script file.
    // ARemove : the handler sets to true, iff the variable assignment line shold be removed.
    function HandleVariable(const AScriptFile : String; var AVariableName, AVariableValue : String; var AWhatToDoWithThisVariable : TThingsThatCanBeDoneToAVariableInAVariableHandlerMethod) : Boolean; virtual; abstract;

    procedure SetVariable(AVariableName, AVariableValueExpression : String; AIncludeDepth : Integer);

    property OnAddProcessOutputLine : TAddProcessOutputLineEvent read FOnAddProcessOutputLine write SetOnAddProcessOutputLine;
    property WorkDirectory : String read FWorkDirectory write SetWorkDirectory;

    property Error : String read FError write SetError;

    property IsDummyTarget : Boolean read FIsDummyTarget write FIsDummyTarget;
  end; // class TScriptRunner

function RemoveQuotes(AString : String) : String;
function SplitCommandLine(ACommandLine : String; var AExecutableName, AParams : String) : Boolean;


implementation

uses
  Process, Dialogs, strutils;


const
  EXEC_OUTPUT_BUFFER_SIZE = 2048;


function RemoveQuotes(AString : String) : String;
begin
  Result := AnsiReplaceStr(AString, '"', '');
end;



function GetEnv(const EnvVar: String): String;
var
  buf : array[0..32767] of Char;
begin
  SetString(Result, buf, GetEnvironmentVariable(PChar(EnvVar), buf, SizeOf(buf)));
end;

function FindFileFromSearchPath(AFileName : String) : String;
begin
  // Try to find the given file in PATH, e.g. compiler or linker exe
  Result := FileSearch(RemoveQuotes(AFileName), GetEnv('PATH'));
  if Result <> '' then
    Result := ExpandFileName(Result);
end;


function GetValueFromStrings(AStrings : TStrings; AName : String) : String;
var
  i, np, ep : Integer;
  s : String;
begin
  Result := '';
  for i := 0 to AStrings.Count - 1 do
  begin
    s := AStrings[i];
    ep := Pos('=', s);
    np := Pos(AName, s);
    if (np = 1) and (ep > np) and (ep = (np + Length(AName))) then
    begin
      Result := Copy(s, ep+1, Length(s)-ep);
      Exit;
    end;
  end;
end;

function Strings_GetVariable(AVariables : TStrings; AVariableName : String) : String;
begin
{  if AVariableName = 'PROJECT_FILE' then
    Result := GetValueFromStrings(FVariables, AVariableName)
  else}
    Result := AVariables.Values[AVariableName];

    // undefined variables act as empty strings

//  if Result = '' then
//    raise Exception.CreateFmt('HUPSISTAKEIKKAA nysse kysyy %s mutta ei löydy.'#13'Löytyy vain:'#13'%s', [AVariableName, AVariables.Text]);
end;

function Strings_ExpandVariables(AVariables : TStrings; AString: String): String;
var
  parentheses : Boolean;
  varind, i : Integer;
  variable_name, variable_value : String;
begin
  varind := Pos('$', AString);
  if varind > 0 then
  begin // contains at least one variable to be expanded
    variable_name := '';
    i := varind + 1; // skip '$'

    parentheses := ((i <= Length(AString)) and (AString[i] = '('));
    if parentheses then Inc(i); // skip '('

    while (i <= Length(AString)) and
        (
          (parentheses and (AString[i] <> ')'))
          or
          (not parentheses and (UpCase(AString[i]) in ['0'..'9', '_', 'A'..'Z', '@', '<', '^']))
        )
    do
    begin
      variable_name := variable_name + AString[i];
      Inc(i);
    end;
    if (i <= Length(AString)) and parentheses then Inc(i); // skip ')'

    if variable_name <> '' then
      variable_value := Strings_GetVariable(AVariables, variable_name)
    else
      variable_value := '';

    // Do the rest recursively.
    Result := Copy(AString, 1, varind - 1) + variable_value + Strings_ExpandVariables(AVariables, Copy(AString, i, Length(AString) - i + 1));
  end
  else
    Result := AString;
end;


{ TConditionalStack }

constructor TConditionalStack.Create;
begin
  SetLength(FItems, 10);
  FStackTop := -1;
end;

destructor TConditionalStack.Destroy;
begin
  inherited Destroy;
end;

procedure TConditionalStack.Clear;
begin
  FStackTop := -1;
end;

procedure SplitStringInTwo(AString, ASeparator : String; var AFirstPart, ASecondPart : String);
var
  p : Integer;
begin
  p := Pos(ASeparator, AString);
  if p < 1 then
  begin
    AFirstPart := AString;
    ASecondPart := '';
  end
  else
  begin
    AFirstPart := Copy(AString, 1, p-1);
    ASecondPart := Copy(AString, p + Length(ASeparator), Length(AString));
  end;
end;

function TConditionalStack.EvaluateEquivalenceCondition(AConditionalString : String; AVariables : TStrings) : Boolean;
var
  c, s, arg1, arg2, arg1_expanded, arg2_expanded : String;
begin
  c := Trim(AConditionalString);
  if Length(c) = 0 then raise Exception.Create('invalid ifeq/ifneq condition statement');
  // What kind of statement is it?
  if (Length(c) >= 5) and (c[1] = '(') and (c[Length(c)] = ')') and (Pos(',', c) >= 1) then
  begin
    s := Copy(c, 2, Length(c)-2);
    SplitStringInTwo(s, ',', arg1, arg2);
    arg1_expanded := Strings_ExpandVariables(AVariables, arg1);
    arg2_expanded := Strings_ExpandVariables(AVariables, arg2);
    Result := (arg1_expanded = arg2_expanded);
  end
  else
    raise Exception.Create('invalid or unknown equivalence condition statement');
  // other cases: todo
end;

function TConditionalStack.EvaluateDefinedCondition(AConditionalString : String; AVariables : TStrings) : Boolean;
var
  arg, arg_expanded : String;
begin
  arg := Trim(AConditionalString);
  if Length(arg) = 0 then raise Exception.Create('invalid ifdef/ifndef condition statement');
  arg_expanded := Strings_ExpandVariables(AVariables, '$('+arg+')');
  Result := (arg_expanded <> ''); // non-empty means that it is defined
end;


function TConditionalStack.UpdateAndReturnTrueIffLineIsAConditional(ALine : String; AVariables : TStrings) : Boolean;
var
  line, first_word, remainder : String;
  must_be_else_if : Boolean;
begin
  Result := false;
  must_be_else_if := false;
  line := Trim(ALine);

  SplitStringInTwo(line, ' ', first_word, remainder);
  if first_word = 'else' then
  begin
    if Self.InElseNow then
      raise Exception.Create('Multiple elses in the same conditional');
    if FStackTop < 0 then
      raise Exception.Create('Unmatched else');
    if remainder <> '' then
    begin
      Pop;
      must_be_else_if := true;
    end
    else
    begin
      // Switch true/false only if the whole stack is true. If the whole stack isn't true, then we just parse.
      if Self.ParentStackIsTrueNow then
        FItems[FStackTop].IsTrue := not FItems[FStackTop].IsTrue
      else
        if FItems[FStackTop].IsTrue then // this should never happen
          raise Exception.Create('internal error in TConditionalStack');

      FItems[FStackTop].IsElse := true;
      Result := true;
    end;
    line := remainder;
    SplitStringInTwo(line, ' ', first_word, remainder);
  end;

  if (first_word = 'ifeq') and (remainder <> '') then
  begin
    if Self.ParentStackIsTrueNow and Self.ConditionIsTrueNow then
      Push(true, EvaluateEquivalenceCondition(remainder, AVariables), false)
    else
      Push(false, false, false);
    Result := true;
  end
  else if (first_word = 'ifneq') and (remainder <> '') then
  begin
    if Self.ParentStackIsTrueNow and Self.ConditionIsTrueNow then
      Push(true, not EvaluateEquivalenceCondition(remainder, AVariables), false)
    else
      Push(false, false, false);
    Result := true;
  end
  else if (first_word = 'ifdef') and (remainder <> '') then
  begin
    if Self.ParentStackIsTrueNow and Self.ConditionIsTrueNow then
      Push(true, EvaluateDefinedCondition(remainder, AVariables), false)
    else
      Push(false, false, false);
    Result := true;
  end
  else if (first_word = 'ifndef') and (remainder <> '') then
  begin
    if Self.ParentStackIsTrueNow and Self.ConditionIsTrueNow then
      Push(true, not EvaluateDefinedCondition(remainder, AVariables), false)
    else
      Push(false, false, false);
    Result := true;
    Result := true;
  end
  else if (first_word = 'endif') then
  begin
    if (remainder <> '') then
      raise Exception.Create('Extra text after endif.');
    if FStackTop < 0 then
      raise Exception.Create('Unmatched endif');
    Pop;
    Result := true;
  end;

  if must_be_else_if and not Result then
    raise Exception.CreateFmt('Invalid conditional: %s', [ALine]);
end; // TConditionalStack.UpdateAndReturnTrueIffLineIsAConditional

function TConditionalStack.ConditionIsTrueNow: Boolean;
begin
  Result := (FStackTop < 0) or (FItems[FStackTop].IsTrue);
end;

function TConditionalStack.ParentStackIsTrueNow: Boolean;
begin
  Result := (FStackTop < 0) or (FItems[FStackTop].ParentStackIsTrue);
end;

function TConditionalStack.InElseNow: Boolean;
begin
  if FStackTop >= 0 then
    Result := FItems[FStackTop].IsElse
  else
    Result := false;
end;

function TConditionalStack.NumUnterminatedConditionals: Integer;
begin
  Result := FStackTop + 1;
end;

procedure TConditionalStack.Pop;
begin
  if FStackTop < 0 then
    raise Exception.Create('TConditionalStack: underflow in Pop');
  Dec(FStackTop);
end;

procedure TConditionalStack.Push(AParentIsTrue, AIsTrue, AIsElse: Boolean);
begin
  Inc(FStackTop);
  if FStackTop >= Length(FItems) then
    SetLength(FItems, FStackTop + 1);
  FItems[FStackTop].ParentStackIsTrue := AParentIsTrue;
  FItems[FStackTop].IsElse := AIsElse;
  FItems[FStackTop].IsTrue := AIsTrue;
end;


{ TScriptRunner }

procedure TScriptRunner.AddProcessOutput(AString : String; AIndentLevel : Integer);
begin
  if (FOnAddProcessOutputLine <> nil) then
    FOnAddProcessOutputLine(AString, AIndentLevel);
end;

procedure TScriptRunner.SetOnAddProcessOutputLine(AValue: TAddProcessOutputLineEvent
  );
begin
  if FOnAddProcessOutputLine=AValue then Exit;
  FOnAddProcessOutputLine:=AValue;
end;

function TScriptRunner.Exec(const AFilePath, AParams : String): Integer;
var
  exepath : String;
//  cmdline : String;
  output_buffer : array[1..EXEC_OUTPUT_BUFFER_SIZE] of Byte;
  process : TProcess;
  output_stream : TMemoryStream;
  bytes_read, i : Integer;
  c : Char;
  s : String;
begin
  process := TProcess.Create(nil);
  output_stream := nil;

  try
    exepath := FindFileFromSearchPath(AFilePath); // <-- this removes quotes
    if not FileExists(exepath) then
      raise Exception.CreateFmt('%s not found.', [AFilePath]);

    if (exepath <> '') and (exepath[1] <> '"')  then
        exepath := '"' + exepath + '"'; // ... and this adds them back!

//    process.Executable := exepath;
//    process.Parameters.Add(AParams);
    process.CommandLine := exepath + ' ' + AParams;
    process.Options := [poUsePipes, poStderrToOutput];
    process.ShowWindow := swoHIDE;

    // Display the command line we're about to execute.
    AddProcessOutput('> ' + process.CommandLine, 0);

    process.Execute;
    if process.Output = nil then raise Exception.Create('aaargh');

    output_stream := TMemoryStream.Create;

    i := 0;
    s := '';
    repeat
      bytes_read := process.Output.Read(output_buffer, SizeOf(output_buffer));

      output_stream.Write(output_buffer, bytes_read);
      while i < output_stream.Size do
      begin
        c := PChar(output_stream.Memory)[i];
        case c of
          #13 : begin
            AddProcessOutput(s, 0);
            s := '';
          end;
          #32..#254 : begin
            s := s + c;
          end;
        end;
        Inc(i);
      end;
    until (bytes_read = 0) and not process.Running;

    AddProcessOutput(s, 0);

    Result := process.ExitCode;

  finally
    process.Free;
    output_stream.Free;
  end;
end; // TScriptRunner.Exec

constructor TScriptRunner.Create;
begin
  FVariables := TStringList.Create;
end;

destructor TScriptRunner.Destroy;
begin
  FreeAndNil(FVariables);

  inherited Destroy;
end;

procedure TScriptRunner.SetOnProcessOutputLine(AValue: TAddProcessOutputLineEvent);
begin
  if FOnAddProcessOutputLine =AValue then Exit;
  FOnAddProcessOutputLine :=AValue;
end;

procedure TScriptRunner.SetWorkDirectory(AValue: String);
begin
  if FWorkDirectory=AValue then Exit;
  FWorkDirectory:=AValue;
end;

function TScriptRunner.DosExitCode : DWORD;
begin
  Result := $FFFFFFFF;
  GetExitCodeProcess(FProcessInfo.hProcess, Result);
end;

// Splits the first space-delimited string from ACommandLine to AExecutableName and the rest to AParams.
// Returns true iff the split was done.
// If returns false, then AExecutableName and AParams have not been written.
function SplitCommandLine(ACommandLine : String; var AExecutableName, AParams : String) : Boolean;
var
  spacepos, quotepos2 : Integer;
  s, e, p : String;
begin
  Result := false; // in which case could this be the final return value?

  s := Trim(ACommandLine);

  if s = '' then
  begin
    AExecutableName := '';
    AParams := '';
    Result := true;
    Exit;
  end;

  if s[1] = '"' then
  begin
    quotepos2 := Pos('"', Copy(s, 2, Length(s)-1)) + 1;
    if quotepos2 = 1 then
    begin
      AExecutableName := s + '"';
      AParams := '';
      Result := true;
      Exit;
    end
    else
    begin
      if (Length(s) > quotepos2)
          and (s[quotepos2+1] <> ' ')
      then // Immediately following the second quote, there's something else than a space (or end-of-line)
      begin // Too ambiguous command line, like "my folder\some.exe"blaablaa
            // Is the idea to concatenate blaablaa
        Result := false;
        Exit;
      end;
      AExecutableName := Copy(s, 1, quotepos2); // stuff up to and including the second quote must be the command/executable
      AParams := Trim(Copy(s, quotepos2+2, Length(s)-quotepos2-1)); // and everything following the space after it is parameters
      Result := true;
      Exit;
    end;
  end
  else
  begin // the command line does not begin with a quote
    spacepos := Pos(' ', s);
    if spacepos > 0 then
    begin
      e := Copy(s, 1, spacepos-1);
      p := Copy(s, spacepos+1, Length(s)-spacepos);
      AExecutableName := e;
      AParams := p;
      Result := true;
    end
    else
    if s <> '' then
    begin // a non-empty command without parameters
      AExecutableName := s;
      Result := true;
    end;
  end;
end; // SplitCommandLine

procedure TScriptRunner.SetError(AError : String);
begin
  FError := AError;
end;

procedure TScriptRunner.SetConfigFile(AValue: String);
begin
  if FConfigFile=AValue then Exit;
  FConfigFile:=AValue;
end;

// Sets the value of AVariableName to AVariableValue, expanding all pre-existing variables found in AVariableValue.
// AVariableName must not contain other variable names, i.e. % or $ signs.
// All variable names must be preceded with American currency signs, like $SOMEVAR, and end at whitespace or end-of-line.
// You can also use parentheses like $(SOMEVAR), to maintain Makefile compatibility.
// Variable names are case-insensitive.
function Strings_SetVariable(AVariables : TStrings; AVariableName, AVariableValueExpression : String; AIncludeDepth : Integer) : String;
begin
  if Pos('$', AVariableName) > 0 then
    raise Exception.CreateFmt('Variable name %s contains illegal characters.', [AVariableName]);

  Result := Strings_ExpandVariables(AVariables, AVariableValueExpression);
  AVariables.Values[AVariableName] := Result;
end;


procedure TScriptRunner.SetVariable(AVariableName, AVariableValueExpression : String; AIncludeDepth : Integer);
var
  value : String;
begin
  value := Strings_SetVariable(FVariables, AVariableName, AVariableValueExpression, AIncludeDepth);

  if not ((Length(AVariableName)=1) and (AVariableName[1] in ['@', '<', '^'])) then
    AddProcessOutput('Set variable ' + AVariableName + ' = ' + value, AIncludeDepth);
end;

{
procedure TScriptRunner.ExpandStrings(ASource, ADestination : TStrings);
// This routine is just for testing how variables are expanded
var
  i, eqpos, colonpos : Integer;
  s, varname, varexp : String;
begin
  for i := 0 to ASource.Count - 1 do
  begin
    s := ASource[i];

    eqpos := Pos('=', s);
    colonpos := Pos(':', s);
    if (eqpos > 0) and (colonpos > 0) and (colonpos < eqpos) then
      raise Exception.Create('You have ''='' in a target''s prerequisites ...???');

    if eqpos > 0 then
    begin
      varname := Trim(Copy(s, 1, eqpos - 1));
      varexp := Trim(Copy(s, eqpos+1, Length(s)-eqpos));
      if varname <> '' then
      begin
        SetVariable(varname, varexp);
        ADestination.Add(varname + '=' + GetVariable(varname));
      end;
    end
    else if colonpos > 0 then
    begin
      // BUILD TARGET
    end
    else
      ADestination.Add(ExpandVariables(s));
  end;
end;
}

function TScriptRunner.RunScript(AScriptFileName : String; AScript : TStrings; AIncludeDepth : Integer) : Boolean;
  function ReadLine(var line_index : Integer; out is_indented : Boolean) : String;
  var
    cont, firstline : Boolean;
    untrimmedline, linetmp : String;
  begin
    Result := '';
    firstline := true;
    repeat
      untrimmedline := AScript[line_index];
      is_indented :=
        firstline and ((Length(untrimmedline) > 0) and (Ord(untrimmedline[1]) <= 32)); // some sort of whitespace --> the line is indented
      firstline := false;
      linetmp := Trim(untrimmedline);
      if linetmp = '' then
        cont := false
      else
        cont := (linetmp[Length(linetmp)] = '\'); // lines can be continued with backslash
      if cont then
        Result := Result + ' ' + Copy(linetmp, 1, Length(linetmp) - 1)
      else
        Result := Result + ' ' + linetmp;
      Inc(line_index);
    until (line_index >= AScript.Count) or not cont;
    Result := Trim(Result);
  end;

  procedure DeleteLines(var line_index : Integer; AFirstLineToRemove : Integer);
  begin
    while line_index > AFirstLineToRemove do
    begin
      Dec(line_index);
      AScript.Delete(line_index);
    end;
  end;

var
  // Each script file run has its own conditional stack, so e.g. included files
  // cannot "else" or "endif" a conditional started in the including file
  conditional_stack : TConditionalStack;
  linestart_index, save_line_index, line_index, line_num, eq_pos, colon_pos, hash_pos, include_pos : Integer;
  line, var_name, var_exp, target_name, target_noquotes, target_command, target_prerequisites, include_file : String;
  target_prerequisites_list : TStringList;
  b : Boolean;
  var_what_to_do : TThingsThatCanBeDoneToAVariableInAVariableHandlerMethod;
  line_is_indented, target_done : Boolean;
  old_target_file_was_renamed_to : String; // instead of deleting the old target, we rename it away
  error_message : String;
begin
  Result := false;
  line_num := -1;
  try
    conditional_stack := TConditionalStack.Create;
    try
      line_index := 0; // line_index always points to the first not-yet-read line of input
      while (line_index < AScript.Count) do
      begin
        linestart_index := line_index; // with continued multiline lines, we might need to be able to tell what was the first line index
        line_num := line_index + 1; // line_num is shown in error messages
        line := ReadLine(line_index, line_is_indented); // increases line_index !!!
        // ReadLine returns the line already trimmed, i.e. spaces removed from beginning and end

        // This "parsing" thingy is getting a bit convoluted. Maybe a proper parser is in order at some point.

        hash_pos := Pos('#', line);
        if hash_pos > 0 then // throw away everything that's in comments
          line := Copy(line, 1, hash_pos-1);

        if not conditional_stack.UpdateAndReturnTrueIffLineIsAConditional(line, FVariables) then
        begin
          if conditional_stack.ConditionIsTrueNow then
          begin

            include_pos := Pos('include ', line);
            if include_pos = 1 then
            begin // INCLUDE FILE
              include_file := Trim(
                Strings_ExpandVariables(
                  FVariables,
                  Trim(
                    Copy(line, include_pos + 8, Length(line) - 8)
                  )
                )
              );

              if include_file = '' then
                raise Exception.CreateFmt('KUKA MITÄ HÄH %s %s', [AScriptFileName, line]);

              // TODO: TÄMÄ TÄSTÄ ERILLISEEN INCLUDE-CALLBACKIIN --------------------
              if not FileExists(FWorkDirectory + include_file) then
                raise Exception.CreateFmt(
                       'Cannot include %s, file does not exist. Included in script %s, line %d:\n%s',
                       [include_file, AScriptFileName, line_num, line]);

              AddProcessOutput('Include file ' + include_file, AIncludeDepth);
              if not RunScriptFromFile_internal(FWorkDirectory + include_file, AIncludeDepth + 1) then
                Exit;
              // --------------------------------------------------------------------
            end
            else
            begin // line is not an nclude file
              eq_pos := Pos('=', line);
              colon_pos := Pos(':', line);
              if (eq_pos > 0) and (colon_pos > 0) and (colon_pos < eq_pos) then
                raise Exception.Create('You have ''='' in a target''s prerequisites ...???');
              // TODO: deferred ( = ) vs. immediate ( := ) expansion

              if eq_pos > 0 then
              begin // ***** VARIABLE ***** (SOMETHING=BLAA BLAA)
                var_name := Trim(Copy(line, 1, eq_pos - 1));
                var_exp := Trim(Copy(line, eq_pos+1, Length(line)-eq_pos));
                if var_name <> '' then
                begin
                  var_what_to_do := doNothing;
                  b := HandleVariable(AScriptFileName, var_name, var_exp, var_what_to_do);
                  case var_what_to_do of
                    doNothing : SetVariable(var_name, var_exp, AIncludeDepth); // even in "do-nothing" case, we keep the variable values updated
                    doChange : begin
                      AScript[linestart_index] := var_name + '=' + var_exp;
                      SetVariable(var_name, var_exp, AIncludeDepth);
                    end;
                    doDelete : DeleteLines(line_index, linestart_index); // if the value is deleted, then we want to keep the previous inherited value, so don't SetVariable
                  end;
                  if not b then
                    Exit; // if the handler returned false, we stop processing the script
                end;
              end // line is a variable definition
              else if colon_pos > 0 then
              begin
                // ****** BUILD TARGET ******
                target_name := Strings_ExpandVariables(FVariables, Trim(Copy(line, 1, colon_pos - 1)));
                target_prerequisites := Strings_ExpandVariables(FVariables, Trim(Copy(line, colon_pos + 1, Length(line) - colon_pos)));
                target_prerequisites_list := TStringList.Create;
                try
                  target_prerequisites_list.Delimiter := ' ';
                  target_prerequisites_list.DelimitedText := target_prerequisites;

                  SetVariable('@', target_name, AIncludeDepth);
                  if target_prerequisites_list.Count > 0 then
                    SetVariable('<', target_prerequisites_list[0], AIncludeDepth)
                  else
                    SetVariable('<', '', AIncludeDepth);
                  SetVariable('^', target_prerequisites, AIncludeDepth);

                  if target_name = '' then
                    raise Exception.CreateFmt('Empty target name in %s, line %d', [AScriptFileName, line_num]);

                  if line_index >= AScript.Count then
                    raise Exception.CreateFmt('Sudden end of file? It would have been interesting to know how to build %s.', [target_name]);


                  target_done := false;
                  target_noquotes := RemoveQuotes(target_name);

                  if FileExists(target_noquotes) then
                  begin
                    old_target_file_was_renamed_to := SysUtils.GetTempFileName();
                    RenameFile(target_noquotes, old_target_file_was_renamed_to);
                  end
                  else
                  begin
                    old_target_file_was_renamed_to := '';
                  end;

                  try

                    repeat
                      line := ReadLine(line_index, line_is_indented);
                      target_command := Strings_ExpandVariables(FVariables, line);

                      // probe next line
                      if line_index >= AScript.Count then // end?
                        target_done := true
                      else
                      begin
                        save_line_index := line_index;
                        line := ReadLine(line_index, line_is_indented);
                        target_done := (line = '') or (not line_is_indented);
                        line_index := save_line_index;
                      end;

                      if not HandleBuildTarget(AScriptFileName, target_name, target_command) then
                      begin
                        AddProcessOutput('*** Error: could not execute command ' + target_command + ' for target ' + target_name + ' ***', AIncludeDepth);
                        Exit;
                      end;
                    until target_done;

                    if not FileExists(target_noquotes)
                    and not FIsDummyTarget
                    then // target file wasn't created?
                    begin
                      AddProcessOutput('*** Error: could not build ' + target_name + ' *** (file did not appear on disk as result of build commands)', AIncludeDepth);
                      Exit;
                    end;

                  finally
                    if (old_target_file_was_renamed_to <> '') then
                      if FileExists(target_noquotes) then
                        // if we were able to build, delete the old file
                        DeleteFile(PChar(old_target_file_was_renamed_to))
                      else
                        // if we couldn't build, then rename back the old file
                        RenameFile(old_target_file_was_renamed_to, target_noquotes)
                  end;

                finally
                  target_prerequisites_list.Free;
                end;
              end
              else if (Length(line) > 0) and not (line[1] = '#') then
                raise Exception.CreateFmt('Cannot understand build script line %d', [line_index]);
            end; // not "include " line
          end; // current conditional is true, or we're in unconditional area
        end; // line is not a conditional definition
      end; // while

      if conditional_stack.NumUnterminatedConditionals > 0 then
        raise Exception.Create('Unterminated conditional.'); // TODO: "started on line %d"

    finally
      conditional_stack.Free;
    end;

    Result := true;

  except
    on e : Exception do
    begin
      error_message := Format(
          '*** ERROR *** %s in file %s line %d: %s',
          [e.ClassName, AScriptFileName, line_num, e.Message]
        );
      if Assigned(FOnAddProcessOutputLine) then
        // if we're running a script whose output goes to the text log visible to the user, add the error there
        AddProcessOutput(error_message, AIncludeDepth)
      else
        // otherwise raise it
        raise Exception.Create(error_message);
    end;
  end;
end; // TScriptRunner.RunScript

function TScriptRunner.RunScriptFromFile_internal(AFileName : String; AIncludeDepth : Integer) : Boolean;
var
  script : TStrings;
begin
  script := TStringList.Create;
  script.LoadFromFile(AFileName);
  Result := RunScript(AFileName, script, AIncludeDepth);
  script.Free;
end; // TScriptRunner.RunScriptFromFile_internal

function TScriptRunner.RunScriptFromFile(AFileName : String) : Boolean;
var
  save_current_dir : String;
  start_time, end_time : TDateTime;
begin
  if FWorkDirectory <> '' then save_current_dir := GetCurrentDir;
  try
    if FWorkDirectory <> '' then SetCurrentDir(FWorkDirectory);

    start_time := Now();
    AddProcessOutput('---- Run script from file: ' + AFileName + ' Start: ' + FormatDateTime('YYYY-MM-DD hh:mm:ss', start_time), 0);

    Result := RunScriptFromFile_internal(AFileName, 0);

    end_time := Now();
    AddProcessOutput('--^^ Run script from file: ' + AFileName + ' End: '
      + FormatDateTime('yyyy-mm-dd hh:nn:ss', end_time)
      + ' (duration ' + FormatDateTime('hh:nn:ss', end_time-start_time) + ')', 0);

  finally
    if FWorkDirectory <> '' then SetCurrentDir(save_current_dir);
  end;
end; // TScriptRunner.RunScriptFromFile


end.

