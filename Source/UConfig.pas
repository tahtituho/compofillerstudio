unit UConfig;
// Compofiller Studio
// by Yzi 2017

// Kludge warning. Do not look at this file. Go away.

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  UScriptRunner;

type

  { TConfig }

  TReason = (rToGetAVariableValue, rToSetAVariableValue);

  TConfig = class(TScriptRunner)
  private
    FFileName: String;
    FWhyIAmGoingThroughThisScript : TReason;
    FVariableNameToFind : String;
    FVariableValueToSet : String;
    FNextToLastEncounteredVariableValue : String; // "parent value" i.e. next-to-last encountered value
    FNextToLastEncounteredVariableInScript : String; // and where that parent value is from
    FLastEncounteredVariableValue : String;
    FLastEncounteredVariableInScript : String;
    FAcceptVariablesInIncludedScripts : Boolean;
    FRemoveEmptyVariablesIfThereIsAnInheritedValue : Boolean;
    FStopProcessingScriptsAtFirstEncounterThatMatches_ALL_CRITERIA_InParticularTheInheritanceStatusThingy : Boolean;

    procedure SetFileName(AValue: String);
    procedure SetRemoveEmptyVariablesIfThereIsAnInheritedValue(AValue: Boolean);

    procedure SetVariableValue_internal(AVariableName, AVariableValue : String; AIncludeDepth : Integer);

  public
    constructor Create; override;

    function HandleBuildTarget(AScriptFileName, ATargetName, ATargetCommand: String): Boolean; override;
    function HandleVariable(const AScriptFileName : String; var AVariableName, AVariableValue : String; var AWhatToDoWithThisVariable : TThingsThatCanBeDoneToAVariableInAVariableHandlerMethod) : Boolean; override;

    procedure GetVariableValue(const AVariableName : String; var AFoundValue, AFoundInScript : String; ARunAllIncludedScriptsCompletelyToGetFinalEffectiveValue : Boolean);
    procedure GetVariableValueAndItsInheritedValue(const AVariableName : String; var AFoundValue, AFoundInScript, AInheritedValue, AInheritedValueScript : String; ARunAllIncludedScriptsCompletelyToGetFinalEffectiveValue : Boolean);

    procedure SetVariableValue(AVariableName, AVariableValue : String);

    property FileName : String read FFileName write SetFileName;
    property RemoveEmptyVariablesIfThereIsAnInheritedValue : Boolean read FRemoveEmptyVariablesIfThereIsAnInheritedValue write SetRemoveEmptyVariablesIfThereIsAnInheritedValue;
  end; // class TConfig

implementation

procedure TConfig.SetFileName(AValue: String);
begin
  if FFileName=AValue then Exit;
  FFileName:=AValue;
end;

procedure TConfig.SetRemoveEmptyVariablesIfThereIsAnInheritedValue(
  AValue: Boolean);
begin
  if FRemoveEmptyVariablesIfThereIsAnInheritedValue=AValue then Exit;
  FRemoveEmptyVariablesIfThereIsAnInheritedValue:=AValue;
end;

procedure TConfig.SetVariableValue_internal(AVariableName,
  AVariableValue: String; AIncludeDepth: Integer);
var
  save_current_dir : String;
  script : TStrings;
begin
  AVariableValue := Trim(AVariableValue);
  if FWorkDirectory <> '' then
    save_current_dir := GetCurrentDir;
  try
    if FWorkDirectory <> '' then
      SetCurrentDir(FWorkDirectory);

    script := TStringList.Create;
    script.LoadFromFile(FFileName);

    FWhyIAmGoingThroughThisScript := rToSetAVariableValue;
    FVariableNameToFind := AVariableName;

    FNextToLastEncounteredVariableInScript := '';
    FLastEncounteredVariableInScript := '';
    FVariableValueToSet := AVariableValue;
    FAcceptVariablesInIncludedScripts := false;
    FStopProcessingScriptsAtFirstEncounterThatMatches_ALL_CRITERIA_InParticularTheInheritanceStatusThingy := true;

    if Self.RunScript(FFileName, script, 0) then
      if (ExtractFileName(FLastEncounteredVariableInScript) <> ExtractFileName(FFileName))
          and (AVariableValue<>'')
      then
      begin
        // The script run was able to finish, and the variable wasn't found in
        // the given file or any included file. And the new value to set isn't empty.
        // We'll add the new variable to the end of the script.
        script.Add(AVariableName + '=' + AVariableValue);
      end;
    // And save the changed file.
    script.SaveToFile(FFileName);

    script.Free;

    AddProcessOutput(Format('Set file %s variable %s to %s', [FFileName, AVariableName, AVariableValue]), AIncludeDepth);
  finally
    if FWorkDirectory <> '' then
      SetCurrentDir(save_current_dir);
  end;
end;

