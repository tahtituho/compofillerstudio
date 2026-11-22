unit UVisualsForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Menus;

type

  { TVisualsForm }

  TVisualsForm = class(TForm)
    StayOnTopMenuItem: TMenuItem;
    PopupMenu1: TPopupMenu;
    procedure FormShow(Sender: TObject);
    procedure StayOnTopMenuItemClick(Sender: TObject);
  private
    FAverageFrameTimeMS: Single;
    FShaderCompiling: Boolean;
    procedure UpdateCaption;
  public
    procedure DisplayAverageFrameTime(AValue: Single);
    procedure SetShaderCompiling(AValue: Boolean);
  end;

var
  VisualsForm: TVisualsForm;

implementation

{$R *.lfm}

{ TVisualsForm }


procedure TVisualsForm.FormShow(Sender: TObject);
begin
//  Self.DoubleBuffered := true;
end;

procedure TVisualsForm.StayOnTopMenuItemClick(Sender: TObject);
begin
  if StayOnTopMenuItem.Checked then
  begin
    FormStyle := fsNormal;
    StayOnTopMenuItem.Checked := false;
  end
  else
  begin
    FormStyle := fsStayOnTop;
    StayOnTopMenuItem.Checked := true;
  end;
end;

procedure TVisualsForm.DisplayAverageFrameTime(AValue : Single);
begin
  FAverageFrameTimeMS := AValue;
  UpdateCaption;
end;

procedure TVisualsForm.SetShaderCompiling(AValue: Boolean);
begin
  if FShaderCompiling = AValue then Exit;
  FShaderCompiling := AValue;
  UpdateCaption;
  Repaint;
end;

procedure TVisualsForm.UpdateCaption;
var
  status_text: String;
begin
  if FAverageFrameTimeMS > 0.1 then
    status_text := 'Avg ' + FormatFloat('0.0', 1000.0 / FAverageFrameTimeMS) + ' fps'
  else
    status_text := 'Avg fps not available.';

  if FShaderCompiling then
    Self.Caption := 'Compiling - ' + status_text
  else
    Self.Caption := status_text;
end;

end.

