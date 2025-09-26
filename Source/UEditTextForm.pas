unit UEditTextForm;

// general text editor, for NFO files

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ActnList;

type

  { TEditTextForm }

  TEditTextForm = class(TForm)
    ActionList1: TActionList;
    FileNameLabel: TLabel;
    SaveAction: TAction;
    SaveButton: TButton;
    CancelButton: TButton;
    TextMemo: TMemo;
    procedure CancelButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SaveActionExecute(Sender: TObject);
  private
    FFilePath : String;
    procedure SetFilePath(AValue: String);
  public
    property FilePath : String read FFilePath write SetFilePath;
    procedure DirectoryMoved(AOldDir, ANewDir : String); // "someone" should call this if the project directory moves because of "Save As"
  end;

var
  EditTextForm: TEditTextForm;

implementation

{$R *.lfm}

uses
  UEngine;

{ TEditTextForm }


procedure TEditTextForm.FormCreate(Sender: TObject);
begin
end;

procedure TEditTextForm.CancelButtonClick(Sender: TObject);
begin
  Close;
end;

procedure TEditTextForm.FormShow(Sender: TObject);
begin
  TextMemo.Lines.LoadFromFile(FFilePath);
end;

procedure TEditTextForm.SaveActionExecute(Sender: TObject);
begin
  TextMemo.Lines.SaveToFile(FFilePath);
  Close;
end;

procedure TEditTextForm.SetFilePath(AValue: String);
begin
  if FFilePath=AValue then Exit;
  FFilePath:=AValue;
  FileNameLabel.Caption := ExtractFileName(FilePath);
end;

procedure TEditTextForm.DirectoryMoved(AOldDir, ANewDir: String);
var
  p : String;
begin
  p := ForceProjectDirectoryFormat(ExtractFileDir(FFilePath));
  if (p = AOldDir) then
    FFilePath := ForceProjectDirectoryFormat(ANewDir) + ExtractFileName(FFilePath);
end;

end.

