unit UConfigUIMappingHelpers;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  Controls, Forms, StdCtrls,
  UEngine;


type

  { TFormWithControlsRepresentingVariables }

  TFormWithControlsRepresentingVariables = class(TForm)
  private
    procedure SetEngine(AValue: TEngine);
  protected
    FEngine : TEngine;
    FMassUpdating : Boolean; // all sorts of bulk updates must set this to prevent changed-event cascading

  public
    function GetConfigVariableNameForControl(AControl: TControl): String; virtual; abstract;
    function GetConfigVariableValueToControl(AControl : TControl) : Boolean; virtual;
    function GetProjectVariableNameForControl(AControl: TControl): String; virtual; abstract;
    function GetProjectVariableValueToControl(AControl: TControl): Boolean; virtual;

    function SetVariableValueToControl(AControl : TControl; AVariableValue : String; AIsInheritedValue : Boolean; AScriptName : String) : Boolean; virtual;
    procedure SetAutoRebuildNeeded(AValue : Boolean); virtual; abstract;
    procedure RefreshAllAttributes(Sender : TObject); virtual; abstract;
    procedure RefreshAllStoredAttributesOfChildControls(AParent: TWinControl); virtual;
    procedure ChangeEditValueAndSaveToConfigAndRefresh(AEdit: TCustomEdit; ANewValue: String); virtual;
//    procedure ChangeEditButtonValueAndRefresh(AEdit: TEditButton; ANewValue: String); virtual;
    function SaveControlToConfig(AControl: TControl; ANewValue: String): Boolean; virtual;
    function SaveControlToProject(AControl: TControl; ANewValue: String): Boolean; virtual;

    property Engine : TEngine read FEngine write SetEngine;
  end;

implementation


uses
  EditBtn, Graphics;

{ TFormWithControlsRepresentingVariables }

procedure TFormWithControlsRepresentingVariables.SetEngine(AValue: TEngine);
begin
  if FEngine=AValue then Exit;
  FEngine:=AValue;
end;

function TFormWithControlsRepresentingVariables.GetConfigVariableValueToControl(AControl : TControl) : Boolean;
var
  variable_name : String;
  effective_value : String;
  effective_value_script_name : String;
  is_inherited_value : Boolean;
begin
  Result := false;

  variable_name := Self.GetConfigVariableNameForControl(AControl);
  if variable_name = '' then
    Exit;

  // A config variable's effective value may come from the active config script,
  // or any of the scripts it includes (or any of the scripts that the included scripts include, etc.)
  FEngine.GetEffectiveVariableValueInActiveConfigEx(variable_name, effective_value, effective_value_script_name);

  if (effective_value_script_name = '') then
  begin // not found at all... what's the default?
    // AddProcessOutputLine(Format('Warning: value for variable %s could not be determined for %s!', [variable_name, FEngine.GetActiveConfig]), 0);
    Exit;
  end
  else
  begin
    // If the value is found in a non-active config script (so it must be from an
    // included file),  we call it an "inherited" value and show the value differently.
    is_inherited_value := not (ExtractFileName(effective_value_script_name) = FEngine.ActiveConfig);

    if SetVariableValueToControl(AControl, effective_value, is_inherited_value, effective_value_script_name) then
      SetAutoRebuildNeeded(true);
  end;

  Result := true;
end; // function TFormWithControlsRepresentingVariables.GetConfigVariableValueToControl

function TFormWithControlsRepresentingVariables.GetProjectVariableValueToControl(AControl: TControl): Boolean;
var
  variable_name : String;
  effective_value : String;
begin
  Result := false;

  variable_name := Self.GetProjectVariableNameForControl(AControl);
  if variable_name = '' then
    Exit;

  // A config variable's effective value may come from the active config script,
  // or any of the scripts it includes.
  effective_value := FEngine.GetProjectVariableValue(variable_name);

  if SetVariableValueToControl(AControl, effective_value, false, '') then
    SetAutoRebuildNeeded(true);

  Result := true;
end;


function TFormWithControlsRepresentingVariables.SetVariableValueToControl(
  AControl: TControl; AVariableValue: String; AIsInheritedValue: Boolean;
  AScriptName: String): Boolean;
var
  old_string : String;
  old_boolean : Boolean;
  s : String;
  e : TCustomEdit;
  fne : TFileNameEdit;
  cb : TCheckBox;
  cmb : TCustomComboBox;