constructor TConfig.Create;
begin
  inherited Create;

  FRemoveEmptyVariablesIfThereIsAnInheritedValue := true;
end;


function TConfig.HandleBuildTarget(AScriptFileName, ATargetName, ATargetCommand : String) : Boolean;
begin
  // do nothing
  Result := false;
end;

function TConfig.HandleVariable(const AScriptFileName : String; var AVariableName, AVariableValue : String; var AWhatToDoWithThisVariable : TThingsThatCanBeDoneToAVariableInAVariableHandlerMethod) : Boolean;
begin
  Result := true;
  if FWhyIAmGoingThroughThisScript = rToGetAVariableValue then
  begin
    if (AVariableName = FVariableNameToFind)
        and (FAcceptVariablesInIncludedScripts or (ExtractFileName(AScriptFileName) = Self.FFileName))
    then
    begin
      FNextToLastEncounteredVariableValue := FLastEncounteredVariableValue;
      FNextToLastEncounteredVariableInScript := FLastEncounteredVariableInScript;
      FLastEncounteredVariableValue := AVariableValue;
      FLastEncounteredVariableInScript := AScriptFileName;
      Result := not FStopProcessingScriptsAtFirstEncounterThatMatches_ALL_CRITERIA_InParticularTheInheritanceStatusThingy; // stop running the script
    end;
  end
  else
  if FWhyIAmGoingThroughThisScript = rToSetAVariableValue then
  begin
    if (AVariableName = FVariableNameToFind) then
    begin
      if (FAcceptVariablesInIncludedScripts or (ExtractFileName(AScriptFileName) = Self.FFileName))
      then
      begin
        AVariableValue := FVariableValueToSet;
        Result := not FStopProcessingScriptsAtFirstEncounterThatMatches_ALL_CRITERIA_InParticularTheInheritanceStatusThingy; // stop running the script
        if (FLastEncounteredVariableInScript <> '') // if it was already found somewhere, i.e. it has an inherited value
            and (AVariableValue = '') // and it is being set to empty
            and (FRemoveEmptyVariablesIfThereIsAnInheritedValue)
        then
          AWhatToDoWithThisVariable := doDelete
        else
          AWhatToDoWithThisVariable := doChange;
      end
      else
        AWhatToDoWithThisVariable := doNothing; // we just found an inherited value for it

      FNextToLastEncounteredVariableInScript := FLastEncounteredVariableInScript;
      FLastEncounteredVariableInScript := AScriptFileName;
    end;
  end
  else
    raise Exception.Create('Unknown why.');
end;

procedure TConfig.GetVariableValue(const AVariableName : String; var AFoundValue, AFoundInScript : String; ARunAllIncludedScriptsCompletelyToGetFinalEffectiveValue : Boolean);
var
  dummy, dummy2 : String;
begin
  dummy := '';
  dummy2 := '';
  GetVariableValueAndItsInheritedValue(AVariableName, AFoundValue, AFoundInScript, dummy, dummy2, ARunAllIncludedScriptsCompletelyToGetFinalEffectiveValue);
end;

procedure TConfig.GetVariableValueAndItsInheritedValue(const AVariableName : String; var AFoundValue, AFoundInScript, AInheritedValue, AInheritedValueScript : String; ARunAllIncludedScriptsCompletelyToGetFinalEffectiveValue : Boolean);
begin
  FWhyIAmGoingThroughThisScript := rToGetAVariableValue;
  FVariableNameToFind := AVariableName;
  FNextToLastEncounteredVariableValue := '';
  FNextToLastEncounteredVariableInScript := '';
  FLastEncounteredVariableValue := '';
  FLastEncounteredVariableInScript := '';
  FAcceptVariablesInIncludedScripts := true;
  FStopProcessingScriptsAtFirstEncounterThatMatches_ALL_CRITERIA_InParticularTheInheritanceStatusThingy := not ARunAllIncludedScriptsCompletelyToGetFinalEffectiveValue;
  Self.RunScriptFromFile(Self.FileName);
  AFoundValue := FLastEncounteredVariableValue;
  AFoundInScript := ExtractFileName(FLastEncounteredVariableInScript);
  if (AFoundInScript <> '') and (AFoundInScript <> ExtractFileName(Self.FFileName)) then
  begin // if the variable value was found in somewhere else than this script, then it must be an "inherited" value
    AInheritedValue := AFoundValue;
    AInheritedValueScript := AFoundInScript;
  end
  else
  begin
    // else, if it was found in this script itself, then it's not inherited,
    // and we give the next-to-last value (which can be empty) as the inherited value
    AInheritedValue := FNextToLastEncounteredVariableValue;
    AInheritedValueScript := ExtractFileName(FNextToLastEncounteredVariableInScript);
  end;
end;


procedure TConfig.SetVariableValue(AVariableName, AVariableValue: String);
begin
  SetVariableValue_internal(AVariableName, AVariableValue, 0);
end;

end.

