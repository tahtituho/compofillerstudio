unit UBuilder;
// Compofiller Studio
// by Yzi 2017


// The TBuilder class is sort of a poor man's Make.

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  UScriptRunner;


type
  { TBuilder }

  TBuilder = class(TScriptRunner)
  public
    function HandleBuildTarget(AScriptFileName, ATargetName, ATargetCommand : String) : Boolean; override;
    function HandleVariable(const AScriptFile : String; var AVariableName, AVariableValue : String; var AWhatToDoWithThisVariable : TThingsThatCanBeDoneToAVariableInAVariableHandlerMethod) : Boolean; override;

    // The "make command" is saved to a temporary script instead of running directly,
    // so that you have the complete command available later on, if for some reason,
    // you can't or don't want to use the Compofiller Studio application. Since the
    // scripts are Makefile compatible, and all the actual compilation and linking
    // is done by external programs such as the NASM assembler and the GNU Linker,
    // you can still build your project.
    function SaveScriptToFileAndRun(AScriptFileName, AScriptText : String) : Boolean;

    function RunScriptFromFile(AFileName : String) : Boolean;
  end;


implementation

// Builds target ATargetName, using command ATargetCommand
function TBuilder.HandleBuildTarget(AScriptFileName, ATargetName, ATargetCommand : String) : Boolean;
var
  exe, params : String;
begin
  Result := false;
  exe := '';
  params := '';

  if UScriptRunner.SplitCommandLine(ATargetCommand, exe, params) then
    Exec(exe, params)
  else
  begin
    SetError('Could not split ' + ATargetCommand + ' to command/executable and its parameters.');
    Exit;
  end;

  Result := true;
  SetError('');
end;

function TBuilder.HandleVariable(const AScriptFile : String; var AVariableName, AVariableValue : String; var AWhatToDoWithThisVariable : TThingsThatCanBeDoneToAVariableInAVariableHandlerMethod) : Boolean;
begin
  // no need to do anything special
  Result := true;
end;

function TBuilder.SaveScriptToFileAndRun(AScriptFileName, AScriptText : String) : Boolean;
var
  save_current_dir : String;
  script : TStrings;
  start_time, end_time : TDateTime;
begin
  save_current_dir := GetCurrentDir;
  try
    SetCurrentDir(FWorkDirectory);

    start_time := Now();
    AddProcessOutput('---- Run script from file: ' + AScriptFileName + ' Start: ' + FormatDateTime('YYYY-MM-DD hh:mm:ss', start_time), 0);

    script := TStringList.Create;
    script.TextLineBreakStyle:=tlbsCRLF;
    script.Text := AScriptText;
    if AScriptFileName <> '' then
      script.SaveToFile(AScriptFileName);

    if Self.WorkDirectory = ''  then
      raise Exception.Create('big trouble');

    Result := RunScript(AScriptFileName, script, 0);

    script.Free;

    end_time := Now();
    AddProcessOutput('--^^ Run script from file: ' + AScriptFileName + ' End: '
      + FormatDateTime('yyyy-mm-dd hh:nn:ss', end_time)
      + ' (duration ' + FormatDateTime('hh:nn:ss', end_time-start_time) + ')', 0);

  finally
    SetCurrentDir(save_current_dir);
  end;
end; // TBuilder.SaveScriptToFileAndRun

function TBuilder.RunScriptFromFile(AFileName: String) : Boolean;
begin
  Result := inherited RunScriptFromFile(AFileName);
end;


end.