begin
  Result := false;
  AScriptName := ExtractFileName(AScriptName);
  if AControl is TFileNameEdit then   // FileNameEdit
  begin
    fne := AControl as TFileNameEdit;
    old_string := fne.Text;
    if AIsInheritedValue then
    begin
      fne.Text := '';
      fne.Font.Style := [fsItalic];
      fne.TextHint := AVariableValue + ' (' + AScriptName + ')';
    end
    else
    begin
      fne.Text := AVariableValue;
      fne.Font.Style := [fsBold];
    end;
    Result := (fne.Text <> old_string);
  end
  else
  if AControl is TCustomEdit then     // CustomEdit
  begin
    e := AControl as TCustomEdit;
    old_string := e.Text;
    if AIsInheritedValue then
    begin
      e.Text := '';
      e.Font.Style := [fsItalic];
      e.TextHint := AVariableValue + ' (' + AScriptName + ')';
    end
    else
    begin
      e.Text := AVariableValue;
      e.Font.Style := [fsBold];
    end;
    Result := (e.Text <> old_string);
  end
  else
  if AControl is TCheckBox then       // CheckBox
  begin
    cb := AControl as TCheckBox;
    old_boolean := cb.Checked;
    if AIsInheritedValue then
    begin
      cb.Checked := (AVariableValue <> '0');
      // cb.AllowGrayed := true;
      // cb.Hint := AVariableValue + ' (in ' + AScriptName + ')';
      cb.Color := clBlack;
    end
    else
    begin
      cb.Checked := (AVariableValue <> '0');
      cb.Color := clDefault;
      // cb.AllowGrayed := false
    end;
    Result := (cb.Checked <> old_boolean);
  end
  else if AControl is TCustomComboBox then       // ComboBox
  begin
    cmb := AControl as TCustomComboBox;
    old_string := cmb.Text;
    if AIsInheritedValue then
    begin
      cmb.Items.Clear;
      s := AVariableValue + ' (' + AScriptName + ')';
      cmb.Items.Add(s);
      cmb.Text := s;
      cmb.Font.Style := [fsItalic];
      cmb.Color := clBlack;
    end
    else
    begin
      cmb.Items.Clear;
      s := AVariableValue;
      cmb.Items.Add(s);
      cmb.Text := AVariableValue;
      cmb.Color := clDefault;
      cmb.Font.Style := [fsBold];
    end;
    Result := (old_string <> cmb.Text);
  end;
    ;
end; // TFormWithControlsRepresentingVariables.SetVariableValueToControl

function TFormWithControlsRepresentingVariables.SaveControlToConfig(AControl: TControl; ANewValue : String) : Boolean;
var
  variable_name : String;
begin
  if FMassUpdating then
  begin
//    ProcessOutputMemo.Lines.Add('SaveControlToConfig(' + AControl.ClassName + ', ' + ANewValue + ') MASS UPDATING!! WONT SAVE. Exit.');
    Exit;
  end;

  Result := false;

  variable_name := Self.GetConfigVariableNameForControl(AControl);
  if variable_name = '' then
    Exit;

  // If setting an empty value, the variable will get deleted
  // from the config, if there's an inherited value.
  // see TConfig.RemoveEmptyVariablesIfThereIsAnInheritedValue

  FEngine.SetVariableValueInActiveConfig(variable_name, ANewValue);

  Result := true;
end;

function TFormWithControlsRepresentingVariables.SaveControlToProject(
  AControl: TControl; ANewValue: String): Boolean;
var
  variable_name : String;
begin
  if FMassUpdating then
    Exit;

  Result := false;

  variable_name := Self.GetProjectVariableNameForControl(AControl);
  if variable_name = '' then
    Exit;

  FEngine.SetProjectVariableValue(variable_name, ANewValue);

  Result := true;
end;

procedure TFormWithControlsRepresentingVariables.ChangeEditValueAndSaveToConfigAndRefresh(AEdit: TCustomEdit; ANewValue : String);
var
  p : TPoint;
begin
  p := AEdit.CaretPos;
  SaveControlToConfig(AEdit, ANewValue);
  RefreshAllAttributes(AEdit);
  AEdit.CaretPos := p;
end;

{procedure TFormWithControlsRepresentingVariables.ChangeEditButtonValueAndRefresh
  (AEdit: TEditButton; ANewValue: String);
var
  p : TPoint;
begin
  p := AEdit.CaretPos;
  SaveControlToConfig(AEdit, ANewValue);
  RefreshAllAttributes(AEdit);
  AEdit.CaretPos := p;
end;}

procedure TFormWithControlsRepresentingVariables.RefreshAllStoredAttributesOfChildControls(AParent : TWinControl);
var
  i : Integer;
  c : TControl;
begin
  for i := 0 to AParent.ControlCount - 1 do
  begin
    c := AParent.Controls[i];
    // call recursively
    if c is TWinControl then
      RefreshAllStoredAttributesOfChildControls(c as TWinControl);

    // if it's not a config variable, it could be a project variable
    if not GetConfigVariableValueToControl(c) then
      GetProjectVariableValueToControl(c);
  end;
end;


end.

