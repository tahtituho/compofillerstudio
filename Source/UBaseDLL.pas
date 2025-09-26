unit UBaseDLL;
// Compofiller Studio
// by Yzi 2017

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils
{$ifdef WINDOWS}
  , Windows
{$else}
  , FakeWindows
{$endif}
  ;

type

  { TBaseDLL }

  TBaseDLL = class(TObject)
  private
  protected
    FFilePath : String;
    FHandle: THandle;

    function GetLoaded: Boolean;
    procedure CheckFunc(AFuncPtr : Pointer; AFuncName : String);
    function CheckGetProcAddress(hModule:HINST; lpProcName:LPCSTR):FARPROC;
  public
    constructor Create(AFilePath : String); virtual;
    destructor Destroy; override;

    function Load : Boolean; virtual;
    function Unload : Boolean; virtual;

    property Loaded : Boolean read GetLoaded;
    property Handle : THandle read FHandle;
    property FilePath : String read FFilePath;
  end;

implementation

function TBaseDLL.GetLoaded: Boolean;
begin
  Result := (FHandle > 32);
end;

procedure TBaseDLL.CheckFunc(AFuncPtr: Pointer; AFuncName: String);
begin
  if AFuncPtr = nil then
    raise Exception.CreateFmt('Ouch! Could not GetProcAddress() for function %s in library %s', [AFuncName, FFilePath]);
end;

function TBaseDLL.CheckGetProcAddress(hModule: HINST; lpProcName: LPCSTR
  ): FARPROC;
begin
  Result := GetProcAddress(hModule, lpProcName);
  CheckFunc(Result, StrPas(lpProcName));
end;

constructor TBaseDLL.Create(AFilePath: String);
begin
  inherited Create;

  FFilePath := ExpandFileName(AFilePath);
end;

destructor TBaseDLL.Destroy;
begin
  if Self.Loaded then
    Unload;
  inherited Destroy;
end;

function TBaseDLL.Load: Boolean;
begin
  FHandle := LoadLibrary(PChar(FFilePath));
  Result := Self.Loaded;
  if not Result then
    raise Exception.CreateFmt('Could not LoadLibrary() %s', [FFilePath]);
end;

function TBaseDLL.Unload: Boolean;
begin
  if not Self.Loaded then
    Exit(True);

  Result := FreeLibrary(FHandle);
  if Result then
    FHandle := 0;
end;



end.

