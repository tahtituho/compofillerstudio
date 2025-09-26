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
    { private declarations }
  public
    { public declarations }
    procedure DisplayAverageFrameTime(AValue: Single);
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
  if AValue > 0.1 then
    Self.Caption := 'Avg ' + FormatFloat('0.0', 1000.0 / AValue) + ' fps'
  else
    Self.Caption := 'Avg fps not available.';
end;

end.

