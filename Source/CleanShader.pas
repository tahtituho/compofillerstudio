program CleanShader;
// Compofiller Studio by Yzi 2017
// Shader preprocessor command-line utility for running in build scripts.
// CleanShader tries to remove from GLSL shader source files stuff that Shader Minifier can't handle

{$mode objfpc}{$H+}

uses
  SysUtils,
  Classes,
  UPreprocessShader;

procedure CopyStringsButLeaveOutStuffShaderMinifierCannotHandle(AInStrings, AOutStrings : TStrings);
var
  i, j : Integer;
  s : String;
begin
  UPreprocessShader.RemoveCComments(AInStrings);
  for i := 0 to AInStrings.Count - 1 do
  begin
    s := AInStrings[i];
    if Trim(s) = 'precision mediump float;' then s := '';
    for j := 1 to Length(s) do
      if (Ord(s[j]) < 32) or (Ord(s[j]) > 126) then
        s[j] := ' ';
    AOutStrings.Add(s);
  end;
end;

procedure AbortWithMessage(AMessage : String);
begin
  WriteLn(AMessage);
  HALT;
end;

var
  infilename, outfilename : String;
  insl, outsl : TStringList;
  outstring : String;
  outfile : File;
begin
  infilename := '';
  outfilename := '';
  if ParamCount < 2 then
    AbortWithMessage('Usage: CleanShader <input file> <shader text output file>');
  
  infilename := ParamStr(1);
  outfilename := ParamStr(2);

  insl := TStringList.Create;
  try
    insl.LoadFromFile(infilename);
    if LowerCase(ExtractFileExt(infilename)) = '.h' then
    begin // .h file ... let's not try to do anything smart, we'll assume it's "clean" already
      UPreprocessShader.ShaderMinifierHToPlainString(insl, outstring, nil);
      AssignFile(outfile, outfilename);
      ReWrite(outfile, 1);
      BlockWrite(outfile, outstring[1], Length(outstring));
      CloseFile(outfile);    
      WriteLn('Wrote ', Length(outstring), ' bytes to ', outfilename, '.');	    
    end
    else
    begin
      outsl := TStringList.Create;
      CopyStringsButLeaveOutStuffShaderMinifierCannotHandle(insl, outsl);
      outsl.SaveToFile(outfilename);
      WriteLn('Wrote the text lines from ', infilename, ' to ', outfilename, ' without processing.');
      outsl.Free;
    end;

  finally
    insl.Free;
  end;
end.
